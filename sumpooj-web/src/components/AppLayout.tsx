import {
  AppBar,
  Toolbar,
  Typography,
  Button,
  Container
} from "@mui/material";
import { useAuth } from "../auth/AuthContext";
import { useNavigate } from "react-router-dom";
import { useRoles } from "../auth/useRoles";


export default function AppLayout({ children }: { children: React.ReactNode }) {
  const auth = useAuth();
  const navigate = useNavigate();
  const roles = useRoles();
  const isAdmin = roles.includes("CompanyAdmin");

  const logout = () => {
    auth.logout();
    navigate("/auth/login");
  };

  return (
    <>
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            Florist ERP
          </Typography>
          {isAdmin && (
            <>
              <Button color="inherit" onClick={() => navigate("/customers")}>
                Customers
              </Button>
              <Button color="inherit" onClick={() => navigate("/customers")}>
                Orders
              </Button>
              <Button color="inherit" onClick={() => navigate("/customers")}>
                Delivery
              </Button>
              <Button color="inherit" onClick={() => navigate("/customers")}>
                Reports
              </Button>
              <Button color="inherit" onClick={() => navigate("/customers")}>
                Items
              </Button>
            </>
          )}
          {auth.isAuthenticated && (
            <Button color="inherit" onClick={logout}>
              Logout
            </Button>
          )}
        </Toolbar>
      </AppBar>

      <Container sx={{ mt: 4 }}>
        {children}
      </Container>
    </>
  );
}
