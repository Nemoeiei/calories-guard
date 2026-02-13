  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'login_register/screens/welcome_screen.dart';
  import 'services/notification_helper.dart'; // ✅ อย่าลืม import ไฟล์ที่สร้างเมื่อกี้

  void main() async { // ✅ 1. เพิ่ม async
    // ✅ 2. ต้องมีบรรทัดนี้เสมอถ้าใช้ Plugin (แจ้งเตือน) ก่อน runApp
    WidgetsFlutterBinding.ensureInitialized();

    // ✅ 3. เริ่มต้นระบบแจ้งเตือน
    await NotificationHelper.init();

    // ✅ 4. สั่งตั้งเวลาเตือนล่วงหน้า (เช้า/เที่ยง/เย็น/ค่ำ)
    // เรียกตรงนี้เลย พอเปิดแอปปุ๊บ ระบบจะจำเวลาเตือนไว้ตลอดไป
    await NotificationHelper.scheduleMealReminders();
    await NotificationHelper.scheduleDailyRecap();
    await NotificationHelper.scheduleMorningMotivation();

    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'CleanGoal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4C6414)),
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        home: const WelcomeScreen(),
      );
    }
  }