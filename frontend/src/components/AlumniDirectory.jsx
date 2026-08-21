import React, { useState, useEffect, useCallback } from 'react';
import { Search, Filter, MapPin, Building, GraduationCap, Linkedin, MessageSquare, CheckCircle, Award, Sparkles, RefreshCw } from 'lucide-react';

export default function AlumniDirectory({ token, currentUser, onStartChat }) {
  const [alumniList, setAlumniList] = useState([]);
  const [totalCount, setTotalCount] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);

  // Filters state
  const [searchQuery, setSearchQuery] = useState('');
  const [branchFilter, setBranchFilter] = useState('');
  const [batchFilter, setBatchFilter] = useState('');
  const [locationFilter, setLocationFilter] = useState('');
  const [skillFilter, setSkillFilter] = useState('');

  const fetchAlumni = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (searchQuery.trim()) params.append('search', searchQuery.trim());
      if (branchFilter) params.append('branch', branchFilter);
      if (batchFilter) params.append('batch', batchFilter);
      if (locationFilter.trim()) params.append('location', locationFilter.trim());
      if (skillFilter.trim()) params.append('skills', skillFilter.trim());
      params.append('page', page);
      params.append('limit', 12);

      const res = await fetch(`/api/v1/alumni?${params.toString()}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      if (res.ok) {
        const data = await res.json();
        setAlumniList(data.results || []);
        setTotalCount(data.total || 0);
      }
    } catch (err) {
      console.error('Error fetching alumni directory:', err);
    } finally {
      setLoading(false);
    }
  }, [token, searchQuery, branchFilter, batchFilter, locationFilter, skillFilter, page]);

  useEffect(() => {
    fetchAlumni();
  }, [fetchAlumni]);

  const handleApproveAlumni = async (alumniId) => {
    try {
      const res = await fetch(`/api/v1/alumni/${alumniId}/approve`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` }
      });
      if (res.ok) {
        fetchAlumni();
      }
    } catch (err) {
      console.error('Error approving alumni:', err);
    }
  };

  const handleClearFilters = () => {
    setSearchQuery('');
    setBranchFilter('');
    setBatchFilter('');
    setLocationFilter('');
    setSkillFilter('');
    setPage(1);
  };

  return (
    <div className="directory-container">
      {/* Header Banner */}
      <div className="directory-header-card">
        <div className="header-info">
          <h1 className="directory-title">
            <GraduationCap className="icon-title" size={28} />
            Alumni Network Directory
          </h1>
          <p className="directory-subtitle">
            Connect, network, and seek mentorship from thousands of global alumni leaders.
          </p>
        </div>
        <div className="directory-stats-badge">
          <span className="stats-number">{totalCount}</span>
          <span className="stats-label">Approved Alumni</span>
        </div>
      </div>

      {/* Filter Toolbar */}
      <div className="filter-card">
        <div className="search-row">
          <div className="search-input-box flex-2">
            <Search className="search-icon" size={18} />
            <input
              id="alumni-search-input"
              type="text"
              className="filter-input"
              placeholder="Search by name, designation, or company..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>

          <div className="search-input-box flex-1">
            <GraduationCap className="search-icon" size={18} />
            <select
              className="filter-select"
              value={branchFilter}
              onChange={(e) => setBranchFilter(e.target.value)}
            >
              <option value="">All Branches</option>
              <option value="Computer Science">Computer Science</option>
              <option value="Information Science">Information Science</option>
              <option value="Electronics & Communication">Electronics & Comm</option>
              <option value="Mechanical Engineering">Mechanical</option>
              <option value="Civil Engineering">Civil</option>
              <option value="Electrical Engineering">Electrical</option>
              <option value="Artificial Intelligence">AI & Data Science</option>
            </select>
          </div>

          <div className="search-input-box flex-1">
            <MapPin className="search-icon" size={18} />
            <input
              type="text"
              className="filter-input"
              placeholder="Location (e.g. Bangalore)"
              value={locationFilter}
              onChange={(e) => setLocationFilter(e.target.value)}
            />
          </div>
        </div>

        <div className="filter-secondary-row">
          <div className="search-input-box flex-1">
            <input
              type="number"
              className="filter-input"
              placeholder="Batch Year (e.g. 2020)"
              value={batchFilter}
              onChange={(e) => setBatchFilter(e.target.value)}
            />
          </div>

          <div className="search-input-box flex-2">
            <input
              type="text"
              className="filter-input"
              placeholder="Filter by skill tag (e.g. Python, Machine Learning, Product)"
              value={skillFilter}
              onChange={(e) => setSkillFilter(e.target.value)}
            />
          </div>

          <button className="clear-filter-btn" onClick={handleClearFilters}>
            <RefreshCw size={14} /> Clear Filters
          </button>
        </div>
      </div>

      {/* Directory Grid */}
      {loading ? (
        <div className="loading-spinner-box">
          <div className="spinner"></div>
          <span>Searching directory...</span>
        </div>
      ) : alumniList.length === 0 ? (
        <div className="empty-state-card">
          <GraduationCap size={48} className="empty-icon" />
          <h3>No alumni found matching your criteria</h3>
          <p>Try clearing filters or adjusting search keywords to find profiles.</p>
          <button className="primary-btn sm" onClick={handleClearFilters}>Reset Filters</button>
        </div>
      ) : (
        <div className="alumni-grid">
          {alumniList.map((alumni) => {
            const initials = alumni.full_name
              ? alumni.full_name.split(' ').map((n) => n[0]).join('').substring(0, 2).toUpperCase()
              : 'A';

            return (
              <div key={alumni.id} className="alumni-card">
                <div className="alumni-card-header">
                  <div className="alumni-avatar">
                    {initials}
                  </div>
                  <div className="alumni-main-meta">
                    <h3 className="alumni-name">{alumni.full_name}</h3>
                    <div className="alumni-role-company">
                      <Building size={14} className="meta-icon" />
                      <span>{alumni.designation || 'Alumni'} {alumni.company ? `at ${alumni.company}` : ''}</span>
                    </div>
                  </div>
                </div>

                <div className="alumni-card-body">
                  <div className="meta-badge-row">
                    {alumni.branch && (
                      <span className="meta-chip branch">
                        <GraduationCap size={12} /> {alumni.branch} ({alumni.graduation_year})
                      </span>
                    )}
                    {alumni.location && (
                      <span className="meta-chip location">
                        <MapPin size={12} /> {alumni.location}
                      </span>
                    )}
                  </div>

                  {alumni.skills && alumni.skills.length > 0 && (
                    <div className="skills-pill-box">
                      {alumni.skills.map((skill, idx) => (
                        <span key={idx} className="skill-pill">{skill}</span>
                      ))}
                    </div>
                  )}
                </div>

                <div className="alumni-card-footer">
                  <button
                    id={`btn-chat-alumni-${alumni.id}`}
                    className="action-btn chat-action"
                    onClick={() => onStartChat({ id: alumni.id, full_name: alumni.full_name, email: alumni.email })}
                  >
                    <MessageSquare size={16} />
                    <span>Message Alumni</span>
                  </button>

                  {alumni.linkedin_url && (
                    <a
                      href={alumni.linkedin_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="linkedin-btn"
                      title="LinkedIn Profile"
                    >
                      <Linkedin size={16} />
                    </a>
                  )}

                  {currentUser?.role === 'admin' && (
                    <button
                      className="action-btn approve-action"
                      onClick={() => handleApproveAlumni(alumni.id)}
                      title="Approve Alumni Registration"
                    >
                      <CheckCircle size={16} />
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
