import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    // 1. Request permissions (especially for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission for push notifications');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Setup Foreground notification presentation
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // 3. Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {},
    );

    // 4. Setup message handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        _showLocalNotification(message);
      }
    });

    // 5. Get device token and save it
    await updateDeviceToken();

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });
  }

  // Update token for current user
  Future<void> updateDeviceToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint("Error getting FCM Token: $e");
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // NOTE: We now save this to Supabase instead of Firestore.
      await Supabase.instance.client
          .from('users')
          .update({
            'fcm_token': token,
            // The DB handles updated_at trigger, or you could do it manually
          })
          .eq('id', user.id);
    }
  }

  // Show local notification when app is in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'super_app_alerts', // id
          'Super App Notifications', // name
          channelDescription: 'Notifications for rides and orders',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          color: Color(0xFFFE724C), // Brand orange
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      platformChannelSpecifics,
    );
  }
}
