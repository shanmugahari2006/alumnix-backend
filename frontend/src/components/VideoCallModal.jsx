import React, { useRef, useEffect, useState } from 'react';
import './VideoCallModal.css';

const VideoCallModal = ({
  callState,
  localStream,
  remoteStream,
  callerInfo,
  audioMuted,
  videoDisabled,
  acceptCall,
  rejectCall,
  endCall,
  toggleMuteAudio,
  toggleDisableVideo
}) => {
  const localVideoRef = useRef(null);
  const remoteVideoRef = useRef(null);
  const ringLocalVideoRef = useRef(null); // Local preview during ringing-out
  const modalRef = useRef(null);

  // Floating Local Preview Drag State
  const [dragPos, setDragPos] = useState({ x: 20, y: 20 });
  const [isDragging, setIsDragging] = useState(false);
  const dragStart = useRef({ x: 0, y: 0 });

  // Audio Device Switcher State
  const [audioOutputs, setAudioOutputs] = useState([]);
  const [activeSinkId, setActiveSinkId] = useState('');
  const [showDeviceMenu, setShowDeviceMenu] = useState(false);

  // FIX: Attach local stream to the ringing-out preview video element
  useEffect(() => {
    if (ringLocalVideoRef.current && localStream && callState === 'ringing-out') {
      ringLocalVideoRef.current.srcObject = localStream;
    }
  }, [localStream, callState]);

  // Attach local stream to connected call local preview
  useEffect(() => {
    if (localVideoRef.current && localStream) {
      localVideoRef.current.srcObject = localStream;
    }
  }, [localStream, callState]);

  // Attach remote stream to connected call video element
  useEffect(() => {
    if (remoteVideoRef.current && remoteStream) {
      remoteVideoRef.current.srcObject = remoteStream;
    }
  }, [remoteStream, callState]);

  // Query audio output devices (speakers)
  useEffect(() => {
    if (callState === 'connected') {
      navigator.mediaDevices.enumerateDevices()
        .then(devices => {
          const outputs = devices.filter(device => device.kind === 'audiooutput');
          setAudioOutputs(outputs);
        })
        .catch(err => console.error("Error listing audio output devices:", err));
    }
  }, [callState]);

  // Switch Speaker Output (using setSinkId)
  const handleSwitchAudioOutput = async (deviceId) => {
    if (remoteVideoRef.current && remoteVideoRef.current.setSinkId) {
      try {
        await remoteVideoRef.current.setSinkId(deviceId);
        setActiveSinkId(deviceId);
      } catch (err) {
        console.error("Failed to switch audio output destination:", err);
      }
    }
    setShowDeviceMenu(false);
  };

  // Draggable Handler Functions
  const handleMouseDown = (e) => {
    setIsDragging(true);
    dragStart.current = {
      x: e.clientX - dragPos.x,
      y: e.clientY - dragPos.y
    };
  };

  const handleMouseMove = (e) => {
    if (!isDragging) return;
    let newX = e.clientX - dragStart.current.x;
    let newY = e.clientY - dragStart.current.y;
    const modalWidth = window.innerWidth;
    const modalHeight = window.innerHeight;
    if (newX < 10) newX = 10;
    if (newX > modalWidth - 180) newX = modalWidth - 180;
    if (newY < 10) newY = 10;
    if (newY > modalHeight - 240) newY = modalHeight - 240;
    setDragPos({ x: newX, y: newY });
  };

  const handleMouseUp = () => setIsDragging(false);

  useEffect(() => {
    if (isDragging) {
      window.addEventListener('mousemove', handleMouseMove);
      window.addEventListener('mouseup', handleMouseUp);
    }
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isDragging]);

  // ─── 1. INCOMING CALL (Ringing In) ───────────────────────────────────────────
  // FIX: This is a clear Accept / Decline dialog — call does NOT auto-answer
  if (callState === 'ringing-in') {
    return (
      <div className="call-dialog-overlay">
        <div className="ringing-card incoming-card">
          {/* Pulsing avatar ring animation */}
          <div className="ringing-avatar-wrapper">
            <div className="ringing-pulse ring1" />
            <div className="ringing-pulse ring2" />
            <div className="ringing-avatar">
              {callerInfo?.name ? callerInfo.name.charAt(0).toUpperCase() : '?'}
            </div>
          </div>

          <div className="ringing-labels">
            <span className="ringing-badge">📞 Incoming Video Call</span>
            <h3 className="ringing-caller-name">{callerInfo?.name || 'Someone'}</h3>
            <p className="ringing-subtitle">is calling you...</p>
          </div>

          <div className="ringing-actions">
            <button
              className="ring-btn decline"
              onClick={rejectCall}
              title="Decline"
            >
              <span className="ring-btn-icon">📵</span>
              Decline
            </button>
            <button
              className="ring-btn accept"
              onClick={acceptCall}
              title="Accept"
            >
              <span className="ring-btn-icon">📞</span>
              Accept
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ─── 2. OUTGOING CALL (Ringing Out) ──────────────────────────────────────────
  // FIX: Show caller's own camera preview while waiting for answer
  if (callState === 'ringing-out') {
    return (
      <div className="call-dialog-overlay">
        <div className="ringing-card outgoing-card">
          {/* Self-camera preview while calling */}
          {localStream && (
            <div className="outgoing-self-preview">
              <video
                ref={ringLocalVideoRef}
                autoPlay
                playsInline
                muted
                className="outgoing-self-video"
              />
              <span className="outgoing-self-label">You</span>
            </div>
          )}

          <div className="ringing-labels">
            <div className="ringing-calling-dots">
              <span className="calling-dot" />
              <span className="calling-dot" />
              <span className="calling-dot" />
            </div>
            <h3 className="ringing-caller-name">Calling...</h3>
            <p className="ringing-subtitle">Waiting for the other person to answer</p>
          </div>

          <div className="ringing-actions">
            <button className="ring-btn decline" onClick={endCall} title="Cancel Call">
              <span className="ring-btn-icon">📵</span>
              Cancel
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ─── 3. CONNECTED STATE (Live P2P Video Call) ─────────────────────────────────
  if (callState === 'connected') {
    return (
      <div className="webrtc-modal-overlay" ref={modalRef}>
        <div className="webrtc-call-screen">
          {/* Main Remote Video Stream */}
          <video
            ref={remoteVideoRef}
            autoPlay
            playsInline
            className="remote-video-feed"
          />

          {/* No remote video fallback */}
          {!remoteStream && (
            <div className="remote-video-placeholder">
              <div className="remote-placeholder-avatar">?</div>
              <p>Connecting video...</p>
            </div>
          )}

          {/* Floating draggable local self-view */}
          <div
            className="local-video-preview-wrapper"
            style={{ left: `${dragPos.x}px`, top: `${dragPos.y}px` }}
            onMouseDown={handleMouseDown}
            title="Drag to move"
          >
            <video
              ref={localVideoRef}
              autoPlay
              playsInline
              muted
              className="local-video-feed"
            />
            {videoDisabled && (
              <div className="local-video-off-overlay">
                <span>📷</span>
                <small>Camera Off</small>
              </div>
            )}
          </div>

          {/* In-Call HUD Control Panel */}
          <div className="call-controls-panel">
            {/* Audio Toggle */}
            <button
              className={`control-action-btn ${audioMuted ? 'muted' : 'active'}`}
              onClick={toggleMuteAudio}
              title={audioMuted ? 'Unmute Audio' : 'Mute Audio'}
            >
              {audioMuted ? '🔇' : '🎙️'}
              <span className="control-btn-label">{audioMuted ? 'Unmute' : 'Mute'}</span>
            </button>

            {/* Video Toggle */}
            <button
              className={`control-action-btn ${videoDisabled ? 'disabled' : 'active'}`}
              onClick={toggleDisableVideo}
              title={videoDisabled ? 'Enable Video' : 'Disable Video'}
            >
              {videoDisabled ? '📷' : '📹'}
              <span className="control-btn-label">{videoDisabled ? 'Start Video' : 'Stop Video'}</span>
            </button>

            {/* Speaker switcher */}
            {audioOutputs.length > 0 && (
              <div style={{ position: 'relative' }}>
                <button
                  className="control-action-btn active"
                  onClick={() => setShowDeviceMenu(!showDeviceMenu)}
                  title="Switch Speaker"
                >
                  🔊
                  <span className="control-btn-label">Speaker</span>
                </button>
                {showDeviceMenu && (
                  <div className="device-select-menu">
                    <div className="device-select-title">Audio Output</div>
                    {audioOutputs.map(device => (
                      <button
                        key={device.deviceId}
                        className={`device-item-option ${activeSinkId === device.deviceId ? 'active' : ''}`}
                        onClick={() => handleSwitchAudioOutput(device.deviceId)}
                      >
                        {device.label || `Speaker (${device.deviceId.substring(0, 5)})`}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}

            {/* End Call */}
            <button
              className="control-action-btn end-call"
              onClick={endCall}
              title="End Call"
            >
              📞
              <span className="control-btn-label">End Call</span>
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Not in any calling state
  return null;
};

export default VideoCallModal;
