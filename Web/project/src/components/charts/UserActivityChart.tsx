import { useState, useMemo } from 'react';
import { 
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend 
} from 'recharts';
import ChartSkeleton from './ChartSkeleton';

interface UserActivityChartProps {
  data: { name: string; value: number }[]; // Raw daily data from backend
  isLoading?: boolean;
}

const UserActivityChart = ({ data, isLoading = false }: UserActivityChartProps) => {
  const [activeTab, setActiveTab] = useState<string>('daily');

  // Process data based on active tab
  const processedData = useMemo(() => {
    if (!data || data.length === 0) return [];

    if (activeTab === 'daily') {
      // Return last 30 days for cleaner UI
      return data.slice(-30).map(item => ({
        name: item.name, // Date like "2025-11-23"
        "New Users": item.value
      }));
    } 
    
    if (activeTab === 'weekly') {
      // Group by Week
      const weeklyMap = new Map();
      data.forEach(item => {
        const date = new Date(item.name);
        // Get start of the week
        const day = date.getDay();
        const diff = date.getDate() - day + (day === 0 ? -6 : 1); 
        const weekStart = new Date(date.setDate(diff)).toISOString().split('T')[0];
        
        weeklyMap.set(weekStart, (weeklyMap.get(weekStart) || 0) + item.value);
      });
      return Array.from(weeklyMap).map(([k, v]) => ({ name: k, "New Users": v }));
    }

    if (activeTab === 'monthly') {
      // Group by Month
      const monthlyMap = new Map();
      data.forEach(item => {
        const monthKey = item.name.substring(0, 7); // "2025-11"
        monthlyMap.set(monthKey, (monthlyMap.get(monthKey) || 0) + item.value);
      });
      return Array.from(monthlyMap).map(([k, v]) => ({ name: k, "New Users": v }));
    }

    return [];
  }, [data, activeTab]);

  if (isLoading) {
    return <ChartSkeleton />;
  }

  return (
    <div className="h-full">
      <div className="flex gap-2 mb-4">
        {['daily', 'weekly', 'monthly'].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-3 py-1 text-sm rounded-md capitalize ${
              activeTab === tab 
                ? 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300' 
                : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700'
            }`}
          >
            {tab}
          </button>
        ))}
      </div>
      
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={processedData} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#374151" opacity={0.1} />
            <XAxis dataKey="name" tick={{ fill: '#6B7280' }} fontSize={12} tickFormatter={(val) => val.slice(5)} />
            <YAxis tick={{ fill: '#6B7280' }} allowDecimals={false} />
            <Tooltip 
              contentStyle={{ 
                backgroundColor: 'rgba(255, 255, 255, 0.9)', 
                borderColor: '#E5E7EB',
                borderRadius: '0.375rem'
              }} 
            />
            <Legend />
            <Area 
              type="monotone" 
              dataKey="New Users" 
              stroke="#3B82F6" 
              fill="#3B82F6" 
              fillOpacity={0.3} 
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

export default UserActivityChart;