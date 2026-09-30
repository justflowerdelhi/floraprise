namespace Sumpooj.Application.Interfaces;

public interface IFcmNotificationService
{
    Task<bool> SendDataNotificationAsync(string pushToken, IDictionary<string, string> data, CancellationToken cancellationToken = default);
    Task<int> SendDataNotificationMulticastAsync(IEnumerable<string> pushTokens, IDictionary<string, string> data, CancellationToken cancellationToken = default);
}
