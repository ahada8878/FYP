import { useState, useEffect } from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import ChartSkeleton from './ChartSkeleton';

interface AllergyFrequencyChartProps {
  data: any[];
  isLoading?: boolean;
}

const COLORS = ['#F59E0B', '#EF4444', '#EC4899', '#8B5CF6', '#3B82F6', '#10B981'];

const CustomTooltip = ({ active, payload }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white p-3 border border-gray-200 rounded-md shadow-md text-sm dark:bg-gray-800 dark:border-gray-700">
        <p className="font-medium text-gray-900 dark:text-white">{payload[0].name}</p>
        <p className="text-gray-600 dark:text-gray-300">{`Users: ${payload[0].value}`}</p>
        <p className="text-gray-600 dark:text-gray-300">
          {/* We use payload[0].payload.total which we calculate in the useEffect below */}
          {`Percentage: ${((payload[0].value / payload[0].payload.total) * 100).toFixed(1)}%`}
        </p>
      </div>
    );
  }
  return null;
};

const RADIAN = Math.PI / 180;
const renderCustomizedLabel = ({ cx, cy, midAngle, innerRadius, outerRadius, percent }: any) => {
  const radius = innerRadius + (outerRadius - innerRadius) * 0.5;
  const x = cx + radius * Math.cos(-midAngle * RADIAN);
  const y = cy + radius * Math.sin(-midAngle * RADIAN);

  return (
    percent > 0.05 ? (
      <text 
        x={x} 
        y={y} 
        fill="white" 
        textAnchor="middle" 
        dominantBaseline="central"
        className="text-xs font-medium"
      >
        {`${(percent * 100).toFixed(0)}%`}
      </text>
    ) : null
  );
};

const AllergyFrequencyChart = ({ data, isLoading = false }: AllergyFrequencyChartProps) => {
  const [processedData, setProcessedData] = useState<any[]>([]);

  useEffect(() => {
    if (data && data.length > 0) {
      // Calculate total sum for percentage calculation in tooltip
      const total = data.reduce((sum, item) => sum + (item.value || 0), 0);
      // Add 'total' property to every data item
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
        No allergy data available
      </div>
    );
  }

  return (
    <div className="h-full">
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={processedData}
            cx="50%"
            cy="50%"
            labelLine={false}
            label={renderCustomizedLabel}
            outerRadius={100}
            fill="#8884d8"
            dataKey="value"
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
  );
};

export default AllergyFrequencyChart;