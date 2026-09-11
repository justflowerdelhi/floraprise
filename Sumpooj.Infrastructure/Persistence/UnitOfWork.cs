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
            var trackedBefore = _db.ChangeTracker.Entries()
                .Select(e => e.Entity)
                .ToHashSet();

            try
            {
                return await operation();
            }
            catch
            {
                var trackedOrders = _db.ChangeTracker.Entries<Order>().Select(e => e.Entity).ToList();
                var trackedPayments = _db.ChangeTracker.Entries<Payment>().Select(e => e.Entity).ToList();
                var trackedLedgers = _db.ChangeTracker.Entries<InventoryLedger>().Select(e => e.Entity).ToList();
                var trackedDeliveries = _db.ChangeTracker.Entries<Delivery>().Select(e => e.Entity).ToList();

                _db.Orders.RemoveRange(trackedOrders);
                _db.Payments.RemoveRange(trackedPayments);
                _db.InventoryLedgers.RemoveRange(trackedLedgers);
                _db.Deliveries.RemoveRange(trackedDeliveries);

                foreach (var entry in _db.ChangeTracker.Entries().ToList())
                {
                    if (entry.State == EntityState.Modified)
                    {
                        entry.Reload();
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
