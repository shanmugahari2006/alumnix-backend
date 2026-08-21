import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  ArrowRight, Briefcase, CalendarDays, Check, ChevronLeft, CircleDollarSign,
  ClipboardList, GraduationCap, Heart, Home, LayoutDashboard, LogOut, Menu, MessageCircle, UsersRound,
  Pencil, Plus, RefreshCw, Search, Send, ShieldCheck, Sparkles, Star, UserRound, Users,
  X, BookOpen, MapPin, Building2, Clock3, ExternalLink, SlidersHorizontal, Bell,
} from 'lucide-react';

import MentorshipVideoCall from './components/MentorshipVideoCall';
import VideoCallModal from './components/VideoCallModal';
import { useWebRTCCall } from './hooks/useWebRTCCall';
import './App.css';

const API_BASE = (import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/').replace(/\/$/, '');
const WS_BASE = (import.meta.env.VITE_WS_BASE_URL || 'ws://127.0.0.1:8000/').replace(/\/$/, '');
const ACCESS_KEY = 'aluminix_access_token';
const REFRESH_KEY = 'aluminix_refresh_token';

const navItems = [
  { id: 'home', label: 'Home', icon: Home },
  { id: 'directory', label: 'Alumni directory', icon: Users },
  { id: 'jobs', label: 'Career board', icon: Briefcase },
  { id: 'stories', label: 'Success stories', icon: BookOpen },
  { id: 'fundraisers', label: 'Fundraisers', icon: CircleDollarSign },
  { id: 'events', label: 'Events bulletin', icon: CalendarDays },
  { id: 'chat', label: 'Messages', icon: MessageCircle },
];

const features = [
  { icon: Users, title: 'Alumni directory', text: 'Find mentors, collaborators, and familiar faces across every graduating class.' },
  { icon: Briefcase, title: 'Career board', text: 'Discover trusted opportunities and build a stronger path forward.' },
  { icon: Star, title: 'Success stories', text: 'Learn from the people who turned campus beginnings into meaningful careers.' },
  { icon: CircleDollarSign, title: 'Startup fundraisers', text: 'Back promising student ventures and keep the alumni network moving.' },
  { icon: CalendarDays, title: 'Events bulletin', text: 'Keep the community close with talks, reunions, programs, and meetups.' },
  { icon: MessageCircle, title: 'Private messaging', text: 'Move from a directory introduction to a real conversation in seconds.' },
];

function getStored(key) { return window.sessionStorage.getItem(key) || window.localStorage.getItem(key) || ''; }
function saveTokens(data) {
  if (data?.access_token) window.sessionStorage.setItem(ACCESS_KEY, data.access_token);
  if (data?.refresh_token) window.localStorage.setItem(REFRESH_KEY, data.refresh_token);
}
function clearTokens() {
  window.sessionStorage.removeItem(ACCESS_KEY);
  window.localStorage.removeItem(ACCESS_KEY);
  window.localStorage.removeItem(REFRESH_KEY);
}
function formatDate(value, withTime = false) {
  if (!value) return '—';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? value : date.toLocaleDateString(undefined, withTime ? { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' } : { month: 'short', day: 'numeric', year: 'numeric' });
}
function initials(name = 'Alumnix') { return name.split(' ').map((part) => part[0]).slice(0, 2).join('').toUpperCase(); }

async function decodeError(response) {
  try {
    const data = await response.json();
    const detail = data?.detail;
    if (Array.isArray(detail)) return detail.map((item) => item.msg).join(', ');
    return detail || data?.message || 'Something went wrong. Please try again.';
  } catch { return `Request failed (${response.status}). Please try again.`; }
}

function useApi(accessToken, refreshToken, setTokens, onUnauthorized) {
  const refresh = useCallback(async () => {
    if (!refreshToken) return false;
    const response = await fetch(`${API_BASE}/api/v1/auth/refresh`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ refresh_token: refreshToken }),
    });
    if (!response.ok) return false;
    const data = await response.json();
    setTokens(data);
    return Boolean(data.access_token);
  }, [refreshToken, setTokens]);

  return useCallback(async (path, options = {}, retry = true) => {
    const headers = { ...(options.body instanceof FormData ? {} : { 'Content-Type': 'application/json' }), ...(options.headers || {}) };
    const token = getStored(ACCESS_KEY) || accessToken;
    if (token && !headers.Authorization) headers.Authorization = `Bearer ${token}`;
    const response = await fetch(`${API_BASE}${path}`, { ...options, headers });
    if (response.status === 401 && retry && refreshToken && !path.includes('/auth/refresh')) {
      const renewed = await refresh();
      if (renewed) return useApi(getStored(ACCESS_KEY), refreshToken, setTokens, onUnauthorized)(path, options, false);
      onUnauthorized?.();
    }
    if (!response.ok) throw new Error(await decodeError(response));
    if (response.status === 204) return null;
    return response.json();
  }, [accessToken, refresh, refreshToken, setTokens, onUnauthorized]);
}

function Button({ children, variant = 'primary', className = '', ...props }) {
  return <button className={`button button-${variant} ${className}`} {...props}>{children}</button>;
}
function IconButton({ label, children, ...props }) { return <button className="icon-button" aria-label={label} title={label} {...props}>{children}</button>; }
function Field({ label, hint, ...props }) { return <label className="field"><span>{label}</span><input {...props} />{hint && <small>{hint}</small>}</label>; }
function TextArea({ label, ...props }) { return <label className="field"><span>{label}</span><textarea {...props} /></label>; }
function SelectField({ label, children, ...props }) { return <label className="field"><span>{label}</span><select {...props}>{children}</select></label>; }
function Notice({ type = 'error', children, onClose }) { return <div className={`notice notice-${type}`}><span>{children}</span>{onClose && <IconButton label="Dismiss" onClick={onClose}><X size={15} /></IconButton>}</div>; }
function Loader({ label = 'Loading' }) { return <div className="loader"><span className="loader-ring" />{label}</div>; }
function EmptyState({ icon: Icon = Search, title, text, action }) { return <div className="empty-state"><Icon size={25} /><h3>{title}</h3><p>{text}</p>{action}</div>; }

function Landing({ onLogin, onRegister }) {
  return <div className="landing-page">
    <header className="landing-nav"><div className="brand"><span className="brand-mark"><UsersRound size={21} /></span><span>Alumnix</span></div><div className="landing-actions"><button className="text-button" onClick={onLogin}>Sign in</button><Button onClick={onRegister}>Join the community <ArrowRight size={16} /></Button></div></header>
    <main>
      <section className="hero-section"><div className="hero-copy"><div className="eyebrow"><Sparkles size={14} /> The network behind your next chapter</div><h1>Where campus <em>connections</em> become lasting momentum.</h1><p className="hero-lede">Alumnix brings students, alumni, faculty, and opportunity into one thoughtful community built for growth.</p><div className="hero-actions"><Button onClick={onRegister}>Create your account <ArrowRight size={17} /></Button><button className="outline-button" onClick={onLogin}>I already have an account</button></div><div className="trust-line"><span className="avatar-stack"><i>AM</i><i>RS</i><i>NK</i><i>+</i></span><span>Join a growing network of people who remember where they started.</span></div></div><div className="hero-visual"><div className="orb orb-large" /><div className="orb orb-small" /><div className="network-card"><div className="network-card-top"><span>COMMUNITY PULSE</span><span className="live-dot">Live</span></div><div className="pulse-number">2,480 <small>members</small></div><div className="pulse-bars"><span style={{ height: '42%' }} /><span style={{ height: '68%' }} /><span style={{ height: '53%' }} /><span style={{ height: '84%' }} /><span style={{ height: '62%' }} /><span style={{ height: '92%' }} /><span style={{ height: '76%' }} /></div><div className="pulse-footer"><span><strong>+18.4%</strong> this semester</span><span className="mini-spark">↗</span></div></div><div className="quote-card"><span className="quote-mark">“</span><p>One introduction changed my entire career trajectory.</p><small>— Ananya, Class of 2019</small></div><div className="floating-tag tag-one"><span className="tag-icon"><Users size={13} /></span><span><strong>New connection</strong><small>Rohan joined your network</small></span></div><div className="floating-tag tag-two"><span className="tag-icon gold"><Briefcase size={13} /></span><span><strong>12 new roles</strong><small>matched to your profile</small></span></div></div></section>
      <section className="marquee-strip"><span>STUDENTS</span><span>ALUMNI</span><span>FACULTY</span><span>OPPORTUNITY</span><span>COMMUNITY</span><span>MENTORSHIP</span></section>
      <section className="section-block"><div className="section-heading"><div><div className="eyebrow">Everything in one place</div><h2>A more connected way to move forward.</h2></div><p>Whether you are making your first introduction or giving back to the next generation, the right tools are here.</p></div><div className="feature-grid">{features.map(({ icon: Icon, title, text }) => <article className="feature-card" key={title}><div className="feature-icon"><Icon size={20} /></div><h3>{title}</h3><p>{text}</p><span className="feature-arrow">↗</span></article>)}</div></section>
      <section className="story-banner"><div><div className="eyebrow light">Built around belonging</div><h2>Your next opportunity may already be one conversation away.</h2></div><Button variant="light" onClick={onRegister}>Start connecting <ArrowRight size={16} /></Button></section>
    </main><footer className="landing-footer"><div className="brand"><span className="brand-mark"><UsersRound size={19} /></span><span>Alumnix</span></div><span>Made for the people who make a campus feel like home.</span><span>© {new Date().getFullYear()} Alumnix</span></footer>
  </div>;
}

