import { useState } from 'react';
import Button from './Button';
import InputField from './InputField';

interface OtpModalProps {
  isOpen: boolean;
  email: string;
  onVerify: (otp: string) => void;
  onClose: () => void;
  isLoading: boolean;
}

const OtpModal = ({ isOpen, email, onVerify, onClose, isLoading }: OtpModalProps) => {
  const [otp, setOtp] = useState('');

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-sm shadow-xl">
        <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">Verify Email</h2>
        <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
          We sent a code to <span className="font-semibold">{email}</span>
        </p>
        
        {/* ✅ FIXED: Added missing 'id' prop */}
        <InputField
          id="otp-input"
          label="Verification Code"
          value={otp}
          onChange={(e) => setOtp(e.target.value)}
          placeholder="Enter 6-digit code"
          type="text"
        />

        <div className="flex gap-3 mt-6">
          <Button variant="outline" onClick={onClose} className="flex-1">
            Cancel
          </Button>
          <Button 
            onClick={() => onVerify(otp)} 
            disabled={isLoading || otp.length < 6}
            className="flex-1"
          >
            {isLoading ? 'Verifying...' : 'Verify'}
          </Button>
        </div>
      </div>
    </div>
  );
};

export default OtpModal;