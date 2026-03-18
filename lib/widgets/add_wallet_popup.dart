import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/wallet_model.dart';
import '../models/recurring_rule_model.dart';

class AddWalletPopup extends StatefulWidget {
  const AddWalletPopup({Key? key}) : super(key: key);

  @override
  State<AddWalletPopup> createState() => _AddWalletPopupState();
}

class _AddWalletPopupState extends State<AddWalletPopup> {
  final _nameCtrl    = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _noteCtrl    = TextEditingController();
  final _budgetCtrl  = TextEditingController();
  final _lowBalCtrl  = TextEditingController();

  String _selectedEmoji = '💰';
  double _alertPercent  = 80;
  bool   _showBudget    = false;
  bool   _showRecurring = false;

  // recurring fields
  final _rLabelCtrl  = TextEditingController();
  final _rAmountCtrl = TextEditingController();
  String _rFreq      = 'monthly';
  int    _rDay       = 25;
  String _rCategory  = 'เงินเดือน';

  final List<String> _emojiList = [
    '💰','👛','💳','🏦','💵','🪙','💎','🛒','🏠','🚗','✈️','🎮','📱','🎓','💊','🍜',
  ];
  static const _rCategories = ['เงินเดือน','โบนัส','ธุรกิจ','ค่าเช่า','เบี้ยประกัน','อื่นๆ'];
  static const _weekdays    = {1:'จันทร์',2:'อังคาร',3:'พุธ',4:'พฤหัส',5:'ศุกร์',6:'เสาร์',7:'อาทิตย์'};