function AuthPanel({ mode, setMode, onClose, onAuthenticated }) {
  const [loginForm, setLoginForm] = useState({ email: '', password: '' });
  const [role, setRole] = useState('student');
  const [step, setStep] = useState(0);
  const [form, setForm] = useState({ usn: '', channel: 'email', otp_code: '', password: '', confirm: '', full_name: '', employee_id: '', email: '', phone_number: '', department: '', designation: '' });
  const [verificationToken, setVerificationToken] = useState('');
  const [verifiedName, setVerifiedName] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [expires, setExpires] = useState(600);
  const request = useCallback(async (path, options = {}) => { const response = await fetch(`${API_BASE}${path}`, { ...options, headers: { 'Content-Type': 'application/json', ...(options.headers || {}) } }); if (!response.ok) throw new Error(await decodeError(response)); return response.json(); }, []);
  const update = (key, value) => setForm((current) => ({ ...current, [key]: value }));
  const submitLogin = async (event) => { event.preventDefault(); setBusy(true); setError(''); try { const data = await request('/api/v1/auth/login', { method: 'POST', body: JSON.stringify(loginForm) }); onAuthenticated(data); } catch (err) { setError(err.message.includes('Alumni account pending') ? 'Your alumni account is pending moderation approval.' : err.message); } finally { setBusy(false); } };
  const submitRegister = async (event) => {
    event.preventDefault(); setBusy(true); setError(''); setMessage(''); try {
      if (role === 'faculty') { await request('/api/v1/auth/register/faculty', { method: 'POST', body: JSON.stringify({ employee_id: form.employee_id, full_name: form.full_name, email: form.email || null, phone_number: form.phone_number || null, password: form.password, department: form.department, designation: form.designation }) }); setMessage('Registration submitted. An administrator must approve your teacher or professor account before you can sign in.'); return; }
      if (step === 0) { const data = await request('/api/v1/auth/register/verify-usn', { method: 'POST', body: JSON.stringify({ usn: form.usn, role }) }); setVerifiedName(data.full_name); setStep(1); }
      else if (step === 1) { await request('/api/v1/auth/register/send-otp', { method: 'POST', body: JSON.stringify({ usn: form.usn, channel: form.channel }) }); setExpires(600); setStep(2); setMessage(`Verification code sent via ${form.channel}.`); }
      else if (step === 2) { const data = await request('/api/v1/auth/register/verify-otp', { method: 'POST', body: JSON.stringify({ usn: form.usn, channel: form.channel, otp_code: form.otp_code }) }); setVerificationToken(data.verification_token); setStep(3); setMessage('Identity verified. Set a password to finish your profile.'); }
      else { if (form.password.length < 8) throw new Error('Password must be at least 8 characters.'); if (form.password !== form.confirm) throw new Error('Passwords do not match.'); const data = await request('/api/v1/auth/register/setup-password', { method: 'POST', body: JSON.stringify({ verification_token: verificationToken, password: form.password }) }); onAuthenticated(data); }
    } catch (err) { setError(err.message.includes('USN already registered') ? 'This USN already has an account. Use Sign in with the demo credentials instead of registering it again.' : err.message); } finally { setBusy(false); }
  };
  useEffect(() => { if (mode === 'register' && step === 2 && expires > 0) { const timer = setTimeout(() => setExpires((value) => value - 1), 1000); return () => clearTimeout(timer); } }, [mode, step, expires]);
  const goBack = () => { setError(''); setMessage(''); if (mode === 'login') setMode('landing'); else if (role === 'faculty' || step === 0) setMode('landing'); else setStep((value) => value - 1); };
  return <div className="auth-overlay"><div className="auth-panel"><button className="close-auth" onClick={onClose || (() => setMode('landing'))}><X size={19} /></button><div className="auth-panel-brand"><span className="brand-mark"><UsersRound size={19} /></span><span>Alumnix</span></div>{mode === 'login' ? <><div className="auth-title"><div className="eyebrow">Welcome back</div><h2>Continue your journey.</h2><p>Sign in to pick up where your network left off.</p></div>{error && <Notice onClose={() => setError('')}>{error}</Notice>}{message && <Notice type="success">{message}</Notice>}<form onSubmit={submitLogin} className="auth-form"><Field label="Email or Phone Number" value={loginForm.email} onChange={(e) => setLoginForm({ ...loginForm, email: e.target.value })} placeholder="you@example.com or +91..." required /><Field label="Password" type="password" value={loginForm.password} onChange={(e) => setLoginForm({ ...loginForm, password: e.target.value })} placeholder="At least 8 characters" required minLength={8} /><div className="form-row-between"><button type="button" className="text-button small" onClick={() => setMessage('Password recovery is available from the backend recovery endpoints.')}>Forgot password?</button></div><Button type="submit" className="full-width" disabled={busy}>{busy ? 'Signing in…' : 'Sign in'} <ArrowRight size={16} /></Button></form><div className="demo-credentials"><span>Quick demo login</span><div><button type="button" onClick={() => setLoginForm({ email: 'student@college.com', password: 'password123' })}>Student</button><button type="button" onClick={() => setLoginForm({ email: 'alumni@college.com', password: 'password123' })}>Alumni</button><button type="button" onClick={() => setLoginForm({ email: 'admin@college.com', password: 'admin1234' })}>Admin</button></div><small>Student and alumni use <strong>password123</strong>. Admin uses <strong>admin1234</strong>.</small></div><p className="auth-switch">New to the community? <button className="text-button small" onClick={() => { setError(''); setMode('register'); }}>Create an account</button></p></> : <><div className="auth-title"><div className="eyebrow">Join the network · {role === 'faculty' ? 'Teacher / Professor registration' : `Step ${step + 1} of 4`}</div><h2>{role === 'faculty' ? 'Bring your perspective to the room.' : step === 0 ? 'Let’s find your record.' : step === 1 ? `Welcome, ${verifiedName || 'friend'}.` : step === 2 ? 'Verify it’s really you.' : 'Make it yours.'}</h2><p>{role === 'faculty' ? 'Teacher and professor profiles go live after administrator approval.' : step === 0 ? 'Choose your role and enter the university-issued USN.' : step === 1 ? 'Your registry record is ready. Choose where to receive a code.' : step === 2 ? 'Enter the 6-digit code sent to your registered contact.' : 'Create a secure password to open your complete profile.'}</p></div>{role !== 'faculty' && <div className="step-progress">{[0, 1, 2, 3].map((item) => <span key={item} className={item <= step ? 'done' : ''} />)}</div>}{error && <Notice onClose={() => setError('')}>{error}</Notice>}{message && <Notice type="success">{message}</Notice>}{role === 'faculty' ? <form onSubmit={submitRegister} className="auth-form"><div className="two-fields"><Field label="Full name" value={form.full_name} onChange={(e) => update('full_name', e.target.value)} required /><Field label="Employee ID" value={form.employee_id} onChange={(e) => update('employee_id', e.target.value)} required /></div><div className="two-fields"><Field label="Email" type="email" value={form.email} onChange={(e) => update('email', e.target.value)} placeholder="Optional if phone is provided" /><Field label="Phone number" value={form.phone_number} onChange={(e) => update('phone_number', e.target.value)} placeholder="Optional if email is provided" /></div><div className="two-fields"><Field label="Department" value={form.department} onChange={(e) => update('department', e.target.value)} required /><Field label="Designation" value={form.designation} onChange={(e) => update('designation', e.target.value)} required /></div><Field label="Password" type="password" value={form.password} onChange={(e) => update('password', e.target.value)} minLength={8} required /><Button type="submit" className="full-width" disabled={busy}>{busy ? 'Submitting…' : 'Submit for approval'} <ArrowRight size={16} /></Button></form> : <form onSubmit={submitRegister} className="auth-form">{step === 0 && <><div className="role-picker">{[['student', 'Student', 'Build your first connections'], ['alumni', 'Alumni', 'Give back and stay close'], ['faculty', 'Teacher / Professor', 'Share your academic perspective']].map(([value, title, text]) => <button type="button" key={value} className={`role-option ${role === value ? 'selected' : ''}`} onClick={() => setRole(value)}><span className="role-radio">{role === value && <Check size={12} />}</span><span><strong>{title}</strong><small>{text}</small></span></button>)}</div><Field label="University Seat Number (USN)" value={form.usn} onChange={(e) => update('usn', e.target.value)} placeholder="e.g. 1AB21CS001" required /><Button type="submit" className="full-width" disabled={busy}>{busy ? 'Checking registry…' : 'Verify my record'} <ArrowRight size={16} /></Button></>}{step === 1 && <><div className="welcome-callout"><div className="avatar-circle">{initials(verifiedName)}</div><div><strong>Welcome, {verifiedName}.</strong><span>Your university record has been found.</span></div></div><div className="channel-choice"><button type="button" className={form.channel === 'email' ? 'channel selected' : 'channel'} onClick={() => update('channel', 'email')}><span>✉</span><strong>Send to email</strong><small>Use the email on your registry record</small></button><button type="button" className={form.channel === 'phone' ? 'channel selected' : 'channel'} onClick={() => update('channel', 'phone')}><span>⌁</span><strong>Send to phone</strong><small>Use the phone on your registry record</small></button></div><Button type="submit" className="full-width" disabled={busy}>{busy ? 'Sending code…' : 'Send verification code'} <Send size={15} /></Button></>}{step === 2 && <><div className="otp-header"><span>Code sent via <strong>{form.channel}</strong></span><span className={expires < 60 ? 'timer urgent' : 'timer'}>{Math.floor(expires / 60)}:{String(expires % 60).padStart(2, '0')}</span></div><Field label="One-time verification code" value={form.otp_code} onChange={(e) => update('otp_code', e.target.value.replace(/\D/g, '').slice(0, 6))} placeholder="000000" inputMode="numeric" required /><Button type="submit" className="full-width" disabled={busy || form.otp_code.length < 4}>{busy ? 'Verifying…' : 'Verify code'} <Check size={16} /></Button><button type="button" className="resend-button" onClick={() => { setStep(1); setMessage('Choose a channel to resend your code.'); }}>Resend OTP</button></>}{step === 3 && <><Field label="Create password" type="password" value={form.password} onChange={(e) => update('password', e.target.value)} hint="Use at least 8 characters." required minLength={8} /><Field label="Confirm password" type="password" value={form.confirm} onChange={(e) => update('confirm', e.target.value)} required /><Button type="submit" className="full-width" disabled={busy}>{busy ? 'Creating your profile…' : 'Open my complete profile'} <ArrowRight size={16} /></Button></>}</form>}{role !== 'faculty' && step === 0 && <button className="faculty-link" type="button" onClick={() => setRole('faculty')}>Register as Teacher / Professor instead <ArrowRight size={14} /></button>}{role === 'faculty' && <button className="faculty-link" type="button" onClick={() => setRole('student')}>Back to student / alumni registration <ChevronLeft size={14} /></button>}<p className="auth-switch">Already registered? <button className="text-button small" onClick={() => { setError(''); setMode('login'); }}>Sign in</button></p></>}</div><button className="auth-backdrop" onClick={() => setMode('landing')} aria-label="Close authentication" /></div>;
}

