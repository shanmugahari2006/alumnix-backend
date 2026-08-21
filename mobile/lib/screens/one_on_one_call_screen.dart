import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/io.dart';

class OneOnOneCallScreen extends StatefulWidget {
  final String jwtToken;
  final String userId;
  final String targetUserId;
  final String backendHost; // e.g. "localhost:8000" or "api.college.com"
  final bool isIncoming;
  final String? incomingCallerName;
  final String? incomingRoomId;
  final String? incomingCallId;

  const OneOnOneCallScreen({
    Key? key,
    required this.jwtToken,
    required this.userId,
    required this.targetUserId,
    required this.backendHost,
    required this.isIncoming,
    this.incomingCallerName,
    this.incomingRoomId,
    this.incomingCallId,
  }) : super(key: key);

  @override
  State<OneOnOneCallScreen> createState() => _OneOnOneCallScreenState();
}

class _OneOnOneCallScreenState extends State<OneOnOneCallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  IOWebSocketChannel? _channel;
  
  bool _isPermissionsGranted = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  String _connectionStateBanner = "Initializing...";
  String? _callId;
  String? _roomId;

  @override
  void initState() {
    super.initState();
    _callId = widget.incomingCallId;
    _roomId = widget.incomingRoomId;
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. Initialize Renderers
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    // 2. Request Camera and Mic Permissions
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && micStatus.isGranted) {
      setState(() {
        _isPermissionsGranted = true;
        _connectionStateBanner = "Connecting to signaling server...";
      });
      _connectSignaling();
    } else {
      setState(() {
        _connectionStateBanner = "Camera & Mic permissions denied.";
      });
    }
  }

  void _connectSignaling() {
    final protocol = widget.backendHost.startsWith("https") ? "wss" : "ws";
    final host = widget.backendHost.replaceAll("http://", "").replaceAll("https://", "");
    final wsUrl = "$protocol://$host/ws/calls/signal?token=${widget.jwtToken}";

    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        (message) => _onSignalingMessage(jsonDecode(message)),
        onDone: _onSignalingClosed,
        onError: (err) => _onSignalingError(err),
      );

      if (widget.isIncoming) {
        setState(() {
          _connectionStateBanner = "Incoming Call from ${widget.incomingCallerName}...";
        });
      } else {
        _startCall();
      }
    } catch (e) {
      _updateBanner("Signaling connection failed.");
    }
  }

  void _startCall() {
    _roomId = "GEC-Flutter-${widget.userId.substring(0, 5)}-${widget.targetUserId.substring(0, 5)}";
    
    // Initiate Call via WebSockets
    final initiateMsg = {
      "event_type": "call-initiate",
      "target_id": widget.targetUserId,
      "payload": {
        "room_id": _roomId
      }
    };
    
    _channel!.sink.add(jsonEncode(initiateMsg));
    _updateBanner("Ringing...");
  }

  Future<void> _onSignalingMessage(Map<String, dynamic> data) async {
    final eventType = data["event_type"];
    final senderId = data["sender_id"];
    final payload = data["payload"];

    switch (eventType) {
      case 'incoming-call':
        // Handled in handshake initialization for incoming
        break;

      case 'call-offer':
        // Setup peer connection
        await _setupPeerConnection();
        // Set remote description
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(payload["sdp"], payload["type"]),
        );
        // Create answer
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);

        // Send answer back
        _channel!.sink.add(jsonEncode({
          "event_type": "call-answer",
          "target_id": senderId,
          "payload": {
            "sdp": answer.sdp,
            "type": answer.type,
            "call_id": _callId
          }
        }));
        _updateBanner("Connected");
        break;

      case 'call-answer':
        if (_peerConnection != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(payload["sdp"], payload["type"]),
          );
          _updateBanner("Connected");
        }
        break;

      case 'ice-candidate':
        if (_peerConnection != null && payload["candidate"] != null) {
          final candidate = RTCIceCandidate(
            payload["candidate"]["candidate"],
            payload["candidate"]["sdpMid"],
            payload["candidate"]["sdpMLineIndex"],
          );
          await _peerConnection!.addCandidate(candidate);
        }
        break;

      case 'call-rejected':
        _updateBanner("Call Rejected by peer.");
        _hangUp(notify: false);
        break;

      case 'call-ended':
        _updateBanner("Call Ended.");
        _hangUp(notify: false);
        break;

      case 'call-missed':
        _updateBanner("Call Missed.");
        _hangUp(notify: false);
        break;

      case 'call-error':
        _updateBanner("Error: ${data["message"]}");
        _hangUp(notify: false);
        break;
    }
  }

  Future<void> _setupPeerConnection() async {
    final config = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
        {"urls": "stun:stun1.l.google.com:19302"}
      ]
    };

    _peerConnection = await createPeerConnection(config);

    // Track state changes
    _peerConnection!.onConnectionState = (state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          _updateBanner("Connecting WebRTC...");
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _updateBanner("Connected");
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _updateBanner("Disconnected");
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _updateBanner("WebRTC connection failed.");
          break;
        default:
          break;
      }
    };

    // Capture Local Camera & Audio
    final mediaConstraints = {
      "audio": true,
      "video": {
        "mandatory": {
          "minWidth": "640",
          "minHeight": "480",
          "minFrameRate": "30",
        },
        "facingMode": "user",
        "optional": [],
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = _localStream;

    // Attach local stream tracks to WebRTC peer connection
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // Listen for remote peer tracks
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    // Listen for local ICE candidates and send to signaling gateway
    _peerConnection!.onIceCandidate = (candidate) {
      if (_channel != null) {
        _channel!.sink.add(jsonEncode({
          "event_type": "ice-candidate",
          "target_id": widget.targetUserId,
          "payload": {
            "candidate": {
              "candidate": candidate.candidate,
              "sdpMid": candidate.sdpMid,
              "sdpMLineIndex": candidate.sdpMLineIndex
            }
          }
        }));
      }
    };
  }

  void _acceptCall() async {
    _updateBanner("Connecting...");
    await _setupPeerConnection();
    // Re-trigger offer/answer loop. The WebSocket will route signaling
  }

  void _declineCall() {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        "event_type": "call-reject",
        "target_id": widget.targetUserId,
        "payload": {
          "call_id": _callId
        }
      }));
    }
    _hangUp(notify: false);
  }

  void _hangUp({bool notify = true}) {
    if (notify && _channel != null) {
      _channel!.sink.add(jsonEncode({
        "event_type": "call-end",
        "target_id": widget.targetUserId,
        "payload": {
          "call_id": _callId
        }
      }));
    }

    _peerConnection?.close();
    _peerConnection = null;
    
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;

    _channel?.sink.close();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _toggleMute() {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks()[0];
      audioTrack.enabled = !audioTrack.enabled;
      setState(() {
        _isMuted = !audioTrack.enabled;
      });
    }
  }

  void _toggleVideo() {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks()[0];
      videoTrack.enabled = !videoTrack.enabled;
      setState(() {
        _isVideoOff = !videoTrack.enabled;
      });
    }
  }

  void _flipCamera() {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks()[0];
      Helper.switchCamera(videoTrack);
    }
  }

  void _updateBanner(String statusText) {
    if (mounted) {
      setState(() {
        _connectionStateBanner = statusText;
      });
    }
  }

  void _onSignalingClosed() {
    _updateBanner("Signaling channel closed.");
    _hangUp(notify: false);
  }

  void _onSignalingError(dynamic err) {
    _updateBanner("Signaling channel error: $err");
    _hangUp(notify: false);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _localStream?.getTracks().forEach((track) => track.stop());
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionsGranted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _connectionStateBanner,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => openAppSettings(),
                child: const Text("Grant Permissions"),
              )
            ],
          ),
        ),
      );
    }

    // 1. Render Ringing In screen
    if (widget.isIncoming && _localStream == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent,
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 48, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Incoming Call from ${widget.incomingCallerName ?? 'Alumni'}",
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Mentorship Video Call", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: _declineCall,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.green,
                    onPressed: _acceptCall,
                    child: const Icon(Icons.videocam, color: Colors.white),
                  )
                ],
              )
            ],
          ),
        ),
      );
    }

    // 2. Render Ringing Out / Outgoing Ringing
    if (!widget.isIncoming && _localStream != null && _remoteRenderer.srcObject == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Stack(
          children: [
            // Outgoing Caller Video preview
            Positioned.fill(
              child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blue),
                  const SizedBox(height: 24),
                  Text(
                    _connectionStateBanner,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () => _hangUp(notify: true),
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      );
    }

    // 3. Render Live Video Room (Connected)
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Participant Video View (Full Screen)
          Positioned.fill(
            child: _remoteRenderer.srcObject != null
                ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : const Center(
                    child: Text(
                      "Waiting for remote video track...",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
          ),

          // Floating Picture-in-Picture Local Video Card
          Positioned(
            top: 48,
            right: 16,
            width: 120,
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black45,
                child: _localRenderer.srcObject != null && !_isVideoOff
                    ? RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                    : const Center(
                        child: Icon(Icons.videocam_off, color: Colors.white),
                      ),
              ),
            ),
          ),

          // Status Connection Banner
          if (_connectionStateBanner != "Connected")
            Positioned(
              top: 48,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _connectionStateBanner,
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                ),
              ),
            ),

          // Calling Controls Floating Panel overlay
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Toggle Audio Mic
                FloatingActionButton(
                  mini: true,
                  backgroundColor: _isMuted ? Colors.amber : Colors.white24,
                  onPressed: _toggleMute,
                  child: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                ),
                // Toggle Video Camera
                FloatingActionButton(
                  mini: true,
                  backgroundColor: _isVideoOff ? Colors.amber : Colors.white24,
                  onPressed: _toggleVideo,
                  child: Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam, color: Colors.white),
                ),
                // Flip Camera
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white24,
                  onPressed: _flipCamera,
                  child: const Icon(Icons.flip_camera_ios, color: Colors.white),
                ),
                // Red End Call button
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () => _hangUp(notify: true),
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
