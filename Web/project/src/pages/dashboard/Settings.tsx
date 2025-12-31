import { useState, useEffect } from 'react';
import { Save, Lock, User, AlertCircle } from 'lucide-react';
import Card from '../../components/ui/Card';
import Button from '../../components/ui/Button';
import InputField from '../../components/ui/InputField';
import OtpModal from '../../components/ui/OtpModal';

const API_BASE_URL = 'http://localhost:5000/api/web';

const Settings = () => {
  // --- STATE: Profile ---
  const [profile, setProfile] = useState({
    firstName: '',
    lastName: '',
    email: ''
  });
  const [originalEmail, setOriginalEmail] = useState('');
  
  // --- STATE: Password ---
  const [passwords, setPasswords] = useState({
    oldPassword: '',
    newPassword: '',
    confirmPassword: ''
  });

  // --- STATE: UI ---
  const [isLoading, setIsLoading] = useState(false);
  const [showOtpModal, setShowOtpModal] = useState(false);
  const [message, setMessage] = useState({ type: '', text: '' });

  // 1. Load Current Admin Data
  useEffect(() => {
    const storedUser = localStorage.getItem('adminUser');
    if (storedUser) {
      const user = JSON.parse(storedUser);
      setProfile({
        firstName: user.firstName || '',
        lastName: user.lastName || '',
        email: user.email || ''
      });
      setOriginalEmail(user.email || '');
    }
  }, []);

  const getAuthHeader = () => {
    const token = localStorage.getItem('adminToken');
    return { 
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}` 
    };
  };

  // --- HANDLER: Update Profile ---
  const handleProfileUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage({ type: '', text: '' });

    try {
      const response = await fetch(`${API_BASE_URL}/settings/profile`, {
        method: 'PUT',
        headers: getAuthHeader(),
        body: JSON.stringify(profile)
      });

      const data = await response.json();

      if (response.ok) {
        if (data.verifyEmail) {
          setShowOtpModal(true); // Open OTP Modal for email change
        } else {
          // Update Local Storage immediately if only name changed
          const currentUser = JSON.parse(localStorage.getItem('adminUser') || '{}');
          const updatedUser = { ...currentUser, ...data.admin };
          localStorage.setItem('adminUser', JSON.stringify(updatedUser));
          
          setMessage({ type: 'success', text: 'Profile updated successfully.' });
          // Force reload to update Header name (optional, or use Context)
          window.location.reload(); 
        }
      } else {
        setMessage({ type: 'error', text: data.message });
      }
    } catch (error) {
      setMessage({ type: 'error', text: 'Update failed. Check connection.' });
    } finally {
      setIsLoading(false);
    }
  };

  // --- HANDLER: Verify New Email ---
  const handleVerifyEmail = async (otp: string) => {
    setIsLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}/settings/verify-email`, {
        method: 'POST',
        headers: getAuthHeader(),
        body: JSON.stringify({ email: profile.email, otp })
      });

      const data = await response.json();

      if (response.ok) {
        setShowOtpModal(false);
        setOriginalEmail(profile.email); // Commit new email
        
        // Update Local Storage
        const currentUser = JSON.parse(localStorage.getItem('adminUser') || '{}');
        currentUser.email = profile.email;
        currentUser.firstName = profile.firstName;
        currentUser.lastName = profile.lastName;
        localStorage.setItem('adminUser', JSON.stringify(currentUser));

        setMessage({ type: 'success', text: 'Email verified and updated successfully.' });
      } else {
        alert(data.message || 'Verification failed');
      }
    } catch (error) {
      alert('Verification error');
    } finally {
      setIsLoading(false);
    }
  };

  // --- HANDLER: Change Password ---
  const handlePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault();
    setMessage({ type: '', text: '' });

    if (passwords.newPassword !== passwords.confirmPassword) {
      setMessage({ type: 'error', text: 'New passwords do not match.' });
      return;
    }

    if (passwords.newPassword.length < 6) {
      setMessage({ type: 'error', text: 'Password must be at least 6 characters.' });
      return;
    }

    setIsLoading(true);

    try {
      const response = await fetch(`${API_BASE_URL}/settings/password`, {
        method: 'PUT',
        headers: getAuthHeader(),
        body: JSON.stringify({
          oldPassword: passwords.oldPassword,
          newPassword: passwords.newPassword
        })
      });

      const data = await response.json();

      if (response.ok) {
        setMessage({ type: 'success', text: 'Password changed successfully.' });
        setPasswords({ oldPassword: '', newPassword: '', confirmPassword: '' });
      } else {
        setMessage({ type: 'error', text: data.message });
      }
    } catch (error) {
      setMessage({ type: 'error', text: 'Password change failed.' });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Admin Settings</h1>
        <p className="text-gray-600 dark:text-gray-400">Update your profile and security preferences.</p>
      </div>

      {message.text && (
        <div className={`p-4 rounded-lg flex items-center ${
          message.type === 'error' ? 'bg-red-50 text-red-700' : 'bg-green-50 text-green-700'
        }`}>
          <AlertCircle size={20} className="mr-2" />
          {message.text}
        </div>
      )}

      {/* 1. Profile Settings */}
      <Card title="Profile Information">
        <form onSubmit={handleProfileUpdate} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <InputField
              id="firstName"
              label="First Name"
              value={profile.firstName}
              onChange={(e) => setProfile({ ...profile, firstName: e.target.value })}
            />
            <InputField
              id="lastName"
              label="Last Name"
              value={profile.lastName}
              onChange={(e) => setProfile({ ...profile, lastName: e.target.value })}
            />
          </div>
          
          <div className="relative">
            <InputField
              id="email"
              type="email"
              label="Email Address"
              value={profile.email}
              onChange={(e) => setProfile({ ...profile, email: e.target.value })}
            />
            {profile.email !== originalEmail && (
              <span className="text-xs text-amber-600 absolute right-0 top-0 mt-1 mr-1">
                (Requires Verification)
              </span>
            )}
          </div>

          <div className="flex justify-end">
            <Button type="submit" disabled={isLoading} className="inline-flex items-center">
              <User size={16} className="mr-2" />
              Update Profile
            </Button>
          </div>
        </form>
      </Card>

      {/* 2. Security Settings */}
      <Card title="Change Password">
        <form onSubmit={handlePasswordChange} className="space-y-6">
          <InputField
            id="oldPassword"
            type="password"
            label="Current Password"
            value={passwords.oldPassword}
            onChange={(e) => setPasswords({ ...passwords, oldPassword: e.target.value })}
            required
          />
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <InputField
              id="newPassword"
              type="password"
              label="New Password"
              value={passwords.newPassword}
              onChange={(e) => setPasswords({ ...passwords, newPassword: e.target.value })}
              required
            />
            <InputField
              id="confirmPassword"
              type="password"
              label="Confirm New Password"
              value={passwords.confirmPassword}
              onChange={(e) => setPasswords({ ...passwords, confirmPassword: e.target.value })}
              required
            />
          </div>

          <div className="flex justify-end">
            <Button type="submit" disabled={isLoading} variant="outline" className="inline-flex items-center">
              <Lock size={16} className="mr-2" />
              Change Password
            </Button>
          </div>
        </form>
      </Card>

      {/* OTP Modal for Email Change */}
      <OtpModal 
        isOpen={showOtpModal}
        email={profile.email}
        onVerify={handleVerifyEmail}
        onClose={() => setShowOtpModal(false)}
        isLoading={isLoading}
      />
    </div>
  );
};

export default Settings;