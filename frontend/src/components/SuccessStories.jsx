import React, { useState, useEffect, useCallback } from 'react';
import { Rocket, Heart, Plus, Award, User, Clock, Sparkles, MessageSquare, ExternalLink } from 'lucide-react';

export default function SuccessStories({ token, currentUser }) {
  const [stories, setStories] = useState([]);
  const [loading, setLoading] = useState(false);
  const [isPostModalOpen, setIsPostModalOpen] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newContent, setNewContent] = useState('');
  const [postError, setPostError] = useState('');

  const fetchStories = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/v1/stories', {
        headers: { Authorization: `Bearer ${token}` }
      });
      if (res.ok) {
        const data = await res.json();
        setStories(data);
      }
    } catch (err) {
      console.error('Error fetching stories:', err);
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    fetchStories();
  }, [fetchStories]);

  const handleLikeToggle = async (storyId) => {
    try {
      const res = await fetch(`/api/v1/stories/${storyId}/like`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` }
      });
      if (res.ok) {
        const data = await res.json();
        setStories((prev) =>
          prev.map((s) => (s.id === storyId ? { ...s, likes_count: data.likes_count } : s))
        );
      }
    } catch (err) {
      console.error('Error liking story:', err);
    }
  };

  const handleCreateStory = async (e) => {
    e.preventDefault();
    setPostError('');
    try {
      const res = await fetch('/api/v1/stories', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          title: newTitle,
          content: newContent
        })
      });
      if (res.ok) {
        setIsPostModalOpen(false);
        setNewTitle('');
        setNewContent('');
        fetchStories();
      } else {
        const data = await res.json();
        setPostError(data.detail || 'Failed to post story');
      }
    } catch (err) {
      setPostError('Server error while posting story');
    }
  };

  const canPost = currentUser?.role === 'alumni' || currentUser?.role === 'admin';

  return (
    <div className="stories-container">
      {/* Banner */}
      <div className="stories-header-card">
        <div className="header-info">
          <h1 className="stories-title">
            <Rocket className="icon-title" size={28} />
            Success Stories & Startup Showcase
          </h1>
          <p className="stories-subtitle">
            Celebrating alumni achievements, startup fundraising rounds, product launches, and career breakthroughs.
          </p>
        </div>

        {canPost && (
          <button
            id="btn-post-story"
            className="primary-btn flex-btn"
            onClick={() => setIsPostModalOpen(true)}
          >
            <Plus size={18} />
            <span>Share Story / Startup Pitch</span>
          </button>
        )}
      </div>

      {/* Stories Feed */}
      {loading ? (
        <div className="loading-spinner-box">
          <div className="spinner"></div>
          <span>Loading success stories feed...</span>
        </div>
      ) : stories.length === 0 ? (
        <div className="empty-state-card">
          <Award size={48} className="empty-icon" />
          <h3>No stories shared yet</h3>
          <p>Be the first alumni to share a career milestone or startup launch!</p>
        </div>
      ) : (
        <div className="stories-feed flex-col">
          {stories.map((story) => (
            <div key={story.id} className="story-card">
              <div className="story-card-header">
                <div className="author-meta-row">
                  <div className="author-avatar">
                    {story.author_name ? story.author_name[0].toUpperCase() : 'A'}
                  </div>
                  <div className="author-info">
                    <h4 className="author-name">{story.author_name || 'Alumni Contributor'}</h4>
                    <span className="story-date">
                      <Clock size={12} /> {new Date(story.created_at).toLocaleDateString()}
                    </span>
                  </div>
                </div>

                <div className="story-badge">
                  <Sparkles size={13} /> Milestone
                </div>
              </div>

              <div className="story-card-body">
                <h2 className="story-item-title">{story.title}</h2>
                <p className="story-item-content">{story.content}</p>
              </div>

              <div className="story-card-footer">
                <button
                  id={`btn-like-story-${story.id}`}
                  className="like-btn"
                  onClick={() => handleLikeToggle(story.id)}
                >
                  <Heart size={18} className="heart-icon" />
                  <span>{story.likes_count} Likes</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Post Story Modal */}
      {isPostModalOpen && (
        <div className="modal-overlay">
          <div className="modal-card">
            <div className="modal-header">
              <h2 className="modal-title">Share Success Story or Pitch Startup</h2>
              <button className="modal-close-btn" onClick={() => setIsPostModalOpen(false)}>×</button>
            </div>

            <form onSubmit={handleCreateStory} className="modal-form">
              {postError && <div className="auth-error-banner">{postError}</div>}

              <div className="form-group">
                <label className="form-label">Headline / Title *</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="e.g. Raised $2M Seed Round for AI Startup / Promoted to VP of Engineering"
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Story / Launch Details *</label>
                <textarea
                  className="form-control text-area"
                  rows={6}
                  placeholder="Share your journey, key lessons, team details, or advice for current students..."
                  value={newContent}
                  onChange={(e) => setNewContent(e.target.value)}
                  required
                />
              </div>

              <div className="modal-footer">
                <button type="button" className="secondary-btn" onClick={() => setIsPostModalOpen(false)}>Cancel</button>
                <button type="submit" className="primary-btn">Publish to Feed</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
