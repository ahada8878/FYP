import React from 'react';
import { TrendingUp, TrendingDown } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: string;
  change: string;
  trend: 'up' | 'down' | 'neutral';
  icon?: React.ReactNode;
  isLoading?: boolean;
}

const StatCard = ({ title, value, change, trend, icon, isLoading = false }: StatCardProps) => {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 transition-all duration-200 hover:shadow-md">
      {isLoading ? (
        <>
          <div className="animate-pulse flex items-center justify-between mb-3">
            <div className="h-4 w-24 bg-gray-200 dark:bg-gray-700 rounded"></div>
            <div className="h-8 w-8 bg-gray-200 dark:bg-gray-700 rounded"></div>
          </div>
          <div className="animate-pulse">
            <div className="h-8 w-20 bg-gray-300 dark:bg-gray-600 rounded mb-3"></div>
            <div className="h-4 w-16 bg-gray-200 dark:bg-gray-700 rounded"></div>
          </div>
        </>
      ) : (
        <>
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-500 dark:text-gray-400">{title}</span>
            {icon}
          </div>
          <div className="flex items-baseline">
            <span className="text-2xl font-bold text-gray-900 dark:text-white mr-2">{value}</span>
            <div className={`flex items-center text-sm ${
              trend === 'up' ? 'text-green-600 dark:text-green-500' : 
              trend === 'down' ? 'text-red-600 dark:text-red-500' : 
              'text-gray-600 dark:text-gray-400'
            }`}>
              {trend === 'up' ? (
                <TrendingUp className="h-4 w-4 mr-1" />
              ) : trend === 'down' ? (
                <TrendingDown className="h-4 w-4 mr-1" />
              ) : null}
              <span>{change}</span>
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default StatCard;