function Sidebar({ page, setPage, user, unread, onLogout, onProfile }) {
  return <aside className="sidebar"><div className="sidebar-brand"><span className="brand-mark"><UsersRound size={19} /></span><span>Alumnix</span></div><div className="workspace-label">YOUR WORKSPACE</div><nav>{navItems.map(({ id, label, icon: Icon }) => <button key={id} className={page === id ? 'side-link active' : 'side-link'} onClick={() => setPage(id)}><Icon size={17} /><span>{label}</span>{id === 'chat' && unread > 0 && <b>{unread}</b>}</button>)}{user?.role === 'admin' && <button className={page === 'admin' ? 'side-link active' : 'side-link'} onClick={() => setPage('admin')}><ShieldCheck size={17} /><span>Admin review</span></button>}</nav><div className="sidebar-bottom"><button className="profile-mini" onClick={onProfile}><span className="avatar-circle small">{initials(user?.full_name)}</span><span><strong>{user?.full_name || 'Member'}</strong><small>{user?.role || 'member'}</small></span><ChevronLeft size={15} className="profile-chevron" /></button><button className="side-link logout-link" onClick={onLogout}><LogOut size={16} /><span>Sign out</span></button></div></aside>;
}
function Topbar({ title, subtitle, user, onProfile, onRefresh }) { return <header className="topbar"><div><div className="breadcrumb">Alumnix <span>/</span> <strong>{title}</strong></div><h1>{title}</h1>{subtitle && <p>{subtitle}</p>}</div><div className="topbar-actions"><IconButton label="Refresh data" onClick={onRefresh}><RefreshCw size={17} /></IconButton><button className="top-profile" onClick={onProfile}><span className="avatar-circle small">{initials(user?.full_name)}</span><span><strong>{user?.full_name}</strong><small>{user?.role}</small></span><ChevronLeft size={15} className="down-chevron" /></button></div></header>; }
function PageHeader({ eyebrow, title, text, action }) { return <div className="page-header"><div><div className="eyebrow">{eyebrow}</div><h2>{title}</h2>{text && <p>{text}</p>}</div>{action}</div>; }
function StatCard({ label, value, note, icon: Icon, accent = 'blue' }) { return <div className={`stat-card accent-${accent}`}><span className="stat-icon"><Icon size={17} /></span><div><small>{label}</small><strong>{value}</strong><span>{note}</span></div></div>; }

