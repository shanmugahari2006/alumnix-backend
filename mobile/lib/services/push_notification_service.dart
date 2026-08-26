import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/dio_client.dart';
import 'callkit_service.dart';

// Top-level callback for handling incoming background messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Safe fallback if Firebase config is missing
    return;
  }

  print("Received background FCM payload: ${message.data}");

  final eventType = message.data['event_type'];
  if (eventType == 'incoming_call') {
    final callerName = message.data['sender_name'] ?? 'Alumni';
    final roomId = message.data['room_id'] ?? '';
    final callId = message.data['call_id'] ?? '';
    final callerId = message.data['caller_id'] ?? '';

    // Show native incoming call overlay
    await CallKitService().showIncomingCall(
      uuid: callId,
      callerName: callerName,
      roomId: roomId,
      callId: callId,
      callerId: callerId,
    );
  }
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  DioClient? _dioClient;
  bool _firebaseConfigured = false;

  void setDioClient(DioClient client) {
    _dioClient = client;
  }

  Future<void> initialize() async {
    // 1. Safely initialize Firebase Core without crashing if configuration files are missing
    try {
      await Firebase.initializeApp();
      _firebaseConfigured = true;
      print("Firebase successfully initialized on mobile.");
    } catch (e) {
      print("Firebase initialization bypassed/unavailable: $e. Running in mock push mode.");
      _firebaseConfigured = false;
      
      // Even if Firebase is not active, register a mock token so the backend has a target to print mock outputs to
      await registerTokenWithBackend("mock-device-token-alumnix");
      return;
    }

    try {
      final fcm = FirebaseMessaging.instance;

      // 2. Request OS notification permissions (needed for iOS/Android 13+)
      NotificationSettings settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print("User push settings state: ${settings.authorizationStatus}");

      // 3. Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Set foreground messaging handler (runs when app is active)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print("Received foreground FCM payload: ${message.data}");

        final eventType = message.data['event_type'];
        if (eventType == 'incoming_call') {
          final callerName = message.data['sender_name'] ?? 'Alumni';
          final roomId = message.data['room_id'] ?? '';
          final callId = message.data['call_id'] ?? '';
          final callerId = message.data['caller_id'] ?? '';

          // Display call overlay instantly even in foreground
          await CallKitService().showIncomingCall(
            uuid: callId,
            callerName: callerName,
            roomId: roomId,
            callId: callId,
            callerId: callerId,
          );
        }
      });

      // 5. Fetch FCM Registration Token and register with backend
      final token = await getDeviceToken();
      if (token != null) {
        await registerTokenWithBackend(token);
      }

      // 6. Listen for token refreshes
      fcm.onTokenRefresh.listen((newToken) async {
        await registerTokenWithBackend(newToken);
      });

    } catch (e) {
      print("Failed to initialize Firebase Messaging listeners: $e");
    }
  }

  // Get unique device push registration token
  Future<String?> getDeviceToken() async {
    if (!_firebaseConfigured) return "mock-device-token-alumnix";
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print("Failed to fetch FCM device token: $e");
      return null;
    }
  }

  // Upload registration token to backend database
  Future<void> registerTokenWithBackend(String token) async {
    if (_dioClient == null) return;
    try {
      await _dioClient!.post('/auth/device-token', data: {'token': token});
      print("FCM device token registered with backend successfully.");
    } catch (e) {
      print("Failed to upload device token to backend: $e");
    }
  }

  // Unregister token (called on logout)
  Future<void> unregisterTokenWithBackend() async {
    if (_dioClient == null) return;
    final token = await getDeviceToken();
    if (token == null) return;

    try {
      await _dioClient!.delete('/auth/device-token', data: {'token': token});
      print("FCM device token unregistered from backend successfully.");
    } catch (e) {
      print("Failed to unregister device token: $e");
    }
  }
}
