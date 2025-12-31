import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import ChartSkeleton from './ChartSkeleton';

interface GoalDistributionChartProps {
  data: any[];
  isLoading?: boolean;
}

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white p-3 border border-gray-200 rounded-md shadow-md text-sm dark:bg-gray-800 dark:border-gray-700">
        <p className="font-medium text-gray-900 dark:text-white">{label}</p>
        {/* Updated to display 'value' from backend data */}
        <p className="text-gray-600 dark:text-gray-300">{`Users: ${payload[0].value.toLocaleString()}`}</p>
      </div>
    );
  }
  return null;
};

const GoalDistributionChart = ({ data, isLoading = false }: GoalDistributionChartProps) => {

  if (isLoading) {
    return <ChartSkeleton />;
  }

  if (!data || data.length === 0) {
    return (
      <div className="h-full flex items-center justify-center text-gray-400">
        No goal data available
      </div>
    );
  }

  return (
    <div className="h-full">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart
          data={data}
          layout="vertical"
          margin={{
            top: 5,
            right: 30,
            left: 20,
            bottom: 5,
          }}
        >
          <CartesianGrid strokeDasharray="3 3" stroke="#374151" opacity={0.1} horizontal={true} vertical={false} />
          <XAxis type="number" tick={{ fill: '#6B7280' }} />
          <YAxis 
            dataKey="name" 
            type="category" 
            tick={{ fill: '#6B7280' }} 
            width={120} // Increased width slightly to fit longer goal names
            style={{ fontSize: '12px' }} 
          />
          <Tooltip content={<CustomTooltip />} />
          {/* Updated dataKey to 'value' to match backend response */}
          <Bar dataKey="value" radius={[0, 4, 4, 0]} fill="#3B82F6" />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
};

export default GoalDistributionChart;