function HomeFeed({ user, goTo, request }) {
  const [stories, setStories] = useState([]); const [jobs, setJobs] = useState([]); const [loading, setLoading] = useState(true); const [error, setError] = useState(''); const [update, setUpdate] = useState('');
  const load = useCallback(async () => { setLoading(true); const [storyResult, jobResult] = await Promise.allSettled([request('/api/v1/stories'), request('/api/v1/jobs')]); if (storyResult.status === 'fulfilled') setStories(storyResult.value || []); if (jobResult.status === 'fulfilled') setJobs(jobResult.value || []); if (storyResult.status === 'rejected' && jobResult.status === 'rejected') setError('Your feed is temporarily unavailable. Try refreshing in a moment.'); else setError(''); setLoading(false); }, [request]);
  useEffect(() => { load(); }, []);
  const like = async (id) => { try { const result = await request(`/api/v1/stories/${id}/like`, { method: 'POST' }); setStories((items) => items.map((story) => story.id === id ? { ...story, likes_count: result.likes_count } : story)); } catch (err) { setError(err.message); } };
  const publish = async (event) => { event.preventDefault(); if (!update.trim()) return; try { await request('/api/v1/stories', { method: 'POST', body: JSON.stringify({ title: `An update from ${user?.full_name || 'your community'}`, content: update.trim() }) }); setUpdate(''); load(); } catch (err) { setError(err.message); } };
  return <div className="home-feed"><div className="feed-main"><section className="feed-welcome"><div><div className="eyebrow light">Your community feed</div><h2>Good to see you, {user?.full_name?.split(' ')[0] || 'there'}.</h2><p>See what your alumni, classmates, and mentors are sharing today.</p></div><span className="feed-live"><span /> Live network</span></section><form className="compose-card" onSubmit={publish}><div className="compose-top"><span className="avatar-circle">{initials(user?.full_name)}</span><textarea value={update} onChange={(event) => setUpdate(event.target.value)} placeholder="Share an update with your community..." rows={2} /></div><div className="compose-actions"><span><button type="button" onClick={() => setUpdate((value) => `${value}${value ? ' ' : ''}What I am learning: `)}>Add a thought</button><button type="button" onClick={() => setUpdate((value) => `${value}${value ? ' ' : ''}An opportunity worth sharing: `)}>Share opportunity</button></span><Button type="submit" disabled={!update.trim()}>Post update <ArrowRight size={15} /></Button></div></form>{error && <Notice>{error}</Notice>}{loading ? <Loader label="Loading your feed" /> : stories.length ? stories.map((story) => <article className="feed-post" key={story.id}><div className="post-header"><span className="avatar-circle">{initials(story.author_name)}</span><div><strong>{story.author_name || 'Alumnix member'}</strong><small>Alumni community · {formatDate(story.created_at)}</small></div><span className="post-badge">Community</span></div><h3>{story.title}</h3><p>{story.content}</p><div className="post-actions"><button onClick={() => like(story.id)}><Heart size={16} /> {story.likes_count || 0} Likes</button><button onClick={() => goTo('chat')}><MessageCircle size={16} /> Comment</button><button onClick={() => navigator.clipboard?.writeText(window.location.href)}><Send size={15} /> Share</button></div></article>) : <EmptyState icon={Heart} title="Your feed is ready for its first post" text="Explore the community or share a thought to start the conversation." action={<Button onClick={() => goTo('directory')}>Find people to follow</Button>} />}</div><aside className="feed-rail"><section className="rail-card profile-rail"><div className="eyebrow">Your profile</div><div className="rail-profile"><span className="avatar-circle large">{initials(user?.full_name)}</span><div><strong>{user?.full_name}</strong><small>{user?.role}</small></div></div><Button variant="secondary" className="full-width" onClick={() => goTo('profile')}>View profile</Button></section><section className="rail-card"><div className="rail-heading"><div><div className="eyebrow">Career pulse</div><h3>Opportunities for you</h3></div><Briefcase size={17} /></div>{jobs.slice(0, 3).map((job) => <button className="rail-job" key={job.id} onClick={() => goTo('jobs')}><span className="company-logo">{initials(job.company)}</span><span><strong>{job.title}</strong><small>{job.company} · {job.location}</small></span><ArrowRight size={14} /></button>)}{!jobs.length && <p className="rail-muted">New opportunities will appear here.</p>}<button className="rail-link" onClick={() => goTo('jobs')}>See all opportunities <ArrowRight size={14} /></button></section><section className="rail-card"><div className="rail-heading"><div><div className="eyebrow">Build your network</div><h3>Make a meaningful next move.</h3></div><UsersRound size={17} /></div><p className="rail-muted">Find a mentor, join the conversation, or share what you have learned.</p><button className="rail-link" onClick={() => goTo('directory')}>Explore the directory <ArrowRight size={14} /></button></section></aside></div>;
}

