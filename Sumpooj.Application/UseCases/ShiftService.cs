using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Shifts;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class ShiftService
{
    private readonly IShiftRepository _shiftRepository;

    public ShiftService(IShiftRepository shiftRepository)
    {
        _shiftRepository = shiftRepository;
    }

    /// <summary>
    /// Get the currently-open shift for a location, or null if none.
    /// </summary>
    public async Task<ShiftDto?> GetActiveShiftAsync(Guid companyId, Guid locationId)
    {
        var shift = await _shiftRepository.GetActiveShiftAsync(companyId, locationId);
        return shift == null ? null : MapToDto(shift);
    }

    /// <summary>
    /// Get a shift by ID.
    /// </summary>
    public async Task<ShiftDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var shift = await _shiftRepository.GetByIdAsync(companyId, id);
        return shift == null ? null : MapToDto(shift);
    }

    /// <summary>
    /// Get recent shift history for a location.
    /// </summary>
    public async Task<List<ShiftDto>> GetHistoryAsync(Guid companyId, Guid locationId, int count = 20)
    {
        var shifts = await _shiftRepository.GetHistoryAsync(companyId, locationId, count);
        return shifts.Select(MapToDto).ToList();
    }

    /// <summary>
    /// Open a new shift. Throws if a shift is already open at the location.
    /// </summary>
    public async Task<Guid> OpenAsync(Guid companyId, OpenShiftRequest request, Guid userId, string userName)
    {
        var existing = await _shiftRepository.GetActiveShiftAsync(companyId, request.LocationId);
        if (existing != null)
            throw new InvalidOperationException("A shift is already open at this location. Close it before opening a new one.");

        var shift = new Shift(
            companyId,
            request.LocationId,
            userId,
            userName,
            request.OpeningCash);

        await _shiftRepository.AddAsync(shift);
        return shift.Id;
    }

    /// <summary>
    /// Close the active shift at a location.
    /// </summary>
    public async Task CloseAsync(Guid companyId, Guid shiftId, CloseShiftRequest request, Guid userId, string userName)
    {
        var shift = await _shiftRepository.GetByIdAsync(companyId, shiftId)
            ?? throw new InvalidOperationException("Shift not found");

        shift.Close(userId, userName, request.ClosingCashCount, request.Notes);
        await _shiftRepository.UpdateAsync(shift);
    }

    /// <summary>
    /// Record a sale on the active shift (called internally when a POS order completes).
    /// </summary>
    public async Task RecordSaleAsync(Guid companyId, Guid locationId,
        decimal cash, decimal card, decimal upi, decimal giftCard, decimal other)
    {
        var shift = await _shiftRepository.GetActiveShiftAsync(companyId, locationId);
        if (shift == null) return; // No active shift — skip silently

        shift.RecordSale(cash, card, upi, giftCard, other);
        await _shiftRepository.UpdateAsync(shift);
    }

    /// <summary>
    /// Record a refund on the active shift.
    /// </summary>
    public async Task RecordRefundAsync(Guid companyId, Guid locationId, decimal amount)
    {
        var shift = await _shiftRepository.GetActiveShiftAsync(companyId, locationId);
        if (shift == null) return;

        shift.RecordRefund(amount);
        await _shiftRepository.UpdateAsync(shift);
    }

    // ─── Mapping ────────────────────────────────────────

    private static ShiftDto MapToDto(Shift s) => new()
    {
        Id = s.Id,
        LocationId = s.LocationId,
        OpenedByUserId = s.OpenedByUserId,
        OpenedByName = s.OpenedByName,
        OpenedAt = s.OpenedAt,
        OpeningCash = s.OpeningCash,
        ClosedByUserId = s.ClosedByUserId,
        ClosedByName = s.ClosedByName,
        ClosedAt = s.ClosedAt,
        ClosingCashCount = s.ClosingCashCount,
        CashDifference = s.CashDifference,
        CashSales = s.CashSales,
        CardSales = s.CardSales,
        UpiSales = s.UpiSales,
        GiftCardSales = s.GiftCardSales,
        OtherSales = s.OtherSales,
        TotalRefunds = s.TotalRefunds,
        PaidOuts = s.PaidOuts,
        TransactionCount = s.TransactionCount,
        ExpectedCash = s.ExpectedCash,
        Status = s.Status.ToString(),
        IsClosed = s.IsClosed,
        Notes = s.Notes,
    };
}
