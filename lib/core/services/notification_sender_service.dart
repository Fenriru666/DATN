import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationSenderService {
  static String get _notifyUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api/notify';
      }
    } catch (e) {
      // Ignore for web
    }
    return 'http://localhost:3000/api/notify';
  }

  static String get _notifyTopicUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api/notify-topic';
      }
    } catch (e) {
      // Ignore for web
    }
    return 'http://localhost:3000/api/notify-topic';
  }

  /// Sends a push notification to a specific user by looking up their FCM Token
  static Future<void> notifyUser({
    required String targetUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1. Fetch the FCM token for the target user
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .get();

      if (!userDoc.exists) return;

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint("User $targetUserId has no FCM Token.");
        return;
      }

      // 2. Send HTTP request to Node.js backend
      final response = await http.post(
        Uri.parse(_notifyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Successfully notified user $targetUserId via Node.js");
      } else {
        debugPrint(
          "Failed to notify: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Error sending push notification: $e");
    }
  }

  /// Sends a push notification to all users subscribed to a specific FCM Topic
  static Future<void> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_notifyTopicUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': topic,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Successfully notified topic $topic");
      } else {
        debugPrint(
          "Failed to notify topic: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Error sending topic notification: $e");
    }
  }
}
