using Sumpooj.Application.DayClose;

namespace Sumpooj.Application.Interfaces;

public interface ICashDrawerRepository
{
    Task<CashDrawerSummary> GetSummaryAsync(Guid companyId, DateTime date);
}