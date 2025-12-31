import { useState, useEffect } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import ChartSkeleton from './ChartSkeleton';

interface MealPlanChartProps {
  isLoading?: boolean;
}

// Mock data for the chart
const generateMockData = () => [
  {
    name: 'Breakfast',
    plans: Math.floor(Math.random() * 1000) + 2000,
    satisfaction: Math.floor(Math.random() * 20) + 80,
  },
  {
    name: 'Lunch',
    plans: Math.floor(Math.random() * 1000) + 1800,
    satisfaction: Math.floor(Math.random() * 20) + 80,
  },
  {
    name: 'Dinner',
    plans: Math.floor(Math.random() * 1000) + 2200,
    satisfaction: Math.floor(Math.random() * 20) + 80,
  },
  {
    name: 'Snacks',
    plans: Math.floor(Math.random() * 500) + 1000,
    satisfaction: Math.floor(Math.random() * 20) + 80,
  },
];

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white p-3 border border-gray-200 rounded-md shadow-md text-sm dark:bg-gray-800 dark:border-gray-700">
        <p className="font-medium text-gray-900 dark:text-white">{label}</p>
        <p className="text-blue-600 dark:text-blue-400">Plans Generated: {payload[0].value}</p>
        <p className="text-green-600 dark:text-green-400">Satisfaction: {payload[1].value}%</p>
      </div>
    );
  }
  return null;
};

const MealPlanChart = ({ isLoading = false }: MealPlanChartProps) => {
  const [data, setData] = useState<any[]>([]);

  useEffect(() => {
    setData(generateMockData());
  }, []);

  if (isLoading || data.length === 0) {
    return <ChartSkeleton />;
  }

  return (
    <div className="h-full">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart
          data={data}
          margin={{
            top: 20,
            right: 30,
            left: 20,
            bottom: 5,
          }}
        >
          <CartesianGrid strokeDasharray="3 3" stroke="#374151" opacity={0.1} />
          <XAxis dataKey="name" tick={{ fill: '#6B7280' }} />
          <YAxis yAxisId="left" orientation="left" tick={{ fill: '#6B7280' }} />
          <YAxis yAxisId="right" orientation="right" tick={{ fill: '#6B7280' }} />
          <Tooltip content={<CustomTooltip />} />
          <Legend />
          <Bar yAxisId="left" dataKey="plans" name="Plans Generated" fill="#3B82F6" radius={[4, 4, 0, 0]} />
          <Bar yAxisId="right" dataKey="satisfaction" name="Satisfaction %" fill="#10B981" radius={[4, 4, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
};

export default MealPlanChart;