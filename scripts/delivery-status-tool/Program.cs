using Npgsql;

if (args.Length < 2)
{
    Console.Error.WriteLine("Usage: delivery-status-tool <deliveryId> <statusInt>");
    return 1;
}

if (!Guid.TryParse(args[0], out var deliveryId))
{
    Console.Error.WriteLine("Invalid deliveryId");
    return 1;
}

if (!int.TryParse(args[1], out var statusInt))
{
    Console.Error.WriteLine("Invalid statusInt");
    return 1;
}

var cs = "Host=localhost;Port=5432;Database=FloristERP;Username=postgres;Password=postgres123";

await using var conn = new NpgsqlConnection(cs);
await conn.OpenAsync();

await using (var cmd = new NpgsqlCommand("UPDATE \"Deliveries\" SET \"Status\"=@s, \"UpdatedAtUtc\"=NOW() WHERE \"Id\"=@id", conn))
{
    cmd.Parameters.AddWithValue("s", statusInt);
    cmd.Parameters.AddWithValue("id", deliveryId);
    var rows = await cmd.ExecuteNonQueryAsync();
    Console.WriteLine($"RowsUpdated={rows}");
}

await using (var cmd = new NpgsqlCommand("SELECT \"Id\", \"Status\", \"DeliveryPersonId\", \"DeliveryRouteId\" FROM \"Deliveries\" WHERE \"Id\"=@id", conn))
{
    cmd.Parameters.AddWithValue("id", deliveryId);
    await using var reader = await cmd.ExecuteReaderAsync();
    while (await reader.ReadAsync())
    {
        var id = reader.GetGuid(0);
        var status = reader.GetInt32(1);
        var person = reader.IsDBNull(2) ? "null" : reader.GetGuid(2).ToString();
        var route = reader.IsDBNull(3) ? "null" : reader.GetGuid(3).ToString();
        Console.WriteLine($"DeliveryId={id} Status={status} DeliveryPersonId={person} DeliveryRouteId={route}");
    }
}

return 0;
