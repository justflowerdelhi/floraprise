import { createContext, useContext, useState } from "react";

type AuthContextType = {
  isAuthenticated: boolean;
  login: (token: string) => void;
  logout: () => void;
};

const AuthContext = createContext<AuthContextType | null>(null);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [isAuthenticated, setAuth] = useState(
    !!localStorage.getItem("auth_token")
  );

  const login = (token: string) => {
    localStorage.setItem("auth_token", token);
    setAuth(true);
  };

  const logout = () => {
    localStorage.removeItem("auth_token");
    setAuth(false);
  };

  return (
    <AuthContext.Provider value={{ isAuthenticated, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext)!;
