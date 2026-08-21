import React, { useState, useEffect, useRef } from 'react';

export default function ChatWindow({
  conversation,
  messages,
  currentUserId,
  onSendMessage,
  onBack,
  isConnected,
  onStartVideoCall
}) {
  const [inputText, setInputText] = useState('');
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!inputText.trim()) return;
    onSendMessage(inputText);
    setInputText('');
  };

  if (!conversation) {
    return (
      <div className="chat-window">
        <div className="empty-state-view">
          <div className="empty-icon-box">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
            </svg>
          </div>
          <h3 style={{ fontFamily: 'var(--font-heading)', fontSize: '1.25rem', marginBottom: '8px', color: 'var(--text-primary)' }}>
            WhatsApp Chat for Alumnix
          </h3>
          <p style={{ maxWidth: '340px', fontSize: '0.88rem' }}>
            Select a conversation from the sidebar or click '+' to search and start a private one-to-one message.
          </p>
        </div>
      </div>
    );
  }

  const partner = conversation.partner;
  const partnerInitials = partner?.full_name
    ? partner.full_name.split(' ').map((n) => n[0]).join('').substring(0, 2).toUpperCase()
    : '?';

  const formatMsgTime = (dateStr) => {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className="chat-window">
      {/* Header */}
      <div className="chat-header">
        <div className="chat-header-user">
          <button className="back-btn" onClick={onBack} title="Back to chats">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <line x1="19" y1="12" x2="5" y2="12"></line>
              <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
          </button>

          {partner?.avatar_url ? (
            <img src={partner.avatar_url} alt={partner.full_name} className="avatar" />
          ) : (
            <div className="avatar">{partnerInitials}</div>
          )}

          <div className="header-user-details">
            <span className="header-name">{partner?.full_name}</span>
            <span className="header-subtext">
              {partner?.company ? `${partner.designation || 'Alumni'} at ${partner.company}` : (partner?.role || 'User')}
              {isConnected && <span style={{ color: 'var(--accent-teal)', marginLeft: '8px' }}>● Online</span>}
            </span>
          </div>
        </div>

        {partner && onStartVideoCall && (
          <button 
            id="btn-video-call"
            className="logout-btn" 
            onClick={() => onStartVideoCall(partner.id)} 
            style={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: '6px', 
              borderColor: 'var(--accent-teal)', 
              color: 'var(--accent-teal)',
              padding: '6px 12px',
              borderRadius: '8px',
              cursor: 'pointer',
              fontWeight: 500
            }}
            title="Start Video Call"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M23 7l-7 5 7 5V7z"></path>
              <rect x="1" y="5" width="15" height="14" rx="2" ry="2"></rect>
            </svg>
            Video Call
          </button>
        )}
      </div>

      {/* Messages list */}
      <div className="messages-container">
        {messages.length === 0 ? (
          <div className="empty-state-view" style={{ flex: 'none', margin: 'auto 0' }}>
            <p style={{ fontSize: '0.88rem' }}>No messages yet. Say hi to {partner?.full_name}!</p>
          </div>
        ) : (
          messages.map((msg) => {
            const isSent = msg.sender_id === currentUserId;
            return (
              <div
                key={msg.id}
                className={`message-wrapper ${isSent ? 'sent' : 'received'}`}
              >
                <div className="message-bubble">
                  <span>{msg.content}</span>
                  <div className="msg-footer">
                    <span className="msg-time">{formatMsgTime(msg.created_at)}</span>
                    {isSent && (
                      <span className={`read-ticks ${msg.is_read ? 'read' : ''}`}>
                        {msg.is_read ? '✓✓' : '✓'}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input Area */}
      <div className="chat-input-area">
        <form className="chat-input-form" onSubmit={handleSubmit}>
          <input
            id="msg-text-input"
            type="text"
            className="msg-input"
            placeholder="Type a message..."
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
          />
          <button
            id="btn-send-message"
            type="submit"
            className="send-btn"
            disabled={!inputText.trim()}
            title="Send Message"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <line x1="22" y1="2" x2="11" y2="13"></line>
              <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
            </svg>
          </button>
        </form>
      </div>
    </div>
  );
}
