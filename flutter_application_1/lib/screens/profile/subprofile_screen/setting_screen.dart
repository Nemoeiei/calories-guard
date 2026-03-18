import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      appBar: AppBar(
        title: const Text('ตั้งค่า', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFF4C6414),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text(
          'หน้าตั้งค่ากำลังอยู่ในช่วงพัฒนา',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
