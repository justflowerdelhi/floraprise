import AppRoutes from './routes/AppRoutes';
import { AppBootGuard } from './auth/AppBootGuard';
import { AuthProvider } from './auth/AuthContext';
import { ToastProvider } from './hooks/useToast';

const basename = import.meta.env.PROD ? '/floraprise' : '/';

export default function App() {
  return (
    <ToastProvider>
      <AuthProvider>
        <AppBootGuard>
          <AppRoutes />
        </AppBootGuard>
      </AuthProvider>
    </ToastProvider>
  );
}
