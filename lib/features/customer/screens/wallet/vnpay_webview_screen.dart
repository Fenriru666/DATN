import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:datn/features/customer/services/wallet_service.dart';

class VnpayWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  final double amount;

  const VnpayWebviewScreen({
    super.key,
    required this.paymentUrl,
    required this.amount,
  });

  @override
  State<VnpayWebviewScreen> createState() => _VnpayWebviewScreenState();
}

class _VnpayWebviewScreenState extends State<VnpayWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            // Intercept the return URL
            if (url.contains('vnp_ResponseCode=')) {
              _handlePaymentResponse(url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _handlePaymentResponse(String url) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final uri = Uri.parse(url);
    final responseCode = uri.queryParameters['vnp_ResponseCode'];

    // 00 is VNPAY success code
    // 24 is Cancelled
    if (responseCode == '00') {
      try {
        await WalletService().topUp(widget.amount);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nạp tiền thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true indicates success
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi hệ thống khi nạp tiền: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, false);
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giao dịch thất bại hoặc đã bị hủy!'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán VNPAY (Sandbox)')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading || _isProcessing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
