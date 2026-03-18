import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/user_provider.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../widgets/add_wallet_popup.dart';
import '../widgets/custom_calendar.dart';
import '../widgets/wallet_detail_popup.dart';
import 'settings_screen.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, child) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,

            // ── ชื่อ + รูปโปรไฟล์ (กดได้ → Settings) ──────
            title: Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final profile = userProvider.profile;
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: profile.avatarPath != null
                            ? FileImage(File(profile.avatarPath!)) as ImageProvider
                            : null,
                        child: profile.avatarPath == null
                            ? Text(
                                profile.displayName.isNotEmpty
                                    ? profile.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(profile.displayName,
                          style: const TextStyle(
                              color: Colors.black87, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_right,
                          size: 18, color: Colors.grey.shade400),
                    ],
                  ),
                );
              },
            ),

            // ── ปุ่มฟันเฟือง มุมขวาบน ─────────────────────
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.black54),
                tooltip: 'ตั้งค่า',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
              const SizedBox(width: 4),
            ],
          ),

          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildWalletList(context, finance),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(finance),
                      const SizedBox(height: 20),
                      _buildBudgetOverview(finance),
                      const CustomCalendar(),
                      const SizedBox(height: 20),
                      const Text('รายการล่าสุด',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildRecentTransactions(context, finance),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────
  // Wallet chips
  // ──────────────────────────────────────────────────────
  Widget _buildWalletList(BuildContext context, FinanceProvider finance) {
    final wallets = finance.wallets;
    return SizedBox(
      height: 66,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: wallets.length + 1,
        itemBuilder: (context, index) {
          // ปุ่ม +
          if (index == wallets.length) {
            return GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => AddWalletPopup(),
              ),
              child: Container(
                width: 70,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                    color: Colors.grey[300], borderRadius: BorderRadius.circular(30)),
                child: const Center(
                    child: Icon(Icons.add, color: Colors.blueGrey, size: 28)),
              ),
            );
          }

          final wallet = wallets[index];
          final walletId = wallet.id;
          final BudgetStatus status =
              walletId != null ? finance.getBudgetStatus(walletId) : BudgetStatus.none;
          final String badgeText =
              walletId != null ? finance.getBudgetBadgeText(walletId) : '';
          final double balance = walletId != null
              ? finance.getWalletBalance(walletId)
              : wallet.initialBalance;

          Color chipBg, chipBorder, balanceColor;
          Color? dotColor, badgeBg, badgeTextColor;

          switch (status) {
            case BudgetStatus.exceeded:
              chipBg = Colors.red.shade50; chipBorder = Colors.red.shade300;
              dotColor = Colors.red; balanceColor = Colors.red.shade700;
              badgeBg = Colors.red.shade100; badgeTextColor = Colors.red.shade800;
              break;
            case BudgetStatus.warning:
              chipBg = Colors.orange.shade50; chipBorder = Colors.orange.shade300;
              dotColor = Colors.orange; balanceColor = Colors.orange.shade800;
              badgeBg = Colors.orange.shade100; badgeTextColor = Colors.orange.shade900;
              break;
            default:
              chipBg = Colors.grey.shade200; chipBorder = Colors.transparent;
              dotColor = null; balanceColor = Colors.black54;
              badgeBg = null; badgeTextColor = null;
          }

          return GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => WalletDetailPopup(wallet: wallet),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: chipBorder, width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Stack(clipBehavior: Clip.none, children: [
                  Text(wallet.emojiIcon.isNotEmpty ? wallet.emojiIcon : '👛',
                      style: const TextStyle(fontSize: 22)),
                  if (dotColor != null)
                    Positioned(
                      top: -3, right: -5,
                      child: Container(
                        width: 11, height: 11,
                        decoration: BoxDecoration(
                          color: dotColor, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(wallet.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      if (badgeText.isNotEmpty && badgeBg != null) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                              color: badgeBg, borderRadius: BorderRadius.circular(8)),
                          child: Text(badgeText,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: badgeTextColor)),
                        ),
                      ],
                    ]),
                    Text('${balance.toStringAsFixed(2)} บาท',
                        style: TextStyle(fontSize: 11, color: balanceColor)),
                  ],
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Budget overview
  // ──────────────────────────────────────────────────────
  Widget _buildBudgetOverview(FinanceProvider finance) {
    final budgetWallets = finance.wallets
        .where((w) => w.monthlyBudget != null && w.id != null)
        .toList();
    if (budgetWallets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('งบประมาณเดือนนี้',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...budgetWallets.map((wallet) {
          final spent  = finance.getMonthlyExpenseByWallet(wallet.id!);
          final budget = wallet.monthlyBudget!;
          final ratio  = finance.getBudgetUsageRatio(wallet.id!).clamp(0.0, 1.0);
          final status = finance.getBudgetStatus(wallet.id!);
          Color barColor;
          switch (status) {
            case BudgetStatus.exceeded: barColor = Colors.red; break;
            case BudgetStatus.warning:  barColor = Colors.orange; break;
            default: barColor = Colors.green;
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5, spreadRadius: 1)],
            ),
            child: Column(children: [
              Row(children: [
                Text(wallet.emojiIcon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(child: Text(wallet.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                Text('฿${spent.toStringAsFixed(0)} / ฿${budget.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 13, color: barColor, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio, minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('ใช้ไป ${(ratio * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(
                  budget - spent >= 0
                      ? 'เหลือ ฿${(budget - spent).toStringAsFixed(0)}'
                      : 'เกิน ฿${(spent - budget).toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: budget - spent >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ]),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }

  // ──────────────────────────────────────────────────────
  // Summary cards
  // ──────────────────────────────────────────────────────
  Widget _buildSummaryCards(FinanceProvider finance) {
    return Column(children: [
      Row(children: [
        Expanded(child: _buildCard('รอบเดือน', finance.monthlyExpense, Colors.orange)),
        const SizedBox(width: 10),
        Expanded(child: _buildCard('รายวัน', finance.dailyExpense, Colors.redAccent)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _buildCard('รายรับรวม', finance.totalIncomeMonth, Colors.green)),
        const SizedBox(width: 10),
        Expanded(child: _buildCard('คงเหลือ', finance.totalBalance, Colors.blueAccent)),
      ]),
    ]);
  }

  Widget _buildCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5, spreadRadius: 1)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Text('฿${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  // ──────────────────────────────────────────────────────
  // Recent transactions (แสดงชื่อกระเป๋า)
  // ──────────────────────────────────────────────────────
  Widget _buildRecentTransactions(BuildContext context, FinanceProvider finance) {
    final transactions = finance.transactions;
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('ยังไม่มีรายการ', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    final count = transactions.length > 5 ? 5 : transactions.length;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isIncome = tx.type == 'income';
        final wallet = finance.wallets.firstWhere(
          (w) => w.id == tx.walletId,
          orElse: () => Wallet(id: 0, name: 'ไม่ทราบ', emojiIcon: '👛', initialBalance: 0),
        );
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.category,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${tx.dateTime.day}/${tx.dateTime.month}/${tx.dateTime.year}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text(wallet.emojiIcon.isNotEmpty ? wallet.emojiIcon : '👛',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(wallet.name,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ]),
                ],
              )),
              Text(
                '${isIncome ? '+' : '-'} ฿${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15,
                    color: isIncome ? Colors.green : Colors.red),
              ),
            ]),
          ),
        );
      },
    );
  }
}
