import { Activity } from 'lucide-react';

interface LogoProps {
  iconOnly?: boolean;
}

const Logo = ({ iconOnly = false }: LogoProps) => {
  return (
    <div className="flex items-center">
      <Activity size={24} className="text-blue-600 dark:text-blue-500" />
      {!iconOnly && (
        <span className="ml-2 text-xl font-bold text-gray-900 dark:text-white">
          NutriWise
        </span>
      )}
    </div>
  );
};

export default Logo;