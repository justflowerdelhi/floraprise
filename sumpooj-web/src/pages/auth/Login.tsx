import { useState } from "react";
import {
  Box,
  Button,
  Card,
  CardContent,
  TextField,
  Typography,
  Alert,
  useTheme
} from "@mui/material";
import { useNavigate } from "react-router-dom";
import { login as loginApi } from "../../api/auth.api";
import { useAuth } from "../../auth/AuthContext";

export default function Login() {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");

  const auth = useAuth();
  const navigate = useNavigate();

  const submit = async () => {
    setError("");

    if (!email || !password) {
      setError("Email and password are required");
      return;
    }

    try {
      const res = await loginApi(email, password);
      auth.login(res.access_token);
      navigate("/customers");
    } catch {
      setError("Invalid email or password");
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
          >
            Login
          </Button>
        </CardContent>
      </Card>
    </Box>
  );
}





