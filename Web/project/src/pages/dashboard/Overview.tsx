import { useEffect, useState } from 'react';
import { BarChart, Utensils } from 'lucide-react';
import Card from '../../components/ui/Card';
import StatCard from '../../components/ui/StatCard';
import DietDistributionChart from '../../components/charts/DietDistributionChart';
import GoalDistributionChart from '../../components/charts/GoalDistributionChart';
import AllergyFrequencyChart from '../../components/charts/AllergyFrequencyChart';

// Define the API Base URL (Change this if your backend runs on a different port)
const API_BASE_URL = 'http://localhost:5000/api/web';

const Overview = () => {
  const [isLoading, setIsLoading] = useState(true);
  
  // State for the data
  const [stats, setStats] = useState({ totalUsers: 0, totalMealPlans: 0 });
  const [dietData, setDietData] = useState([]);
  const [goalData, setGoalData] = useState([]);
  const [allergyData, setAllergyData] = useState([]);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        // Fetch all data in parallel for better performance
        const [statsRes, dietRes, goalRes, allergyRes] = await Promise.all([
          fetch(`${API_BASE_URL}/stats`),
          fetch(`${API_BASE_URL}/diets`),
          fetch(`${API_BASE_URL}/goals`),
          fetch(`${API_BASE_URL}/allergies`)
        ]);

        // Parse JSON
        const statsData = await statsRes.json();
        const dietDataRaw = await dietRes.json();
        const goalDataRaw = await goalRes.json();
        const allergyDataRaw = await allergyRes.json();

        // Update State
        setStats(statsData);
        setDietData(dietDataRaw);
        setGoalData(goalDataRaw);
        setAllergyData(allergyDataRaw);

      } catch (error) {
        console.error("Failed to fetch dashboard data:", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Dashboard Overview</h1>
        <p className="text-gray-600 dark:text-gray-400">Welcome back, here's what's happening with your platform today.</p>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
        <StatCard 
          title="Total Users" 
          value={stats.totalUsers.toLocaleString()} 
          change="Live" // You can calculate growth if you add historical data later
          trend="up" 
          icon={<BarChart className="h-8 w-8 text-blue-600 dark:text-blue-500" />}
          isLoading={isLoading}
        />
        <StatCard 
          title="Meal Plans Generated" 
          value={stats.totalMealPlans.toLocaleString()} 
          change="Live" 
          trend="up" 
          icon={<Utensils className="h-8 w-8 text-amber-600 dark:text-amber-500" />}
          isLoading={isLoading}
        />
      </div>

      {/* Distribution Graphs Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card title="Diet Distribution">
          <div className="h-80">
            {/* Pass the fetched data to your chart component */}
            <DietDistributionChart data={dietData} isLoading={isLoading} />
          </div>
        </Card>
        <Card title="Most Common Goals">
          <div className="h-80">
            <GoalDistributionChart data={goalData} isLoading={isLoading} />
          </div>
        </Card>
      </div>

      {/* Frequency Graph Row */}
      <div className="grid grid-cols-1 gap-6">
        <Card title="Allergy Frequency">
          <div className="h-80">
            <AllergyFrequencyChart data={allergyData} isLoading={isLoading} />
          </div>
        </Card>
      </div>
    </div>
  );
};

export default Overview;