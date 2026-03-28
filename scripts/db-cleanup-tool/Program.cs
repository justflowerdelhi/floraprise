using Npgsql;
using NpgsqlTypes;

var connString = Environment.GetEnvironmentVariable("FLORISTERP_DB")
    ?? "Host=148.72.210.248;Port=5432;Database=FloristERP;Username=postgres;Password=postgres123";

var doDelete = args.Contains("--delete", StringComparer.OrdinalIgnoreCase);
var targetOrderNumbers = ParseTargetOrderNumbers(args);

const string CandidateSql = @"
WITH incomplete_orders AS (
    SELECT
        o.""Id"",
        o.""CompanyId"",
        o.""OrderNumber"",
        COALESCE(SUM(CASE WHEN j.""Description"" ILIKE '%payment%' THEN 1 ELSE 0 END),0) AS payment_entries,
        COALESCE(SUM(CASE WHEN j.""Description"" ILIKE '%revenue%' THEN 1 ELSE 0 END),0) AS revenue_entries,
        COALESCE(SUM(CASE WHEN j.""Description"" ILIKE '%cogs%' THEN 1 ELSE 0 END),0) AS cogs_entries,
        COALESCE(SUM(CASE WHEN j.""Description"" ILIKE '%inventory reduction%' THEN 1 ELSE 0 END),0) AS inventory_reduction_entries
    FROM ""Orders"" o
    LEFT JOIN ""JournalEntries"" j
      ON j.""CompanyId"" = o.""CompanyId""
     AND j.""Reference"" = o.""OrderNumber""
    WHERE o.""Status"" = 5
      AND o.""PaymentStatus"" = 2
    GROUP BY o.""Id"", o.""CompanyId"", o.""OrderNumber""
)
SELECT ""Id"", ""CompanyId"", ""OrderNumber"", payment_entries, revenue_entries, cogs_entries, inventory_reduction_entries
FROM incomplete_orders
WHERE payment_entries = 0
   OR revenue_entries = 0
   OR cogs_entries = 0
   OR inventory_reduction_entries = 0
ORDER BY ""OrderNumber"";
";

const string DeleteSql = @"
WITH keys AS (
    SELECT *
    FROM unnest(@ids::uuid[], @company_ids::uuid[], @order_numbers::text[])
         AS k(""Id"", ""CompanyId"", ""OrderNumber"")
),
del_inv AS (
    DELETE FROM ""InventoryLedgers"" l
    USING keys k
    WHERE l.""CompanyId"" = k.""CompanyId""
      AND l.""Reference"" = k.""OrderNumber""
    RETURNING l.""Id""
),
del_journal AS (
    DELETE FROM ""JournalEntries"" j
    USING keys k
    WHERE j.""CompanyId"" = k.""CompanyId""
      AND j.""Reference"" = k.""OrderNumber""
    RETURNING j.""Id""
),
del_pay_tx AS (
    DELETE FROM ""PaymentTransactions"" pt
    USING keys k
    WHERE pt.""OrderId"" = k.""Id""
    RETURNING pt.""Id""
),
del_payments AS (
    DELETE FROM ""Payments"" p
    USING keys k
    WHERE p.""OrderId"" = k.""Id""
    RETURNING p.""Id""
),
del_items AS (
    DELETE FROM ""OrderItems"" oi
    USING keys k
    WHERE oi.""OrderId"" = k.""Id""
    RETURNING oi.""Id""
),
del_orders AS (
    DELETE FROM ""Orders"" o
    USING keys k
    WHERE o.""Id"" = k.""Id""
    RETURNING o.""Id""
)
SELECT
    (SELECT COUNT(*) FROM keys) AS orders_targeted,
    (SELECT COUNT(*) FROM del_inv) AS inventory_ledgers_deleted,
    (SELECT COUNT(*) FROM del_journal) AS journal_entries_deleted,
    (SELECT COUNT(*) FROM del_pay_tx) AS payment_transactions_deleted,
    (SELECT COUNT(*) FROM del_payments) AS payments_deleted,
    (SELECT COUNT(*) FROM del_items) AS order_items_deleted,
    (SELECT COUNT(*) FROM del_orders) AS orders_deleted;
";

