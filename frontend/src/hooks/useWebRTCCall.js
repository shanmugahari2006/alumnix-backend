import { useEffect, useRef, useState, useCallback } from 'react';

export const useWebRTCCall = (jwtToken, userId) => {
  const [callState, setCallState] = useState('idle'); // 'idle', 'ringing-in', 'ringing-out', 'connected'
  const [localStream, setLocalStream] = useState(null);
  const [remoteStream, setRemoteStream] = useState(null);
  const [callerInfo, setCallerInfo] = useState(null); // { id, name, room_id, call_id }
  const [audioMuted, setAudioMuted] = useState(false);
  const [videoDisabled, setVideoDisabled] = useState(false);

  const ws = useRef(null);
  const pc = useRef(null);
  const localStreamRef = useRef(null);

  // Use refs for values needed inside async callbacks to avoid stale closures
  const targetIdRef = useRef(null);
  const callIdRef = useRef(null);
  // Queue of ICE candidates received before remote description is set
  const pendingCandidates = useRef([]);
  // Store the incoming SDP offer to process only after user accepts
  const pendingOffer = useRef(null);

  // Configuration for ICE Servers (STUN/TURN)
  const serversConfig = {
    iceServers: [
      { urls: 'stun:stun.l.google.com:19302' },
      { urls: 'stun:stun1.l.google.com:19302' },
      { urls: 'stun:stun2.l.google.com:19302' },
    ]
  };

  // Close and clean up peer connections and streams
  const cleanupCall = useCallback(() => {
    if (pc.current) {
      pc.current.ontrack = null;
      pc.current.onicecandidate = null;
      pc.current.onconnectionstatechange = null;
      pc.current.close();
      pc.current = null;
    }
    if (localStreamRef.current) {
      localStreamRef.current.getTracks().forEach(track => track.stop());
      localStreamRef.current = null;
    }
    setLocalStream(null);
    setRemoteStream(null);
    setCallerInfo(null);
    targetIdRef.current = null;
    callIdRef.current = null;
    pendingCandidates.current = [];
    pendingOffer.current = null;
    setCallState('idle');
    setAudioMuted(false);
    setVideoDisabled(false);
  }, []);

  // Setup local media stream and peer connection event handlers
  // FIX: Pass targetId explicitly to avoid stale closure bug on onicecandidate
  const setupPeerConnection = useCallback(async (peerTargetId) => {
    pc.current = new RTCPeerConnection(serversConfig);

    // Capture Local Camera & Mic
    const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
    localStreamRef.current = stream;
    setLocalStream(stream);

    // Attach local tracks to WebRTC connection
    stream.getTracks().forEach(track => pc.current.addTrack(track, stream));

    // Handle remote streams when peer adds tracks
    pc.current.ontrack = (event) => {
      if (event.streams && event.streams[0]) {
        setRemoteStream(event.streams[0]);
      }
    };

    // FIX: Use peerTargetId parameter (not stale state) to relay ICE candidates correctly
    pc.current.onicecandidate = (event) => {
      if (event.candidate && ws.current && ws.current.readyState === WebSocket.OPEN) {
        ws.current.send(JSON.stringify({
          event_type: 'ice-candidate',
          target_id: peerTargetId,
          payload: { candidate: event.candidate }
        }));
      }
    };

    // Handle abrupt disconnections (e.g. network drop or tab close)
    pc.current.onconnectionstatechange = () => {
      const state = pc.current?.connectionState;
      console.log('WebRTC connection state changed:', state);
      if (state === 'disconnected' || state === 'failed' || state === 'closed') {
        cleanupCall();
      }
    };
  }, [cleanupCall]);

  // Drain any ICE candidates that arrived before the remote description was set
  const drainPendingCandidates = useCallback(async () => {
    while (pendingCandidates.current.length > 0) {
      const candidate = pendingCandidates.current.shift();
      try {
        await pc.current.addIceCandidate(new RTCIceCandidate(candidate));
      } catch (e) {
        console.error('Error adding queued ICE candidate:', e);
      }
    }
  }, []);

  // Initialize WebSockets connection for signaling
  useEffect(() => {
    if (!jwtToken) return;

    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = import.meta.env.DEV ? `${window.location.hostname}:8000` : window.location.host;
    const wsUrl = `${protocol}//${host}/ws/calls/signal?token=${jwtToken}`;

    ws.current = new WebSocket(wsUrl);

    ws.current.onopen = () => {
      console.log('Connected to WebRTC Signaling Gateway.');
    };

    ws.current.onmessage = async (event) => {
      const data = JSON.parse(event.data);
      // Server sends 'caller_id' in incoming-call, 'sender_id' in relayed events
      const { event_type, sender_id, caller_id, caller_name, room_id, call_id, payload } = data;

      switch (event_type) {
        case 'incoming-call':
          // ROOT FIX: server sends 'caller_id' (not 'sender_id') for this event
          // Using undefined here was causing all accept/decline routing to break
          targetIdRef.current = caller_id;
          callIdRef.current = call_id;
          setCallerInfo({ id: caller_id, name: caller_name, room_id, call_id });
          setCallState('ringing-in');
          break;

        case 'call-offer':
          // Store the SDP offer — only process it AFTER the user clicks Accept
          // Also store the sender_id here as reliable fallback for targetIdRef
          pendingOffer.current = { sdp: payload.sdp, senderId: sender_id, callId: call_id };
          // Ensure targetIdRef is populated (offer sender_id is always correct)
          if (!targetIdRef.current && sender_id) {
            targetIdRef.current = sender_id;
          }
          // Edge case: user already clicked Accept before offer arrived — process it now
          if (pc.current && pc.current.signalingState === 'stable') {
            const { sdp, senderId, callId } = pendingOffer.current;
            try {
              await pc.current.setRemoteDescription(new RTCSessionDescription(sdp));
              while (pendingCandidates.current.length > 0) {
                const c = pendingCandidates.current.shift();
                await pc.current.addIceCandidate(new RTCIceCandidate(c));
              }
              const answer = await pc.current.createAnswer();
              await pc.current.setLocalDescription(answer);
              ws.current.send(JSON.stringify({
                event_type: 'call-answer',
                target_id: senderId || targetIdRef.current,
                payload: { sdp: answer, call_id: callId }
              }));
              pendingOffer.current = null;
              setCallState('connected');
            } catch (e) {
              console.error('Failed to process late offer:', e);
            }
          }
          break;


        case 'call-answer':
          // Received SDP Answer from receiver after caller sent offer
          if (pc.current) {
            await pc.current.setRemoteDescription(new RTCSessionDescription(payload.sdp));
            await drainPendingCandidates();
            setCallState('connected');
          }
          break;

        case 'ice-candidate':
          // FIX: Queue candidates if peer connection / remote desc not ready yet
          if (pc.current && pc.current.remoteDescription) {
            try {
              await pc.current.addIceCandidate(new RTCIceCandidate(payload.candidate));
            } catch (e) {
              console.error('Error adding received ICE candidate:', e);
            }
          } else {
            // Queue it to apply after remote description is set
            pendingCandidates.current.push(payload.candidate);
          }
          break;

        case 'call-rejected':
        case 'call-ended':
        case 'call-missed':
          cleanupCall();
          break;

        case 'call-error':
          alert(data.message || 'Call signaling error.');
          cleanupCall();
          break;

        default:
          break;
      }
    };

    ws.current.onclose = () => {
      console.log('WebRTC Signaling Gateway connection closed.');
      // Only cleanup if there was an active call, not on normal logout
      cleanupCall();
    };

    return () => {
      if (ws.current) {
        ws.current.close();
      }
    };
  }, [jwtToken, cleanupCall, drainPendingCandidates]);

  // 1. Initiate a Call (Caller starts)
  const initiateCall = useCallback(async (receiverId) => {
    if (!ws.current || ws.current.readyState !== WebSocket.OPEN) {
      alert('Signaling connection is not ready. Please reload the page and try again.');
      return;
    }

    // Capture media and create peer connection FIRST (while ringing)
    // so the caller can see their own camera preview during the outgoing ring
    try {
      targetIdRef.current = receiverId;
      setCallState('ringing-out');

      await setupPeerConnection(receiverId);

      const generatedRoom = `GEC-WebRTC-${userId.substring(0, 8)}-${receiverId.substring(0, 8)}`;

      // Send call-initiate to server to notify the receiver
      ws.current.send(JSON.stringify({
        event_type: 'call-initiate',
        target_id: receiverId,
        payload: { room_id: generatedRoom }
      }));

      // Create and send SDP offer immediately so it arrives shortly after incoming-call
      const offer = await pc.current.createOffer();
      await pc.current.setLocalDescription(offer);

      ws.current.send(JSON.stringify({
        event_type: 'call-offer',
        target_id: receiverId,
        payload: { sdp: offer }
      }));

    } catch (e) {
      console.error('Failed to initiate call:', e);
      alert('Could not access camera/microphone. Please allow permissions and try again.');
      cleanupCall();
    }
  }, [userId, setupPeerConnection, cleanupCall]);

  // 2. Accept Incoming Call (Receiver explicitly clicks Accept)
  const acceptCall = useCallback(async () => {
    if (callState !== 'ringing-in') return;

    // Resolve the caller's ID — prefer the ref (set from incoming-call.caller_id),
    // but fall back to the offer's sender_id in case of race conditions
    const callerTargetId = targetIdRef.current || pendingOffer.current?.senderId;
    if (!callerTargetId) {
      console.error('acceptCall: cannot resolve caller ID');
      return;
    }
    // Ensure the ref is always set for ICE candidate routing
    targetIdRef.current = callerTargetId;

    try {
      // Setup local media + peer connection NOW (after explicit user approval)
      await setupPeerConnection(callerTargetId);

      // Process the stored SDP offer that arrived while ringing
      if (pendingOffer.current) {
        const { sdp, senderId, callId } = pendingOffer.current;

        await pc.current.setRemoteDescription(new RTCSessionDescription(sdp));
        // Drain any ICE candidates that arrived before setRemoteDescription
        await drainPendingCandidates();

        // Create and send SDP answer
        const answer = await pc.current.createAnswer();
        await pc.current.setLocalDescription(answer);

        ws.current.send(JSON.stringify({
          event_type: 'call-answer',
          target_id: senderId || callerTargetId,
          payload: { sdp: answer, call_id: callId }
        }));

        pendingOffer.current = null;
        setCallState('connected');
      } else {
        // Offer hasn't arrived yet — wait for it in onmessage
        // The state is now 'accepted' with pc.current ready to receive the offer
        console.log('Accepted call, waiting for SDP offer from caller...');
        setCallState('ringing-in'); // keep showing accepted state — offer is on the way
      }
    } catch (e) {
      console.error('Failed to accept video call:', e);
      alert('Could not access camera/microphone. Please allow permissions and try again.');
      cleanupCall();
    }
  }, [callState, setupPeerConnection, drainPendingCandidates, cleanupCall]);


  // 3. Reject Call (Receiver rejects)
  const rejectCall = useCallback(() => {
    if (ws.current && ws.current.readyState === WebSocket.OPEN && targetIdRef.current) {
      ws.current.send(JSON.stringify({
        event_type: 'call-reject',
        target_id: targetIdRef.current,
        payload: { call_id: callIdRef.current }
      }));
    }
    cleanupCall();
  }, [cleanupCall]);

  // 4. Hang up / End Call
  const endCall = useCallback(() => {
    if (ws.current && ws.current.readyState === WebSocket.OPEN && targetIdRef.current) {
      ws.current.send(JSON.stringify({
        event_type: 'call-end',
        target_id: targetIdRef.current,
        payload: { call_id: callIdRef.current }
      }));
    }
    cleanupCall();
  }, [cleanupCall]);

  // Mute Audio track
  const toggleMuteAudio = useCallback(() => {
    if (localStreamRef.current) {
      const audioTrack = localStreamRef.current.getAudioTracks()[0];
      if (audioTrack) {
        audioTrack.enabled = !audioTrack.enabled;
        setAudioMuted(!audioTrack.enabled);
      }
    }
  }, []);

  // Disable Video track
  const toggleDisableVideo = useCallback(() => {
    if (localStreamRef.current) {
      const videoTrack = localStreamRef.current.getVideoTracks()[0];
      if (videoTrack) {
        videoTrack.enabled = !videoTrack.enabled;
        setVideoDisabled(!videoTrack.enabled);
      }
    }
  }, []);

  return {
    callState,
    localStream,
    remoteStream,
    callerInfo,
    audioMuted,
    videoDisabled,
    initiateCall,
    acceptCall,
    rejectCall,
    endCall,
    toggleMuteAudio,
    toggleDisableVideo
  };
};
