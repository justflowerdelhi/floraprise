import { Routes, Route } from "react-router-dom";
import Login from "../pages/auth/Login";
import RequireAuth from "../auth/RequireAuth";
import CustomerList from "../pages/customers/CustomerList";
import OrderForm from "../pages/orders/OrderForm";
import AppLayout from "../components/AppLayout";
import AddProductForm from "../pages/products/AddProductForm";

export default function AppRoutes() {
  return (
    <Routes>
      <Route path="/auth/login" element={<Login />} />

      <Route
        path="/customers"
        element={
          <RequireAuth>
            <AppLayout>
              <CustomerList />
            </AppLayout>
          </RequireAuth>
        }
      />

      <Route
        path="/orders/new"
        element={<OrderForm />}
      />

      {/* Product Routes */}
      <Route
        path="/products/new"
        element={<AddProductForm />}
      />
    </Routes>
  );
}
