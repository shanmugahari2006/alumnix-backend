import React, { useState, useEffect, useCallback } from 'react';
import { Calendar, Plus, Users, Clock, ExternalLink, MapPin, Tag, CheckCircle2, UserCheck, AlertCircle } from 'lucide-react';

export default function EventsBulletin({ token, currentUser }) {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(false);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);

  // Form states
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState('Webinar');
  const [eventDate, setEventDate] = useState('');
  const [regDeadline, setRegDeadline] = useState('');
  const [regUrl, setRegUrl] = useState('');
  const [createError, setCreateError] = useState('');

  // Registered tracking state
  const [registeredIds, setRegisteredIds] = useState(new Set());

  const fetchEvents = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/v1/bulletin-events', {
        headers: { Authorization: `Bearer ${token}` }
      });
      if (res.ok) {
        const data = await res.json();
        setEvents(data);
      }
    } catch (err) {
      console.error('Error fetching bulletin events:', err);
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    fetchEvents();
  }, [fetchEvents]);

  const handleRegisterEvent = async (eventId) => {
    try {
      const res = await fetch(`/api/v1/bulletin-events/${eventId}/register`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` }
      });
      if (res.ok) {
        setRegisteredIds((prev) => new Set(prev).add(eventId));
        fetchEvents();
      }
    } catch (err) {
      console.error('Error registering for event:', err);
    }
  };

  const handleCreateEvent = async (e) => {
    e.preventDefault();
    setCreateError('');
    try {
      const res = await fetch('/api/v1/bulletin-events', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          title,
          description,
          category,
          event_date: eventDate ? new Date(eventDate).toISOString() : new Date().toISOString(),
          registration_deadline: regDeadline ? new Date(regDeadline).toISOString() : undefined,
          registration_url: regUrl || undefined
        })
      });
      if (res.ok) {
        setIsCreateModalOpen(false);
        setTitle('');
        setDescription('');
        setRegUrl('');
        fetchEvents();
      } else {
        const data = await res.json();
        setCreateError(data.detail || 'Failed to create event notice');
      }
    } catch (err) {
      setCreateError('Server error while creating event notice');
    }
  };

  const canCreateEvent = currentUser?.role === 'faculty' || currentUser?.role === 'admin';

  return (
    <div className="events-container">
      {/* Header Banner */}
      <div className="events-header-card">
        <div className="header-info">
          <h1 className="events-title">
            <Calendar className="icon-title" size={28} />
            Upcoming Events Bulletin
          </h1>
          <p className="events-subtitle">
            Institutional announcements, webinars, campus hackathons, tech talks, and alumni meetups.
          </p>
        </div>

        {canCreateEvent && (
          <button
            id="btn-create-event"
            className="primary-btn flex-btn"
            onClick={() => setIsCreateModalOpen(true)}
          >
            <Plus size={18} />
            <span>Post Event Notice</span>
          </button>
        )}
      </div>

      {/* Events Grid */}
      {loading ? (
        <div className="loading-spinner-box">
          <div className="spinner"></div>
          <span>Fetching upcoming events...</span>
        </div>
      ) : events.length === 0 ? (
        <div className="empty-state-card">
          <Calendar size={48} className="empty-icon" />
          <h3>No upcoming events listed</h3>
          <p>Faculty members and administrators can publish new event notices.</p>
        </div>
      ) : (
        <div className="events-grid">
          {events.map((eventItem) => {
            const isReg = registeredIds.has(eventItem.id);
            const dateObj = new Date(eventItem.event_date);
            const monthStr = dateObj.toLocaleString('default', { month: 'short' }).toUpperCase();
            const dayStr = dateObj.getDate();

            return (
              <div key={eventItem.id} className="event-card">
                <div className="event-date-badge">
                  <span className="month">{monthStr}</span>
                  <span className="day">{dayStr}</span>
                </div>

                <div className="event-content">
                  <div className="event-top-row">
                    <span className="event-category-chip">
                      <Tag size={12} /> {eventItem.category || 'General Notice'}
                    </span>
                    <span className="event-participants-badge">
                      <Users size={13} /> {eventItem.registration_count} Registered
                    </span>
                  </div>

                  <h3 className="event-item-title">{eventItem.title}</h3>
                  <p className="event-item-desc">{eventItem.description}</p>

                  <div className="event-meta-info">
                    <div className="meta-line">
                      <Clock size={14} />
                      <span>Date: {dateObj.toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })}</span>
                    </div>

                    {eventItem.creator_name && (
                      <div className="meta-line">
                        <UserCheck size={14} />
                        <span>Posted by: {eventItem.creator_name}</span>
                      </div>
                    )}
                  </div>

                  <div className="event-footer-row">
                    <button
                      id={`btn-register-event-${eventItem.id}`}
                      className={`primary-btn sm ${isReg ? 'success' : ''}`}
                      onClick={() => handleRegisterEvent(eventItem.id)}
                      disabled={isReg}
                    >
                      {isReg ? (
                        <>
                          <CheckCircle2 size={15} /> Registered!
                        </>
                      ) : (
                        'Register Interest'
                      )}
                    </button>

                    {eventItem.registration_url && (
                      <a
                        href={eventItem.registration_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="secondary-btn sm icon-btn"
                        title="External Registration Link"
                      >
                        <ExternalLink size={15} />
                      </a>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Create Event Notice Modal */}
      {isCreateModalOpen && (
        <div className="modal-overlay">
          <div className="modal-card wide-modal">
            <div className="modal-header">
              <h2 className="modal-title">Post New Event Notice / Bulletin</h2>
              <button className="modal-close-btn" onClick={() => setIsCreateModalOpen(false)}>×</button>
            </div>

            <form onSubmit={handleCreateEvent} className="modal-form">
              {createError && <div className="auth-error-banner">{createError}</div>}

              <div className="form-group">
                <label className="form-label">Event Title *</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="e.g. Annual Alumni Career Summit & Tech Webinar"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  required
                />
              </div>

              <div className="form-row">
                <div className="form-group half">
                  <label className="form-label">Category</label>
                  <select
                    className="form-control"
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                  >
                    <option value="Webinar">Webinar / Tech Talk</option>
                    <option value="Campus Recruitment">Campus Recruitment</option>
                    <option value="Alumni Meetup">Alumni Meetup</option>
                    <option value="Hackathon">Hackathon / Competition</option>
                    <option value="Workshop">Workshop</option>
                  </select>
                </div>

                <div className="form-group half">
                  <label className="form-label">Event Date & Time *</label>
                  <input
                    type="datetime-local"
                    className="form-control"
                    value={eventDate}
                    onChange={(e) => setEventDate(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group half">
                  <label className="form-label">Registration Deadline</label>
                  <input
                    type="datetime-local"
                    className="form-control"
                    value={regDeadline}
                    onChange={(e) => setRegDeadline(e.target.value)}
                  />
                </div>

                <div className="form-group half">
                  <label className="form-label">External Registration / Meet Link</label>
                  <input
                    type="url"
                    className="form-control"
                    placeholder="https://meet.google.com/xyz or Zoom Link"
                    value={regUrl}
                    onChange={(e) => setRegUrl(e.target.value)}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Event Description & Agenda *</label>
                <textarea
                  className="form-control text-area"
                  rows={4}
                  placeholder="Outline the event speakers, target audience, topic overview..."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  required
                />
              </div>

              <div className="modal-footer">
                <button type="button" className="secondary-btn" onClick={() => setIsCreateModalOpen(false)}>Cancel</button>
                <button type="submit" className="primary-btn">Publish Event Notice</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
