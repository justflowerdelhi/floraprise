$ErrorActionPreference = 'Stop'

Add-Type -Path 'Sumpooj.API/bin/Debug/net10.0/Npgsql.dll'
$connString = 'Host=148.72.210.248;Port=5432;Database=FloristERP;Username=postgres;Password=postgres123'

$sql = @'
WITH incomplete_orders AS (
    SELECT
        o."Id",
        o."CompanyId",
        o."OrderNumber",
        COALESCE(SUM(CASE WHEN j."Description" ILIKE '%payment%' THEN 1 ELSE 0 END),0) AS payment_entries,
        COALESCE(SUM(CASE WHEN j."Description" ILIKE '%revenue%' THEN 1 ELSE 0 END),0) AS revenue_entries,
        COALESCE(SUM(CASE WHEN j."Description" ILIKE '%cogs%' THEN 1 ELSE 0 END),0) AS cogs_entries,
        COALESCE(SUM(CASE WHEN j."Description" ILIKE '%inventory reduction%' THEN 1 ELSE 0 END),0) AS inventory_reduction_entries
    FROM "Orders" o
    LEFT JOIN "JournalEntries" j
      ON j."CompanyId" = o."CompanyId"
     AND j."Reference" = o."OrderNumber"
    WHERE o."Status" = 5
      AND o."PaymentStatus" = 2
    GROUP BY o."Id", o."CompanyId", o."OrderNumber"
)
SELECT *
FROM incomplete_orders
WHERE payment_entries = 0
   OR revenue_entries = 0
   OR cogs_entries = 0
   OR inventory_reduction_entries = 0
ORDER BY "OrderNumber";
'@

$conn = [Npgsql.NpgsqlConnection]::new($connString)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = $sql
$reader = $cmd.ExecuteReader()
$rows = @()
while ($reader.Read()) {
    $rows += [pscustomobject]@{
        Id = $reader['Id']
        CompanyId = $reader['CompanyId']
        OrderNumber = $reader['OrderNumber']
        PaymentEntries = $reader['payment_entries']
        RevenueEntries = $reader['revenue_entries']
        CogsEntries = $reader['cogs_entries']
        InventoryReductionEntries = $reader['inventory_reduction_entries']
    }
}
$reader.Close()
$conn.Close()

Write-Output "Found $($rows.Count) incomplete completed+paid orders"
$rows | Select-Object -First 100 | Format-Table -AutoSize