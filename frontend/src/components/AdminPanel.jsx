import React, { useState, useEffect, useCallback } from 'react';
import { ShieldCheck, UserCheck, CheckCircle, RefreshCw, AlertTriangle, School, GraduationCap, Users } from 'lucide-react';

export default function AdminPanel({ token }) {
  const [stats, setStats] = useState({ alumniCount: 0, jobsCount: 0, eventsCount: 0, storiesCount: 0 });
  const [loading, setLoading] = useState(false);
  const [unapprovedAlumni, setUnapprovedAlumni] = useState([]);
  const [msg, setMsg] = useState('');

  const loadAdminData = useCallback(async () => {
    setLoading(true);
    try {
      // 1. Fetch directory & jobs & events & stories count
      const [alumniRes, jobsRes, eventsRes, storiesRes] = await Promise.all([
        fetch('/api/v1/alumni?limit=100', { headers: { Authorization: `Bearer ${token}` } }),
        fetch('/api/v1/jobs', { headers: { Authorization: `Bearer ${token}` } }),
        fetch('/api/v1/bulletin-events', { headers: { Authorization: `Bearer ${token}` } }),
        fetch('/api/v1/stories', { headers: { Authorization: `Bearer ${token}` } })
      ]);

      if (alumniRes.ok && jobsRes.ok && eventsRes.ok && storiesRes.ok) {
        const alumniData = await alumniRes.json();
        const jobsData = await jobsRes.json();
        const eventsData = await eventsRes.json();
        const storiesData = await storiesRes.json();

        setStats({
          alumniCount: alumniData.total || 0,
          jobsCount: jobsData.length || 0,
          eventsCount: eventsData.length || 0,
          storiesCount: storiesData.length || 0
        });

        // Filter unapproved alumni from total results if any
        setUnapprovedAlumni(alumniData.results?.filter((a) => !a.is_approved) || []);
      }
    } catch (err) {
      console.error('Error loading admin dashboard data:', err);
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    loadAdminData();
  }, [loadAdminData]);

  const handleApproveAlumni = async (alumniId) => {
    try {
      const res = await fetch(`/api/v1/alumni/${alumniId}/approve`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` }
      });
      if (res.ok) {
        setMsg('Alumni approved successfully!');
        loadAdminData();
        setTimeout(() => setMsg(''), 2000);
      }
    } catch (err) {
      console.error('Error approving alumni:', err);
    }
  };

  return (
    <div className="admin-panel-container">
      {/* Header */}
      <div className="admin-header-card">
        <div className="header-info">
          <h1 className="admin-title">
            <ShieldCheck className="icon-title" size={28} />
            Institutional Administration & Moderation Panel
          </h1>
          <p className="admin-subtitle">
            System overview, alumni approval management, faculty verifications, and platform compliance.
          </p>
        </div>

        <button className="secondary-btn sm flex-btn" onClick={loadAdminData}>
          <RefreshCw size={14} /> Refresh Metrics
        </button>
      </div>

      {msg && <div className="auth-success-banner m-16">{msg}</div>}

      {/* Metrics Row */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon-wrapper alumni">
            <GraduationCap size={24} />
          </div>
          <div className="stat-meta">
            <span className="stat-num">{stats.alumniCount}</span>
            <span className="stat-name">Total Registered Alumni</span>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon-wrapper jobs">
            <Users size={24} />
          </div>
          <div className="stat-meta">
            <span className="stat-num">{stats.jobsCount}</span>
            <span className="stat-name">Active Job Opportunities</span>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon-wrapper events">
            <School size={24} />
          </div>
          <div className="stat-meta">
            <span className="stat-num">{stats.eventsCount}</span>
            <span className="stat-name">Published Event Notices</span>
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-icon-wrapper stories">
            <ShieldCheck size={24} />
          </div>
          <div className="stat-meta">
            <span className="stat-num">{stats.storiesCount}</span>
            <span className="stat-name">Success Stories & Pitches</span>
          </div>
        </div>
      </div>

      {/* Moderation Section */}
      <div className="moderation-card">
        <div className="card-header-bar">
          <h3 className="card-heading">
            <UserCheck size={20} /> Pending Registrations Moderation
          </h3>
        </div>

        <div className="card-body">
          {loading ? (
            <div className="loading-spinner-box">
              <div className="spinner"></div>
            </div>
          ) : unapprovedAlumni.length === 0 ? (
            <div className="empty-approval-box">
              <CheckCircle size={32} className="text-teal" />
              <p>All registered alumni accounts have been verified and approved!</p>
            </div>
          ) : (
            <div className="unapproved-list">
              {unapprovedAlumni.map((item) => (
                <div key={item.id} className="unapproved-row">
                  <div className="unapproved-info">
                    <strong>{item.full_name}</strong> ({item.email})
                    <span className="sub-text">{item.branch} | Batch of {item.graduation_year}</span>
                  </div>

                  <button
                    className="primary-btn sm"
                    onClick={() => handleApproveAlumni(item.id)}
                  >
                    <CheckCircle size={14} /> Approve Registration
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