  @override
  void dispose() {
    _nameCtrl.dispose(); _balanceCtrl.dispose(); _noteCtrl.dispose();
    _budgetCtrl.dispose(); _lowBalCtrl.dispose();
    _rLabelCtrl.dispose(); _rAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    final name = _nameCtrl.text.trim();
    final balText = _balanceCtrl.text.trim();
    if (name.isEmpty || balText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อกระเป๋าและเงินตั้งต้นให้ครบ')),
      );
      return;
    }
    // validate recurring ถ้าเปิดไว้
    if (_showRecurring) {
      if (_rLabelCtrl.text.trim().isEmpty || double.tryParse(_rAmountCtrl.text.trim()) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกชื่อและจำนวนเงินรายรับประจำให้ครบ')),
        );
        return;
      }
    }

    final balance = double.tryParse(balText) ?? 0.0;
    final budget  = double.tryParse(_budgetCtrl.text.trim());
    final lowBal  = double.tryParse(_lowBalCtrl.text.trim());

    final newWallet = Wallet(
      name:                name,
      emojiIcon:           _selectedEmoji,
      initialBalance:      balance,
      note:                _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      monthlyBudget:       _showBudget ? budget : null,
      alertPercent:        _showBudget && budget != null ? _alertPercent : null,
      lowBalanceThreshold: _showBudget ? lowBal : null,
    );

    final finance = Provider.of<FinanceProvider>(context, listen: false);
    await finance.addWallet(newWallet);

    // เพิ่ม recurring rule ถ้าตั้งไว้
    if (_showRecurring) {
      final walletId = finance.wallets.last.id!;
      final rule = RecurringRule(
        walletId: walletId,
        label:    _rLabelCtrl.text.trim(),
        amount:   double.parse(_rAmountCtrl.text.trim()),
        category: _rCategory,
        frequency: _rFreq,
        dayValue: _rDay,
      );
      await finance.addRecurringRule(rule);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            const SizedBox(height: 16),
            const Text('เพิ่มกระเป๋าตัง',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Emoji picker
            GestureDetector(
              onTap: () => _showEmojiPicker(context),
              child: Stack(alignment: Alignment.bottomRight, children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(_selectedEmoji, style: const TextStyle(fontSize: 30)),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, size: 12, color: Colors.white),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            Text('แตะเพื่อเปลี่ยน', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 16),

            _field(_nameCtrl, 'ชื่อกระเป๋า *', hint: 'เช่น เงินสด, บัญชีธนาคาร',
                icon: Icons.wallet_outlined),
            const SizedBox(height: 12),
            _field(_balanceCtrl, 'ยอดเงินตั้งต้น *', prefix: '฿ ', keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _field(_noteCtrl, 'บันทึกช่วยจำ (ไม่บังคับ)', icon: Icons.notes_outlined),
            const SizedBox(height: 16),

            // ── Toggle: งบประมาณ ──────────────────────
            _toggleSection(
              icon: Icons.add_chart_outlined,
              label: 'ตั้งงบประมาณรายเดือน',
              isOpen: _showBudget,
              onTap: () => setState(() => _showBudget = !_showBudget),
            ),
            if (_showBudget) ...[
              const SizedBox(height: 12),
              _budgetPanel(),
            ],
            const SizedBox(height: 12),

            // ── Toggle: รายรับประจำ ───────────────────
            _toggleSection(
              icon: Icons.repeat,
              label: 'ตั้งรายรับประจำ',
              isOpen: _showRecurring,
              color: Colors.green,
              onTap: () => setState(() => _showRecurring = !_showRecurring),
            ),
            if (_showRecurring) ...[
              const SizedBox(height: 12),
              _recurringPanel(),
            ],
            const SizedBox(height: 24),

            // ── ปุ่มสร้าง ─────────────────────────────
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _saveWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('สร้างกระเป๋า',
                    style: TextStyle(fontSize: 17, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Budget panel ────────────────────────────────────
  Widget _budgetPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _field(_budgetCtrl, 'งบรายจ่ายต่อเดือน', prefix: '฿ ', suffix: '/ เดือน',
            keyboard: TextInputType.number, filled: true),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('แจ้งเตือนเมื่อใช้ถึง',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _alertColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${_alertPercent.toStringAsFixed(0)}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: _alertColor())),
          ),
        ]),
        Slider(
          value: _alertPercent, min: 50, max: 100, divisions: 10,
          activeColor: _alertColor(),
          label: '${_alertPercent.toStringAsFixed(0)}%',
          onChanged: (v) => setState(() => _alertPercent = v),
        ),
        const SizedBox(height: 8),
        _field(_lowBalCtrl, 'แจ้งเตือนเมื่อเหลือต่ำกว่า',
            hint: 'เช่น 500 (ว่าง = ไม่แจ้งเตือน)', prefix: '฿ ',
            keyboard: TextInputType.number, filled: true),
      ]),
    );
  }

  // ── Recurring panel ─────────────────────────────────
  Widget _recurringPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _field(_rLabelCtrl, 'ชื่อรายรับ *', hint: 'เช่น เงินเดือน, ค่าเช่า',
            filled: true, fillColor: Colors.white),
        const SizedBox(height: 12),
        _field(_rAmountCtrl, 'จำนวนเงิน *', prefix: '฿ ',
            keyboard: TextInputType.number, filled: true, fillColor: Colors.white),
        const SizedBox(height: 14),

        // หมวดหมู่
        const Text('หมวดหมู่', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: _rCategories.map((cat) {
          final sel = _rCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _rCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? Colors.green.shade100 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? Colors.green.shade300 : Colors.grey.shade300),
              ),
              child: Text(cat, style: TextStyle(fontSize: 12,
                  color: sel ? Colors.green.shade800 : Colors.grey.shade700,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList()),
        const SizedBox(height: 14),

        // ความถี่
        const Text('ความถี่', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(children: [
          _freqBtn('รายเดือน', 'monthly'),
          const SizedBox(width: 8),
          _freqBtn('รายสัปดาห์', 'weekly'),
          const SizedBox(width: 8),
          _freqBtn('ทุกวัน', 'daily'),
        ]),
        const SizedBox(height: 14),

        // วันที่
        if (_rFreq == 'monthly') ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('วันที่เงินเข้า',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('วันที่ $_rDay',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 12)),
            ),
          ]),
          Slider(
            value: _rDay.toDouble(), min: 1, max: 31, divisions: 30,
            activeColor: Colors.green,
            label: 'วันที่ $_rDay',
            onChanged: (v) => setState(() => _rDay = v.round()),
          ),
        ] else if (_rFreq == 'weekly') ...[
          const Text('วันในสัปดาห์', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: _weekdays.entries.map((e) {
            final sel = _rDay == e.key;
            return GestureDetector(
              onTap: () => setState(() => _rDay = e.key),
              child: Container(
                width: 38, height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? Colors.green.shade100 : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? Colors.green.shade300 : Colors.grey.shade300),
                ),
                child: Text(e.value.substring(0, 1),
                    style: TextStyle(fontSize: 12,
                        color: sel ? Colors.green.shade800 : Colors.grey.shade700,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          }).toList()),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.info_outline, size: 14, color: Colors.green.shade700),
              const SizedBox(width: 6),
              Text('เงินจะเข้าทุกวันที่เปิดแอป',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Helpers ─────────────────────────────────────────
  Widget _handle() => Container(
    width: 40, height: 4,
    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
  );

  Widget _field(TextEditingController ctrl, String label,
      {String? hint, String? prefix, String? suffix,
       IconData? icon, TextInputType? keyboard,
       bool filled = false, Color? fillColor}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        suffixText: suffix,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: filled,
        fillColor: fillColor ?? Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: filled ? BorderSide.none : const BorderSide(),
        ),
      ),
    );
  }

  Widget _toggleSection({
    required IconData icon,
    required String label,
    required bool isOpen,
    required VoidCallback onTap,
    Color color = Colors.blueAccent,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isOpen ? color.withOpacity(0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isOpen ? color.withOpacity(0.4) : Colors.grey.shade300),
        ),
        child: Row(children: [
          Icon(icon, color: isOpen ? color : Colors.grey, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: TextStyle(fontWeight: FontWeight.w600,
                  color: isOpen ? color : Colors.grey.shade700))),
          Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: isOpen ? color : Colors.grey),
        ]),
      ),
    );
  }

  Widget _freqBtn(String label, String value) {
    final sel = _rFreq == value;
    return GestureDetector(
      onTap: () => setState(() {
        _rFreq = value;
        _rDay  = value == 'monthly' ? 25 : value == 'weekly' ? 1 : 0;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? Colors.green.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? Colors.green.shade300 : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(fontSize: 12,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            color: sel ? Colors.green.shade800 : Colors.grey.shade700)),
      ),
    );
  }

  Color _alertColor() {
    if (_alertPercent >= 90) return Colors.red;
    if (_alertPercent >= 70) return Colors.orange;
    return Colors.green;
  }

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('เลือกไอคอน',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: _emojiList.map((e) {
              final sel = e == _selectedEmoji;
              return GestureDetector(
                onTap: () { setState(() => _selectedEmoji = e); Navigator.pop(context); },
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: sel ? Colors.blue.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: sel ? Border.all(color: Colors.blueAccent, width: 2) : null,
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 26))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}
