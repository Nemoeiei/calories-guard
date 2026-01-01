import 'package:flutter/material.dart';
// 👇 แก้บรรทัดนี้ให้เป็น path ที่ถูกต้องของไฟล์ WelcomeScreen ในเครื่องคุณ
// ตัวอย่าง: import 'package:flutter_application_1/screens/welcome_screen.dart'; 
import 'package:flutter_application_1/login_register/screens/welcome_screen.dart'; 

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF), // พื้นหลังสีครีมเขียว
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ตั้งค่า',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- Group 1: ทั่วไป ---
            _buildMenuGroup([
              _buildMenuItem('ความเป็นส่วนตัว'),
              _buildMenuItem('การแจ้งเตือน', showDivider: false),
            ], isFirst: true),

            // --- Group 2: การแสดงผล ---
            _buildMenuGroup([
              _buildMenuItem('ภาษา'),
              _buildMenuItem('ธีม', showDivider: false),
            ]),

            // --- Group 3: สนับสนุน ---
            _buildMenuGroup([
              _buildMenuItem('เสนอฟีเจอร์ใหม่'),
              _buildMenuItem('ขอความช่วยเหลือ', showDivider: false),
            ]),

            // --- Group 4: เกี่ยวกับ ---
            _buildMenuGroup([
              _buildMenuItem('ให้คะแนนเรา'),
              _buildMenuItem('เกี่ยวกับ', showDivider: false),
            ]),

            // --- Group 5: บัญชี ---
            _buildMenuGroup([
              _buildMenuItem('เปลี่ยนบัญชี'),
              _buildMenuItem('ลบบัญชี', showDivider: false),
            ]),

            const SizedBox(height: 40),

            // --- ปุ่มออกจากระบบ (สีแดง) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 65),
              child: ElevatedButton(
                onPressed: () {
                  // ✅ สั่งให้ไปหน้า WelcomeScreen และลบประวัติหน้าเก่าทิ้งทั้งหมด
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false, // false = ไม่ให้กด Back กลับมาหน้านี้ได้อีก
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D4D), // สีแดง
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Helper: สร้างกลุ่มเมนู (กล่องขาว + ขอบดำ) ---
  Widget _buildMenuGroup(List<Widget> children, {bool isFirst = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        // กำหนดขอบสีดำ
        border: Border(
          top: isFirst ? const BorderSide(color: Colors.black) : BorderSide.none,
          left: const BorderSide(color: Colors.black),
          right: const BorderSide(color: Colors.black),
          bottom: const BorderSide(color: Colors.black),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // --- Helper: สร้างรายการเมนูย่อย ---
  Widget _buildMenuItem(String title, {bool showDivider = true}) {
    return Container(
      decoration: BoxDecoration(
        // เส้นคั่นระหว่างเมนูย่อย
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: Colors.black, width: 1),
              )
            : null,
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
        onTap: () {
          // ใส่ action เมื่อกดเมนูย่อยอื่นๆ
        },
      ),
    );
  }
}