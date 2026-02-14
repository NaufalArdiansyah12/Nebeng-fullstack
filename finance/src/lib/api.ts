// src/lib/api.ts
import axios from "axios";

const api = axios.create({
  baseURL: "http://127.0.0.1:8000/api/finance",
});

// Add interceptor to include user data in headers
api.interceptors.request.use((config) => {
  const userStr = localStorage.getItem("user");
  if (userStr) {
    config.headers['X-User-Data'] = userStr;
  }
  return config;
});

export default api;
