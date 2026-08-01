namespace Sumpooj.Blazor.Auth;

public class OwnerAuthService
{
    private const string OwnerPassword = "admin123"; // TODO: Move to secure configuration
    private const string SecretCode = "FLORAPRISE2024"; // TODO: Move to secure configuration
    
    private bool _isAuthenticated = false;

    public bool IsAuthenticated => _isAuthenticated;

    public bool Login(string password, string secretCode)
    {
        if (password == OwnerPassword && secretCode == SecretCode)
        {
            _isAuthenticated = true;
            return true;
        }
        return false;
    }

    public void Logout()
    {
        _isAuthenticated = false;
    }
}
