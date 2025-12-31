import { useEffect, useState } from 'react';
import Card from '../../components/ui/Card';
import UserTable from '../../components/tables/UserTable';

// Import the Chart Components
import UserBMIChart from '../../components/charts/UserBMIChart';
import DietDistributionChart from '../../components/charts/DietDistributionChart';
import GoalDistributionChart from '../../components/charts/GoalDistributionChart';
import AllergyFrequencyChart from '../../components/charts/AllergyFrequencyChart';

const API_BASE_URL = 'http://localhost:5000/api/web';

const UserAnalytics = () => {
  // ✅ FIX: Added <any[]> to explicitly tell TypeScript these are arrays of data
  const [bmiData, setBmiData] = useState<any[]>([]);
  const [dietData, setDietData] = useState<any[]>([]);
  const [goalData, setGoalData] = useState<any[]>([]);
  const [allergyData, setAllergyData] = useState<any[]>([]);
  
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Fetch ALL analytics data in parallel
        const [bmiRes, dietRes, goalRes, allergyRes] = await Promise.all([
          fetch(`${API_BASE_URL}/bmi-distribution`),
          fetch(`${API_BASE_URL}/diets`),
          fetch(`${API_BASE_URL}/goals`),
          fetch(`${API_BASE_URL}/allergies`)
        ]);

        const bmi = await bmiRes.json();
        const diet = await dietRes.json();
        const goal = await goalRes.json();
        const allergy = await allergyRes.json();
        
        // Safely set state
        setBmiData(Array.isArray(bmi) ? bmi : []);
        setDietData(Array.isArray(diet) ? diet : []);
        setGoalData(Array.isArray(goal) ? goal : []);
        setAllergyData(Array.isArray(allergy) ? allergy : []);

      } catch (error) {
        console.error("Failed to fetch analytics data:", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">User Analytics</h1>
        <p className="text-gray-600 dark:text-gray-400">Detailed health metrics, demographics, and preferences of your user base.</p>
      </div>

      {/* Row 1: BMI Distribution */}
      <Card title="User BMI Distribution">
        <div className="h-80">
          <UserBMIChart data={bmiData} isLoading={isLoading} />
        </div>
      </Card>

      {/* Row 2: Diet & Goals */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card title="Diet Distribution">
          <div className="h-80">
            <DietDistributionChart data={dietData} isLoading={isLoading} />
          </div>
        </Card>
        <Card title="Most Common Goals">
          <div className="h-80">
            <GoalDistributionChart data={goalData} isLoading={isLoading} />
          </div>
        </Card>
      </div>

      {/* Row 3: Allergies */}
      <div className="grid grid-cols-1 gap-6">
        <Card title="Allergy/Health Concern Frequency">
          <div className="h-80">
            <AllergyFrequencyChart data={allergyData} isLoading={isLoading} />
          </div>
        </Card>
      </div>

      {/* Row 4: User Table */}
      <Card title="User Details">
        <UserTable />
      </Card>
    </div>
  );
};

export default UserAnalytics;