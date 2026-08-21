import React, { useState } from 'react';
import { LogIn, UserPlus, PhoneCall, School, ArrowRight, CheckCircle, ShieldAlert, Sparkles, KeyRound } from 'lucide-react';

export default function AuthModal({ onLoginSuccess }) {
  const [authMode, setAuthMode] = useState('login'); // 'login' | 'usn_register' | 'phone_login' | 'faculty_register'

  // Login state
  const [emailInput, setEmailInput] = useState('student@college.com');
  const [passwordInput, setPasswordInput] = useState('admin1234');
  const [loginError, setLoginError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // USN Register states (Multi-step)
  const [usnStep, setUsnStep] = useState(1); // 1: verify USN, 2: send OTP, 3: verify OTP, 4: setup password
  const [usnInput, setUsnInput] = useState('1RV20CS001');
  const [usnRole, setUsnRole] = useState('student');
  const [registryName, setRegistryName] = useState('');
  const [otpChannel, setOtpChannel] = useState('email');
  const [otpInput, setOtpInput] = useState('');
  const [verificationToken, setVerificationToken] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [regError, setRegError] = useState('');

  // Phone OTP states
  const [phoneInput, setPhoneInput] = useState('+919876543210');
  const [phoneOtpInput, setPhoneOtpInput] = useState('');
  const [phoneOtpSent, setPhoneOtpSent] = useState(false);
  const [phoneError, setPhoneError] = useState('');

  // Faculty Register states
  const [facName, setFacName] = useState('');
  const [facEmpId, setFacEmpId] = useState('');
  const [facDept, setFacDept] = useState('Computer Science');
  const [facDesignation, setFacDesignation] = useState('Assistant Professor');
  const [facEmail, setFacEmail] = useState('');
  const [facPhone, setFacPhone] = useState('');
  const [facPassword, setFacPassword] = useState('');
  const [facSuccessMsg, setFacSuccessMsg] = useState('');
  const [facError, setFacError] = useState('');

  // 1. Password Login Submit
  const handlePasswordLogin = async (e) => {
    e.preventDefault();
    setLoginError('');
    setIsSubmitting(true);
    try {
      const res = await fetch('/api/v1/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: emailInput.trim(), password: passwordInput })
      });
      const data = await res.json();
      if (res.ok && data.access_token) {
        onLoginSuccess(data.access_token);
      } else {
        setLoginError(data.detail || 'Login failed. Check credentials.');
      }
    } catch (err) {
      setLoginError('Unable to connect to authentication server.');
    } finally {
      setIsSubmitting(false);
    }
  };

  // 2. USN Registration Step Handlers
  const handleVerifyUSN = async (e) => {
    e.preventDefault();
    setRegError('');
    setIsSubmitting(true);
    try {
      const res = await fetch('/api/v1/auth/register/verify-usn', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ usn: usnInput.trim(), role: usnRole })
      });
      const data = await res.json();
      if (res.ok) {
        setRegistryName(data.full_name);
        setUsnStep(2);
      } else {
        setRegError(data.detail || 'USN verification failed.');
      }
    } catch (err) {
      setRegError('Server connection error.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSendOTP = async () => {
    setRegError('');
    setIsSubmitting(true);
    try {
      const res = await fetch('/api/v1/auth/register/send-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ usn: usnInput.trim(), channel: otpChannel })
      });
      const data = await res.json();
      if (res.ok) {
        setUsnStep(3);
      } else {
        setRegError(data.detail || 'Failed to send OTP.');
      }
    } catch (err) {
      setRegError('Server connection error.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleVerifyOTP = async (e) => {
    e.preventDefault();
    setRegError('');
    setIsSubmitting(true);
    try {
      const res = await fetch('/api/v1/auth/register/verify-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ usn: usnInput.trim(), channel: otpChannel, otp_code: otpInput.trim() })
      });
      const data = await res.json();
      if (res.ok && data.verification_token) {
        setVerificationToken(data.verification_token);
        setUsnStep(4);
      } else {
        setRegError(data.detail || 'Invalid or expired OTP code.');
      }
    } catch (err) {
      setRegError('Server connection error.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSetupPassword = async (e) => {
    e.preventDefault();
    setRegError('');
    setIsSubmitting(true);
    try {
      const res = await fetch('/api/v1/auth/register/setup-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ verification_token: verificationToken, password: newPassword })
      });
      const data = await res.json();
      if (res.ok && data.access_token) {
        onLoginSuccess(data.access_token);
      } else {
        setRegError(data.detail || 'Password setup failed.');
      }
    } catch (err) {
      setRegError('Server connection error.');
    } finally {
      setIsSubmitting(false);
    }
  };

  // 3. Phone OTP Handlers
  const handleSendPhoneOTP = async (e) => {
    e.preventDefault();
    setPhoneError('');
    setIsSubmitting(true);
    try {
      const res = await fetch('/api/v1/auth/phone/send-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone_number: phoneInput.trim() })
      });
      const data = await res.json();
      if (res.ok) {
        setPhoneOtpSent(true);
      } else {
        setPhoneError(data.detail || 'Failed to send OTP.');
      }
    } catch (err) {
      setPhoneError('Server error.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleVerifyPhoneOTP = async (e) => {
    e.preventDefault();
    setPhoneError('');
    setIsSubmitting(true);
    try {
      const res = await fetch('/api/v1/auth/phone/verify-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone_number: phoneInput.trim(), otp_code: phoneOtpInput.trim() })
      });
      const data = await res.json();
      if (res.ok && data.access_token) {
        onLoginSuccess(data.access_token);
      } else {
        setPhoneError(data.detail || 'Invalid OTP code.');
      }
    } catch (err) {
      setPhoneError('Server error.');
    } finally {
      setIsSubmitting(false);
    }
  };

  // 4. Faculty Signup Handler
  const handleFacultyRegister = async (e) => {
    e.preventDefault();
    setFacError('');
    setFacSuccessMsg('');
    setIsSubmitting(true);
    try {
      const res = await fetch('/api/v1/auth/register/faculty', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          full_name: facName.trim(),
          employee_id: facEmpId.trim(),
          department: facDept,
          designation: facDesignation,
          email: facEmail.trim() || undefined,
          phone_number: facPhone.trim() || undefined,
          password: facPassword
        })
      });
      const data = await res.json();
      if (res.ok) {
        setFacSuccessMsg('Faculty account submitted successfully! Pending admin approval before sign-in.');
      } else {
        setFacError(data.detail || 'Faculty registration failed.');
      }
    } catch (err) {
      setFacError('Server connection error.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="auth-overlay">
      <div className="auth-card-wrapper">
        <div className="auth-header-brand">
          <div className="brand-logo-large">
            <span>A</span>
          </div>
          <h1 className="auth-app-title">Alumnix</h1>
          <p className="auth-app-subtitle">Institutional Alumni & Career Intelligence Platform</p>
        </div>

        {/* Tab Selector */}
        <div className="auth-tabs">
          <button
            className={`auth-tab-btn ${authMode === 'login' ? 'active' : ''}`}
            onClick={() => setAuthMode('login')}
          >
            <LogIn size={15} />
            <span>Sign In</span>
          </button>
          <button
            className={`auth-tab-btn ${authMode === 'usn_register' ? 'active' : ''}`}
            onClick={() => setAuthMode('usn_register')}
          >
            <UserPlus size={15} />
            <span>USN Register</span>
          </button>
          <button
            className={`auth-tab-btn ${authMode === 'phone_login' ? 'active' : ''}`}
            onClick={() => setAuthMode('phone_login')}
          >
            <PhoneCall size={15} />
            <span>Phone OTP</span>
          </button>
          <button
            className={`auth-tab-btn ${authMode === 'faculty_register' ? 'active' : ''}`}
            onClick={() => setAuthMode('faculty_register')}
          >
            <School size={15} />
            <span>Faculty Sign Up</span>
          </button>
        </div>

        {/* Form Container */}
        <div className="auth-body-container">
          {/* 1. PASSWORD LOGIN */}
          {authMode === 'login' && (
            <div className="auth-section">
              <h2 className="auth-form-title">Account Login</h2>
              <p className="auth-form-desc">Enter your email or phone number to access your account</p>

              {loginError && (
                <div className="auth-error-banner">
                  <ShieldAlert size={16} />
                  <span>{loginError}</span>
                </div>
              )}

              <form onSubmit={handlePasswordLogin}>
                <div className="form-group">
                  <label className="form-label">Email or Phone Number</label>
                  <input
                    id="input-login-email"
                    type="text"
                    className="form-control"
                    placeholder="student@college.com or +91..."
                    value={emailInput}
                    onChange={(e) => setEmailInput(e.target.value)}
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Password</label>
                  <input
                    id="input-login-password"
                    type="password"
                    className="form-control"
                    placeholder="••••••••"
                    value={passwordInput}
                    onChange={(e) => setPasswordInput(e.target.value)}
                    required
                  />
                </div>

                <button id="btn-login-submit" type="submit" className="primary-btn wide" disabled={isSubmitting}>
                  {isSubmitting ? 'Signing in...' : 'Sign In'}
                  <ArrowRight size={16} />
                </button>
              </form>

              {/* Fast Demo Accounts */}
              <div className="demo-accounts-box">
                <span className="demo-box-label">Instant Demo Credentials:</span>
                <div className="demo-btn-grid">
                  <button
                    className="demo-chip student"
                    onClick={() => {
                      setEmailInput('student@college.com');
                      setPasswordInput('admin1234');
                    }}
                  >
                    ⚡ Demo Student
                  </button>
                  <button
                    className="demo-chip alumni"
                    onClick={() => {
                      setEmailInput('alumni@college.com');
                      setPasswordInput('admin1234');
                    }}
                  >
                    ⚡ Demo Alumni
                  </button>
                  <button
                    className="demo-chip admin"
                    onClick={() => {
                      setEmailInput('admin@college.com');
                      setPasswordInput('admin1234');
                    }}
                  >
                    ⚡ Demo Admin
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* 2. USN ONBOARDING */}
          {authMode === 'usn_register' && (
            <div className="auth-section">
              <div className="step-indicator-bar">
                <span className={`step-dot ${usnStep >= 1 ? 'active' : ''}`}>1. USN</span>
                <span className={`step-dot ${usnStep >= 2 ? 'active' : ''}`}>2. OTP</span>
                <span className={`step-dot ${usnStep >= 3 ? 'active' : ''}`}>3. Verify</span>
                <span className={`step-dot ${usnStep >= 4 ? 'active' : ''}`}>4. Password</span>
              </div>

              {regError && (
                <div className="auth-error-banner">
                  <ShieldAlert size={16} />
                  <span>{regError}</span>
                </div>
              )}

              {usnStep === 1 && (
                <form onSubmit={handleVerifyUSN}>
                  <h3 className="auth-form-title">Step 1: Check Registry USN</h3>
                  <p className="auth-form-desc">Verify your USN against the official college database</p>
                  
                  <div className="form-group">
                    <label className="form-label">Select Role</label>
                    <div className="role-selector-row">
                      <button
                        type="button"
                        className={`role-select-chip ${usnRole === 'student' ? 'active' : ''}`}
                        onClick={() => setUsnRole('student')}
                      >
                        Student
                      </button>
                      <button
                        type="button"
                        className={`role-select-chip ${usnRole === 'alumni' ? 'active' : ''}`}
                        onClick={() => setUsnRole('alumni')}
                      >
                        Alumni
                      </button>
                    </div>
                  </div>

                  <div className="form-group">
                    <label className="form-label">University Serial Number (USN)</label>
                    <input
                      type="text"
                      className="form-control uppercase"
                      placeholder="e.g. 1RV20CS001"
                      value={usnInput}
                      onChange={(e) => setUsnInput(e.target.value.toUpperCase())}
                      required
                    />
                  </div>

                  <button type="submit" className="primary-btn wide" disabled={isSubmitting}>
                    {isSubmitting ? 'Verifying Registry...' : 'Verify USN'}
                  </button>
                </form>
              )}

              {usnStep === 2 && (
                <div>
                  <h3 className="auth-form-title">Step 2: Verification Channel</h3>
                  <p className="auth-form-desc">Registry Match Found: <strong>{registryName}</strong></p>
                  
                  <div className="form-group" style={{ marginTop: '14px' }}>
                    <label className="form-label">Send OTP Code via</label>
                    <div className="role-selector-row">
                      <button
                        type="button"
                        className={`role-select-chip ${otpChannel === 'email' ? 'active' : ''}`}
                        onClick={() => setOtpChannel('email')}
                      >
                        Registered Email
                      </button>
                      <button
                        type="button"
                        className={`role-select-chip ${otpChannel === 'phone' ? 'active' : ''}`}
                        onClick={() => setOtpChannel('phone')}
                      >
                        Registered SMS
                      </button>
                    </div>
                  </div>

                  <button onClick={handleSendOTP} className="primary-btn wide" disabled={isSubmitting}>
                    {isSubmitting ? 'Sending OTP Code...' : 'Send Verification OTP'}
                  </button>
                </div>
              )}

              {usnStep === 3 && (
                <form onSubmit={handleVerifyOTP}>
                  <h3 className="auth-form-title">Step 3: Enter OTP</h3>
                  <p className="auth-form-desc">Code sent to registered {otpChannel} for USN: {usnInput}</p>
                  
                  <div className="form-group">
                    <label className="form-label">6-Digit Verification Code</label>
                    <input
                      type="text"
                      className="form-control letter-spacing-lg"
                      placeholder="e.g. 123456"
                      maxLength={6}
                      value={otpInput}
                      onChange={(e) => setOtpInput(e.target.value)}
                      required
                    />
                  </div>

                  <button type="submit" className="primary-btn wide" disabled={isSubmitting}>
                    {isSubmitting ? 'Verifying Code...' : 'Verify & Continue'}
                  </button>
                </form>
              )}

              {usnStep === 4 && (
                <form onSubmit={handleSetupPassword}>
                  <h3 className="auth-form-title">Step 4: Create Password</h3>
                  <p className="auth-form-desc">Identity Verified! Set a secure password to complete signup.</p>

                  <div className="form-group">
                    <label className="form-label">New Account Password</label>
                    <input
                      type="password"
                      className="form-control"
                      placeholder="Minimum 6 characters"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      required
                    />
                  </div>

                  <button type="submit" className="primary-btn wide" disabled={isSubmitting}>
                    {isSubmitting ? 'Creating Account...' : 'Complete Registration'}
                  </button>
                </form>
              )}
            </div>
          )}

          {/* 3. PHONE OTP LOGIN */}
          {authMode === 'phone_login' && (
            <div className="auth-section">
              <h2 className="auth-form-title">Phone OTP Sign In</h2>
              <p className="auth-form-desc">Log in or auto-register using SMS mobile verification</p>

              {phoneError && (
                <div className="auth-error-banner">
                  <ShieldAlert size={16} />
                  <span>{phoneError}</span>
                </div>
              )}

              {!phoneOtpSent ? (
                <form onSubmit={handleSendPhoneOTP}>
                  <div className="form-group">
                    <label className="form-label">Phone Number (E.164 Format)</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="+919876543210"
                      value={phoneInput}
                      onChange={(e) => setPhoneInput(e.target.value)}
                      required
                    />
                  </div>
                  <button type="submit" className="primary-btn wide" disabled={isSubmitting}>
                    {isSubmitting ? 'Sending SMS...' : 'Send OTP via SMS'}
                  </button>
                </form>
              ) : (
                <form onSubmit={handleVerifyPhoneOTP}>
                  <div className="form-group">
                    <label className="form-label">Enter SMS OTP</label>
                    <input
                      type="text"
                      className="form-control letter-spacing-lg"
                      placeholder="123456"
                      maxLength={6}
                      value={phoneOtpInput}
                      onChange={(e) => setPhoneOtpInput(e.target.value)}
                      required
                    />
                  </div>
                  <button type="submit" className="primary-btn wide" disabled={isSubmitting}>
                    {isSubmitting ? 'Verifying...' : 'Verify & Log In'}
                  </button>
                </form>
              )}
            </div>
          )}

          {/* 4. FACULTY SIGNUP */}
          {authMode === 'faculty_register' && (
            <div className="auth-section">
              <h2 className="auth-form-title">Faculty Registration</h2>
              <p className="auth-form-desc">Register as institutional faculty (subject to Admin approval)</p>

              {facError && (
                <div className="auth-error-banner">
                  <ShieldAlert size={16} />
                  <span>{facError}</span>
                </div>
              )}

              {facSuccessMsg && (
                <div className="auth-success-banner">
                  <CheckCircle size={16} />
                  <span>{facSuccessMsg}</span>
                </div>
              )}

              <form onSubmit={handleFacultyRegister}>
                <div className="form-row">
                  <div className="form-group half">
                    <label className="form-label">Full Name</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="Dr. Rajesh Kumar"
                      value={facName}
                      onChange={(e) => setFacName(e.target.value)}
                      required
                    />
                  </div>
                  <div className="form-group half">
                    <label className="form-label">Employee ID</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="EMP-8092"
                      value={facEmpId}
                      onChange={(e) => setFacEmpId(e.target.value)}
                      required
                    />
                  </div>
                </div>

                <div className="form-row">
                  <div className="form-group half">
                    <label className="form-label">Department</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="Computer Science"
                      value={facDept}
                      onChange={(e) => setFacDept(e.target.value)}
                      required
                    />
                  </div>
                  <div className="form-group half">
                    <label className="form-label">Designation</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="Associate Professor"
                      value={facDesignation}
                      onChange={(e) => setFacDesignation(e.target.value)}
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Email Address</label>
                  <input
                    type="email"
                    className="form-control"
                    placeholder="rajesh.cs@college.edu"
                    value={facEmail}
                    onChange={(e) => setFacEmail(e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Password</label>
                  <input
                    type="password"
                    className="form-control"
                    placeholder="••••••••"
                    value={facPassword}
                    onChange={(e) => setFacPassword(e.target.value)}
                    required
                  />
                </div>

                <button type="submit" className="primary-btn wide" disabled={isSubmitting}>
                  {isSubmitting ? 'Registering Faculty...' : 'Submit Faculty Application'}
                </button>
              </form>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
