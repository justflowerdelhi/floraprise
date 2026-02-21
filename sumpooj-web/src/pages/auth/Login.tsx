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
import { login as loginApi } from "../../api/auth.api";
import { useAuth } from "../../auth/AuthContext";
import { useToast } from "../../hooks/useToast";

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

    if (!email || !password) {
      setError("Email and password are required");
      return;
    }

    setLoading(true);
    try {
      const res = await loginApi(email, password);
      // Pass user & tenant directly from login response (no extra /auth/me call)
      await auth.login(res.access_token, res.user as any, res.tenant as any);
      toast.success('Welcome back!');
      navigate("/pos");
    } catch {
      setError("Invalid email or password");
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
          src={dk ? '/assets/logo/floraedge-logo-light.svg' : '/assets/logo/floraedge-logo.svg'}
          alt="FloraEdge"
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
          />

          <TextField
            label="Password"
            type="password"
            fullWidth
            margin="normal"
            value={password}
            onChange={e => setPassword(e.target.value)}
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





