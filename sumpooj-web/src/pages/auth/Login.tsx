import { useState } from "react";
import {
  Box,
  Button,
  Card,
  CardContent,
  TextField,
  Typography,
  Alert,
  CircularProgress,
  useTheme
} from "@mui/material";
import { useNavigate } from "react-router-dom";
import { login as loginApi, normalizeRole } from "../../api/auth.api";
import { useAuth } from "../../auth/AuthContext";
import { useToast } from "../../hooks/useToast";
import { DEFAULT_LANDING } from "../../core/rbac/RBACTypes";

export default function Login() {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const auth = useAuth();
  const navigate = useNavigate();
  const toast = useToast();

  const submit = async () => {
    setError("");
    const trimmedEmail = email.trim();

    if (!trimmedEmail || !password) {
      setError("Email and password are required");
      return;
    }

    setLoading(true);
    try {
      const res = await loginApi(trimmedEmail, password);
      // Normalize backend role to frontend role, then pass to auth context
      const normalizedUser = {
        ...res.user,
        role: normalizeRole(res.user.role),
      };
      await auth.login(res.access_token, normalizedUser as any, res.tenant as any, res.refresh_token);
      toast.success('Welcome back!');
      // Role-based landing page
      const landing = DEFAULT_LANDING[normalizedUser.role] ?? '/home';
      navigate(landing);
    } catch (err: any) {
      // Show the actual backend message if available, otherwise a generic one
      const backendMsg = err?.response?.data?.message;
      const statusCode = err?.response?.status;
      if (backendMsg) {
        setError(backendMsg);
      } else if (statusCode) {
        setError(`Login failed (HTTP ${statusCode}). Please try again.`);
      } else if (err?.code === 'ERR_NETWORK') {
        setError("Cannot reach the server. Please check your internet connection.");
      } else {
        setError("Invalid email or password");
      }
      console.error('Login error:', err);
      toast.error("Login failed. Please check your credentials.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box
      sx={{
        minHeight: "100vh",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        backgroundColor: dk ? "#1F2937" : "#F9FAFB",
        gap: 3
      }}
    >
      {/* Logo */}
      <Box sx={{ textAlign: 'center' }}>
        <img 
          src={dk ? '/assets/logo/floraprise-logo-light.svg' : '/assets/logo/floraprise-logo.svg'}
          alt="FloraPrice"
          style={{ height: '48px', marginBottom: '16px' }}
        />
        <Typography 
          variant="body2" 
          sx={{ 
            color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary',
            fontWeight: 500,
            letterSpacing: 0.5
          }}
        >
          Floral Intelligence for Modern Florists
        </Typography>
      </Box>

      <Card sx={{ width: 380, boxShadow: 3 }}>
        <CardContent sx={{ p: 4 }}>
          <Typography variant="h5" textAlign="center" mb={3} fontWeight={600}>
            Welcome Back
          </Typography>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          <TextField
            label="Email"
            fullWidth
            margin="normal"
            value={email}
            onChange={e => setEmail(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && submit()}
            autoComplete="email"
          />

          <TextField
            label="Password"
            type="password"
            fullWidth
            margin="normal"
            value={password}
            onChange={e => setPassword(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && submit()}
            autoComplete="current-password"
          />

          <Button
            variant="contained"
            fullWidth
            sx={{ mt: 2 }}
            onClick={submit}
            disabled={loading}
            startIcon={loading ? <CircularProgress size={18} color="inherit" /> : undefined}
          >
            {loading ? 'Signing in…' : 'Login'}
          </Button>
        </CardContent>
      </Card>
    </Box>
  );
}





