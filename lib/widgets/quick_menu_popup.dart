import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../providers/finance_provider.dart';
import '../providers/user_provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class QuickMenuPopup extends StatefulWidget {
  const QuickMenuPopup({Key? key}) : super(key: key);

  @override
  State<QuickMenuPopup> createState() => _QuickMenuPopupState();
}

class _QuickMenuPopupState extends State<QuickMenuPopup> {
  bool _isIncome = false;
  int? _selectedWalletId;
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  CategoryItem? _selectedCategory;
  bool _isScanning = false;
  String? _scannedImagePath; // ✅ เก็บ path รูปสลิปที่สแกน

  // ── Scan Slip ────────────────────────────────────────
  Future<void> _scanSlip(ImageSource source) async {
    setState(() => _isScanning = true);
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: source, imageQuality: 90);
      if (xFile == null) { setState(() => _isScanning = false); return; }

      final inputImage = InputImage.fromFilePath(xFile.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result     = await recognizer.processImage(inputImage);
      recognizer.close();

      // ── Parse จำนวนเงินจาก OCR text ──────────────────
      final amount = _extractAmount(result.text);
      if (amount != null) {
        setState(() {
          _amountController.text = amount.toStringAsFixed(2);
          _scannedImagePath = xFile.path; // ✅ เก็บรูปไว้แนบ transaction
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สแกนได้ ฿${amount.toStringAsFixed(2)} ✓'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // สแกนไม่เจอตัวเลข แต่ยังเก็บรูปไว้แนบได้
        setState(() => _scannedImagePath = xFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบจำนวนเงินในสลิป กรุณากรอกเอง'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการสแกน')));
    } finally {
      setState(() => _isScanning = false);
    }
  }

