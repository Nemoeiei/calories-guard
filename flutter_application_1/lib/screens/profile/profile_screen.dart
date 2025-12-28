import 'package:flutter/material.dart';
// ตรวจสอบ path import ให้ถูกต้องตามโปรเจกต์ของคุณนะครับ
import 'package:flutter_application_1/screens/profile/subprofile_screen/progress_screen.dart';
import 'package:flutter_application_1/screens/profile/subprofile_screen/edit_profile_screen.dart';
import 'package:flutter_application_1/screens/profile/subprofile_screen/unit_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 37), // Top margin

              // --- 1. Header (ปุ่มย้อนกลับ + ชื่อหน้า) ---
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context); // คำสั่งย้อนกลับ
                    },
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: 40), // จัดกึ่งกลางชดเชยปุ่มซ้าย
                      child: Text(
                        'โปรไฟล์ส่วนตัว',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- 2. Profile Section (รูป + ข้อมูล) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // รูปโปรไฟล์ (วงกลม)
                  Container(
                    width: 121,
                    height: 121,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      image: DecorationImage(
                        image: AssetImage('assets/images/profile/profile.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // ข้อมูลด้านขวา
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'หวาน',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'อายุ 22 • สูง 170 ซม.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w200,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // กล่องเป้าหมาย
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'เป้าหมาย: ลดน้ำหนัก',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // --- 3. Stats Card (น้ำหนัก/เป้าหมาย/วัน) ---
              Container(
                height: 103,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('70', 'น้ำหนักปัจจุบัน',
                        const Color(0xFF47DB67)), // เขียว
                    _buildVerticalDivider(),
                    _buildStatItem(
                        '50', 'เป้าหมาย', const Color(0xFFB74D4D)), // แดง
                    _buildVerticalDivider(),
                    _buildStatItem('54', 'วันที่เหลือ',
                        const Color(0xFF344CE6)), // น้ำเงิน
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --- 4. Menu Group 1: ข้อมูลส่วนตัว ---
              const Text(
                'ข้อมูลส่วนตัว',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF6E6A6A),
                ),
              ),
              const SizedBox(height: 10),

              // กล่องเมนู 1
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      Icons.edit,
                      'แก้ไขโปรไฟล์',
                      showDivider: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EditProfileScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(Icons.flag, 'เป้าหมาย', showDivider: true),
                    _buildMenuItem(Icons.directions_run, 'กิจกรรม',
                        showDivider: false),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- 5. Menu Group 2: การแสดงผลข้อมูล ---
              const Text(
                'การเเสดงผลข้อมูล',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF6E6A6A),
                ),
              ),
              const SizedBox(height: 10),

              // กล่องเมนู 2
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      Icons.sync,
                      'ยูนิต',
                      showDivider: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const UnitSettingsScreen()),
                        );
                      },
                    ),

                    // --- แก้ไขจุดนี้: ใส่ onTap เพื่อลิ้งค์ไปหน้า ProgressScreen ---
                    _buildMenuItem(
                      Icons.bar_chart,
                      'ความคืบหน้า',
                      showDivider: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProgressScreen()),
                        );
                      },
                    ),
                    // --------------------------------------------------------

                    _buildMenuItem(
                        Icons.pie_chart, 'เป้าหมายแคลอรี่และสารอาหารหลัก',
                        showDivider: false),
                  ],
                ),
              ),

              const SizedBox(height: 40), // Bottom padding
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
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w100,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.black,
    );
  }

  // --- แก้ไขฟังก์ชันนี้: เพิ่มตัวรับค่า onTap ---
  Widget _buildMenuItem(IconData icon, String title,
      {required bool showDivider, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 30,
            height: 30,
            child: Icon(icon, color: Colors.black, size: 26),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios,
              size: 16, color: Colors.black),
          onTap: onTap, // นำค่าที่รับมาใส่ตรงนี้
        ),
        if (showDivider)
          const Divider(
              height: 1, color: Colors.black, indent: 20, endIndent: 20),
      ],
    );
  }
}
