using Sumpooj.Application.Mobile;

namespace Sumpooj.API.Services.Mobile;

public interface IPosSaleSyncService
{
    Task<PosSaleSyncResponse> SyncAsync(
        Guid companyId,
        Guid mobileUserId,
        Guid identityUserId,
        string deviceId,
        PosSaleSyncRequest request,
        string payloadHash,
        CancellationToken cancellationToken = default);
}