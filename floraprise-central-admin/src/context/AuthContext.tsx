import React, { createContext, useContext, useState, useEffect } from 'react';
import { AdminUser } from '../types/platform';
import { authService } from '../services/api/authService';

interface AuthContextType {
  user: AdminUser | null;
  isAuthenticated: boolean;
  isAuthenticating: boolean;
  login: (email: string, role?: AdminUser['role']) => void;
  loginWithCredentials: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  logout: () => void;
}

const DEFAULT_USER: AdminUser = {
  id: 'usr-admin-01',
  name: 'Platform Operator',
  email: 'admin@floraprise.com',
  role: 'SuperAdmin',
  status: 'Active',
  lastLoginAt: 'Just now',
  twoFactorEnabled: true,
  avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=96&h=96&fit=crop'
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<AdminUser | null>(() => {
    const token = localStorage.getItem('floraprise_access_token');
    const saved = localStorage.getItem('floraprise_admin_user');
    if (token && saved) {
      try {
        return JSON.parse(saved);
      } catch {
        return null;
      }
    }
    return null;
  });
  const [isAuthenticating, setIsAuthenticating] = useState<boolean>(false);

  useEffect(() => {
    if (user) {
      localStorage.setItem('floraprise_admin_user', JSON.stringify(user));
    } else {
      localStorage.removeItem('floraprise_admin_user');
      localStorage.removeItem('floraprise_access_token');
    }
  }, [user]);

  // Check token on initial load
  useEffect(() => {
    const token = localStorage.getItem('floraprise_access_token');
    if (token) {
      authService.getCurrentUser().then(realUser => {
        if (realUser) {
          setUser(realUser);
        } else {
          // Token expired or invalid
          setUser(null);
          localStorage.removeItem('floraprise_access_token');
          localStorage.removeItem('floraprise_admin_user');
        }
      }).catch(() => {});
    }
  }, []);

  const login = (email: string, role: AdminUser['role'] = 'SuperAdmin') => {
    const newUser: AdminUser = {
      id: crypto.randomUUID(),
      name: email.split('@')[0].toUpperCase() + ' (Operator)',
      email,
      role,
      status: 'Active',
      lastLoginAt: 'Just now',
      twoFactorEnabled: true,
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=96&h=96&fit=crop'
    };
    setUser(newUser);
  };

  const loginWithCredentials = async (email: string, password: string): Promise<{ success: boolean; error?: string }> => {
    setIsAuthenticating(true);
    try {
      const res = await authService.loginWithCredentials(email, password);
      if (res.success && res.user) {
        setUser(res.user);
        return { success: true };
      }
      return { success: false, error: res.error };
    } catch (err: any) {
      return { success: false, error: err?.message || 'Login request failed.' };
    } finally {
      setIsAuthenticating(false);
    }
  };

  const logout = () => {
    authService.logout();
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ 
      user, 
      isAuthenticated: !!user, 
      isAuthenticating,
      login, 
      loginWithCredentials, 
      logout 
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
