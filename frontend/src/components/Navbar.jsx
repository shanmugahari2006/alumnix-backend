import React from 'react';
import { 
  GraduationCap, 
  Briefcase, 
  Rocket, 
  Calendar, 
  MessageSquare, 
  ShieldCheck, 
  LogOut, 
  User as UserIcon,
  Sparkles
} from 'lucide-react';

export default function Navbar({
  activeTab,
  setActiveTab,
  currentUser,
  onLogout,
  onOpenProfile,
  unreadCount = 0
}) {
  const userInitials = currentUser?.full_name
    ? currentUser.full_name.split(' ').map((n) => n[0]).join('').substring(0, 2).toUpperCase()
    : 'U';

  const navItems = [
    { id: 'directory', label: 'Directory', icon: GraduationCap },
    { id: 'jobs', label: 'Job Portal', icon: Briefcase },
    { id: 'stories', label: 'Stories & Startups', icon: Rocket },
    { id: 'events', label: 'Events Bulletin', icon: Calendar },
    { 
      id: 'chat', 
      label: 'Real-time Chat', 
      icon: MessageSquare,
      badge: unreadCount > 0 ? unreadCount : null 
    },
  ];

  if (currentUser?.role === 'admin') {
    navItems.push({ id: 'admin', label: 'Admin Panel', icon: ShieldCheck });
  }

  return (
    <nav className="navbar">
      <div className="brand-section">
        <div className="brand-logo">
          <span>A</span>
        </div>
        <div className="brand-text-container">
          <span className="brand-title">Alumnix</span>
          <span className="brand-subtitle">Alumni Network & Career Hub</span>
        </div>
      </div>

      <div className="nav-tabs">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              id={`nav-tab-${item.id}`}
              className={`nav-tab-btn ${isActive ? 'active' : ''}`}
              onClick={() => setActiveTab(item.id)}
            >
              <Icon size={18} className="nav-tab-icon" />
              <span>{item.label}</span>
              {item.badge && <span className="nav-badge">{item.badge}</span>}
            </button>
          );
        })}
      </div>

      <div className="user-profile-bar">
        <div className="user-info-text" onClick={onOpenProfile} style={{ cursor: 'pointer' }}>
          <span className="user-name">{currentUser?.full_name || 'User'}</span>
          <span className={`user-role-badge role-${currentUser?.role}`}>
            {currentUser?.role}
          </span>
        </div>

        <div 
          className="avatar-btn" 
          onClick={onOpenProfile} 
          title="Click to view profile"
        >
          {userInitials}
        </div>

        <button 
          className="logout-btn" 
          onClick={onLogout} 
          title="Log out"
          id="btn-navbar-logout"
        >
          <LogOut size={16} />
          <span className="logout-text">Logout</span>
        </button>
      </div>
    </nav>
  );
}
