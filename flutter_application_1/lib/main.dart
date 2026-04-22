import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'constants/constants.dart';
import 'login_register/screens/welcome_screen.dart';
import 'services/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

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
    await NotificationHelper.scheduleWaterReminders();
    await NotificationHelper.scheduleWeeklyWeightCheck();
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
