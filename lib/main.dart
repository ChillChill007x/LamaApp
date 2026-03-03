import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/finance_provider.dart';
import 'screens/splash_screen.dart';


void main() {
  runApp(
    // ใช้ MultiProvider เผื่ออนาคตคุณมี Provider ตัวอื่นเพิ่มเข้ามา
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance App',
      debugShowCheckedModeBanner: false, // เอาแถบ Debug สีแดงมุมขวาบนออก
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'iannnnn', // แนะนำให้ใช้ฟอนต์ไทยสวยๆ (ถ้ามี)
      ),
      // กำหนดให้หน้าแรกที่เปิดมาคือ SplashScreen
      home: const SplashScreen(),
    );
  }
}