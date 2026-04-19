import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/features/chatbot/services/chat_service.dart';
import 'package:datn/features/chatbot/screens/chatbot_screen.dart';
import 'package:intl/intl.dart';

class AiHistoryScreen extends StatefulWidget {
  final String role;

  const AiHistoryScreen({super.key, this.role = 'consumer'});

  @override
  State<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends State<AiHistoryScreen> {
  final ChatService _chatService = ChatService();
  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  void _showNewChatBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn Chủ Đề Trợ Lý',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI sẽ điều chỉnh cách trả lời và công cụ dựa trên chủ đề bạn chọn.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (widget.role == 'driver') ...[
                _buildTopicTile(
                  context,
                  icon: Icons.monetization_on,
                  color: Colors.amber,
                  title: 'Tối Ưu Thu Nhập',
                  description: 'Phân tích doanh thu, chiến thuật nhận chuyến.',
                  topicId: 'driver_earnings',
                ),
                _buildTopicTile(
                  context,
                  icon: Icons.shield,
                  color: Colors.blueGrey,
                  title: 'Hỗ Trợ Chuyến Đi',
                  description: 'Giá cước, hủy chuyến, luật lệ an toàn.',
                  topicId: 'driver_support',
                ),
                _buildTopicTile(
                  context,
                  icon: Icons.build,
                  color: Colors.brown,
                  title: 'Kỹ Thuật App',
                  description: 'Sự cố GPS, lỗi ứng dụng.',
                  topicId: 'driver_tech_support',
                ),
              ] else ...[
                _buildTopicTile(
                  context,
                  icon: Icons.support_agent,
                  color: Colors.blue,
                  title: 'Hỗ Trợ Khách Hàng',
                  description: 'Giải đáp thắc mắc chung về dịch vụ.',
                  topicId: 'customer_support',
                ),
                _buildTopicTile(
                  context,
                  icon: Icons.directions_car,
                  color: Colors.green,
                  title: 'Đặt Xe / Gọi Tài Xế',
                  description: 'Hỗ trợ tìm và gọi xe nhanh chóng.',
                  topicId: 'ride_hailing',
                ),
                _buildTopicTile(
                  context,
                  icon: Icons.fastfood,
                  color: Colors.orange,
                  title: 'Gợi Ý Quán Ăn',
                  description: 'Tìm kiếm hàng quán, đặt món ăn ngon.',
                  topicId: 'food_delivery',
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopicTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String topicId,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(50),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      onTap: () => _startNewSession(context, topicId, title),
    );
  }

  Future<void> _startNewSession(
    BuildContext sheetContext,
    String topicId,
    String title,
  ) async {
    final userId = _userId;
    if (userId == null) return;

    // 1. Close the bottom sheet immediately using its specific context
    Navigator.of(sheetContext).pop();

    if (!mounted) return;

    // 2. Show loading dialog using the Screen's persistent context
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final sessionId = await _chatService.createNewSession(
        userId: userId,
        topic: topicId,
      );

      if (!mounted) return;

      // 3. Close the loading dialog
      Navigator.of(context).pop();

      // 4. Navigate to Chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatbotScreen(
            sessionId: sessionId,
            topic: topicId,
            topicName: title,
            role: widget.role,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close the loading dialog on error
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi tạo phiên bản trò chuyện.')),
      );
    }
  }

  void _continueSession(String sessionId, String topicId) {
    String title = 'Trợ Lý AI';
    if (topicId == 'ride_hailing') title = 'Đặt Xe / Gọi Tài Xế';
    if (topicId == 'food_delivery') title = 'Gợi Ý Quán Ăn';
    if (topicId == 'customer_support') title = 'Hỗ Trợ Khách Hàng';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotScreen(
          sessionId: sessionId,
          topic: topicId,
          topicName: title,
          role: widget.role,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Trò Chuyện'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _userId == null
          ? const Center(child: Text("Vui lòng đăng nhập"))
          : StreamBuilder<QuerySnapshot>(
              stream: _chatService.streamSessions(_userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint("Stream Error: ${snapshot.error}");
                  return Center(
                    child: Text("Đã xảy ra lỗi: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Chưa có cuộc trò chuyện nào",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final sessions = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final data = sessions[index].data() as Map<String, dynamic>;
                    final sessionId = sessions[index].id;
                    final topic = data['topic'] ?? 'Unknown';
                    final lastMessage = data['lastMessage'] ?? '...';
                    final updatedAt = data['updatedAt'] as Timestamp?;

                    String formattedDate = '';
                    if (updatedAt != null) {
                      final now = DateTime.now();
                      final date = updatedAt.toDate();
                      if (now.difference(date).inDays == 0 &&
                          now.day == date.day) {
                        formattedDate = DateFormat.Hm().format(date);
                      } else {
                        formattedDate = DateFormat('dd/MM HH:mm').format(date);
                      }
                    }

                    IconData topicIcon = Icons.support_agent;
                    Color topicColor = Colors.blue;
                    String topicName = 'Hỗ Trợ Khách Hàng';

                    if (topic == 'ride_hailing') {
                      topicIcon = Icons.directions_car;
                      topicColor = Colors.green;
                      topicName = 'Đặt Xe';
                    } else if (topic == 'food_delivery') {
                      topicIcon = Icons.fastfood;
                      topicColor = Colors.orange;
                      topicName = 'Gợi Ý Đồ Ăn';
                    }

                    return Dismissible(
                      key: Key(sessionId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Xác nhận"),
                              content: const Text(
                                "Sếp có chắc chắn muốn xóa cuộc trò chuyện này không?",
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text(
                                    "Hủy",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text("Xóa"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        await _chatService.deleteSession(_userId!, sessionId);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Đã xóa cuộc trò chuyện'),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _continueSession(sessionId, topic),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      topicIcon,
                                      color: topicColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      topicName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: topicColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  lastMessage,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewChatBottomSheet(context),
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Chat Mới',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
