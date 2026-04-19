import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/features/chatbot/screens/chatbot_screen.dart'; // To reuse ChatMessage model

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['role'] ?? 'customer';
      }
    } catch (e) {
      debugPrint("Lỗi lấy role: $e");
    }
    return 'customer';
  }

  // Create a new chat session
  Future<String> createNewSession({
    required String userId,
    required String topic,
  }) async {
    try {
      final sessionRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .add({
            'topic': topic,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lastMessage': 'Bắt đầu trò chuyện',
          });
      return sessionRef.id;
    } catch (e) {
      debugPrint("Lỗi tạo session: $e");
      throw Exception("Không thể tạo phiên chat mới.");
    }
  }

  // Stream list of chat sessions for a user
  Stream<QuerySnapshot> streamSessions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_sessions')
        // Removing orderBy to prevent Missing Index Error for now
        .snapshots();
  }

  // Save a new message to Firestore within a specific session
  Future<void> saveMessage({
    required String userId,
    required String sessionId,
    required ChatMessage message,
  }) async {
    try {
      final sessionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId);

      await sessionRef.collection('messages').add({
        'text': message.text,
        'isFromUser': message.isFromUser,
        'type': message.type,
        'data': message.data,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the session's lastMessage and updatedAt for the history list preview
      await sessionRef.update({
        'lastMessage': message.text.isNotEmpty
            ? message.text
            : 'Đã gửi một thẻ chức năng',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Lỗi khi lưu tin nhắn: $e");
      throw Exception("Không thể lưu tin nhắn.");
    }
  }

  // Stream chat history ordered by timestamp for a specific session
  Stream<List<ChatMessage>> streamChatHistory(String userId, String sessionId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ChatMessage(
              text: data['text'] ?? '',
              isFromUser: data['isFromUser'] ?? true,
              type: data['type'] ?? 'text',
              data: data['data'],
            );
          }).toList();
        });
  }

  // Delete a chat session
  Future<void> deleteSession(String userId, String sessionId) async {
    try {
      final sessionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId);

      // Fetch and delete all messages in the subcollection first
      final messagesSnapshot = await sessionRef.collection('messages').get();
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Finally delete the session document
      await sessionRef.delete();
    } catch (e) {
      debugPrint("Lỗi khi xóa session: $e");
      throw Exception("Không thể xóa phiên chat.");
    }
  }
}
