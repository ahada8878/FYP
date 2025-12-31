import React from 'react';

const ChartSkeleton = () => {
  return (
    <div className="h-full flex flex-col justify-center items-center">
      <div className="w-full h-full flex items-center justify-center">
        <div className="animate-pulse w-full h-4/5 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
      </div>
    </div>
  );
};

export default ChartSkeleton;