import React, { useState, useEffect } from 'react';

export default function NewChatModal({ isOpen, onClose, onSelectUser, fetchUsers }) {
  const [query, setQuery] = useState('');
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!isOpen) return;
    let isMounted = true;
    setLoading(true);

    fetchUsers(query)
      .then((data) => {
        if (isMounted) setUsers(data);
      })
      .catch((err) => console.error('Error fetching users for new chat:', err))
      .finally(() => {
        if (isMounted) setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [isOpen, query, fetchUsers]);

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3 className="modal-title">New Conversation</h3>
          <button className="modal-close-btn" onClick={onClose}>&times;</button>
        </div>

        <div className="search-container" style={{ padding: '12px 16px' }}>
          <div className="search-input-wrapper">
            <svg className="search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="11" cy="11" r="8"></circle>
              <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
            <input
              id="new-chat-search-input"
              type="text"
              className="search-input"
              placeholder="Search alumni or students by name..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              autoFocus
            />
          </div>
        </div>

        <div className="user-search-list">
          {loading ? (
            <div className="empty-state-view" style={{ padding: '20px' }}>
              <p style={{ fontSize: '0.85rem' }}>Loading users...</p>
            </div>
          ) : users.length === 0 ? (
            <div className="empty-state-view" style={{ padding: '20px' }}>
              <p style={{ fontSize: '0.85rem' }}>No users found matching "{query}"</p>
            </div>
          ) : (
            users.map((u) => {
              const initials = u.full_name
                ? u.full_name.split(' ').map((n) => n[0]).join('').substring(0, 2).toUpperCase()
                : '?';

              return (
                <div
                  key={u.id}
                  id={`user-item-${u.id}`}
                  className="user-search-item"
                  onClick={() => {
                    onSelectUser(u);
                    onClose();
                  }}
                >
                  <div className="avatar-wrapper" style={{ marginRight: '12px' }}>
                    {u.avatar_url ? (
                      <img src={u.avatar_url} alt={u.full_name} className="avatar small" />
                    ) : (
                      <div className="avatar small">{initials}</div>
                    )}
                  </div>

                  <div className="header-user-details" style={{ flex: 1 }}>
                    <span className="partner-name">{u.full_name}</span>
                    <span className="user-meta-sub">
                      {u.company ? `${u.designation || 'Alumni'} at ${u.company}` : (u.role || 'Student')}
                      {u.branch ? ` • ${u.branch}` : ''}
                    </span>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}
