import { Navigate, useLocation } from 'react-router-dom';

interface ProtectedRouteProps {
  children: JSX.Element;
}

const ProtectedRoute = ({ children }: ProtectedRouteProps) => {
  const token = localStorage.getItem('adminToken');
  const location = useLocation();

  if (!token) {
    // If no token found, redirect to Login page
    // replace: true prevents hitting "Back" to return to the dashboard
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return children;
};

export default ProtectedRoute;