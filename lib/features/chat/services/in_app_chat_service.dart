import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/core/models/message_model.dart';
import 'package:datn/core/services/notification_sender_service.dart';

class InAppChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a message within a specific order
  Future<void> sendMessage({
    required String orderId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final timestamp = DateTime.now();

    final message = MessageModel(
      id: '', // Firestore will generate this
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      createdAt: timestamp,
      isRead: false,
    );

    // Save to Firestore under orders/{orderId}/messages/{messageId}
    await _firestore
        .collection('orders')
        .doc(orderId)
        .collection('messages')
        .add(message.toMap());

    // Update the parent order document with a lastMessage snippet
    await _firestore.collection('orders').doc(orderId).update({
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // Send push notification to the receiver
    await NotificationSenderService.notifyUser(
      targetUserId: receiverId,
      title: "Tin nhắn mới",
      body: content,
    );
  }

  /// Get stream of messages for a specific order
  Stream<List<MessageModel>> getMessages(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Mark all messages in an order as read by a specific user
  Future<void> markMessagesAsRead(String orderId, String currentUserId) async {
    final snapshot = await _firestore
        .collection('orders')
        .doc(orderId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}
