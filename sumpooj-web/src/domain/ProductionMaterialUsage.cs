using System;

namespace FloristERP.Domain
{
    public class ProductionMaterialUsage
    {
        public Guid Id { get; private set; }
        public Guid ProductionJobId { get; private set; }
        public Guid ProductId { get; private set; }
        public Guid ProductBatchId { get; private set; }
        public int UnitsUsed { get; private set; }
        public DateTime CreatedAtUtc { get; private set; }

        public ProductionMaterialUsage(Guid productionJobId, Guid productId, Guid productBatchId, int unitsUsed)
        {
            if (unitsUsed <= 0)
                throw new ArgumentOutOfRangeException(nameof(unitsUsed), "UnitsUsed must be greater than zero.");

            Id = Guid.NewGuid();
            ProductionJobId = productionJobId;
            ProductId = productId;
            ProductBatchId = productBatchId;
            UnitsUsed = unitsUsed;
            CreatedAtUtc = DateTime.UtcNow;
        }
    }
}
