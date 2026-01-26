import { ReactNode } from "react";
import { Navigate } from "react-router-dom";

interface ProtectedRouteProps {
  children: ReactNode;
}

const ProtectedRoute = ({ children }: ProtectedRouteProps) => {
  const user = localStorage.getItem("user");

  if (!user) {
    return <Navigate to="/login-finance" replace />;
  }

  return <>{children}</>;
};

export default ProtectedRoute;
