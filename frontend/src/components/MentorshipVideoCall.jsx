import React, { useState } from 'react';
import { JitsiMeeting } from '@jitsi/react-sdk';
import './MentorshipVideoCall.css';

const MentorshipVideoCall = ({ roomName, userName, jwtToken, onCallEnd }) => {
  const [isLoading, setIsLoading] = useState(true);

  // Dynamic domain configured via environment variables with a fallback
  const jitsiDomain = import.meta.env.VITE_JITSI_DOMAIN || 'meet.jit.si';

  const handleApiReady = (jitsiApi) => {
    setIsLoading(false);

    // Listens for meeting close or left conference events to trigger callback
    jitsiApi.addEventListener('videoConferenceLeft', () => {
      if (onCallEnd) onCallEnd();
    });

    jitsiApi.addEventListener('readyToClose', () => {
      if (onCallEnd) onCallEnd();
    });
  };

  return (
    <div className="alumni-call-wrapper">
      {isLoading && (
        <div className="alumni-call-loading-overlay">
          <div className="alumni-call-spinner-wrapper">
            <div className="alumni-call-spinner"></div>
            <p className="alumni-call-loading-text">Connecting to Call Securely...</p>
          </div>
        </div>
      )}
      
      <div className="alumni-call-iframe-container">
        <JitsiMeeting
          domain={jitsiDomain}
          roomName={roomName}
          jwt={jwtToken}
          configOverwrite={{
            startWithAudioMuted: true,
            startWithVideoMuted: true,
            disableThirdPartyRequests: true,
            prejoinPageEnabled: false, // Skip prejoin page for direct connection
            enableUserRolesBasedOnToken: true,
          }}
          interfaceConfigOverwrite={{
            // Keep only: mic, camera, screen share, tile view, and hangup
            TOOLBAR_BUTTONS: [
              'microphone',
              'camera',
              'desktop', // Screen sharing
              'tileview',
              'hangup'
            ],
            SHOW_CHROMECAST_BUTTON: false,
            SETTINGS_SECTIONS: ['devices', 'language'],
          }}
          userInfo={{
            displayName: userName
          }}
          onApiReady={handleApiReady}
          getIFrameRef={(iframeRef) => {
            iframeRef.style.height = '100%';
            iframeRef.style.width = '100%';
            iframeRef.style.border = 'none';
          }}
        />
      </div>
    </div>
  );
};

export default MentorshipVideoCall;
