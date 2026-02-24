import 'package:flutter/material.dart';
// ✅ อย่าลืม Import หน้า Login ให้ถูกต้องตาม Path ของคุณ
import '/login_register/screens/login_screen.dart'; 
import 'admin_request_screen.dart'; // Import หน้าดูคำขอ
import 'admin_food_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF), // พื้นหลังสีเขียวอ่อน
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Header (แสดงชื่อ Admin อย่างเดียว)
                const Text(
                  'Admin',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 40),

                // 2. Profile Image
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    // ใส่รูปโปรไฟล์ Admin (ถ้ามี)
                    image: const DecorationImage(
                      image: NetworkImage('https://via.placeholder.com/110'), 
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: const Icon(Icons.person, size: 60, color: Colors.white), // ใส่ไอคอนเผื่อไว้ถ้ารูปไม่โหลด
                ),

                const SizedBox(height: 50),

                // 3. Label "จัดการข้อมูล"
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 15, bottom: 10),
                    child: Text(
                      'จัดการข้อมูล',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color(0xFF6E6A6A),
                      ),
                    ),
                  ),
                ),

                // 4. กล่องเมนู (Menu Box)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4C6414), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // เมนู 1: เพิ่ม/ลดข้อมูล
                      _buildMenuItem(
                        icon: Icons.edit_note,
                        title: 'เพิ่ม/ลดข้อมูล', // หรือเปลี่ยนชื่อเป็น "จัดการเมนูอาหาร"
                        onTap: () {
                          // ✅ 2. ใส่ Navigator ตรงนี้ครับ
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminFoodListScreen()),
                          );
                        },
                      ),
                      
                      // เส้นคั่น
                      const Divider(color: Color(0xFF628141), height: 1, thickness: 1, indent: 15, endIndent: 15),

                      // เมนู 2: ดูคำขอเพิ่มเมนู
                      _buildMenuItem(
                        icon: Icons.assignment_outlined,
                        title: 'ดูคำขอเพิ่มเมนู',
                        onTap: () {
                          // ไปหน้า AdminRequestScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminRequestScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 5. ปุ่มออกจากระบบ
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFBF3B3B),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFBF3B3B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // ออกจากระบบแล้วกลับไปหน้า Login และล้าง stack ทั้งหมด
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget ย่อยสำหรับสร้างรายการเมนู
  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 26),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}