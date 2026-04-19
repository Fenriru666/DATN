import 'package:flutter/material.dart';
import 'package:datn/features/customer/services/wallet_service.dart';
import 'package:datn/core/models/transaction_model.dart';
import 'package:datn/core/utils/ui_helpers.dart';
import 'package:datn/features/customer/screens/wallet/transfer_money_screen.dart';
import 'package:datn/features/customer/screens/wallet/withdraw_screen.dart';
import 'package:datn/features/customer/services/vnpay_service.dart';
import 'package:datn/features/customer/screens/wallet/vnpay_webview_screen.dart';
import 'package:intl/intl.dart';
import 'package:datn/l10n/app_localizations.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );
  final DateFormat _dateFormat = DateFormat('dd MMM, hh:mm a');

  void _showTopUpDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (VNĐ)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amountStr = amountController.text.trim();
              if (amountStr.isEmpty) return;

              final amount = double.tryParse(amountStr);
              if (amount == null || amount <= 0) {
                UIHelpers.showSnackBar(
                  context,
                  'Invalid amount',
                  isError: true,
                );
                return;
              }

              Navigator.pop(ctx); // Close Dialog

              final vnpayService = VnpayService();
              final url = vnpayService.generatePaymentUrl(
                amount: amount,
                description: 'Nap tien vao vi SuperApp',
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      VnpayWebviewScreen(paymentUrl: url, amount: amount),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE724C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.walletTitle,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Digital Card
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFE724C), Color(0xFFFFA183)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFE724C).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.walletTotalBalance,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'VND',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  StreamBuilder<double>(
                    stream: _walletService.walletBalanceStream,
                    builder: (context, snapshot) {
                      final balance = snapshot.data ?? 0.0;
                      return Text(
                        _currencyFormat.format(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SuperApp Pay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 30,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _showTopUpDialog,
                  child: _WalletAction(
                    icon: Icons.add,
                    label: AppLocalizations.of(context)!.walletTopUp,
                    color: Colors.blue,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransferMoneyScreen(),
                      ),
                    );
                  },
                  child: _WalletAction(
                    icon: Icons.swap_horiz,
                    label: AppLocalizations.of(context)!.walletTransfer,
                    color: Colors.purple,
                  ),
                ),
                GestureDetector(
                  onTap: () => UIHelpers.showSnackBar(
                    context,
                    AppLocalizations.of(context)!.featureUnderDev,
                  ),
                  child: _WalletAction(
                    icon: Icons.qr_code_scanner,
                    label: AppLocalizations.of(context)!.walletScanQR,
                    color: Colors.orange,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WithdrawScreen()),
                    );
                  },
                  child: _WalletAction(
                    icon: Icons.arrow_outward,
                    label: AppLocalizations.of(context)!.walletWithdraw,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Transaction History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.walletRecentTransactions,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.walletViewAll,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<TransactionModel>>(
              stream: _walletService.transactionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.walletNoRecentTransactions,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length > 5
                      ? 5
                      : transactions.length, // Show up to 5 recent
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isIncome = tx.amount > 0;
                    final isDarkInner =
                        Theme.of(context).brightness == Brightness.dark;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDarkInner
                                  ? Colors.grey[800]
                                  : (isIncome
                                        ? Colors.green[50]
                                        : Colors.red[50]),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.account_balance_wallet
                                  : Icons.shopping_bag,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.description.isNotEmpty
                                      ? tx.description
                                      : 'Transaction',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDarkInner
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dateFormat.format(tx.createdAt),
                                  style: TextStyle(
                                    color: isDarkInner
                                        ? Colors.grey[400]
                                        : Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            (isIncome ? '+' : '') +
                                _currencyFormat.format(tx.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isIncome ? Colors.green : Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;

  const _WalletAction({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : color[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
