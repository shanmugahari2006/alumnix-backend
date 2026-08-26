import 'dart:convert';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:web_socket_channel/io.dart';

class CallKitService {
  static final CallKitService _instance = CallKitService._internal();
  factory CallKitService() => _instance;
  CallKitService._internal();

  Function(Map<String, dynamic> extra)? onCallAccepted;
  Function(Map<String, dynamic> extra)? onCallDeclined;

  String? _jwtToken;
  String? _backendHost;

  void init({required String jwtToken, required String backendHost}) {
    _jwtToken = jwtToken;
    _backendHost = backendHost;
    _listenToCallKitEvents();
  }

  // Display native full screen callkit ringer
  Future<void> showIncomingCall({
    required String uuid,
    required String callerName,
    required String roomId,
    required String callId,
    required String callerId,
    String? avatarUrl,
  }) async {
    CallKitParams params = CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'Alumnix',
      avatar: avatarUrl ?? '',
      handle: 'Mentorship Video Call',
      type: 1, // 0: Audio, 1: Video
      duration: 30000, // Ring for 30s max
      extra: <String, dynamic>{
        'room_id': roomId,
        'caller_id': callerId,
        'call_id': callId,
      },
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0f172a',
        actionColor: '#4f46e5',
        incomingCallNotificationChannelName: 'Incoming Call Alerts',
      ),
      ios: IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  // Listen to actions triggered by the native overlay buttons
  void _listenToCallKitEvents() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      if (event == null) return;

      switch (event.event) {
        case Event.ACTION_CALL_ACCEPT:
          final extra = Map<String, dynamic>.from(event.body['extra'] ?? {});
          if (onCallAccepted != null) {
            onCallAccepted!(extra);
          }
          break;

        case Event.ACTION_CALL_DECLINE:
          final extra = Map<String, dynamic>.from(event.body['extra'] ?? {});
          await _declineCallBackend(extra);
          if (onCallDeclined != null) {
            onCallDeclined!(extra);
          }
          break;

        case Event.ACTION_CALL_TIMEOUT:
          final extra = Map<String, dynamic>.from(event.body['extra'] ?? {});
          await _declineCallBackend(extra);
          break;

        default:
          break;
      }
    });
  }

  // Reject call via WebSocket channel (fires when app is backgrounded)
  Future<void> _declineCallBackend(Map<String, dynamic> extra) async {
    final callId = extra['call_id'];
    final callerId = extra['caller_id'];
    if (callId == null || _jwtToken == null || _backendHost == null) return;

    final protocol = _backendHost!.startsWith("https") ? "wss" : "ws";
    final host = _backendHost!.replaceAll("http://", "").replaceAll("https://", "");
    final wsUrl = "$protocol://$host/ws/calls/signal?token=$_jwtToken";

    try {
      final channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      channel.sink.add(jsonEncode({
        "event_type": "call-reject",
        "target_id": callerId ?? '',
        "payload": {"call_id": callId}
      }));
      // Close channel immediately after sending rejection
      await Future.delayed(const Duration(milliseconds: 300));
      await channel.sink.close();
      print("Call $callId declined and synced on backend via WebSocket.");
    } catch (e) {
      print("Failed to sync call rejection on backend: $e");
    }
  }

  // Unregister all CallKit ringers on hangup
  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }
}
