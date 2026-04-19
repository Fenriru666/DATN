import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/features/chatbot/services/chat_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:datn/features/customer/screens/ride/ride_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:datn/features/customer/services/goong_service.dart';

// --- Custom Message Model ---
class ChatMessage {
  final String text;
  final bool isFromUser;
  final String type; // 'text', 'ride_card', 'food_card'
  final Map<String, dynamic>? data;

  ChatMessage({
    required this.text,
    required this.isFromUser,
    this.type = 'text',
    this.data,
  });
}

class ChatbotScreen extends StatefulWidget {
  final String sessionId;
  final String topic;
  final String topicName;
  final String role;

  const ChatbotScreen({
    super.key,
    required this.sessionId,
    required this.topic,
    required this.topicName,
    this.role = 'consumer',
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // Use localhost for Chrome testing, 10.0.2.2 for Android Emulator
  String get _backendUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api/chat';
      }
    } catch (e) {
      // Ignored for Web
    }
    return 'http://localhost:3000/api/chat';
  }

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();

  final ChatService _chatService = ChatService();
  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  bool _loading = false;

  // --- Voice AI variables ---
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isAutoReadEnabled = true; // Bật sẵn chế độ tự động đọc

  // --- Location variables ---
  String _currentAddress = 'Vị trí hiện tại của bạn';
  final GoongService _goongService = GoongService();

  @override
  void initState() {
    super.initState();
    _initVoiceSystem();
    _initLocation();
    // Default welcome message handled in ListView directly.
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      final address = await _goongService.reverseGeocode(latLng);
      if (mounted) {
        setState(() {
          _currentAddress = address;
        });
      }
    } catch (e) {
      debugPrint("Error fetching location for chatbot: $e");
    }
  }

  Future<void> _initVoiceSystem() async {
    // Khởi tạo Speech To Text
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (mounted) {
          setState(() {
            _isListening = val == 'listening';
          });
        }
      },
      onError: (val) => debugPrint('STT Error: $val'),
    );
    if (!available) {
      debugPrint("STT Not Available");
    }

    // Cấu hình Text To Speech cho Tiếng Việt
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5); // Tốc độ vừa phải
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _scrollController.dispose();
    _textController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  // Removed _fetchUserRole as it's passed synchronously now

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _loading = true;
    });

    _textController.clear();
    _scrollDown();

    final userId = _userId;
    if (userId != null) {
      await _chatService.saveMessage(
        userId: userId,
        sessionId: widget.sessionId,
        message: ChatMessage(text: message, isFromUser: true),
      );
    }

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          if (userId != null) 'userId': userId,
          'role': widget.role,
          'sessionId': widget.sessionId,
          'topic': widget.topic,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String botResponseText = data['text'] ?? '';
        Map<String, dynamic>? botData = data['data'];

        // Sửa lỗi placeholder Backend trả về cho logic đặt xe
        botResponseText = botResponseText.replaceAll(
          '<đây là điểm xuất phát của bạn>',
          _currentAddress,
        );
        if (botData != null && botData['pickup'] != null) {
          botData['pickup'] = botData['pickup'].toString().replaceAll(
            '<đây là điểm xuất phát của bạn>',
            _currentAddress,
          );
        }

        if (userId != null) {
          await _chatService.saveMessage(
            userId: userId,
            sessionId: widget.sessionId,
            message: ChatMessage(
              text: botResponseText,
              isFromUser: false,
              type: data['type'] ?? 'text',
              data: botData,
            ),
          );
        }

        // --- Text-to-Speech ---
        if (_isAutoReadEnabled && botResponseText.isNotEmpty) {
          await _flutterTts.speak(botResponseText);
        }
      } else {
        _showError('Server returned Error: ${response.statusCode}');
      }
    } catch (e) {
      // DỰ PHÒNG: Nếu chưa chạy backend, mock lại dữ liệu để UX không bị gãy
      debugPrint("Error connecting to backend: $e");
      _addMockResponse(message);
    } finally {
      setState(() {
        _loading = false;
      });
      _scrollDown();
      _textFieldFocus.requestFocus();
    }
  }

  Future<void> _addMockResponse(String text) async {
    // --- Fallback Mock Agent Logic if Backend is offline ---
    final lowerText = text.toLowerCase();
    ChatMessage? mockMessage;

    // 1. Book a Ride Mock
    if (lowerText.contains('đặt xe') ||
        lowerText.contains('chở') ||
        lowerText.contains('đi')) {
      mockMessage = ChatMessage(
        text:
            "Mình đã tìm được tài xế gần bạn nhất. Đây là thông tin chuyến đi, bạn xác nhận nhé! (Lưu ý: Đang chạy Mock vì Server offline)",
        isFromUser: false,
        type: 'ride_card',
        data: {
          'driverName': 'Tài xế Ảo (Mock)',
          'car': 'Honda Vario - 59X1-12345',
          'rating': 4.9,
          'price': '45,000đ',
          'pickup': _currentAddress,
          'dropoff': 'Quận 1, TP.HCM',
        },
      );
    }
    // 2. Order Food Mock
    else if (lowerText.contains('thèm') ||
        lowerText.contains('đồ ăn') ||
        lowerText.contains('ngọt') ||
        lowerText.contains('buồn')) {
      mockMessage = ChatMessage(
        text:
            "Đừng buồn nhé! Một chút đồ ngọt sẽ làm bạn vui hơn. Mình gợi ý vài món ăn nhẹ ở cửa hàng gần nhất đây:",
        isFromUser: false,
        type: 'food_card',
        data: {
          'restaurantName': 'The Coffee House',
          'items': [
            {'name': 'Trà Đào Cam Sả', 'price': '45,000đ'},
            {'name': 'Bánh Mousse', 'price': '35,000đ'},
          ],
          'total': '80,000đ',
        },
      );
    } else {
      // Normal text response simulation
      mockMessage = ChatMessage(
        text:
            "Xin lỗi, hiện tại Server Backend đang tắt. Bạn hãy chạy node server.js để có phản hồi thật từ AI nhé.",
        isFromUser: false,
      );
    }

    // --- Giả lập gọi TTS khi có phản hồi mock ---
    if (_isAutoReadEnabled && mockMessage.text.isNotEmpty) {
      await _flutterTts.speak(mockMessage.text);
    }

    if (_userId != null) {
      await _chatService.saveMessage(
        userId: _userId!,
        sessionId: widget.sessionId,
        message: mockMessage,
      );
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (mounted) {
            setState(() => _isListening = val == 'listening');
          }
        },
        onError: (val) {
          debugPrint('STT Error: $val');
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _textController.text = val.recognizedWords;
          }),
          localeId: 'vi_VN',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      // Optional: Auto-send after stop listening
      // if (_textController.text.isNotEmpty) {
      //   _sendChatMessage(_textController.text);
      // }
    }
  }

  void _showError(String errMsg) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lỗi Server'),
          content: SingleChildScrollView(child: SelectableText(errMsg)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topicName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Phiên: ${widget.sessionId.substring(0, 8)}...',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(
              _isAutoReadEnabled ? Icons.volume_up : Icons.volume_off,
              color: _isAutoReadEnabled ? const Color(0xFFFE724C) : Colors.grey,
            ),
            tooltip: _isAutoReadEnabled
                ? 'Tắt tự động đọc'
                : 'Bật tự động đọc',
            onPressed: () {
              setState(() {
                _isAutoReadEnabled = !_isAutoReadEnabled;
                if (!_isAutoReadEnabled) {
                  _flutterTts.stop(); // Stop immediately if toggled off
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isAutoReadEnabled
                        ? 'Đã BẬT tự động đọc văn bản'
                        : 'Đã TẮT tự động đọc văn bản',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _userId != null
                    ? _chatService.streamChatHistory(_userId!, widget.sessionId)
                    : const Stream.empty(),
                builder: (context, snapshot) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFE724C),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Lỗi tải tin nhắn: ${snapshot.error}"),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount:
                        messages.length + 1, // +1 for the welcome message
                    itemBuilder: (context, idx) {
                      if (idx == 0) {
                        return _buildMessageRow(
                          ChatMessage(
                            text:
                                "Xin chào! Mình là Trợ lý AI Thông minh.\nMình có thể giúp bạn đặt xe, tìm quán ăn, hoặc trả lời các câu hỏi thông thường. Hôm nay bạn cần giúp gì? Lịch sử chat của bạn đã được khôi phục!",
                            isFromUser: false,
                          ),
                        );
                      }
                      final message = messages[idx - 1];
                      return _buildMessageRow(message);
                    },
                  );
                },
              ),
            ),
            if (_loading)
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFFFE724C),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Trợ lý đang suy nghĩ...",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.isFromUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Text bubble
          Row(
            mainAxisAlignment: message.isFromUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isFromUser) ...[
                CircleAvatar(
                  backgroundColor: const Color(0xFFFE724C).withAlpha(30),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Color(0xFFFE724C),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isFromUser
                        ? const Color(0xFFFE724C)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: message.isFromUser
                          ? const Radius.circular(0)
                          : const Radius.circular(20),
                      topLeft: !message.isFromUser
                          ? const Radius.circular(0)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      if (!message.isFromUser)
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: message.isFromUser
                            ? Colors.white
                            : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              if (message.isFromUser) const SizedBox(width: 40), // indent
            ],
          ),

          // Render Interactive Cards based on type
          if (message.type == 'ride_card' && message.data != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 48),
              child: _buildRideCard(message.data!),
            ),

          if (message.type == 'food_card' && message.data != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 48),
              child: _buildFoodCard(message.data!),
            ),

          if (message.type == 'stats_card' && message.data != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 48),
              child: _buildStatsCard(message.data!),
            ),
        ],
      ),
    );
  }

  // --- Specialized Renderers for Agent Actions ---

  Widget _buildStatsCard(Map<String, dynamic> data) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Báo cáo Doanh Thu',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimelineRow(
            'Doanh thu',
            data['revenue'] ?? '0đ',
            isLast: false,
          ),
          _buildTimelineRow(
            'Số lượng đơn',
            '${data['orders'] ?? 0} đơn',
            isLast: false,
          ),
          _buildTimelineRow(
            'Mức Tăng trưởng',
            data['growth'] ?? '0%',
            isLast: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['insight'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> data) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lộ trình đề xuất',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimelineRow(
            'Điểm đón',
            data['pickup'] ?? 'Trống',
            isLast: false,
          ),
          _buildTimelineRow(
            'Điểm đến',
            data['dropoff'] ?? 'Trống',
            isLast: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Handoff to Real Core Ride System [Priority 45]
                final dropoff = data['dropoff'];
                final pickup = data['pickup'];
                final realPickup =
                    (pickup != null && pickup != 'Vị trí hiện tại')
                    ? pickup
                    : null;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RideScreen(
                      initialDestination: dropoff,
                      initialPickup: realPickup,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE724C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tiếp tục đặt xe'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(
    String title,
    String subtitle, {
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isLast ? const Color(0xFFFE724C) : Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 20, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(subtitle, style: const TextStyle(fontSize: 14)),
              if (!isLast) const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> data) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: Color(0xFFFE724C)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['restaurantName'] ?? 'Cửa hàng',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data['items'] != null)
            ...(data['items'] as List).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '1x ${item['name'] ?? ''}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['price'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng:', style: TextStyle(color: Colors.grey)),
              Text(
                data['total'] ?? '...',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFFE724C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã thêm vào giỏ hàng!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE724C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Thanh toán ngay'),
            ),
          ),
        ],
      ),
    );
  }

  // --- Input Field ---

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFieldFocus,
                      decoration: const InputDecoration(
                        hintText: 'Hỏi hoặc yêu cầu gì đó...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: _sendChatMessage,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : Colors.grey,
                    ),
                    onPressed: _loading ? null : _listen,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _loading
                ? null
                : () {
                    // Nếu đang nghe mà bấm gửi thì dừng nghe và gửi luôn
                    if (_isListening) {
                      _speech.stop();
                      setState(() => _isListening = false);
                    }
                    _sendChatMessage(_textController.text);
                  },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFE724C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
