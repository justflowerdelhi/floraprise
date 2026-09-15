using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence;

public class UnitOfWork : IUnitOfWork
{
    private readonly SumpoojDbContext _db;

    public UnitOfWork(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<T> ExecuteInTransactionAsync<T>(Func<Task<T>> operation, CancellationToken cancellationToken = default)
    {
        if (!_db.Database.IsRelational())
        {
            var existingDeliveries = _db.Deliveries.AsNoTracking().ToList();
            var existingOrders = _db.Orders.AsNoTracking().ToList();
            var existingProducts = _db.Products.AsNoTracking().ToList();
            var existingDeliveryIds = existingDeliveries.Select(d => d.Id).ToHashSet();
            var existingOrderIds = existingOrders.Select(o => o.Id).ToHashSet();
            var existingLedgerIds = _db.InventoryLedgers.AsNoTracking().Select(l => l.Id).ToHashSet();
            var existingPaymentIds = _db.Payments.AsNoTracking().Select(p => p.Id).ToHashSet();

            try
            {
                return await operation();
            }
            catch
            {
                var addedOrders = _db.Orders.Where(o => !existingOrderIds.Contains(o.Id)).ToList();
                var addedPayments = _db.Payments.Where(p => !existingPaymentIds.Contains(p.Id)).ToList();
                var addedLedgers = _db.InventoryLedgers.Where(l => !existingLedgerIds.Contains(l.Id)).ToList();
                var addedDeliveries = _db.Deliveries.Where(d => !existingDeliveryIds.Contains(d.Id)).ToList();

                _db.Orders.RemoveRange(addedOrders);
                _db.Payments.RemoveRange(addedPayments);
                _db.InventoryLedgers.RemoveRange(addedLedgers);
                _db.Deliveries.RemoveRange(addedDeliveries);

                foreach (var original in existingDeliveries)
                {
                    var current = _db.Deliveries.Find(original.Id);
                    if (current != null)
                    {
                        _db.Entry(current).CurrentValues.SetValues(original);
                    }
                }

                foreach (var original in existingOrders)
                {
                    var current = _db.Orders.Find(original.Id);
                    if (current != null)
                    {
                        _db.Entry(current).CurrentValues.SetValues(original);
                    }
                }

                foreach (var original in existingProducts)
                {
                    var current = _db.Products.Find(original.Id);
                    if (current != null)
                    {
                        _db.Entry(current).CurrentValues.SetValues(original);
                    }
                }

                try
                {
                    await _db.SaveChangesAsync(cancellationToken);
                }
                catch
                {
                    // In-memory cleanup best effort
                }

                _db.ChangeTracker.Clear();
                throw;
            }
        }

        var strategy = _db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                var result = await operation();
                await transaction.CommitAsync(cancellationToken);
                return result;
            }
            catch
            {
                await transaction.RollbackAsync(cancellationToken);
                throw;
            }
        });
    }

    public async Task ExecuteInTransactionAsync(Func<Task> operation, CancellationToken cancellationToken = default)
    {
        await ExecuteInTransactionAsync<bool>(async () =>
        {
            await operation();
            return true;
        }, cancellationToken);
    }
}
