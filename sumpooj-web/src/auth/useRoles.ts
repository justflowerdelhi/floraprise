import { jwtDecode } from 'jwt-decode';

export const useRoles = () => {
  const token = localStorage.getItem("auth_token");
  if (!token) return [];

  try {
    const decoded: any = jwtDecode(token);
    return decoded.role
      ? Array.isArray(decoded.role)
        ? decoded.role
        : [decoded.role]
      : [];
  } catch (error) {
    console.error("Failed to decode token:", error);
    return [];
  }
};
