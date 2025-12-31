import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/auth/LoginPage';
import SignupPage from './pages/auth/SignupPage';
import DashboardLayout from './layouts/DashboardLayout';
import Overview from './pages/dashboard/Overview';
import UserAnalytics from './pages/dashboard/UserAnalytics';
import Complaints from './pages/dashboard/Complaints';
import Settings from './pages/dashboard/Settings';
import { ThemeProvider } from './context/ThemeContext';
import ProtectedRoute from './components/auth/ProtectedRoute';
import PublicRoute from './components/auth/PublicRoute';

function App() {
  // We no longer need the 'isAuthenticated' state here.
  // The routes manage themselves based on the localStorage token.

  return (
    <ThemeProvider>
      <Router>
        <Routes>
          {/* --- Public Routes (Login/Signup) --- */}
          <Route 
            path="/login" 
            element={
              <PublicRoute>
                <LoginPage onLogin={() => {}} />
              </PublicRoute>
            } 
          />
          
          <Route 
            path="/signup" 
            element={
              <PublicRoute>
                <SignupPage onSignup={() => {}} />
              </PublicRoute>
            } 
          />

          {/* --- Protected Dashboard Routes --- */}
          <Route 
            path="/dashboard" 
            element={
              <ProtectedRoute>
                <DashboardLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Overview />} />
            <Route path="users" element={<UserAnalytics />} />
            <Route path="complaints" element={<Complaints />} />
            <Route path="settings" element={<Settings />} />
          </Route>

          {/* --- Fallback Route --- */}
          {/* Redirect any unknown URL to dashboard (which handles its own protection) */}
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </Router>
    </ThemeProvider>
  );
}

export default App;