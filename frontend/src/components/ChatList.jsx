import React from 'react';

export default function ChatList({
  conversations,
  activeConversationId,
  onSelectConversation,
  searchQuery,
  onSearchChange,
  onOpenNewChatModal
}) {
  const formatTime = (dateStr) => {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    const now = new Date();
    const isToday = d.toDateString() === now.toDateString();
    if (isToday) {
      return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
    const isThisWeek = (now - d) < 7 * 24 * 60 * 60 * 1000;
    if (isThisWeek) {
      return d.toLocaleDateString([], { weekday: 'short' });
    }
    return d.toLocaleDateString([], { month: 'short', day: 'numeric' });
  };

  const filteredConversations = conversations.filter((c) => {
    if (!searchQuery.trim()) return true;
    const name = c.partner?.full_name?.toLowerCase() || '';
    const msg = c.last_message?.content?.toLowerCase() || '';
    const q = searchQuery.toLowerCase();
    return name.includes(q) || msg.includes(q);
  });

  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <h2 className="sidebar-title">Chats</h2>
        <button
          className="new-chat-btn"
          onClick={onOpenNewChatModal}
          title="New Chat"
          id="btn-new-chat"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
          </svg>
        </button>
      </div>

      <div className="search-container">
        <div className="search-input-wrapper">
          <svg className="search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="11" cy="11" r="8"></circle>
            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
          </svg>
          <input
            id="chat-search-input"
            type="text"
            className="search-input"
            placeholder="Search chats or messages..."
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
          />
        </div>
      </div>

      <div className="conversations-list">
        {filteredConversations.length === 0 ? (
          <div className="empty-state-view" style={{ padding: '20px' }}>
            <p style={{ fontSize: '0.85rem' }}>No conversations found</p>
          </div>
        ) : (
          filteredConversations.map((c) => {
            const isActive = c.id === activeConversationId;
            const initials = c.partner?.full_name
              ? c.partner.full_name.split(' ').map((n) => n[0]).join('').substring(0, 2).toUpperCase()
              : '?';

            return (
              <div
                key={c.id}
                id={`conv-item-${c.id}`}
                className={`conversation-item ${isActive ? 'active' : ''}`}
                onClick={() => onSelectConversation(c)}
              >
                <div className="avatar-wrapper">
                  {c.partner?.avatar_url ? (
                    <img src={c.partner.avatar_url} alt={c.partner.full_name} className="avatar" />
                  ) : (
                    <div className="avatar">{initials}</div>
                  )}
                </div>

                <div className="conv-info">
                  <div className="conv-top-row">
                    <span className="partner-name">{c.partner?.full_name}</span>
                    <span className={`time-stamp ${c.unread_count > 0 ? 'unread' : ''}`}>
                      {formatTime(c.last_message?.created_at || c.updated_at)}
                    </span>
                  </div>

                  <div className="conv-bottom-row">
                    <span className="last-message">
                      {c.last_message ? c.last_message.content : 'No messages yet'}
                    </span>
                    {c.unread_count > 0 && (
                      <span className="unread-badge">{c.unread_count}</span>
                    )}
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