  /// ดึงจำนวนเงินจาก OCR text
  /// รองรับหลายรูปแบบ เช่น "1,000.00", "฿500", "จำนวนเงิน 250.00", "THB 1500"
  double? _extractAmount(String text) {
    // Pattern สำหรับจำนวนเงินในสลิปไทย
    final patterns = [
      // "จำนวนเงิน" หรือ "ยอดโอน" ตามด้วยตัวเลข
      RegExp(r'(?:จำนวนเงิน|ยอดโอน|ยอดเงิน|amount|total|transferred?)\s*:?\s*฿?\s*([\d,]+\.?\d*)', caseSensitive: false),
      // THB ตามด้วยตัวเลข
      RegExp(r'THB\s*([\d,]+\.?\d*)', caseSensitive: false),
      // ฿ ตามด้วยตัวเลข
      RegExp(r'฿\s*([\d,]+\.?\d*)'),
      // ตัวเลขที่มี , และ . เช่น 1,500.00
      RegExp(r'\b(\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?)\b'),
      // ตัวเลขทศนิยม 2 ตำแหน่ง เช่น 250.00
      RegExp(r'\b(\d+\.\d{2})\b'),
    ];

    List<double> candidates = [];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        final raw = match.group(1)?.replaceAll(',', '') ?? '';
        final val = double.tryParse(raw);
        if (val != null && val > 0 && val < 10000000) {
          candidates.add(val);
        }
      }
      if (candidates.isNotEmpty) break; // ใช้ pattern แรกที่เจอ
    }

    if (candidates.isEmpty) return null;
    // เลือกค่าที่ใหญ่สุด (มักจะเป็นยอดโอนจริง)
    candidates.sort((a, b) => b.compareTo(a));
    return candidates.first;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final finance  = Provider.of<FinanceProvider>(context, listen: false);
      final userProv = Provider.of<UserProvider>(context, listen: false);

      // ตั้งค่ากระเป๋าแรก
      if (finance.wallets.isNotEmpty) {
        setState(() => _selectedWalletId = finance.wallets.first.id);
      }

      // ตั้งค่า category แรกจาก UserProvider
      final cats = userProv.expenseCategories;
      if (cats.isNotEmpty) {
        setState(() => _selectedCategory = cats.first);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาสร้างกระเป๋าตังก่อนครับ!')));
      return;
    }
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาระบุจำนวนเงิน')));
      return;
    }
    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('จำนวนเงินต้องมากกว่า 0')));
      return;
    }

    // ชื่อหมวดหมู่ที่บันทึก = "emoji ชื่อ" เช่น "🍜 อาหาร"
    final catLabel = _selectedCategory != null
        ? '${_selectedCategory!.emoji} ${_selectedCategory!.name}'
        : 'อื่นๆ';

    final transaction = TransactionItem(
      walletId: _selectedWalletId!,
      type: _isIncome ? 'income' : 'expense',
      amount: amount,
      category: catLabel,
      dateTime: _selectedDate,
      imagePath: _scannedImagePath, // ✅ แนบรูปสลิปที่สแกนไปด้วย
    );

    Provider.of<FinanceProvider>(context, listen: false).addTransaction(transaction);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final finance  = Provider.of<FinanceProvider>(context);
    final userProv = Provider.of<UserProvider>(context);
    final wallets  = finance.wallets;

    // ดึง categories จาก UserProvider ตามประเภทที่เลือก
    final categories = _isIncome
        ? userProv.incomeCategories
        : userProv.expenseCategories;

    // ถ้า category ที่เลือกไม่อยู่ใน list ปัจจุบัน → reset
    if (_selectedCategory != null &&
        !categories.any((c) => c.id == _selectedCategory!.id)) {
      _selectedCategory = categories.isNotEmpty ? categories.first : null;
    }

    // ป้องกันบัค Dropdown wallet
    if (wallets.isNotEmpty && !wallets.any((w) => w.id == _selectedWalletId)) {
      _selectedWalletId = wallets.first.id;
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            const Text('บันทึกรายการ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // 1. เลือกกระเป๋า
            if (wallets.isEmpty)
              const Text('⚠️ กรุณาสร้างกระเป๋าตังก่อนบันทึกรายการ',
                  style: TextStyle(color: Colors.red))
            else
              DropdownButtonFormField<int>(
                value: _selectedWalletId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'เลือกกระเป๋าตัง',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: wallets.map((w) {
                  final bal = finance.getWalletBalance(w.id!);
                  return DropdownMenuItem<int>(
                    value: w.id,
                    child: Text(
                      '${w.emojiIcon} ${w.name} (คงเหลือ: ฿${bal.toStringAsFixed(2)})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedWalletId = val),
              ),
            const SizedBox(height: 15),

            // 2. ประเภท
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_isIncome ? Colors.redAccent : Colors.grey.shade200,
                    foregroundColor: !_isIncome ? Colors.white : Colors.black,
                  ),
                  onPressed: () => setState(() {
                    _isIncome = false;
                    _selectedCategory = userProv.expenseCategories.isNotEmpty
                        ? userProv.expenseCategories.first : null;
                  }),
                  child: const Text('รายจ่าย'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isIncome ? Colors.green : Colors.grey.shade200,
                    foregroundColor: _isIncome ? Colors.white : Colors.black,
                  ),
                  onPressed: () => setState(() {
                    _isIncome = true;
                    _selectedCategory = userProv.incomeCategories.isNotEmpty
                        ? userProv.incomeCategories.first : null;
                  }),
                  child: const Text('รายรับ'),
                ),
              ),
            ]),
            const SizedBox(height: 15),

            // 3. จำนวนเงิน + ปุ่มสแกนสลิป
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '฿ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),

            // ── ปุ่มสแกนสลิป ─────────────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: _isScanning
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text(_isScanning ? 'กำลังสแกน...' : 'สแกนสลิป (กล้อง)',
                      style: const TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blueAccent.shade100),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    foregroundColor: Colors.blueAccent,
                  ),
                  onPressed: _isScanning ? null
                      : () => _scanSlip(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('จากคลัง', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blueAccent.shade100),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    foregroundColor: Colors.blueAccent,
                  ),
                  onPressed: _isScanning ? null
                      : () => _scanSlip(ImageSource.gallery),
                ),
              ),
            ]),

            // ── Preview สลิปที่สแกน ───────────────────────
            if (_scannedImagePath != null) ...[
              const SizedBox(height: 10),
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_scannedImagePath!),
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                // ปุ่มลบรูป
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _scannedImagePath = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ),
                // badge บอกว่าจะแนบไปกับ transaction
                Positioned(
                  bottom: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('📎 จะแนบสลิปนี้ไปด้วย',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 15),

            // 4. หมวดหมู่ (แสดง emoji จาก UserProvider)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('หมวดหมู่', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = _selectedCategory?.id == cat.id;
                return ChoiceChip(
                  // แสดง emoji + ชื่อ
                  label: Text('${cat.emoji} ${cat.name}',
                      style: const TextStyle(fontSize: 13)),
                  selected: isSelected,
                  selectedColor: _isIncome
                      ? Colors.green.shade100 : Colors.red.shade100,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 15),

            // 5. วันที่
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('วันที่: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: const Text('เปลี่ยนวันที่'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 6. ปุ่มยืนยัน
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saveTransaction,
                child: const Text('ยืนยัน',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
