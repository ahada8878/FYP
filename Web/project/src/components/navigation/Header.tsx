import { useState, useEffect } from 'react';
import { Moon, Sun, Menu } from 'lucide-react';
import { useTheme } from '../../context/ThemeContext';

interface HeaderProps {
  toggleSidebar: () => void;
}

const Header = ({ toggleSidebar }: HeaderProps) => {
  const { theme, toggleTheme } = useTheme();
  const [adminName, setAdminName] = useState({ first: 'Admin', last: '' });

  // Load Admin Data from LocalStorage
  useEffect(() => {
    const storedUser = localStorage.getItem('adminUser');
    if (storedUser) {
      try {
        const user = JSON.parse(storedUser);
        setAdminName({
          first: user.firstName || 'Admin',
          last: user.lastName || ''
        });
      } catch (e) {
        console.error("Failed to load admin user data");
      }
    }
  }, []);

  const fullName = `${adminName.first} ${adminName.last}`.trim();
  const initials = `${adminName.first.charAt(0)}${adminName.last.charAt(0)}`.toUpperCase();

  return (
    <header className="sticky top-0 z-20 py-4 px-6 bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700 transition-colors duration-200">
      <div className="flex items-center justify-between">
        <div className="flex items-center">
          <button
            onClick={toggleSidebar}
            className="md:hidden p-2 mr-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors duration-200"
          >
            <Menu size={20} className="text-gray-500 dark:text-gray-400" />
          </button>
          <h1 className="text-xl font-semibold text-gray-800 dark:text-white">Health Admin Dashboard</h1>
        </div>

        <div className="flex items-center space-x-4">
          <button 
            onClick={toggleTheme} 
            className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors duration-200"
            aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
          >
            {theme === 'dark' ? (
              <Sun size={20} className="text-gray-400" />
            ) : (
              <Moon size={20} className="text-gray-500" />
            )}
          </button>
          
          {/* Notification Button Removed as requested */}
          
          <div className="flex items-center space-x-3">
            <div className="h-8 w-8 rounded-full bg-blue-500 flex items-center justify-center text-white font-medium">
              {initials}
            </div>
            <div className="hidden md:block">
              <p className="text-sm font-medium text-gray-700 dark:text-white">
                {fullName}
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400">Admin</p>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;