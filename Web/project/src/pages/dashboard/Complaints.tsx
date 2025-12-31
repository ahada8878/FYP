import { useState, useEffect } from 'react';
import { AlertCircle, CheckCircle2, XCircle, Clock, Mail } from 'lucide-react';
import Card from '../../components/ui/Card';
import Button from '../../components/ui/Button';

// API Base URL
const API_BASE_URL = 'http://localhost:5000/api/complaints';

interface Complaint {
  _id: string;
  // User can be an object, a string ID, or null (if user was deleted)
  user: { _id: string; email?: string } | string | null; 
  email: string;
  subject: string;
  message: string;
  status: 'UNRESOLVED' | 'RESOLVED' | 'REJECTED';
  createdAt: string;
}

const Complaints = () => {
  const [complaints, setComplaints] = useState<Complaint[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState<string>('all');

  useEffect(() => {
    const fetchComplaints = async () => {
      try {
        const response = await fetch(API_BASE_URL);
        const data = await response.json();
        if (Array.isArray(data)) {
          setComplaints(data);
        }
      } catch (error) {
        console.error("Failed to fetch complaints:", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchComplaints();
  }, []);

  const handleUpdateStatus = async (id: string, newStatus: 'RESOLVED' | 'REJECTED') => {
    if (!window.confirm(`Mark this complaint as ${newStatus}?`)) return;

    try {
      // Optimistic Update
      setComplaints(prev => prev.map(c => 
        c._id === id ? { ...c, status: newStatus } : c
      ));

      await fetch(`${API_BASE_URL}/${id}/status`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus })
      });

      if (newStatus === 'RESOLVED') {
        alert('Complaint resolved. Notification email sent.');
      }

    } catch (error) {
      console.error("Failed to update status:", error);
      alert("Failed to update status.");
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'UNRESOLVED': return 'text-amber-600 dark:text-amber-400 bg-amber-100 dark:bg-amber-900/30 px-2 py-1 rounded-full';
      case 'RESOLVED': return 'text-green-600 dark:text-green-400 bg-green-100 dark:bg-green-900/30 px-2 py-1 rounded-full';
      case 'REJECTED': return 'text-red-600 dark:text-red-400 bg-red-100 dark:bg-red-900/30 px-2 py-1 rounded-full';
      default: return 'text-gray-600';
    }
  };

  const pendingCount = complaints.filter(c => c.status === 'UNRESOLVED').length;
  const resolvedCount = complaints.filter(c => c.status === 'RESOLVED').length;
  const rejectedCount = complaints.filter(c => c.status === 'REJECTED').length;

  const filteredComplaints = complaints.filter(c => 
    filterStatus === 'all' || c.status === filterStatus
  );

  // --- Helper to Safely Get User ID ---
  const getUserIdDisplay = (user: Complaint['user']) => {
    if (!user) return 'Deleted User'; // Handle null
    if (typeof user === 'string') return user; // Handle raw ID string
    return user._id || 'Unknown ID'; // Handle populated object
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Complaints Management</h1>
        <p className="text-gray-600 dark:text-gray-400">Manage user issues and track resolutions.</p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <div className="text-center">
            <div className="inline-flex items-center justify-center h-12 w-12 rounded-full bg-amber-100 text-amber-600 dark:bg-amber-900 dark:text-amber-400 mb-4">
              <Clock size={24} />
            </div>
            <h3 className="text-lg font-medium text-gray-900 dark:text-white">Pending</h3>
            <p className="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-2">{pendingCount}</p>
          </div>
        </Card>
        <Card>
          <div className="text-center">
            <div className="inline-flex items-center justify-center h-12 w-12 rounded-full bg-green-100 text-green-600 dark:bg-green-900 dark:text-green-400 mb-4">
              <CheckCircle2 size={24} />
            </div>
            <h3 className="text-lg font-medium text-gray-900 dark:text-white">Resolved</h3>
            <p className="text-2xl font-bold text-green-600 dark:text-green-400 mt-2">{resolvedCount}</p>
          </div>
        </Card>
        <Card>
          <div className="text-center">
            <div className="inline-flex items-center justify-center h-12 w-12 rounded-full bg-red-100 text-red-600 dark:bg-red-900 dark:text-red-400 mb-4">
              <XCircle size={24} />
            </div>
            <h3 className="text-lg font-medium text-gray-900 dark:text-white">Rejected</h3>
            <p className="text-2xl font-bold text-red-600 dark:text-red-400 mt-2">{rejectedCount}</p>
          </div>
        </Card>
      </div>

      {/* Table */}
      <Card>
        <div className="mb-6 flex gap-4">
          <select
            className="px-4 py-2 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
          >
            <option value="all">All Complaints</option>
            <option value="UNRESOLVED">Unresolved</option>
            <option value="RESOLVED">Resolved</option>
            <option value="REJECTED">Rejected</option>
          </select>
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead className="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User ID</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Subject</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200 dark:bg-gray-900 dark:divide-gray-700">
              {isLoading ? (
                <tr><td colSpan={6} className="text-center py-4">Loading complaints...</td></tr>
              ) : filteredComplaints.length === 0 ? (
                <tr><td colSpan={6} className="text-center py-4 text-gray-500">No complaints found.</td></tr>
              ) : (
                filteredComplaints.map((complaint) => (
                  <tr key={complaint._id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                    
                    {/* ✅ User ID - SAFELY RENDERED */}
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400 font-mono">
                      {getUserIdDisplay(complaint.user)}
                    </td>

                    {/* Email */}
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <Mail size={16} className="text-gray-400 mr-2" />
                        <span className="text-sm text-gray-900 dark:text-white">{complaint.email}</span>
                      </div>
                    </td>

                    {/* Subject */}
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-gray-900 dark:text-white">{complaint.subject}</div>
                      <div className="text-xs text-gray-500 truncate max-w-xs" title={complaint.message}>
                        {complaint.message}
                      </div>
                    </td>

                    {/* Date */}
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                      {new Date(complaint.createdAt).toLocaleDateString()}
                    </td>

                    {/* Status */}
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`text-xs font-bold ${getStatusColor(complaint.status)}`}>
                        {complaint.status}
                      </span>
                    </td>

                    {/* Actions */}
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      {complaint.status === 'UNRESOLVED' ? (
                        <div className="flex justify-end gap-2">
                          <Button 
                            variant="ghost" 
                            size="sm"
                            className="text-green-600 hover:bg-green-50 hover:text-green-700"
                            onClick={() => handleUpdateStatus(complaint._id, 'RESOLVED')}
                          >
                            <CheckCircle2 size={18} className="mr-1" /> Resolve
                          </Button>
                          <Button 
                            variant="ghost" 
                            size="sm" 
                            className="text-red-600 hover:bg-red-50 hover:text-red-700"
                            onClick={() => handleUpdateStatus(complaint._id, 'REJECTED')}
                          >
                            <XCircle size={18} className="mr-1" /> Reject
                          </Button>
                        </div>
                      ) : (
                        <span className="text-gray-400 italic text-xs">
                          {complaint.status === 'RESOLVED' ? 'Resolved' : 'Rejected'}
                        </span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
};

export default Complaints;