using System;
using System.Linq;
using System.Threading.Tasks;

namespace FloristERP.Domain
{
    public class PaymentCompletionHandler
    {
        private readonly IProductionJobRepository _productionJobRepository;

        public PaymentCompletionHandler(IProductionJobRepository productionJobRepository)
        {
            _productionJobRepository = productionJobRepository;
        }

        public async Task HandleOrderPaidAsync(Order order)
        {
            if (order == null) throw new ArgumentNullException(nameof(order));
            if (order.Status != OrderStatus.Paid) return;

            var customBouquetItems = order.Items
                .Where(i => i.ItemType == OrderItemType.CustomBouquet)
                .ToList();

            foreach (var item in customBouquetItems)
            {
                if (string.IsNullOrWhiteSpace(item.CustomDescription))
                    throw new InvalidOperationException("Custom bouquet item must have a description.");

                var job = new ProductionJob(
                    order.Id,
                    item.CustomDescription
                );
                await _productionJobRepository.SaveAsync(job);
            }
        }
    }

    // Repository interface for saving ProductionJob
    public interface IProductionJobRepository
    {
        Task SaveAsync(ProductionJob job);
    }
}
