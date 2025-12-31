import { useEffect, useState } from 'react';
import Card from '../../components/ui/Card';
import GoalDistributionChart from '../../components/charts/GoalDistributionChart';

const HealthGoals = () => {
  const [isLoading, setIsLoading] = useState(true);

  // Simulate loading data
  useEffect(() => {
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 1000);
    return () => clearTimeout(timer);
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Health Goals</h1>
        <p className="text-gray-600 dark:text-gray-400">Analysis of user health goals and achievement rates.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card>
          <div className="text-center">
            <div className="inline-flex items-center justify-center h-12 w-12 rounded-full bg-blue-100 text-blue-500 dark:bg-blue-900 dark:text-blue-300 mb-4">
              <span className="text-xl font-bold">72%</span>
            </div>
            <h3 className="text-lg font-medium text-gray-900 dark:text-white">Average Goal Achievement</h3>
            <p className="text-sm text-gray-500 dark:text-gray-400">Across all users and goals</p>
          </div>
        </Card>
        <Card>
          <div className="text-center">
            <div className="inline-flex items-center justify-center h-12 w-12 rounded-full bg-green-100 text-green-500 dark:bg-green-900 dark:text-green-300 mb-4">
              <span className="text-xl font-bold">85%</span>
            </div>
            <h3 className="text-lg font-medium text-gray-900 dark:text-white">User Satisfaction</h3>
            <p className="text-sm text-gray-500 dark:text-gray-400">With goal tracking features</p>
          </div>
        </Card>
        <Card>
          <div className="text-center">
            <div className="inline-flex items-center justify-center h-12 w-12 rounded-full bg-purple-100 text-purple-500 dark:bg-purple-900 dark:text-purple-300 mb-4">
              <span className="text-xl font-bold">68%</span>
            </div>
            <h3 className="text-lg font-medium text-gray-900 dark:text-white">Goal Retention</h3>
            <p className="text-sm text-gray-500 dark:text-gray-400">User maintains goal for 30+ days</p>
          </div>
        </Card>
      </div>

      <Card title="Most Common User Goals">
        <div className="h-80">
          <GoalDistributionChart isLoading={isLoading} />
        </div>
      </Card>

      <Card title="Goal Achievement by Demographics">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead className="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                  Age Group
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                  Top Goal
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                  Achievement Rate
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
                  Avg. Time to Achieve
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200 dark:bg-gray-900 dark:divide-gray-700">
              {isLoading ? (
                Array(4).fill(0).map((_, i) => (
                  <tr key={i}>
                    {Array(4).fill(0).map((_, j) => (
                      <td key={j} className="px-6 py-4 whitespace-nowrap">
                        <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-24"></div>
                      </td>
                    ))}
                  </tr>
                ))
              ) : (
                <>
                  <tr>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">18-24</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">Muscle Gain</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">68%</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">8 weeks</td>
                  </tr>
                  <tr>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">25-34</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">Weight Loss</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">72%</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">10 weeks</td>
                  </tr>
                  <tr>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">35-44</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">More Energy</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">65%</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">6 weeks</td>
                  </tr>
                  <tr>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">45+</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">Heart Health</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">78%</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">12 weeks</td>
                  </tr>
                </>
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
};

export default HealthGoals;