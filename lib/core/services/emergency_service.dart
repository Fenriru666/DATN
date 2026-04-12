import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/core/models/emergency_model.dart';
import 'package:datn/core/services/notification_sender_service.dart';

class EmergencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kích hoạt SOS khẩn cấp
  /// Lưu tọa độ vào bảng 'emergencies' và gửi Push Notification "Báo Động Đỏ" cho Admin
  Future<void> triggerSOS(EmergencyModel emergencyData) async {
    try {
      // 1. Lưu thông tin cầu cứu vào Firestore
      await _firestore.collection('emergencies').add(emergencyData.toMap());

      // 2. Gửi Push Notification (Topic)
      // Giả sử các Admin đã đăng ký topic 'admin_alerts'
      // Trong thực tế, có thể loop qua danh sách UID của Admin
      // Nhưng để demo nhanh, ta gửi qua topic
      await NotificationSenderService.sendTopicNotification(
        topic: 'admin_alerts',
        title: "🚨 BÁO ĐỘNG SOS 🚨",
        body:
            "Phát hiện tín hiệu cầu cứu từ [${emergencyData.userRole}]. Vui lòng kiểm tra khẩn cấp!",
      );
    } catch (e) {
      throw Exception("Lỗi khi gửi báo động SOS: $e");
    }
  }
}
