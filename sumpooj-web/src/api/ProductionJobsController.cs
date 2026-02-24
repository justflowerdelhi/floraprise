using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using FloristERP.Domain;

namespace FloristERP.Api
{
    [ApiController]
    [Route("api/production-jobs")]
    public class ProductionJobsController : ControllerBase
    {
        private readonly IProductionJobRepository _repository;
        private readonly IOrderRepository _orderRepository;

        public ProductionJobsController(IProductionJobRepository repository, IOrderRepository orderRepository)
        {
            _repository = repository;
            _orderRepository = orderRepository;
        }

        [HttpGet]
        public async Task<IActionResult> Get([FromQuery] ProductionStatus? status = null)
        {
            var jobs = await _repository.GetAllAsync();
            if (status.HasValue)
                jobs = jobs.Where(j => j.Status == status.Value).ToList();

            // Fetch order numbers for jobs
            var orderIds = jobs.Select(j => j.OrderId).Distinct().ToList();
            var orders = await _orderRepository.GetOrdersByIdsAsync(orderIds);
            var orderNumberMap = orders.ToDictionary(o => o.Id, o => o.OrderNumber);

            var result = jobs
                .OrderBy(j => j.CreatedAtUtc)
                .Select(j => new
                {
                    JobId = j.Id,
                    OrderId = j.OrderId,
                    OrderNumber = orderNumberMap.TryGetValue(j.OrderId, out var num) ? num : null,
                    Description = j.Description,
                    Status = j.Status.ToString(),
                    CreatedAtUtc = j.CreatedAtUtc
                })
                .ToList();

            return Ok(result);
        }
    }

    public interface IOrderRepository
    {
        Task<List<Order>> GetOrdersByIdsAsync(IEnumerable<Guid> orderIds);
    }
}
