  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'login_register/screens/welcome_screen.dart';
  import 'services/notification_helper.dart'; // ✅ อย่าลืม import ไฟล์ที่สร้างเมื่อกี้

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // แสดง UI ทันที ไม่บล็อกด้วยการแจ้งเตือน (เลี่ยงค้างที่หน้าโลโก้บนบางเครื่อง)
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // เริ่มต้นและตั้งเวลาแจ้งเตือนในพื้นหลัง
    NotificationHelper.init().then((_) async {
      await NotificationHelper.scheduleMealReminders();
      await NotificationHelper.scheduleDailyRecap();
      await NotificationHelper.scheduleMorningMotivation();
    });
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'CalorieGuard',
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