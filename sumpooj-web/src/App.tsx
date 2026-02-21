import { BrowserRouter } from 'react-router-dom';
import { AuthProvider } from './auth/AuthContext';
import { AppBootGuard } from './auth/AppBootGuard';
import { ToastProvider } from './hooks/useToast';
import AppRoutes from './routes/AppRoutes';

const basename = import.meta.env.PROD ? '/floraedge' : '/';

export default function App() {
  return (
    <ToastProvider>
      <AuthProvider>
        <AppBootGuard>
          <BrowserRouter basename={basename}>
            <AppRoutes />
          </BrowserRouter>
        </AppBootGuard>
      </AuthProvider>
    </ToastProvider>
  );
}
