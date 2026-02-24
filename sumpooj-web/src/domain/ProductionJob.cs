using System;

namespace FloristERP.Domain
{
    public enum ProductionStatus
    {
        Pending,
        InProgress,
        Completed,
        Cancelled
    }

    public class ProductionJob
    {
        public Guid Id { get; private set; }
        public Guid OrderId { get; private set; }
        public string Description { get; private set; }
        public ProductionStatus Status { get; private set; }
        public DateTime CreatedAtUtc { get; private set; }

        public ProductionJob(Guid orderId, string description)
        {
            Id = Guid.NewGuid();
            OrderId = orderId;
            Description = description ?? throw new ArgumentNullException(nameof(description));
            Status = ProductionStatus.Pending;
            CreatedAtUtc = DateTime.UtcNow;
        }

        public void Start()
        {
            if (Status != ProductionStatus.Pending)
                throw new InvalidOperationException("Job can only be started from Pending state.");
            Status = ProductionStatus.InProgress;
        }

        public void Complete()
        {
            if (Status != ProductionStatus.InProgress)
                throw new InvalidOperationException("Job can only be completed from InProgress state.");
            Status = ProductionStatus.Completed;
        }

        public void Cancel()
        {
            if (Status == ProductionStatus.Completed)
                throw new InvalidOperationException("Cannot cancel a completed job.");
            Status = ProductionStatus.Cancelled;
        }
    }
}
