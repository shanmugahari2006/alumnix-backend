import React, { useState } from 'react';
import { User, Mail, GraduationCap, Building, MapPin, Linkedin, Save, CheckCircle, ShieldAlert } from 'lucide-react';

export default function UserProfileModal({ isOpen, onClose, token, currentUser, onProfileUpdated }) {
  if (!isOpen || !currentUser) return null;

  const isAlumni = currentUser.role === 'alumni';
  const alumniProfile = currentUser.alumni_profile || {};

  const [company, setCompany] = useState(alumniProfile.company || '');
  const [designation, setDesignation] = useState(alumniProfile.designation || '');
  const [location, setLocation] = useState(alumniProfile.location || '');
  const [linkedinUrl, setLinkedinUrl] = useState(alumniProfile.linkedin_url || '');
  const [skillsStr, setSkillsStr] = useState(alumniProfile.skills ? alumniProfile.skills.join(', ') : '');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  const handleUpdateAlumniProfile = async (e) => {
    e.preventDefault();
    setErrorMsg('');
    setSuccessMsg('');
    setIsSubmitting(true);

    try {
      const skillsArray = skillsStr.split(',').map((s) => s.trim()).filter(Boolean);
      const res = await fetch('/api/v1/alumni/profile', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          company: company || undefined,
          designation: designation || undefined,
          location: location || undefined,
          linkedin_url: linkedinUrl || undefined,
          skills: skillsArray
        })
      });

      if (res.ok) {
        setSuccessMsg('Profile updated successfully!');
        if (onProfileUpdated) onProfileUpdated();
        setTimeout(() => setSuccessMsg(''), 2000);
      } else {
        const data = await res.json();
        setErrorMsg(data.detail || 'Failed to update profile');
      }
    } catch (err) {
      setErrorMsg('Server connection error while updating profile');
    } finally {
      setIsSubmitting(false);
    }
  };

  const initials = currentUser.full_name
    ? currentUser.full_name.split(' ').map((n) => n[0]).join('').substring(0, 2).toUpperCase()
    : 'U';

  return (
    <div className="modal-overlay">
      <div className="modal-card wide-modal">
        <div className="modal-header">
          <h2 className="modal-title">My Profile & Account Info</h2>
          <button className="modal-close-btn" onClick={onClose}>×</button>
        </div>

        <div className="modal-body p-20">
          <div className="profile-hero-card">
            <div className="profile-avatar-large">{initials}</div>
            <div className="profile-hero-text">
              <h3 className="profile-name">{currentUser.full_name}</h3>
              <p className="profile-email">
                <Mail size={14} /> {currentUser.email || 'No email provided'}
              </p>
              <span className={`user-role-badge role-${currentUser.role}`}>
                {currentUser.role}
              </span>
            </div>
          </div>

          {errorMsg && <div className="auth-error-banner m-b-16">{errorMsg}</div>}
          {successMsg && <div className="auth-success-banner m-b-16">{successMsg}</div>}

          {isAlumni ? (
            <form onSubmit={handleUpdateAlumniProfile} className="profile-form">
              <h4 className="section-sub-title">Directory & Professional Details</h4>

              <div className="form-row">
                <div className="form-group half">
                  <label className="form-label">Current Designation</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Senior Software Engineer"
                    value={designation}
                    onChange={(e) => setDesignation(e.target.value)}
                  />
                </div>
                <div className="form-group half">
                  <label className="form-label">Company / Organization</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Microsoft / Google"
                    value={company}
                    onChange={(e) => setCompany(e.target.value)}
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group half">
                  <label className="form-label">Location / City</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Bangalore, India"
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                  />
                </div>
                <div className="form-group half">
                  <label className="form-label">LinkedIn Profile URL</label>
                  <input
                    type="url"
                    className="form-control"
                    placeholder="https://linkedin.com/in/username"
                    value={linkedinUrl}
                    onChange={(e) => setLinkedinUrl(e.target.value)}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Skills & Expertise (Comma-separated)</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="e.g. Python, React, Distributed Systems, Machine Learning"
                  value={skillsStr}
                  onChange={(e) => setSkillsStr(e.target.value)}
                />
              </div>

              <div className="modal-footer">
                <button type="button" className="secondary-btn" onClick={onClose}>Close</button>
                <button type="submit" className="primary-btn" disabled={isSubmitting}>
                  <Save size={16} /> {isSubmitting ? 'Saving...' : 'Save Profile Changes'}
                </button>
              </div>
            </form>
          ) : (
            <div className="non-alumni-info">
              <h4 className="section-sub-title">Account Attributes</h4>
              {currentUser.student_profile && (
                <div className="info-attr-grid">
                  <div className="attr-item">
                    <span className="attr-label">USN</span>
                    <span className="attr-val">{currentUser.student_profile.usn}</span>
                  </div>
                  <div className="attr-item">
                    <span className="attr-label">Branch</span>
                    <span className="attr-val">{currentUser.student_profile.branch}</span>
                  </div>
                  <div className="attr-item">
                    <span className="attr-label">Graduation Year</span>
                    <span className="attr-val">{currentUser.student_profile.graduation_year}</span>
                  </div>
                </div>
              )}
              {currentUser.faculty_profile && (
                <div className="info-attr-grid">
                  <div className="attr-item">
                    <span className="attr-label">Employee ID</span>
                    <span className="attr-val">{currentUser.faculty_profile.employee_id}</span>
                  </div>
                  <div className="attr-item">
                    <span className="attr-label">Department</span>
                    <span className="attr-val">{currentUser.faculty_profile.department}</span>
                  </div>
                  <div className="attr-item">
                    <span className="attr-label">Designation</span>
                    <span className="attr-val">{currentUser.faculty_profile.designation}</span>
                  </div>
                </div>
              )}

              <div className="modal-footer" style={{ marginTop: '20px' }}>
                <button type="button" className="primary-btn" onClick={onClose}>Done</button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
