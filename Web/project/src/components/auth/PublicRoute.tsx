import { Navigate } from 'react-router-dom';

interface PublicRouteProps {
  children: JSX.Element;
}

const PublicRoute = ({ children }: PublicRouteProps) => {
  const token = localStorage.getItem('adminToken');

  if (token) {
    // If already logged in, redirect to Dashboard
    return <Navigate to="/dashboard" replace />;
  }

  return children;
};

export default PublicRoute;