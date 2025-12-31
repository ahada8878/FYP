import { useNavigate, NavLink } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Users, 
  Settings, 
  ChevronLeft, 
  ChevronRight,
  LogOut,
  AlertCircle 
} from 'lucide-react';
import Logo from '../ui/Logo';
import { useTheme } from '../../context/ThemeContext';

interface SidebarProps {
  isOpen: boolean;
  toggleSidebar: () => void;
}

const Sidebar = ({ isOpen, toggleSidebar }: SidebarProps) => {
  const { theme } = useTheme();
  const navigate = useNavigate();
  
  const navItems = [
    { name: 'Overview', path: '/dashboard', icon: LayoutDashboard },
    { name: 'User Analytics', path: '/dashboard/users', icon: Users },
    { name: 'Complaints', path: '/dashboard/complaints', icon: AlertCircle },
    { name: 'Settings', path: '/dashboard/settings', icon: Settings },
  ];

  const handleLogout = () => {
    // 1. Clear credentials
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
    
    // 2. Force navigation to login (replace: true prevents 'Back' button from working)
    navigate('/login', { replace: true });
  };

  return (
    <div 
      className={`${isOpen ? 'w-64' : 'w-20'} fixed inset-y-0 left-0 z-30 transform transition-all duration-300 shadow-lg
                  bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 h-screen`}
    >
      <div className="h-full flex flex-col justify-between">
        <div>
          {/* Header / Logo Area */}
          <div className="px-4 py-6 flex items-center justify-between">
            {isOpen ? (
              <Logo />
            ) : (
              <div className="w-full flex justify-center">
                <Logo iconOnly />
              </div>
            )}
            <button 
              type="button" // ✅ Good Practice
              onClick={toggleSidebar}
              className="p-1 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors duration-200"
              aria-label={isOpen ? "Close sidebar" : "Open sidebar"}
            >
              {isOpen ? 
                <ChevronLeft size={20} className="text-gray-500 dark:text-gray-400" /> : 
                <ChevronRight size={20} className="text-gray-500 dark:text-gray-400" />
              }
            </button>
          </div>

          {/* Navigation Links */}
          <nav className="mt-8 px-2">
            <ul className="space-y-2">
              {navItems.map((item) => {
                const Icon = item.icon;
                return (
                  <li key={item.name}>
                    <NavLink
                      to={item.path}
                      className={({ isActive }) => `
                        flex items-center px-4 py-3 rounded-lg transition-colors duration-200
                        ${isActive 
                          ? 'bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 font-medium' 
                          : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'
                        }
                      `}
                      end={item.path === '/dashboard'}
                    >
                      <Icon size={20} className="flex-shrink-0" />
                      {isOpen && <span className="ml-3">{item.name}</span>}
                    </NavLink>
                  </li>
                );
              })}
            </ul>
          </nav>
        </div>

        {/* Logout Section */}
        <div className="p-4 border-t border-gray-200 dark:border-gray-700">
          <button 
            type="button" // ✅ CRITICAL FIX: Prevents form submission/refresh behavior
            onClick={handleLogout}
            className={`w-full flex items-center px-4 py-3 rounded-lg text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/30 transition-colors duration-200`}
          >
            <LogOut size={20} className="flex-shrink-0" />
            {isOpen && <span className="ml-3">Logout</span>}
          </button>
        </div>
      </div>
    </div>
  );
};

export default Sidebar;