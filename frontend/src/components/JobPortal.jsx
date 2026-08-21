import React, { useState, useEffect, useCallback } from 'react';
import { Briefcase, Building, MapPin, DollarSign, Plus, Search, Filter, Clock, ExternalLink, CheckCircle, XCircle, FileText, Send, User } from 'lucide-react';

export default function JobPortal({ token, currentUser }) {
  const [jobs, setJobs] = useState([]);
  const [loading, setLoading] = useState(false);

  // Search & Filter state
  const [titleFilter, setTitleFilter] = useState('');
  const [companyFilter, setCompanyFilter] = useState('');
  const [typeFilter, setTypeFilter] = useState('');

  // Post Job Modal State
  const [isPostModalOpen, setIsPostModalOpen] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newCompany, setNewCompany] = useState('');
  const [newLocation, setNewLocation] = useState('Remote / Onsite');
  const [newType, setNewType] = useState('Full-Time');
  const [newSalary, setNewSalary] = useState('');
  const [newDesc, setNewDesc] = useState('');
  const [newReqs, setNewReqs] = useState('');
  const [postError, setPostError] = useState('');

  // Apply Modal State
  const [applyJob, setApplyJob] = useState(null);
  const [resumeUrl, setResumeUrl] = useState('https://linkedin.com/in/student-resume.pdf');
  const [coverNote, setCoverNote] = useState('');
  const [applySuccess, setApplySuccess] = useState('');
  const [applyError, setApplyError] = useState('');

  // View Applicants Modal State
  const [viewApplicantsJob, setViewApplicantsJob] = useState(null);
  const [applications, setApplications] = useState([]);
  const [appsLoading, setAppsLoading] = useState(false);

  const fetchJobs = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (titleFilter.trim()) params.append('title', titleFilter.trim());
      if (companyFilter.trim()) params.append('company', companyFilter.trim());
      if (typeFilter) params.append('job_type', typeFilter);

      const res = await fetch(`/api/v1/jobs?${params.toString()}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      if (res.ok) {
        const data = await res.json();
        setJobs(data);
      }
    } catch (err) {
      console.error('Error fetching jobs:', err);
    } finally {
      setLoading(false);
    }
  }, [token, titleFilter, companyFilter, typeFilter]);

  useEffect(() => {
    fetchJobs();
  }, [fetchJobs]);

  const handlePostJob = async (e) => {
    e.preventDefault();
    setPostError('');
    try {
      const res = await fetch('/api/v1/jobs', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          title: newTitle,
          company: newCompany,
          location: newLocation,
          job_type: newType,
          salary_range: newSalary || undefined,
          description: newDesc,
          requirements: newReqs ? newReqs.split(',').map((r) => r.trim()) : []
        })
      });
      if (res.ok) {
        setIsPostModalOpen(false);
        setNewTitle('');
        setNewCompany('');
        setNewSalary('');
        setNewDesc('');
        setNewReqs('');
        fetchJobs();
      } else {
        const data = await res.json();
        setPostError(data.detail || 'Failed to post job');
      }
    } catch (err) {
      setPostError('Server error while posting job');
    }
  };

  const handleApply = async (e) => {
    e.preventDefault();
    if (!applyJob) return;
    setApplyError('');
    setApplySuccess('');
    try {
      const res = await fetch(`/api/v1/jobs/${applyJob.id}/apply`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          resume_url: resumeUrl,
          cover_note: coverNote || undefined
        })
      });
      if (res.ok) {
        setApplySuccess('Application submitted successfully!');
        setTimeout(() => {
          setApplyJob(null);
          setApplySuccess('');
        }, 1500);
      } else {
        const data = await res.json();
        setApplyError(data.detail || 'Failed to submit application');
      }
    } catch (err) {
      setApplyError('Server error submitting application');
    }
  };

  const fetchApplicationsForJob = async (job) => {
    setViewApplicantsJob(job);
    setAppsLoading(true);
    try {
      const res = await fetch(`/api/v1/jobs/${job.id}/applications`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      if (res.ok) {
        const data = await res.json();
        setApplications(data);
      }
    } catch (err) {
      console.error('Error fetching applications:', err);
    } finally {
      setAppsLoading(false);
    }
  };

  const handleUpdateAppStatus = async (appId, newStatus) => {
    try {
      const res = await fetch(`/api/v1/jobs/applications/${appId}/status`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({ status: newStatus })
      });
      if (res.ok) {
        if (viewApplicantsJob) {
          fetchApplicationsForJob(viewApplicantsJob);
        }
      }
    } catch (err) {
      console.error('Error updating application status:', err);
    }
  };

  const canPostJob = currentUser?.role === 'alumni' || currentUser?.role === 'admin';
  const canApplyJob = currentUser?.role === 'student';

  return (
    <div className="portal-container">
      {/* Banner */}
      <div className="portal-header-card">
        <div className="header-info">
          <h1 className="portal-title">
            <Briefcase className="icon-title" size={28} />
            Alumni Job & Internship Portal
          </h1>
          <p className="portal-subtitle">
            Exclusive job opportunities, referral postings, and internships posted directly by college alumni.
          </p>
        </div>

        {canPostJob && (
          <button
            id="btn-post-job"
            className="primary-btn flex-btn"
            onClick={() => setIsPostModalOpen(true)}
          >
            <Plus size={18} />
            <span>Post a Job Listing</span>
          </button>
        )}
      </div>

      {/* Filter Toolbar */}
      <div className="filter-card">
        <div className="search-row">
          <div className="search-input-box flex-2">
            <Search className="search-icon" size={18} />
            <input
              type="text"
              className="filter-input"
              placeholder="Search by job title or keyword..."
              value={titleFilter}
              onChange={(e) => setTitleFilter(e.target.value)}
            />
          </div>

          <div className="search-input-box flex-1">
            <Building className="search-icon" size={18} />
            <input
              type="text"
              className="filter-input"
              placeholder="Company name..."
              value={companyFilter}
              onChange={(e) => setCompanyFilter(e.target.value)}
            />
          </div>

          <div className="search-input-box flex-1">
            <Filter className="search-icon" size={18} />
            <select
              className="filter-select"
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
            >
              <option value="">All Job Types</option>
              <option value="Full-Time">Full-Time</option>
              <option value="Internship">Internship</option>
              <option value="Contract">Contract</option>
              <option value="Remote">Remote</option>
            </select>
          </div>
        </div>
      </div>

      {/* Jobs Grid */}
      {loading ? (
        <div className="loading-spinner-box">
          <div className="spinner"></div>
          <span>Loading job opportunities...</span>
        </div>
      ) : jobs.length === 0 ? (
        <div className="empty-state-card">
          <Briefcase size={48} className="empty-icon" />
          <h3>No active job listings found</h3>
          <p>Alumni members can post new job opportunities anytime.</p>
        </div>
      ) : (
        <div className="jobs-list">
          {jobs.map((job) => (
            <div key={job.id} className="job-card">
              <div className="job-card-header">
                <div className="job-title-row">
                  <h3 className="job-title">{job.title}</h3>
                  <span className={`job-type-pill ${job.job_type?.toLowerCase()}`}>
                    {job.job_type}
                  </span>
                </div>
                <div className="job-company-row">
                  <Building size={14} />
                  <span>{job.company}</span>
                  <span className="dot-sep">•</span>
                  <MapPin size={14} />
                  <span>{job.location}</span>
                </div>
              </div>

              <div className="job-card-body">
                <p className="job-desc">{job.description}</p>

                {job.salary_range && (
                  <div className="salary-pill">
                    <DollarSign size={13} /> {job.salary_range}
                  </div>
                )}

                {job.requirements && job.requirements.length > 0 && (
                  <div className="req-tags-box">
                    {job.requirements.map((req, idx) => (
                      <span key={idx} className="req-tag">{req}</span>
                    ))}
                  </div>
                )}
              </div>

              <div className="job-card-footer">
                <div className="posted-meta">
                  <Clock size={13} />
                  <span>Posted {new Date(job.created_at).toLocaleDateString()}</span>
                </div>

                <div className="job-actions-row">
                  {canApplyJob && (
                    <button
                      id={`btn-apply-job-${job.id}`}
                      className="primary-btn sm"
                      onClick={() => setApplyJob(job)}
                    >
                      Apply Now
                    </button>
                  )}

                  {(currentUser?.id === job.posted_by_id || currentUser?.role === 'admin') && (
                    <button
                      className="secondary-btn sm"
                      onClick={() => fetchApplicationsForJob(job)}
                    >
                      View Applicants
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* 1. Post Job Modal */}
      {isPostModalOpen && (
        <div className="modal-overlay">
          <div className="modal-card wide-modal">
            <div className="modal-header">
              <h2 className="modal-title">Post New Job / Referral Opportunity</h2>
              <button className="modal-close-btn" onClick={() => setIsPostModalOpen(false)}>×</button>
            </div>

            <form onSubmit={handlePostJob} className="modal-form">
              {postError && <div className="auth-error-banner">{postError}</div>}

              <div className="form-row">
                <div className="form-group half">
                  <label className="form-label">Job Title *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Senior Software Engineer"
                    value={newTitle}
                    onChange={(e) => setNewTitle(e.target.value)}
                    required
                  />
                </div>
                <div className="form-group half">
                  <label className="form-label">Company Name *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Google / Microsoft / Startup"
                    value={newCompany}
                    onChange={(e) => setNewCompany(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group half">
                  <label className="form-label">Location</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Bangalore, India (Hybrid)"
                    value={newLocation}
                    onChange={(e) => setNewLocation(e.target.value)}
                  />
                </div>
                <div className="form-group half">
                  <label className="form-label">Job Type</label>
                  <select
                    className="form-control"
                    value={newType}
                    onChange={(e) => setNewType(e.target.value)}
                  >
                    <option value="Full-Time">Full-Time</option>
                    <option value="Internship">Internship</option>
                    <option value="Contract">Contract</option>
                    <option value="Remote">Remote</option>
                  </select>
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Salary / Stipend Range</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="e.g. ₹15,00,000 - ₹22,00,000 / year or ₹50,000/mo"
                  value={newSalary}
                  onChange={(e) => setNewSalary(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label className="form-label">Job Description *</label>
                <textarea
                  className="form-control text-area"
                  rows={4}
                  placeholder="Describe the role expectations, key responsibilities, and how students/alumni can reach out..."
                  value={newDesc}
                  onChange={(e) => setNewDesc(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Key Requirements (Comma-separated)</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="e.g. React, Node.js, SQL, Problem Solving"
                  value={newReqs}
                  onChange={(e) => setNewReqs(e.target.value)}
                />
              </div>

              <div className="modal-footer">
                <button type="button" className="secondary-btn" onClick={() => setIsPostModalOpen(false)}>Cancel</button>
                <button type="submit" className="primary-btn">Publish Job Listing</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 2. Apply Modal */}
      {applyJob && (
        <div className="modal-overlay">
          <div className="modal-card">
            <div className="modal-header">
              <h2 className="modal-title">Apply for {applyJob.title}</h2>
              <button className="modal-close-btn" onClick={() => setApplyJob(null)}>×</button>
            </div>

            <form onSubmit={handleApply} className="modal-form">
              {applyError && <div className="auth-error-banner">{applyError}</div>}
              {applySuccess && <div className="auth-success-banner">{applySuccess}</div>}

              <div className="form-group">
                <label className="form-label">Resume URL / Portfolio Link *</label>
                <input
                  type="url"
                  className="form-control"
                  placeholder="https://drive.google.com/... or LinkedIn"
                  value={resumeUrl}
                  onChange={(e) => setResumeUrl(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Cover Note / Brief Pitch</label>
                <textarea
                  className="form-control text-area"
                  rows={3}
                  placeholder="Why are you a good fit for this role?"
                  value={coverNote}
                  onChange={(e) => setCoverNote(e.target.value)}
                />
              </div>

              <div className="modal-footer">
                <button type="button" className="secondary-btn" onClick={() => setApplyJob(null)}>Cancel</button>
                <button type="submit" className="primary-btn">Submit Application</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 3. Applicants List Modal */}
      {viewApplicantsJob && (
        <div className="modal-overlay">
          <div className="modal-card wide-modal">
            <div className="modal-header">
              <h2 className="modal-title">Applicants for {viewApplicantsJob.title}</h2>
              <button className="modal-close-btn" onClick={() => setViewApplicantsJob(null)}>×</button>
            </div>

            <div className="modal-body p-16">
              {appsLoading ? (
                <div className="loading-spinner-box">
                  <div className="spinner"></div>
                </div>
              ) : applications.length === 0 ? (
                <p className="empty-subtext">No candidates have applied for this listing yet.</p>
              ) : (
                <div className="applicants-list">
                  {applications.map((app) => (
                    <div key={app.id} className="applicant-item-card">
                      <div className="applicant-info-col">
                        <h4 className="applicant-name">{app.student?.user?.full_name}</h4>
                        <p className="applicant-sub">
                          USN: {app.student?.student?.usn} | {app.student?.student?.branch} ({app.student?.student?.graduation_year})
                        </p>
                        <a href={app.resume_url} target="_blank" rel="noopener noreferrer" className="resume-link">
                          <FileText size={14} /> View Candidate Resume
                        </a>
                      </div>

                      <div className="applicant-status-col">
                        <span className={`status-pill ${app.status?.toLowerCase()}`}>
                          {app.status}
                        </span>

                        <div className="status-actions">
                          <button
                            className="status-btn shortlist"
                            onClick={() => handleUpdateAppStatus(app.id, 'shortlisted')}
                            title="Shortlist Applicant"
                          >
                            <CheckCircle size={15} /> Shortlist
                          </button>
                          <button
                            className="status-btn reject"
                            onClick={() => handleUpdateAppStatus(app.id, 'rejected')}
                            title="Reject Applicant"
                          >
                            <XCircle size={15} /> Reject
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