function Overview({ user, goTo, request }) {
  const [summary, setSummary] = useState({ members: '—', jobs: '—', stories: '—', events: '—' });
  useEffect(() => { let active = true; Promise.allSettled(['/api/v1/alumni?limit=1', '/api/v1/jobs', '/api/v1/stories', '/api/v1/bulletin-events'].map((path) => request(path))).then((results) => { if (!active) return; setSummary({ members: results[0].status === 'fulfilled' ? results[0].value.total ?? '—' : '—', jobs: results[1].status === 'fulfilled' ? results[1].value.length : '—', stories: results[2].status === 'fulfilled' ? results[2].value.length : '—', events: results[3].status === 'fulfilled' ? results[3].value.length : '—' }); }); return () => { active = false; }; }, [request]);
  return <div className="page-content"><div className="welcome-banner"><div><div className="eyebrow light">{new Date().toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric' })}</div><h2>Good to see you, {user?.full_name?.split(' ')[0] || 'there'}.</h2><p>Your community is ready when you are. Take one small step today.</p></div><div className="banner-decoration"><div /><div /><div /></div></div><div className="stats-grid"><StatCard label="Community members" value={summary.members} note="Across every cohort" icon={Users} accent="blue" /><StatCard label="Open opportunities" value={summary.jobs} note="Roles to explore" icon={Briefcase} accent="gold" /><StatCard label="Shared stories" value={summary.stories} note="Ideas worth reading" icon={BookOpen} accent="violet" /><StatCard label="Upcoming events" value={summary.events} note="Ways to reconnect" icon={CalendarDays} accent="mint" /></div><div className="overview-grid"><div className="panel journey-panel"><div className="panel-heading"><div><div className="eyebrow">A simple next step</div><h3>Make your profile work for you.</h3></div><Pencil size={17} /></div><p>Complete the details that help the right people find you, then explore the parts of the community that feel most relevant.</p><div className="journey-steps"><button onClick={() => goTo('directory')}><span>01</span><strong>Find a connection</strong><small>Browse the alumni directory</small><ArrowRight size={15} /></button><button onClick={() => goTo('jobs')}><span>02</span><strong>Explore opportunity</strong><small>See roles posted by alumni</small><ArrowRight size={15} /></button><button onClick={() => goTo('chat')}><span>03</span><strong>Start a conversation</strong><small>Reach out with intention</small><ArrowRight size={15} /></button></div></div><div className="panel signal-panel"><div className="panel-heading"><div><div className="eyebrow">Your role</div><h3>{user?.role ? user.role[0].toUpperCase() + user.role.slice(1) : 'Member'} profile</h3></div><ShieldCheck size={17} /></div><div className="signal-profile"><span className="avatar-circle large">{initials(user?.full_name)}</span><div><strong>{user?.full_name}</strong><small>{user?.email}</small><span className="verified-chip"><Check size={12} /> Account active</span></div></div><button className="soft-button" onClick={() => goTo('profile')}>Review profile <ArrowRight size={14} /></button></div></div></div>;
}

function Directory({ user, request, onStartChat }) {
  const [filters, setFilters] = useState({ query: '', branch: '', graduation_year: '', location: '', skills: '' }); const [data, setData] = useState({ results: [], total: 0 }); const [state, setState] = useState({ loading: true, error: '' }); const [editing, setEditing] = useState(false); const [profile, setProfile] = useState({ company: '', designation: '', location: '', linkedin_url: '', skills: '', branch: '' });
  const load = useCallback(async () => { setState({ loading: true, error: '' }); try { const params = new URLSearchParams({ page: '1', limit: '30' }); Object.entries(filters).forEach(([key, value]) => value && params.set(key, value)); const result = await request(`/api/v1/alumni?${params}`); setData(result); } catch (err) { setState({ loading: false, error: err.message }); return; } setState({ loading: false, error: '' }); }, [filters, request]); useEffect(() => { load(); }, []);
  const saveProfile = async (event) => { event.preventDefault(); try { await request('/api/v1/alumni/profile', { method: 'PUT', body: JSON.stringify({ ...profile, skills: profile.skills.split(',').map((item) => item.trim()).filter(Boolean) }) }); setEditing(false); } catch (err) { setState((s) => ({ ...s, error: err.message })); } };
  return <div className="page-content"><PageHeader eyebrow="People like you" title="Alumni directory" text="Search the full community by experience, cohort, and shared interests." action={<Button onClick={() => setEditing(true)}><Pencil size={15} /> Edit my profile</Button>} /><div className="filter-bar"><div className="search-input"><Search size={16} /><input value={filters.query} onChange={(e) => setFilters({ ...filters, query: e.target.value })} onKeyDown={(e) => e.key === 'Enter' && load()} placeholder="Search by name, company, or skill" /></div><input value={filters.branch} onChange={(e) => setFilters({ ...filters, branch: e.target.value })} placeholder="Branch" /><input value={filters.graduation_year} onChange={(e) => setFilters({ ...filters, graduation_year: e.target.value })} placeholder="Graduation year" /><input value={filters.location} onChange={(e) => setFilters({ ...filters, location: e.target.value })} placeholder="Location" /><Button variant="secondary" onClick={load}><SlidersHorizontal size={15} /> Apply filters</Button></div>{state.error && <Notice>{state.error}</Notice>}{state.loading ? <Loader label="Loading alumni" /> : data.results?.length ? <div className="directory-grid">{data.results.map((person) => <article className="person-card" key={person.id}><div className="person-card-top"><span className="avatar-circle large">{initials(person.full_name)}</span><span className="person-status"><span /> Active</span></div><h3>{person.full_name}</h3><p className="person-role">{person.designation || 'Alumni member'}{person.company ? ` · ${person.company}` : ''}</p><div className="person-meta"><span><GraduationCap size={13} /> {person.branch || 'Community'} · {person.graduation_year || '—'}</span><span><MapPin size={13} /> {person.location || 'Location private'}</span></div><div className="tag-row">{(person.skills || []).slice(0, 3).map((skill) => <span key={skill}>{skill}</span>)}</div><Button variant="outline" className="full-width" onClick={() => onStartChat(person)}><MessageCircle size={15} /> Start a conversation</Button></article>)}</div> : <EmptyState icon={Users} title="No members found" text="Try a wider search or check another graduating year." />}{editing && <Modal title="Update your profile" onClose={() => setEditing(false)}><form className="modal-form" onSubmit={saveProfile}><Field label="Company" value={profile.company} onChange={(e) => setProfile({ ...profile, company: e.target.value })} /><Field label="Designation" value={profile.designation} onChange={(e) => setProfile({ ...profile, designation: e.target.value })} /><div className="two-fields"><Field label="Location" value={profile.location} onChange={(e) => setProfile({ ...profile, location: e.target.value })} /><Field label="Branch" value={profile.branch} onChange={(e) => setProfile({ ...profile, branch: e.target.value })} /></div><Field label="LinkedIn URL" value={profile.linkedin_url} onChange={(e) => setProfile({ ...profile, linkedin_url: e.target.value })} /><Field label="Skills" value={profile.skills} onChange={(e) => setProfile({ ...profile, skills: e.target.value })} hint="Separate skills with commas." /><div className="modal-actions"><Button variant="secondary" type="button" onClick={() => setEditing(false)}>Cancel</Button><Button type="submit">Save profile</Button></div></form></Modal>}</div>;
}

function Jobs({ user, request }) {
  const [jobs, setJobs] = useState([]); const [selected, setSelected] = useState(null); const [filters, setFilters] = useState({ title: '', company: '', job_type: '' }); const [loading, setLoading] = useState(true); const [error, setError] = useState(''); const [showCreate, setShowCreate] = useState(false); const [showApply, setShowApply] = useState(false); const [resume, setResume] = useState(''); const [form, setForm] = useState({ title: '', company: '', description: '', location: '', job_type: 'Full-time', salary: '' });
  const load = useCallback(async () => { setLoading(true); try { const data = await request('/api/v1/jobs'); setJobs(data); if (!selected && data[0]) setSelected(data[0]); setError(''); } catch (err) { setError(err.message); } finally { setLoading(false); } }, [request, selected]); useEffect(() => { load(); }, []); const visible = jobs.filter((job) => [job.title, job.company, job.job_type].join(' ').toLowerCase().includes([filters.title, filters.company, filters.job_type].join(' ').toLowerCase()));
  const createJob = async (event) => { event.preventDefault(); try { await request('/api/v1/jobs', { method: 'POST', body: JSON.stringify(form) }); setShowCreate(false); load(); } catch (err) { setError(err.message); } }; const apply = async (event) => { event.preventDefault(); try { await request(`/api/v1/jobs/${selected.id}/apply`, { method: 'POST', body: JSON.stringify({ resume_url: resume }) }); setShowApply(false); setResume(''); } catch (err) { setError(err.message); } };
  return <div className="page-content"><PageHeader eyebrow="Move with intention" title="Career board" text="A curated feed of roles shared by people who understand your potential." action={(user.role === 'alumni' || user.role === 'admin') && <Button onClick={() => setShowCreate(true)}><Plus size={16} /> Post an opportunity</Button>} />{error && <Notice>{error}</Notice>}<div className="jobs-layout"><div className="jobs-list-panel"><div className="filter-stack"><div className="search-input"><Search size={15} /><input placeholder="Search roles" value={filters.title} onChange={(e) => setFilters({ ...filters, title: e.target.value })} /></div><div className="filter-pills"><button className={!filters.job_type ? 'active' : ''} onClick={() => setFilters({ ...filters, job_type: '' })}>All roles</button><button className={filters.job_type === 'Full-time' ? 'active' : ''} onClick={() => setFilters({ ...filters, job_type: 'Full-time' })}>Full-time</button><button className={filters.job_type === 'Internship' ? 'active' : ''} onClick={() => setFilters({ ...filters, job_type: 'Internship' })}>Internship</button></div></div>{loading ? <Loader label="Loading roles" /> : visible.length ? visible.map((job) => <button className={`job-list-item ${selected?.id === job.id ? 'selected' : ''}`} key={job.id} onClick={() => setSelected(job)}><span className="company-logo">{initials(job.company)}</span><span><strong>{job.title}</strong><small>{job.company} · {job.location}</small><em>{job.job_type}</em></span><ArrowRight size={15} /></button>) : <EmptyState icon={Briefcase} title="No roles yet" text="Try another search or check back soon." />}</div><div className="job-detail-panel">{selected ? <><div className="job-detail-head"><span className="company-logo large-logo">{initials(selected.company)}</span><div><div className="eyebrow">{selected.job_type}</div><h2>{selected.title}</h2><p>{selected.company} · {selected.location}</p></div><span className="job-date">Posted {formatDate(selected.created_at)}</span></div><div className="detail-divider" /><div className="detail-section"><h3>About the opportunity</h3><p>{selected.description}</p></div>{selected.salary && <div className="salary-callout"><CircleDollarSign size={18} /><span><small>Compensation</small><strong>{selected.salary}</strong></span></div>}<div className="detail-footer"><span><Clock3 size={14} /> Applications reviewed by the creator</span>{user.role === 'student' && <Button onClick={() => setShowApply(true)}>Apply with resume <ArrowRight size={15} /></Button>}</div></> : <EmptyState icon={Briefcase} title="Select a role" text="Choose a listing from the left to see the full opportunity." />}</div></div>{showCreate && <Modal title="Post an opportunity" onClose={() => setShowCreate(false)}><form className="modal-form" onSubmit={createJob}><div className="two-fields"><Field label="Role title" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} required /><Field label="Company" value={form.company} onChange={(e) => setForm({ ...form, company: e.target.value })} required /></div><div className="two-fields"><Field label="Location" value={form.location} onChange={(e) => setForm({ ...form, location: e.target.value })} required /><Field label="Salary" value={form.salary} onChange={(e) => setForm({ ...form, salary: e.target.value })} /></div><SelectField label="Job type" value={form.job_type} onChange={(e) => setForm({ ...form, job_type: e.target.value })}><option>Full-time</option><option>Part-time</option><option>Internship</option><option>Contract</option></SelectField><TextArea label="Description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} required /><div className="modal-actions"><Button variant="secondary" type="button" onClick={() => setShowCreate(false)}>Cancel</Button><Button type="submit">Publish role</Button></div></form></Modal>}{showApply && <Modal title={`Apply to ${selected?.title}`} onClose={() => setShowApply(false)}><form className="modal-form" onSubmit={apply}><Field label="Resume URL" value={resume} onChange={(e) => setResume(e.target.value)} placeholder="https://…" hint="Upload your resume to your preferred drive and paste the public link." required /><div className="modal-actions"><Button variant="secondary" type="button" onClick={() => setShowApply(false)}>Cancel</Button><Button type="submit">Submit application</Button></div></form></Modal>}</div>;
}

function Stories({ user, request }) { const [stories, setStories] = useState([]); const [loading, setLoading] = useState(true); const [error, setError] = useState(''); const [showCreate, setShowCreate] = useState(false); const [form, setForm] = useState({ title: '', content: '' }); const load = useCallback(async () => { try { setLoading(true); setStories(await request('/api/v1/stories')); } catch (err) { setError(err.message); } finally { setLoading(false); } }, [request]); useEffect(() => { load(); }, []); const create = async (event) => { event.preventDefault(); try { await request('/api/v1/stories', { method: 'POST', body: JSON.stringify(form) }); setForm({ title: '', content: '' }); setShowCreate(false); load(); } catch (err) { setError(err.message); } }; const like = async (id) => { try { const result = await request(`/api/v1/stories/${id}/like`, { method: 'POST' }); setStories((items) => items.map((story) => story.id === id ? { ...story, likes_count: result.likes_count } : story)); } catch (err) { setError(err.message); } }; return <div className="page-content"><PageHeader eyebrow="Learn from the journey" title="Success stories" text="Real paths, honest lessons, and the moments that made a difference." action={(user.role === 'alumni' || user.role === 'admin') && <Button onClick={() => setShowCreate(true)}><Plus size={16} /> Share your story</Button>} />{error && <Notice>{error}</Notice>}{loading ? <Loader label="Loading stories" /> : stories.length ? <div className="story-grid">{stories.map((story, index) => <article className={`story-card story-tone-${index % 3}`} key={story.id}><div className="story-card-top"><span className="story-number">0{index + 1}</span><span>{formatDate(story.created_at)}</span></div><h3>{story.title}</h3><p>{story.content}</p><div className="story-author"><span className="avatar-circle">{initials(story.author_name)}</span><span><strong>{story.author_name}</strong><small>Alumni community</small></span><button className="like-button" onClick={() => like(story.id)}><Heart size={15} /> {story.likes_count}</button></div></article>)}</div> : <EmptyState icon={BookOpen} title="The first story is yours" text="Share something that helped you take your next step." />}{showCreate && <Modal title="Share a success story" onClose={() => setShowCreate(false)}><form className="modal-form" onSubmit={create}><Field label="Title" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} placeholder="The introduction that changed everything" required /><TextArea label="Your story" value={form.content} onChange={(e) => setForm({ ...form, content: e.target.value })} placeholder="Tell the community what you learned…" required /><div className="modal-actions"><Button variant="secondary" type="button" onClick={() => setShowCreate(false)}>Cancel</Button><Button type="submit">Publish story</Button></div></form></Modal>}</div>; }

