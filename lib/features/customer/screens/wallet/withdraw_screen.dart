import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:datn/features/customer/services/wallet_service.dart';
import 'package:datn/core/utils/ui_helpers.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _bankController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _walletService = WalletService();
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  bool _isProcessing = false;
  double _currentBalance = 0;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    _walletService.walletBalanceStream.listen((balance) {
      if (mounted) setState(() => _currentBalance = balance);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _processWithdrawal() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final withdrawAmount = double.tryParse(amountText) ?? 0;

    if (withdrawAmount < 50000) {
      UIHelpers.showSnackBar(
        context,
        'Số tiền rút tối thiểu là 50,000 đ',
        isError: true,
      );
      return;
    }

    if (withdrawAmount > _currentBalance) {
      UIHelpers.showSnackBar(
        context,
        'Số dư không đủ để thực hiện giao dịch',
        isError: true,
      );
      return;
    }

    if (_bankController.text.isEmpty || _accountNumberController.text.isEmpty) {
      UIHelpers.showSnackBar(
        context,
        'Vui lòng nhập đầy đủ thông tin ngân hàng thụ hưởng',
        isError: true,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate backend call to process withdrawal
      // We deduct the balance with 'withdraw' reason
      await _walletService.deductBalance(
        withdrawAmount,
        'withdraw',
        'Rút tiền về NH: ${_bankController.text} - ${_accountNumberController.text}',
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text(
              'Thành công',
              style: TextStyle(color: Colors.green),
            ),
            content: const Text(
              'Yêu cầu rút tiền đã được ghi nhận. Quý khách sẽ nhận được tiền trong vòng 24h làm việc.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close screen
                },
                child: const Text('Tuyệt vời'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) UIHelpers.showSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Rút tiền')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  const Text(
                    'Số dư khả dụng',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(_currentBalance),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              "Thông tin rút tiền",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Số tiền cần rút',
                prefixText: 'VND ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _bankController,
              decoration: InputDecoration(
                labelText: 'Tên Ngân hàng (VD: Vietcombank)',
                prefixIcon: const Icon(Icons.account_balance),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tài khoản',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE724C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Xác nhận rút tiền',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
