import 'package:flutter/material.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  body: Container(
    width: double.infinity,
    height: double.infinity,
    color: const Color(0xFFE8EFCF), // 👈 พื้นหลังสีที่ต้องการ
    child: SafeArea(
          // 1. ใส่ ScrollView เพื่อให้หน้าจอเลื่อนได้ถ้าเครื่องมีขนาดเล็ก กันแอปเด้ง
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 80), // ปรับระยะห่างด้านบนให้สมดุลขึ้น
                  
                  // Welcome text
                  const Text(
                    'ยินดีต้อนรับเข้าสู่',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // CleanGoal app name
                  const Text(
                    'CleanGoal',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w700, // ปรับให้หนาขึ้นนิดนึงดูเด่นขึ้น
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 33),
                  
                  // Transformation image
                  Container(
                    width: 219,
                    height: 212,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: const DecorationImage(
                        // หมายเหตุ: ถ้าภาพไม่ขึ้น แนะนำให้เปลี่ยนเป็น AssetImage ที่อยู่ในเครื่อง
                        image: NetworkImage(
                          'https://api.builder.io/api/v1/image/assets/TEMP/cbddba9ea704f1b9f5a791dd788f9759f828f206?width=438',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50), // เพิ่มระยะห่างก่อนถึงปุ่ม
                  
                  // --- ส่วนที่แก้ไขปัญหา Overflow ---
                  Container(
                    // 2. แก้ไข: เพิ่มความกว้างจาก 255 เป็น 340 เพื่อให้ข้อความพอดี
                    width: 340, 
                    height: 55, // เพิ่มความสูงอีกนิดให้กดง่าย
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C6414),
                      borderRadius: BorderRadius.circular(30), // ปรับขอบมนให้สวยงาม (ลบออกได้ถ้าชอบเหลี่ยม)
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30), // ต้องตรงกับด้านบน
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            // 3. แก้ไข: จัดกึ่งกลางเนื้อหา
                            mainAxisAlignment: MainAxisAlignment.center, 
                            children: const [
                              Text(
                                'เข้าสู่ระบบ/สร้างบัญชีใหม่',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20, 
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 50), // พื้นที่ด้านล่างเผื่อไว้
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
