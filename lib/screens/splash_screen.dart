import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../services/sync_service.dart';
import 'main_layout.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // โหลดข้อมูล local ก่อน
    try {
      await Provider.of<FinanceProvider>(context, listen: false).loadData();
    } catch (e) {
      debugPrint('loadData error: $e');
    }

    // ถ้า login อยู่แล้ว ให้ sync จาก cloud (background)
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      SyncService().pullFromCloud(); // ไม่ await — ทำ background
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Route ตาม auth status
    // ถ้า login อยู่ → MainLayout, ถ้าไม่ → LoginScreen
    if (auth.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/loading.png',
              width: 200, height: 200,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                    child: Text('💰', style: TextStyle(fontSize: 40))),
              ),
            ),
            const SizedBox(height: 20),
            const Text('LMA APP',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent)),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
