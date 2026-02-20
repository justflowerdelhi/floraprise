import { BrowserRouter } from 'react-router-dom';
import { AuthProvider } from './auth/AuthContext';
import { AppBootGuard } from './auth/AppBootGuard';
import AppRoutes from './routes/AppRoutes';

export default function App() {
  return (
    <AuthProvider>
      <AppBootGuard>
        <BrowserRouter basename="/floraedge">
          <AppRoutes />
        </BrowserRouter>
      </AppBootGuard>
    </AuthProvider>
  );
}
