import { Navigate } from "react-router-dom";
import { useAuth } from "./AuthContext";
import type { ReactNode } from "react";

export default function RequireAuth({ children }: { children: ReactNode }) {
  const auth = useAuth();
  return auth.isAuthenticated
    ? children
    : <Navigate to="/auth/login" replace />;
}
