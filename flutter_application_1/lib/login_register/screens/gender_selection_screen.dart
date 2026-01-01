import 'package:flutter/material.dart';
import 'personal_info_screen.dart';

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  String? selectedGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFE8EFCF), // 👈 พื้นหลังสีที่ต้องการ
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- ส่วนที่แก้ไข: ปุ่มย้อนกลับ (แทนที่รูปภาพ logo) ---
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 19, top: 12),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 40,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                  ),
                ),
                // ------------------------------------------------

                const SizedBox(height: 24),

                // Title
                const Text(
                  'เลือกเพศของคุณ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 14),

                // Subtitle
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'เพื่อนำไปคำนวณค่า BMR ซึ่งเพศส่งผลต่อระบบเผาผลาญ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 50),

                // Gender Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Female Option
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedGender = 'female';
                          });
                        },
                        child: Container(
                          width: 133,
                          height: 185,
                          decoration: BoxDecoration(
                            color: selectedGender == 'female'
                                ? const Color(0xFF4C6414).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 133,
                                height: 133,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  // image ต้องอยู่ข้างใน BoxDecoration (ก่อนวงเล็บปิด)
                                  image: const DecorationImage(
                                    image: AssetImage(
                                        'assets/images/picture/girl.png'),
                                    fit: BoxFit.cover, // กำหนด fit ตรงนี้
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'หญิง',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Male Option
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedGender = 'male';
                          });
                        },
                        child: Container(
                          width: 133,
                          height: 185,
                          decoration: BoxDecoration(
                            color: selectedGender == 'male'
                                ? const Color(0xFF4C6414).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 133,
                                height: 133,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  // image ต้องอยู่ข้างใน BoxDecoration (ก่อนวงเล็บปิด)
                                  image: const DecorationImage(
                                    image: AssetImage(
                                        'assets/images/picture/boy.png'),
                                    fit: BoxFit.cover, // กำหนด fit ตรงนี้
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'ชาย',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80), // เว้นระยะแทน Spacer

                // Next Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: GestureDetector(
                    onTap: selectedGender != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PersonalInfoScreen(),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      width: 259,
                      height: 54,
                      decoration: BoxDecoration(
                        color: selectedGender != null
                            ? const Color(0xFF4C6414)
                            : const Color(0xFF4C6414).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'ถัดไป',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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
}
