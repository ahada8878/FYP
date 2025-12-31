import { useState, useEffect } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import ChartSkeleton from './ChartSkeleton';

interface FoodDetectionChartProps {
  isLoading?: boolean;
}

// Mock data for the chart
const generateMockData = () => [
  {
    name: 'Breakfast',
    accuracy: Math.floor(Math.random() * 20 + 80),
    failures: Math.floor(Math.random() * 10 + 5),
  },
  {
    name: 'Lunch',
    accuracy: Math.floor(Math.random() * 15 + 82),
    failures: Math.floor(Math.random() * 8 + 4),
  },
  {
    name: 'Dinner',
    accuracy: Math.floor(Math.random() * 18 + 81),
    failures: Math.floor(Math.random() * 9 + 6),
  },
  {
    name: 'Snacks',
    accuracy: Math.floor(Math.random() * 25 + 75),
    failures: Math.floor(Math.random() * 12 + 8),
  },
];

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white p-3 border border-gray-200 rounded-md shadow-md text-sm dark:bg-gray-800 dark:border-gray-700">
        <p className="font-medium text-gray-900 dark:text-white">{label}</p>
        <p className="text-blue-600 dark:text-blue-400">Accuracy: {payload[0].value}%</p>
        <p className="text-red-600 dark:text-red-400">Failures: {payload[1].value}</p>
      </div>
    );
  }
  return null;
};

const FoodDetectionChart = ({ isLoading = false }: FoodDetectionChartProps) => {
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
          <Bar yAxisId="left" dataKey="accuracy" name="Accuracy %" fill="#3B82F6" radius={[4, 4, 0, 0]} />
          <Bar yAxisId="right" dataKey="failures" name="Failed Classifications" fill="#EF4444" radius={[4, 4, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
};

export default FoodDetectionChart;