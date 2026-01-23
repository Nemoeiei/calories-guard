import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ 1. เพิ่ม import riverpod
import '../../providers/user_data_provider.dart'; // ✅ 2. import provider

// sub-screens imports
import 'subprofile_screen/progress_screen.dart';
import 'subprofile_screen/edit_profile_screen.dart';
import 'subprofile_screen/unit_settings_screen.dart';
import 'subprofile_screen/setting_screen.dart'; 
import 'subprofile_screen/article_screen.dart'; 

import '/login_register/screens/goal_selection_screen.dart';
import '/login_register/screens/activity_level_screen.dart';

// ✅ 3. เปลี่ยนจาก StatelessWidget เป็น ConsumerWidget
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  final Color borderColor = const Color(0xFF4C6414);

  @override
  Widget build(BuildContext context, WidgetRef ref) { // ✅ 4. เพิ่ม WidgetRef ref
    
    // ✅ 5. ดึงข้อมูล User จาก Provider
    final userData = ref.watch(userDataProvider);

    // ✅ 6. Logic คำนวณวันที่เหลือ
    String daysLeftText = "0";
    if (userData.targetDate != null) {
      final now = DateTime.now();
      // เอาแค่วันที่ (ตัดเวลาทิ้ง) เพื่อความแม่นยำ
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(userData.targetDate!.year, userData.targetDate!.month, userData.targetDate!.day);
      
      final difference = target.difference(today).inDays;
      
      // ถ้าวันเป้าหมายผ่านไปแล้ว ให้เป็น 0 หรือติดลบตามต้องการ
      daysLeftText = difference > 0 ? difference.toString() : "0";
    }

    // แปลงเป้าหมายเป็นข้อความ (optional)
    String goalText = "ลดน้ำหนัก";
    Color goalColor = Colors.red; // Default: ลดน้ำหนัก = แดง

    if (userData.goal == GoalOption.maintainWeight) {
      goalText = "รักษาน้ำหนัก";
      goalColor = Colors.blue; // รักษาน้ำหนัก = น้ำเงิน
    } else if (userData.goal == GoalOption.buildMuscle) {
      goalText = "เพิ่มกล้ามเนื้อ";
      // ใช้ Colors.amber[700] หรือรหัสสีส้มเหลือง เพื่อให้อ่านออกบนพื้นขาว
      goalColor = const Color(0xFFFBC02D); // เหลืองเข้ม
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 37), 

              // --- 1. Header ---
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 40),
                      child: Text(
                        'โปรไฟล์ส่วนตัว',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w400, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- 2. Profile Section ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 121, height: 121,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      image: DecorationImage(image: AssetImage('assets/images/profile/profile.png'), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData.name, // ✅ ใช้ชื่อจริง
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'อายุ ${userData.age} • สูง ${userData.height.toInt()} ซม.', // ✅ ใช้ข้อมูลจริง
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w200, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: borderColor, width: 1),
  ),
  child: Text(
        'เป้าหมาย: $goalText',
        style: TextStyle( // ⚠️ ลบ const ตรงนี้ออก
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: goalColor, // หรือจะเปลี่ยนสีตามเป้าหมายก็ได้
    ),
  ),
),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // --- 3. Stats Card ---
              Container(
                height: 103,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('${userData.weight.toInt()}', 'น้ำหนักปัจจุบัน', const Color(0xFF47DB67)), // ✅ ใช้ข้อมูลจริง
                    _buildVerticalDivider(),
                    _buildStatItem('${userData.targetWeight.toInt()}', 'เป้าหมาย', const Color(0xFFB74D4D)), // ✅ ใช้ข้อมูลจริง
                    _buildVerticalDivider(),
                    _buildStatItem(daysLeftText, 'วันที่เหลือ', const Color(0xFF344CE6)), // ✅ ใช้วันที่คำนวณได้
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --- 4. Menu Group 1: ข้อมูลส่วนตัว ---
              const Text('ข้อมูลส่วนตัว', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF6E6A6A))),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(Icons.edit, 'แก้ไขโปรไฟล์', showDivider: true, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                    }),
                    
                    _buildMenuItem(Icons.flag, 'เเก้ไขเป้าหมาย', showDivider: true, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalSelectionScreen()));
                    }),

                    _buildMenuItem(Icons.directions_run, 'เเก้ไขกิจกรรม', showDivider: true, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityLevelScreen(isEditing: true))); // ✅ ใส่ isEditing: true
                    }),
                    
                    _buildMenuItem(Icons.settings, 'ตั้งค่า', showDivider: false, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- 5. Menu Group 2: การแสดงผลข้อมูล ---
              const Text('การเเสดงผลข้อมูล', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF6E6A6A))),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(Icons.sync, 'ยูนิต', showDivider: true, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const UnitSettingsScreen()));
                    }),
                    _buildMenuItem(Icons.bar_chart, 'ความคืบหน้า', showDivider: true, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgressScreen()));
                    }),
                    _buildMenuItem(Icons.pie_chart, 'เป้าหมายแคลอรี่และสารอาหารหลัก', showDivider: true),
                    _buildMenuItem(Icons.article, 'บทความ', showDivider: false, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ArticleScreen()));
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildStatItem(String value, String label, Color valueColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w400, color: valueColor)),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w100, color: Colors.black)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 40, color: borderColor);
  }

  Widget _buildMenuItem(IconData icon, String title, {required bool showDivider, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Container(width: 30, height: 30, child: Icon(icon, color: Colors.black, size: 26)),
          title: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
          onTap: onTap,
        ),
        if (showDivider) Divider(height: 1, color: borderColor, indent: 20, endIndent: 20),
      ],
    );
  }
}