import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/user_provider.dart';
import '../services/sync_service.dart';
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isLoading = false;

  final _loginEmailCtrl    = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  bool _loginObscure = true;

  final _regNameCtrl     = TextEditingController();
  final _regEmailCtrl    = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regConfirmCtrl  = TextEditingController();
  bool _regObscure = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmailCtrl.dispose(); _loginPasswordCtrl.dispose();
    _regNameCtrl.dispose(); _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose(); _regConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmailCtrl.text.isEmpty || _loginPasswordCtrl.text.isEmpty) {
      _showError('กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      email: _loginEmailCtrl.text,
      password: _loginPasswordCtrl.text,
    );
    if (!mounted) return;
    if (success) {
      await _onLoginSuccess();
    } else {
      setState(() => _isLoading = false);
      _showError(auth.errorMessage ?? 'เข้าสู่ระบบไม่สำเร็จ');
    }
  }

  Future<void> _register() async {
    if (_regNameCtrl.text.isEmpty || _regEmailCtrl.text.isEmpty ||
        _regPasswordCtrl.text.isEmpty) {
      _showError('กรุณากรอกข้อมูลให้ครบ');
      return;
    }
    if (_regPasswordCtrl.text != _regConfirmCtrl.text) {
      _showError('รหัสผ่านไม่ตรงกัน');
      return;
    }
    if (_regPasswordCtrl.text.length < 6) {
      _showError('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
      return;
    }
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      email: _regEmailCtrl.text,
      password: _regPasswordCtrl.text,
      displayName: _regNameCtrl.text,
    );
    if (!mounted) return;
    if (success) {
      await Provider.of<UserProvider>(context, listen: false)
          .updateDisplayName(_regNameCtrl.text);
      await _onLoginSuccess();
    } else {
      setState(() => _isLoading = false);
      _showError(auth.errorMessage ?? 'สมัครสมาชิกไม่สำเร็จ');
    }
  }

  /// ✅ ไม่ต้อง clear/push แล้ว เพราะ DB แยกตาม userId
  Future<void> _onLoginSuccess() async {
    final finance  = Provider.of<FinanceProvider>(context, listen: false);
    final userProv = Provider.of<UserProvider>(context, listen: false);

    // 1. Pull ข้อมูลจาก cloud (insert เข้า DB โดยใช้ uid ใหม่อัตโนมัติ)
    await SyncService().pullFromCloud();

    // 2. โหลดข้อมูล finance (กรองเฉพาะ uid ที่ login)
    await finance.loadData();

    // 3. โหลด profile
    await userProv.load();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainLayout()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade400));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(children: [
                // ส่วนของ Container ที่เคยเป็น Emoji
              Container(
                width: 72, 
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
              // เปลี่ยนจาก Center(child: Text(...)) เป็น Image.asset
              child: ClipRRect( // ใช้ ClipRRect เพื่อให้รูปโค้งตาม Container
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo_lama.png', // ใส่ path รูปของคุณตรงนี้
                  fit: BoxFit.cover,
                ),
              ),
            ),
                const SizedBox(height: 16),
                const Text('LMA App',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('บันทึกรายรับ-รายจ่าย จัดการได้ทุกที่',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ]),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                indicator: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                tabs: const [
                  Tab(text: 'เข้าสู่ระบบ'),
                  Tab(text: 'สมัครสมาชิก'),
                ],
              ),
            ),
            const SizedBox(height: 4),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildLoginForm(),
                  _buildRegisterForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _field(_loginEmailCtrl, 'อีเมล',
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _passwordField(_loginPasswordCtrl, 'รหัสผ่าน', _loginObscure,
              () => setState(() => _loginObscure = !_loginObscure)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPassword,
              child: const Text('ลืมรหัสผ่าน?',
                  style: TextStyle(fontSize: 13, color: Colors.blueAccent)),
            ),
          ),
          const SizedBox(height: 8),
          _primaryButton('เข้าสู่ระบบ', _isLoading ? null : _login),
          const SizedBox(height: 16),
          Center(
            child: Text('หรือใช้งานโดยไม่ต้อง sync',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          _outlineButton('ใช้งานแบบ Offline', () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainLayout()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _field(_regNameCtrl, 'ชื่อที่แสดง', icon: Icons.person_outline),
          const SizedBox(height: 14),
          _field(_regEmailCtrl, 'อีเมล',
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _passwordField(_regPasswordCtrl, 'รหัสผ่าน', _regObscure,
              () => setState(() => _regObscure = !_regObscure)),
          const SizedBox(height: 14),
          _passwordField(_regConfirmCtrl, 'ยืนยันรหัสผ่าน', _regObscure,
              () => setState(() => _regObscure = !_regObscure)),
          const SizedBox(height: 24),
          _primaryButton('สมัครสมาชิก', _isLoading ? null : _register),
        ],
      ),
    );
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลืมรหัสผ่าน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ระบบจะส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลของคุณ'),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'อีเมล',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final ok = await auth.resetPassword(emailCtrl.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok
                    ? 'ส่งลิงก์รีเซ็ตรหัสผ่านแล้ว กรุณาตรวจสอบอีเมล'
                    : 'ไม่สามารถส่งอีเมลได้'),
                backgroundColor: ok ? Colors.green : Colors.red,
              ));
            },
            child: const Text('ส่งอีเมล'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {IconData? icon, TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _passwordField(TextEditingController ctrl, String label,
      bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        child: _isLoading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        child: Text(label,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
      ),
    );
  }
}
