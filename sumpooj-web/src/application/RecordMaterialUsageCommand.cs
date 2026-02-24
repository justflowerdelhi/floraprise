using System;
using System.Linq;
using System.Threading.Tasks;
using FloristERP.Domain;

namespace FloristERP.Application
{
    public class RecordMaterialUsageCommand
    {
        public Guid ProductionJobId { get; set; }
        public Guid ProductId { get; set; }
        public int UnitsUsed { get; set; }
    }

    public class RecordMaterialUsageHandler
    {
        private readonly IProductionJobRepository _jobRepo;
        private readonly IInventoryRepository _inventoryRepo;
        private readonly IProductionMaterialUsageRepository _usageRepo;

        public RecordMaterialUsageHandler(
            IProductionJobRepository jobRepo,
            IInventoryRepository inventoryRepo,
            IProductionMaterialUsageRepository usageRepo)
        {
            _jobRepo = jobRepo;
            _inventoryRepo = inventoryRepo;
            _usageRepo = usageRepo;
        }

        public async Task HandleAsync(RecordMaterialUsageCommand cmd)
        {
            if (cmd.UnitsUsed <= 0) throw new ArgumentOutOfRangeException(nameof(cmd.UnitsUsed));

            var job = await _jobRepo.GetByIdAsync(cmd.ProductionJobId);
            if (job == null) throw new InvalidOperationException("Production job not found.");
            if (job.Status != ProductionStatus.InProgress)
                throw new InvalidOperationException("Material usage can only be recorded for jobs InProgress.");

            // Find available batches FIFO
            var batches = await _inventoryRepo.GetAvailableBatchesAsync(cmd.ProductId);
            int remaining = cmd.UnitsUsed;
            foreach (var batch in batches.OrderBy(b => b.ReceivedDate))
            {
                if (batch.Quantity <= 0) continue;
                int use = Math.Min(batch.Quantity, remaining);
                if (use > 0)
                {
                    // Reserve and convert to usage
                    await _inventoryRepo.ReserveBatchAsync(batch.BatchId, use);
                    var usage = new ProductionMaterialUsage(job.Id, cmd.ProductId, batch.BatchId, use);
                    await _usageRepo.SaveAsync(usage);
                    remaining -= use;
                }
                if (remaining == 0) break;
            }
            if (remaining > 0)
                throw new InvalidOperationException("Not enough inventory to fulfill usage.");
        }
    }

    public interface IInventoryRepository
    {
        Task<Batch[]> GetAvailableBatchesAsync(Guid productId);
        Task ReserveBatchAsync(Guid batchId, int units);
    }

    public interface IProductionMaterialUsageRepository
    {
        Task SaveAsync(ProductionMaterialUsage usage);
    }

    public class Batch
    {
        public Guid BatchId { get; set; }
        public Guid ProductId { get; set; }
        public int Quantity { get; set; }
        public DateTime ReceivedDate { get; set; }
    }
}
