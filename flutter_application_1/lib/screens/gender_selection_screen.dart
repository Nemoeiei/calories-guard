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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE7DDD1),
              Color(0xFFFFFFFF),
              Color(0xFFE7DDD1),
            ],
            stops: [0.0, 0.5061, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            // 1. ปรับให้ทุกอย่างใน Column จัดกึ่งกลางเเนวนอน
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo (ถ้าอยากให้ Logo อยู่ซ้ายเหมือนเดิม ให้เอา Align ครอบ)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, top: 12),
                  child: Image.network(
                    'https://api.builder.io/api/v1/image/assets/TEMP/63b58034e129f3fabd1182d751daa5314f9c7bcb?width=154',
                    width: 77,
                    height: 73,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
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
                // 2. จัดข้อความให้อยู่กึ่งกลาง
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 14),
              
              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20), // ปรับ padding ให้สมดุลซ้ายขวา
                child: Text(
                  'เพื่อนำไปคำนวณค่า BMR ซึ่งเพศส่งผลต่อระบบเผาผลาญ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  // 3. จัดข้อความยาวๆ ให้อยู่กึ่งกลางเมื่อตัดบรรทัด
                  textAlign: TextAlign.center,
                ),
              ),
              
              // ใช้ Spacer หรือ Flexible แทน SizedBox ขนาดใหญ่ เพื่อให้หน้าจอยืดหยุ่นกับมือถือทุกรุ่น
              const SizedBox(height: 50), 
              
              // Gender Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40), // ปรับระยะห่างด้านข้าง
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // จัดให้อยู่กลาง
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
                        // 4. แก้ Overflow: เพิ่มความสูงจาก 166 เป็น 185
                        height: 185, 
                        decoration: BoxDecoration(
                          color: selectedGender == 'female' 
                              ? const Color(0xFF4C6414).withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          // แสดงเงาเฉพาะตอนที่ยังไม่ได้เลือก หรือเลือกตัวนี้อยู่ (Optional)
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
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  'https://api.builder.io/api/v1/image/assets/TEMP/39033778d5536311cadcc3527d4d76f3a4dc0265?width=266',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8), // เพิ่มระยะห่างนิดนึง
                            const Text(
                              'หญิง',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                height: 1.0, // ช่วยลดความสูงบรรทัดส่วนเกิน
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20), // ระยะห่างระหว่างการ์ด

                    // Male Option
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedGender = 'male';
                        });
                      },
                      child: Container(
                        width: 133,
                        // 4. แก้ Overflow: เพิ่มความสูงจาก 166 เป็น 185
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
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  'https://api.builder.io/api/v1/image/assets/TEMP/df1d246a81b58a4c9e48085bb95048ea1241a078?width=266',
                                  fit: BoxFit.cover,
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
              
              const Spacer(),
              
              // Next Button
              Padding(
                padding: const EdgeInsets.only(bottom: 57),
                child: GestureDetector(
                  onTap: selectedGender != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PersonalInfoScreen(),
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
    );
  }
}