function Events({ user, request }) { const [events, setEvents] = useState([]); const [selected, setSelected] = useState(null); const [loading, setLoading] = useState(true); const [error, setError] = useState(''); const [showCreate, setShowCreate] = useState(false); const [form, setForm] = useState({ title: '', description: '', category: 'Community', event_date: '', registration_deadline: '', registration_url: '' }); const load = useCallback(async () => { try { setLoading(true); setEvents(await request('/api/v1/bulletin-events')); } catch (err) { setError(err.message); } finally { setLoading(false); } }, [request]); useEffect(() => { load(); }, []); const create = async (event) => { event.preventDefault(); try { await request('/api/v1/bulletin-events', { method: 'POST', body: JSON.stringify({ ...form, registration_deadline: form.registration_deadline || null }) }); setShowCreate(false); load(); } catch (err) { setError(err.message); } }; const register = async () => { try { await request(`/api/v1/bulletin-events/${selected.id}/register`, { method: 'POST' }); load(); } catch (err) { setError(err.message); } }; return <div className="page-content"><PageHeader eyebrow="Stay in the loop" title="Events bulletin" text="The talks, programs, and gatherings that keep the community close." action={(user.role === 'faculty' || user.role === 'admin') && <Button onClick={() => setShowCreate(true)}><Plus size={16} /> Create event</Button>} />{error && <Notice>{error}</Notice>}{loading ? <Loader label="Loading events" /> : events.length ? <div className="events-layout"><div className="event-list">{events.map((event) => <button key={event.id} className={`event-list-item ${selected?.id === event.id ? 'selected' : ''}`} onClick={() => setSelected(event)}><span className="date-tile"><strong>{new Date(event.event_date).getDate()}</strong><small>{new Date(event.event_date).toLocaleDateString(undefined, { month: 'short' })}</small></span><span><strong>{event.title}</strong><small>{event.category} · {event.registration_count || 0} registered</small></span><ArrowRight size={15} /></button>)}</div><div className="event-detail">{selected ? <><div className="event-detail-top"><span className="eyebrow">{selected.category}</span><h2>{selected.title}</h2><div className="event-meta"><span><CalendarDays size={14} /> {formatDate(selected.event_date, true)}</span><span><Users size={14} /> {selected.registration_count || 0} registered</span></div></div><p>{selected.description}</p><div className="event-cta"><Button onClick={register}>Register for this event <ArrowRight size={15} /></Button>{selected.registration_url && <a href={selected.registration_url} target="_blank" rel="noreferrer">View registration page <ExternalLink size={14} /></a>}</div></> : <EmptyState icon={CalendarDays} title="Choose an event" text="Select a bulletin item to see details." />}</div></div> : <EmptyState icon={CalendarDays} title="No events published" text="There is nothing on the bulletin just yet." />}{showCreate && <Modal title="Create an event" onClose={() => setShowCreate(false)}><form className="modal-form" onSubmit={create}><Field label="Event title" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} required /><div className="two-fields"><Field label="Category" value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })} required /><Field label="Event date" type="datetime-local" value={form.event_date} onChange={(e) => setForm({ ...form, event_date: e.target.value })} required /></div><TextArea label="Description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} required /><Field label="Registration URL" value={form.registration_url} onChange={(e) => setForm({ ...form, registration_url: e.target.value })} required /><div className="modal-actions"><Button variant="secondary" type="button" onClick={() => setShowCreate(false)}>Cancel</Button><Button type="submit">Publish event</Button></div></form></Modal>}</div>; }

