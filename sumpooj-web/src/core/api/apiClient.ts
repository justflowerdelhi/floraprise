/**
 * apiClient.ts
 * Central Axios client for Floraprise API calls
 */

import axios from "axios";

export const apiClient = axios.create({
  baseURL: "/api",   // backend API prefix
  withCredentials: true,
  headers: {
    "Content-Type": "application/json",
    "Accept": "application/json",
  },
});

// Optional: attach auth token automatically
apiClient.interceptors.request.use((config) => {
  const token =
    localStorage.getItem("auth_token") ||
    localStorage.getItem("authToken");

  if (token && token !== "undefined" && token !== "null") {
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});
