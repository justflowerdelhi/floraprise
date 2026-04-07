using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using System.Data;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class ProductRepository : IProductRepository
{
    private readonly SumpoojDbContext _db;

    public ProductRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<Product?> GetByIdAsync(Guid id)
        => _db.Products
            .Include(p => p.ProductCategoryRef)
            .Include(p => p.TaxRule)
            .FirstOrDefaultAsync(p => p.Id == id);

    public Task<Product?> GetBySkuAsync(string sku)
        => _db.Products
            .Include(p => p.ProductCategoryRef)
            .Include(p => p.TaxRule)
            .FirstOrDefaultAsync(p => p.Sku == sku);

    public async Task AddAsync(Product product)
    {
        _db.Products.Add(product);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Product product)
    {
        _db.Products.Update(product);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(Product product)
    {
        _db.Products.Remove(product);
        await _db.SaveChangesAsync();
    }

    public async Task ForceDeleteWithReferencesAsync(Guid companyId, Guid productId)
    {
        await using var tx = await _db.Database.BeginTransactionAsync();
        var conn = _db.Database.GetDbConnection();
        if (conn.State != ConnectionState.Open)
        {
            await conn.OpenAsync();
        }

        var dbTx = _db.Database.CurrentTransaction?.GetDbTransaction();

        var productIdTables = await GetTablesWithColumnsAsync(conn, dbTx, "ProductId");
        foreach (var (tableName, hasCompanyId) in productIdTables)
        {
            if (string.Equals(tableName, "Products", StringComparison.OrdinalIgnoreCase))
                continue;

            await ExecuteDmlAsync(
                conn,
                dbTx,
                $"DELETE FROM {QuoteIdentifier(tableName)} WHERE \"ProductId\" = @productId" + (hasCompanyId ? " AND \"CompanyId\" = @companyId" : string.Empty),
                companyId,
                productId,
                hasCompanyId);
        }

        var defaultProductTables = await GetTablesWithColumnsAsync(conn, dbTx, "DefaultProductId");
        foreach (var (tableName, hasCompanyId) in defaultProductTables)
        {
            await ExecuteDmlAsync(
                conn,
                dbTx,
                $"UPDATE {QuoteIdentifier(tableName)} SET \"DefaultProductId\" = NULL WHERE \"DefaultProductId\" = @productId" + (hasCompanyId ? " AND \"CompanyId\" = @companyId" : string.Empty),
                companyId,
                productId,
                hasCompanyId);
        }

        await ExecuteDmlAsync(
            conn,
            dbTx,
            "DELETE FROM \"Products\" WHERE \"Id\" = @productId AND \"CompanyId\" = @companyId",
            companyId,
            productId,
            includeCompanyId: true);

        await tx.CommitAsync();
    }

    private static async Task<List<(string TableName, bool HasCompanyId)>> GetTablesWithColumnsAsync(
        System.Data.Common.DbConnection conn,
        System.Data.Common.DbTransaction? tx,
        string keyColumn)
    {
        await using var cmd = conn.CreateCommand();
        cmd.Transaction = tx;
        cmd.CommandText = @"
SELECT c.table_name,
       MAX(CASE WHEN c.column_name = 'CompanyId' THEN 1 ELSE 0 END) AS has_company
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name IN (
      SELECT table_name
      FROM information_schema.columns
      WHERE table_schema = 'public' AND column_name = @keyColumn
  )
  AND c.column_name IN (@keyColumn, 'CompanyId')
GROUP BY c.table_name";

        var p = cmd.CreateParameter();
        p.ParameterName = "@keyColumn";
        p.Value = keyColumn;
        cmd.Parameters.Add(p);

        var rows = new List<(string TableName, bool HasCompanyId)>();
        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            rows.Add((
                reader.GetString(0),
                reader.GetInt32(1) == 1
            ));
        }

        return rows;
    }

    private static async Task ExecuteDmlAsync(
        System.Data.Common.DbConnection conn,
        System.Data.Common.DbTransaction? tx,
        string sql,
        Guid companyId,
        Guid productId,
        bool includeCompanyId)
    {
        await using var cmd = conn.CreateCommand();
        cmd.Transaction = tx;
        cmd.CommandText = sql;

        var productParam = cmd.CreateParameter();
        productParam.ParameterName = "@productId";
        productParam.Value = productId;
        cmd.Parameters.Add(productParam);

        if (includeCompanyId)
        {
            var companyParam = cmd.CreateParameter();
            companyParam.ParameterName = "@companyId";
            companyParam.Value = companyId;
            cmd.Parameters.Add(companyParam);
        }

        await cmd.ExecuteNonQueryAsync();
    }

    private static string QuoteIdentifier(string identifier)
        => $"\"{identifier.Replace("\"", "\"\"")}\"";

    public async Task<(List<Product> Items, int TotalCount)> SearchAsync(
        string? query,
        string? productType,
        string? category,
        bool? isActive,
        bool? isPerishable,
        bool? lowStockOnly,
        int page,
        int pageSize)
    {
        var q = _db.Products.AsNoTracking()
            .Include(p => p.ProductCategoryRef)
            .Include(p => p.TaxRule)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query))
        {
            query = query.ToLower();
            q = q.Where(p =>
                p.Name.ToLower().Contains(query) ||
                p.Sku.ToLower().Contains(query) ||
                (p.Description != null && p.Description.ToLower().Contains(query)));
        }

        if (!string.IsNullOrWhiteSpace(productType))
        {
            if (Enum.TryParse<ProductType>(productType, true, out var pt))
            {
                q = q.Where(p => p.ProductType == pt);
            }
        }

        if (!string.IsNullOrWhiteSpace(category))
        {
            if (Enum.TryParse<ProductCategory>(category, true, out var cat))
            {
                q = q.Where(p => p.Category == cat);
            }
        }

        if (isActive.HasValue)
        {
            q = q.Where(p => p.IsActive == isActive.Value);
        }

        if (isPerishable.HasValue)
        {
            q = q.Where(p => p.ProductCategoryRef != null && p.ProductCategoryRef.IsPerishable == isPerishable.Value);
        }

        if (lowStockOnly == true)
        {
            q = q.Where(p => p.StockQuantity <= p.MinimumStockLevel);
        }

        var total = await q.CountAsync();

        var items = await q
            .OrderBy(p => p.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task<List<Product>> GetLowStockProductsAsync()
    {
        return await _db.Products
            .AsNoTracking()
            .Where(p => p.IsActive && p.TrackInventory && p.StockQuantity <= p.MinimumStockLevel)
            .OrderBy(p => p.StockQuantity)
            .ToListAsync();
    }

    public async Task<List<Product>> GetProductsNeedingReorderAsync()
    {
        return await _db.Products
            .AsNoTracking()
            .Where(p => p.IsActive && p.TrackInventory && p.StockQuantity <= p.ReorderLevel)
            .OrderBy(p => p.StockQuantity)
            .ToListAsync();
    }

    public async Task<bool> SkuExistsAsync(string sku, Guid? excludeProductId = null)
    {
        var query = _db.Products.Where(p => p.Sku == sku);

        if (excludeProductId.HasValue)
        {
            query = query.Where(p => p.Id != excludeProductId.Value);
        }

        return await query.AnyAsync();
    }

    public async Task<int> GetLowStockCountAsync(Guid companyId)
    {
        return await _db.Products
            .CountAsync(p => p.CompanyId == companyId && 
                            p.IsActive && 
                            p.TrackInventory && 
                            p.StockQuantity <= p.MinimumStockLevel);
    }

    public async Task<List<Product>> GetProductsWithoutCategoryAsync()
    {
        return await _db.Products
            .IgnoreQueryFilters()
            .Where(p => p.CategoryId == null)
            .ToListAsync();
    }

    public Task<Product?> GetByIdAsync(Guid companyId, Guid id)
        => _db.Products
            .Include(p => p.ProductCategoryRef)
            .Include(p => p.TaxRule)
            .FirstOrDefaultAsync(p => p.CompanyId == companyId && p.Id == id);

    public async Task<List<Product>> GetAllAsync(Guid companyId)
    {
        return await _db.Products
            .AsNoTracking()
            .Where(p => p.CompanyId == companyId && p.IsActive)
            .OrderBy(p => p.Name)
            .ToListAsync();
    }

    public Task<Product?> GetByBarcodeAsync(string barcode)
        => _db.Products
            .Include(p => p.ProductCategoryRef)
            .FirstOrDefaultAsync(p => p.Barcode == barcode);
}
