import { useState, useEffect } from 'react';
import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import ChartSkeleton from './ChartSkeleton';

interface DietDistributionChartProps {
  data: any[];
  isLoading?: boolean;
}

const COLORS = ['#3B82F6', '#10B981', '#F59E0B', '#8B5CF6', '#EC4899', '#14B8A6'];

const CustomTooltip = ({ active, payload }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white p-3 border border-gray-200 rounded-md shadow-md text-sm dark:bg-gray-800 dark:border-gray-700">
        <p className="font-medium text-gray-900 dark:text-white">{payload[0].name}</p>
        <p className="text-gray-600 dark:text-gray-300">{`Users: ${payload[0].value}`}</p>
        <p className="text-gray-600 dark:text-gray-300">
          {`Percentage: ${((payload[0].value / payload[0].payload.total) * 100).toFixed(1)}%`}
        </p>
      </div>
    );
  }
  return null;
};

const DietDistributionChart = ({ data, isLoading = false }: DietDistributionChartProps) => {
  const [processedData, setProcessedData] = useState<any[]>([]);

  useEffect(() => {
    if (data && data.length > 0) {
      const total = data.reduce((sum, item) => sum + (item.value || 0), 0);
      setProcessedData(data.map(item => ({ ...item, total })));
    } else {
      setProcessedData([]);
    }
  }, [data]);

  if (isLoading) {
    return <ChartSkeleton />;
  }

  if (!processedData || processedData.length === 0) {
    return (
      <div className="h-full flex items-center justify-center text-gray-400">
        No diet data available
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col">
      <div className="flex-1">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={processedData}
              cx="50%"
              cy="50%"
              innerRadius={70}
              outerRadius={100}
              fill="#8884d8"
              paddingAngle={2}
              dataKey="value"
              labelLine={false}
            >
              {processedData.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
              ))}
            </Pie>
            <Tooltip content={<CustomTooltip />} />
            <Legend 
              layout="horizontal" 
              verticalAlign="bottom" 
              align="center"
              formatter={(value) => (
                <span style={{ color: '#6B7280' }}>{value}</span>
              )}
            />
          </PieChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

export default DietDistributionChart;