await using var conn = new NpgsqlConnection(connString);
await conn.OpenAsync();

var candidates = new List<(Guid Id, Guid CompanyId, string OrderNumber, int Payment, int Revenue, int Cogs, int InvRed)>();
await using (var cmd = new NpgsqlCommand(CandidateSql, conn))
await using (var reader = await cmd.ExecuteReaderAsync())
{
    while (await reader.ReadAsync())
    {
        candidates.Add((
            reader.GetGuid(0),
            reader.GetGuid(1),
            reader.GetString(2),
            reader.GetInt32(3),
            reader.GetInt32(4),
            reader.GetInt32(5),
            reader.GetInt32(6)
        ));
    }
}

var selected = candidates;
if (targetOrderNumbers.Count > 0)
{
    selected = candidates
        .Where(c => targetOrderNumbers.Contains(c.OrderNumber, StringComparer.OrdinalIgnoreCase))
        .ToList();
}

Console.WriteLine($"Found {candidates.Count} incomplete completed+paid orders.");
if (targetOrderNumbers.Count > 0)
{
    Console.WriteLine($"Target filter applied: {targetOrderNumbers.Count} order number(s). Matches found: {selected.Count}.");
}

foreach (var c in selected.Take(50))
{
    Console.WriteLine($"- {c.OrderNumber}  payment:{c.Payment} revenue:{c.Revenue} cogs:{c.Cogs} invRed:{c.InvRed}");
}

if (!doDelete)
{
    Console.WriteLine("Preview only. Re-run with --delete to apply cleanup.");
    return;
}

if (selected.Count == 0)
{
    Console.WriteLine("No matching incomplete orders selected for deletion.");
    return;
}

await using var tx = await conn.BeginTransactionAsync();
await using (var del = new NpgsqlCommand(DeleteSql, conn, tx))
{
    var ids = selected.Select(s => s.Id).ToArray();
    var companyIds = selected.Select(s => s.CompanyId).ToArray();
    var orderNumbers = selected.Select(s => s.OrderNumber).ToArray();

    del.Parameters.Add(new NpgsqlParameter<Guid[]>("ids", NpgsqlDbType.Array | NpgsqlDbType.Uuid) { Value = ids });
    del.Parameters.Add(new NpgsqlParameter<Guid[]>("company_ids", NpgsqlDbType.Array | NpgsqlDbType.Uuid) { Value = companyIds });
    del.Parameters.Add(new NpgsqlParameter<string[]>("order_numbers", NpgsqlDbType.Array | NpgsqlDbType.Text) { Value = orderNumbers });

    await using var r = await del.ExecuteReaderAsync();
    if (await r.ReadAsync())
    {
        Console.WriteLine("Cleanup summary:");
        Console.WriteLine($"orders_targeted={r.GetInt64(0)}");
        Console.WriteLine($"inventory_ledgers_deleted={r.GetInt64(1)}");
        Console.WriteLine($"journal_entries_deleted={r.GetInt64(2)}");
        Console.WriteLine($"payment_transactions_deleted={r.GetInt64(3)}");
        Console.WriteLine($"payments_deleted={r.GetInt64(4)}");
        Console.WriteLine($"order_items_deleted={r.GetInt64(5)}");
        Console.WriteLine($"orders_deleted={r.GetInt64(6)}");
    }
}
await tx.CommitAsync();
Console.WriteLine("Cleanup committed.");

static HashSet<string> ParseTargetOrderNumbers(string[] args)
{
    var result = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

    for (var i = 0; i < args.Length; i++)
    {
        var arg = args[i];

        if (arg.StartsWith("--order=", StringComparison.OrdinalIgnoreCase))
        {
            AddOrders(result, arg[8..]);
            continue;
        }

        if (arg.Equals("--order", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
        {
            AddOrders(result, args[++i]);
            continue;
        }

        if (arg.StartsWith("--orders=", StringComparison.OrdinalIgnoreCase))
        {
            AddOrders(result, arg[9..]);
        }
    }

    return result;
}

static void AddOrders(HashSet<string> destination, string raw)
{
    foreach (var part in raw.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
    {
        if (!string.IsNullOrWhiteSpace(part))
        {
            destination.Add(part.Trim());
        }
    }
}
