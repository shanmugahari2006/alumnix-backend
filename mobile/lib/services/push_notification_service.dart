import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'callkit_service.dart';

// Top-level callback for handling incoming background messages.
// This function executes in a separate background isolate when the application is terminated/suspended.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized inside the background isolate context
  await Firebase.initializeApp();

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

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Request OS notification permissions (needed for iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print("User push settings state: ${settings.authorizationStatus}");

    // 2. Set background messaging handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Set foreground messaging handler (runs when app is active)
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
  }

  // Get unique device push registration token
  Future<String?> getDeviceToken() async {
    try {
      String? token = await _fcm.getToken();
      print("Device FCM Registration Token: $token");
      return token;
    } catch (e) {
      print("Failed to fetch FCM device token: $e");
      return null;
    }
  }
}
