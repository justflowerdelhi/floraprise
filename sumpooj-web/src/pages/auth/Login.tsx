import { useState } from "react";
import {
  Box,
  Button,
  Card,
  CardContent,
  TextField,
  Typography,
  Alert
} from "@mui/material";
import { useNavigate } from "react-router-dom";
import { login as loginApi } from "../../api/auth.api";
import { useAuth } from "../../auth/AuthContext";

export default function Login() {
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
        alignItems: "center",
        justifyContent: "center",
        backgroundColor: "#f5f5f5"
      }}
    >
      <Card sx={{ width: 380 }}>
        <CardContent>
          <Typography variant="h5" textAlign="center" mb={2}>
            Florist ERP Login
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