function Fundraisers({ user, request }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showCreate, setShowCreate] = useState(false);
  const [selected, setSelected] = useState(null);
  const [donationAmount, setDonationAmount] = useState('');
  const [form, setForm] = useState({ title: '', description: '', goal_amount: '' });

  const load = useCallback(async () => {
    try {
      setLoading(true);
      setItems(await request('/api/v1/fundraisers'));
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [request]);

  useEffect(() => { load(); }, []);

  const createCampaign = async (event) => {
    event.preventDefault();
    try {
      await request('/api/v1/fundraisers', {
        method: 'POST',
        body: JSON.stringify({
          title: form.title,
          description: form.description,
          goal_amount: parseInt(form.goal_amount) || 0
        })
      });
      setShowCreate(false);
      setForm({ title: '', description: '', goal_amount: '' });
      load();
    } catch (err) {
      setError(err.message);
    }
  };

  const donate = async (event) => {
    event.preventDefault();
    const amount = parseInt(donationAmount);
    if (!amount || amount <= 0) return;
    try {
      await request(`/api/v1/fundraisers/${selected.id}/donate`, {
        method: 'POST',
        body: JSON.stringify({ amount })
      });
      setSelected(null);
      setDonationAmount('');
      load();
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <div className="page-content">
      <PageHeader
        eyebrow="Back a bold idea"
        title="Startup fundraisers"
        text="Support student-led ideas and the people brave enough to build them."
        action={(user.role === 'student' || user.role === 'admin') && (
          <Button onClick={() => setShowCreate(true)}>
            <Plus size={16} /> Start a campaign
          </Button>
        )}
      />
      {error && <Notice>{error}</Notice>}
      {loading ? (
        <Loader label="Loading campaigns" />
      ) : items.length ? (
        <div className="fundraiser-grid">
          {items.map((item) => (
            <article className="fundraiser-card" key={item.id}>
              <div className="fundraiser-art">
                <span>{initials(item.title)}</span>
                <CircleDollarSign size={24} />
              </div>
              <div className="fundraiser-body">
                <span className="eyebrow">Student venture</span>
                <h3>{item.title}</h3>
                <p>{item.description || 'A community-led campaign looking for its first supporters.'}</p>
                <div className="fundraiser-progress">
                  <span style={{ width: `${Math.min(100, ((item.raised_amount || item.current_amount || 0) / (item.goal_amount || 1)) * 100)}%` }} />
                </div>
                <div className="fundraiser-stats">
                  <span><strong>₹{item.raised_amount || item.current_amount || 0}</strong> raised</span>
                  <span>Goal ₹{item.goal_amount || '—'}</span>
                </div>
                <Button className="full-width" onClick={() => setSelected(item)}>
                  View campaign <ArrowRight size={15} />
                </Button>
              </div>
            </article>
          ))}
        </div>
      ) : (
        <EmptyState icon={CircleDollarSign} title="No campaigns yet" text="When a student venture is ready to raise, it will appear here." />
      )}

      {showCreate && (
        <Modal title="Start a campaign" onClose={() => setShowCreate(false)}>
          <form className="modal-form" onSubmit={createCampaign}>
            <Field label="Campaign Title" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} required />
            <Field label="Goal Amount (₹)" type="number" value={form.goal_amount} onChange={(e) => setForm({ ...form, goal_amount: e.target.value })} required />
            <TextArea label="Description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} required />
            <div className="modal-actions">
              <Button variant="secondary" type="button" onClick={() => setShowCreate(false)}>Cancel</Button>
              <Button type="submit">Launch campaign</Button>
            </div>
          </form>
        </Modal>
      )}

      {selected && (
        <Modal title={`Support ${selected.title}`} onClose={() => setSelected(null)}>
          <div className="modal-form">
            <div style={{ marginBottom: '1.5rem' }}>
              <strong>Description:</strong>
              <p style={{ marginTop: '0.5rem', lineHeight: '1.5' }}>{selected.description}</p>
            </div>
            <div className="fundraiser-stats" style={{ marginBottom: '1.5rem', padding: '1rem', background: '#f5f5f5', borderRadius: '8px' }}>
              <span><strong>₹{selected.raised_amount || selected.current_amount || 0}</strong> raised</span>
              <span>Goal ₹{selected.goal_amount}</span>
            </div>
            <form onSubmit={donate}>
              <Field label="Contribution Amount (₹)" type="number" value={donationAmount} onChange={(e) => setDonationAmount(e.target.value)} placeholder="Enter amount to donate" required />
              <div className="modal-actions" style={{ marginTop: '1.5rem' }}>
                <Button variant="secondary" type="button" onClick={() => setSelected(null)}>Cancel</Button>
                <Button type="submit">Contribute now</Button>
              </div>
            </form>
          </div>
        </Modal>
      )}
    </div>
  );
}

function Chat({ user, request }) {
  const [conversations, setConversations] = useState([]); const [active, setActive] = useState(null); const [messages, setMessages] = useState([]); const [search, setSearch] = useState(''); const [users, setUsers] = useState([]); const [text, setText] = useState(''); const [connected, setConnected] = useState(false); const socketRef = useRef(null); const reconnectRef = useRef(0); const loadConversations = useCallback(async () => { try { setConversations(await request('/api/v1/chat/conversations')); } catch { /* parent shell still stays usable */ } }, [request]); useEffect(() => { loadConversations(); }, [loadConversations]); useEffect(() => { let cancelled = false; if (!search.trim()) { setUsers([]); return undefined; } const timer = setTimeout(async () => { try { const result = await request(`/api/v1/chat/users/search?query=${encodeURIComponent(search)}`); if (!cancelled) setUsers(result); } catch { if (!cancelled) setUsers([]); } }, 250); return () => { cancelled = true; clearTimeout(timer); }; }, [search, request]);
  const openConversation = useCallback(async (conversation) => { setActive(conversation); try { const data = await request(`/api/v1/chat/conversations/${conversation.id}/messages`); setMessages(data); await request(`/api/v1/chat/conversations/${conversation.id}/read`, { method: 'PATCH' }); loadConversations(); } catch { setMessages([]); } }, [loadConversations, request]); useEffect(() => { if (!active) return undefined; let alive = true; let socket; const connect = () => { if (!alive) return; const token = getStored(ACCESS_KEY); socket = new WebSocket(`${WS_BASE}/api/v1/chat/ws/${active.id}?token=${encodeURIComponent(token)}`); socketRef.current = socket; socket.onopen = () => { setConnected(true); reconnectRef.current = 0; }; socket.onmessage = (event) => { const data = JSON.parse(event.data); if (data.type === 'new_message') setMessages((current) => current.some((item) => item.id === data.message.id) ? current : [...current, data.message]); if (data.type === 'messages_read') setMessages((current) => current.map((item) => ({ ...item, is_read: true }))); }; socket.onclose = () => { setConnected(false); if (alive) { const delay = Math.min(8000, 700 * 2 ** reconnectRef.current++); setTimeout(connect, delay); } }; }; connect(); const ping = setInterval(() => { if (socket?.readyState === WebSocket.OPEN) socket.send(JSON.stringify({ type: 'ping' })); }, 25000); return () => { alive = false; clearInterval(ping); socket?.close(); socketRef.current = null; setConnected(false); }; }, [active]);
  const startChat = async (target) => { try { const conversation = await request('/api/v1/chat/conversations', { method: 'POST', body: JSON.stringify({ recipient_id: target.id }) }); setSearch(''); setUsers([]); loadConversations(); openConversation(conversation); } catch { /* surfaced by empty states */ } }; const send = async (event) => { event.preventDefault(); const value = text.trim(); if (!value || !active) return; setText(''); if (socketRef.current?.readyState === WebSocket.OPEN) socketRef.current.send(JSON.stringify({ type: 'message', content: value })); else { try { const sent = await request(`/api/v1/chat/conversations/${active.id}/messages`, { method: 'POST', body: JSON.stringify({ content: value }) }); setMessages((current) => [...current, sent]); } catch { setText(value); } } };
  return <div className="page-content chat-page"><PageHeader eyebrow="Stay close" title="Messages" text="Private conversations with the people in your community." /><div className="chat-shell"><aside className="conversation-panel"><div className="conversation-search"><Search size={15} /><input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Find someone to message" /></div>{users.length > 0 && <div className="search-results">{users.map((person) => <button key={person.id} onClick={() => startChat(person)}><span className="avatar-circle">{initials(person.full_name)}</span><span><strong>{person.full_name}</strong><small>{person.designation || person.role}</small></span><Plus size={14} /></button>)}</div>}<div className="conversation-label">YOUR CONVERSATIONS</div>{conversations.length ? conversations.map((conversation) => <button key={conversation.id} className={`conversation-item ${active?.id === conversation.id ? 'active' : ''}`} onClick={() => openConversation(conversation)}><span className="avatar-circle">{initials(conversation.partner?.full_name)}</span><span><strong>{conversation.partner?.full_name}</strong><small>{conversation.last_message?.content || 'Start a conversation'}</small></span>{conversation.unread_count > 0 && <b>{conversation.unread_count}</b>}</button>) : <div className="conversation-empty"><MessageCircle size={19} /><p>Your conversations will appear here.</p></div>}</aside><section className="chat-window">{active ? <><div className="chat-header"><span className="avatar-circle">{initials(active.partner?.full_name)}</span><div><strong>{active.partner?.full_name}</strong><small>{connected ? 'Online conversation' : 'Reconnecting securely…'}</small></div><span className={`connection-dot ${connected ? 'connected' : ''}`} /></div><div className="messages-list">{messages.length ? messages.map((message) => <div className={`message-row ${String(message.sender_id) === String(user.id) ? 'mine' : ''}`} key={message.id}><div className="message-bubble"><p>{message.content}</p><small>{formatDate(message.created_at, true)} {String(message.sender_id) === String(user.id) && (message.is_read ? ' · Read' : ' · Sent')}</small></div></div>) : <div className="chat-empty"><span className="chat-empty-icon"><MessageCircle size={24} /></span><h3>Start the conversation</h3><p>Say hello and make the first connection.</p></div>}</div><form className="message-composer" onSubmit={send}><input value={text} onChange={(e) => setText(e.target.value)} placeholder="Write a thoughtful message…" maxLength={2000} /><button type="submit" aria-label="Send message"><Send size={17} /></button></form></> : <div className="chat-empty"><span className="chat-empty-icon"><MessageCircle size={26} /></span><h3>Select a conversation</h3><p>Choose a person from the left or search the community to start something meaningful.</p></div>}</section></div></div>;
}

function Admin({ request }) { const [facultyId, setFacultyId] = useState(''); const [alumniId, setAlumniId] = useState(''); const [message, setMessage] = useState(''); const [error, setError] = useState(''); const approve = async (type) => { try { const id = type === 'faculty' ? facultyId : alumniId; await request(type === 'faculty' ? `/api/v1/auth/faculty/${id}/approve` : `/api/v1/alumni/${id}/approve`, { method: 'PATCH' }); setMessage(`${type[0].toUpperCase() + type.slice(1)} profile approved.`); } catch (err) { setError(err.message); } }; return <div className="page-content"><PageHeader eyebrow="Keep the network trusted" title="Admin review" text="Approve verified profiles as they are ready to join the active community." />{message && <Notice type="success">{message}</Notice>}{error && <Notice>{error}</Notice>}<div className="review-grid"><div className="panel review-card"><span className="review-icon"><GraduationCap size={19} /></span><h3>Faculty approval</h3><p>Enter the faculty profile ID from the review queue to activate the account.</p><Field label="Faculty ID" value={facultyId} onChange={(e) => setFacultyId(e.target.value)} placeholder="UUID" /><Button onClick={() => approve('faculty')}>Approve faculty <Check size={15} /></Button></div><div className="panel review-card"><span className="review-icon"><Users size={19} /></span><h3>Alumni approval</h3><p>Approve an alumni profile that has completed its moderation review.</p><Field label="Alumni ID" value={alumniId} onChange={(e) => setAlumniId(e.target.value)} placeholder="UUID" /><Button onClick={() => approve('alumni')}>Approve alumni <Check size={15} /></Button></div></div></div>; }
function Profile({ user, onLogout }) { return <div className="page-content"><PageHeader eyebrow="Your identity in the network" title="Profile" text="The details that help your community recognize and support you." action={<Button variant="secondary" onClick={onLogout}><LogOut size={15} /> Sign out</Button>} /><div className="profile-layout"><div className="panel profile-card-large"><span className="avatar-circle giant">{initials(user?.full_name)}</span><div className="eyebrow">{user?.role}</div><h2>{user?.full_name}</h2><p>{user?.email}</p><span className="verified-chip"><Check size={12} /> Active member</span></div><div className="panel profile-details"><div className="panel-heading"><h3>Account details</h3><ShieldCheck size={17} /></div><div className="detail-list"><div><span>Full name</span><strong>{user?.full_name || '—'}</strong></div><div><span>Email</span><strong>{user?.email || '—'}</strong></div><div><span>Role</span><strong>{user?.role || '—'}</strong></div><div><span>Profile status</span><strong>Verified and active</strong></div></div></div></div></div>; }
function Modal({ title, children, onClose }) { return <div className="modal-overlay"><div className="modal-card"><div className="modal-header"><h3>{title}</h3><IconButton label="Close" onClick={onClose}><X size={18} /></IconButton></div>{children}</div><button className="modal-backdrop" onClick={onClose} aria-label="Close modal" /></div>; }

export default function App() {
  const [authMode, setAuthMode] = useState('landing');
  const [accessToken, setAccessToken] = useState(getStored(ACCESS_KEY));
  const [refreshToken, setRefreshToken] = useState(getStored(REFRESH_KEY));
  const [user, setUser] = useState(null);
  const [page, setPage] = useState('home');
  const [profileOpen, setProfileOpen] = useState(false);
  const [unread, setUnread] = useState(0);
  const [hydrating, setHydrating] = useState(Boolean(accessToken || refreshToken));

  const setTokens = useCallback((data) => {
    saveTokens(data);
    if (data.access_token) setAccessToken(data.access_token);
    if (data.refresh_token) setRefreshToken(data.refresh_token);
  }, []);

  const unauthorize = useCallback(() => {
    clearTokens();
    setAccessToken('');
    setRefreshToken('');
    setUser(null);
    setAuthMode('login');
  }, []);

  const request = useApi(accessToken, refreshToken, setTokens, unauthorize);
  const webrtc = useWebRTCCall(accessToken, user?.id || '');

  const hydrate = useCallback(async () => {
    if (!accessToken && !refreshToken) { setHydrating(false); return; }
    try { setUser(await request('/api/v1/auth/me')); }
    catch { unauthorize(); }
    finally { setHydrating(false); }
  }, [accessToken, refreshToken, request, unauthorize]);

  useEffect(() => { hydrate(); }, []);

  useEffect(() => {
    if (!user) return undefined;
    const poll = async () => {
      try {
        const data = await request('/api/v1/chat/unread-count');
        setUnread(data.total_unread || 0);
      } catch { /* keep shell available if chat is unavailable */ }
    };
    poll();
    const timer = setInterval(poll, 30000);
    return () => clearInterval(timer);
  }, [user, request]);

  const logout = async () => {
    try { await request('/api/v1/auth/logout', { method: 'POST' }); }
    catch { /* tokens are still cleared locally */ }
    unauthorize();
  };

  const authenticated = async (data) => {
    setTokens(data);
    setAuthMode('landing');
    setHydrating(true);
    try {
      const response = await fetch(`${API_BASE}/api/v1/auth/me`, {
        headers: { Authorization: `Bearer ${data.access_token}` }
      });
      if (!response.ok) throw new Error(await decodeError(response));
      setUser(await response.json());
    } catch { unauthorize(); }
    finally { setHydrating(false); }
  };

  if (hydrating) return <div className="app-loading"><span className="brand-mark"><UsersRound size={22} /></span><Loader label="Opening your community" /></div>;
  if (!user) return <><Landing onLogin={() => setAuthMode('login')} onRegister={() => setAuthMode('register')} />{authMode !== 'landing' && <AuthPanel mode={authMode} setMode={setAuthMode} onClose={() => setAuthMode('landing')} onAuthenticated={authenticated} />}</>;

  const titles = {
    home: ['Home', 'Your community, at a glance.'],
    directory: ['Alumni directory', 'Find people who can move your next chapter forward.'],
    jobs: ['Career board', 'Trusted opportunities from your network.'],
    stories: ['Success stories', 'Experiences worth carrying forward.'],
    fundraisers: ['Startup fundraisers', 'Back the ideas coming out of your community.'],
    events: ['Events bulletin', 'Keep the calendar close.'],
    chat: ['Messages', 'Private conversations with your community.'],
    admin: ['Admin review', 'Keep the network trusted.'],
    profile: ['Profile', 'Your identity in the network.']
  };

  const [title, subtitle] = titles[profileOpen ? 'profile' : page] || titles.home;
  const openProfile = () => setProfileOpen(true);
  const currentPage = profileOpen ? 'profile' : page;
  const content = {
    home: <HomeFeed user={user} goTo={(next) => { setProfileOpen(false); setPage(next); }} request={request} />,
    directory: <Directory user={user} request={request} onStartChat={(person) => { request('/api/v1/chat/conversations', { method: 'POST', body: JSON.stringify({ recipient_id: person.id }) }).finally(() => setPage('chat')); }} />,
    jobs: <Jobs user={user} request={request} />,
    stories: <Stories user={user} request={request} />,
    fundraisers: <Fundraisers user={user} request={request} />,
    events: <Events user={user} request={request} />,
    chat: <Chat user={user} request={request} />,
    admin: <Admin request={request} />,
    profile: <Profile user={user} onLogout={logout} />
  }[currentPage];

  return (
    <div className="app-shell">
      <Sidebar page={currentPage} setPage={(next) => { setProfileOpen(false); setPage(next); }} user={user} unread={unread} onLogout={logout} onProfile={openProfile} />
      <div className="main-shell">
        <Topbar title={title} subtitle={subtitle} user={user} onProfile={openProfile} onRefresh={() => window.location.reload()} />
        <main className="dashboard-main">{content}</main>
        <footer className="dashboard-footer">
          <span>Alumnix</span>
          <span>Built for connection, designed for momentum.</span>
          <span>API: {API_BASE.replace(/^https?:\/\//, '')}</span>
        </footer>
      </div>
      {webrtc && (
        <VideoCallModal
          callState={webrtc.callState}
          localStream={webrtc.localStream}
          remoteStream={webrtc.remoteStream}
          callerInfo={webrtc.callerInfo}
          audioMuted={webrtc.audioMuted}
          videoDisabled={webrtc.videoDisabled}
          acceptCall={webrtc.acceptCall}
          rejectCall={webrtc.rejectCall}
          endCall={webrtc.endCall}
          toggleMuteAudio={webrtc.toggleMuteAudio}
          toggleDisableVideo={webrtc.toggleDisableVideo}
        />
      )}
    </div>
  );
}
