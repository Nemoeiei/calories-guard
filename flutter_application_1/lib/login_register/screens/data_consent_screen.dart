import 'package:flutter/material.dart';
import 'gender_selection_screen.dart';

class DataConsentScreen extends StatefulWidget {
  const DataConsentScreen({super.key});

  @override
  State<DataConsentScreen> createState() => _DataConsentScreenState();
}

class _DataConsentScreenState extends State<DataConsentScreen> {
  bool _isAccepted = false;

  // Design Colors
  final Color primaryGreen = const Color(0xFF628141);
  final Color darkGreen = const Color(0xFF4C6414);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: null,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 200,
            height: 8,
            child: LinearProgressIndicator(
              value: 0.125, // 10% - ขั้นแรกของการสมัคร
              backgroundColor: Colors.grey.shade200,
              color: primaryGreen,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "การยินยอมการใช้ข้อมูลส่วนบุคคล",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "แอปพลิเคชันนี้มีการเก็บข้อมูลส่วนบุคคลของผู้ใช้ เช่น ชื่อ-นามสกุล อีเมล รหัสผ่าน วันเกิด เพศ น้ำหนัก และส่วนสูง เพื่อใช้ในการสร้างบัญชีผู้ใช้ และนำข้อมูลไปคำนวณค่า BMI, BMR และ TDEE สำหรับการประเมินสุขภาพและแนะนำการรับประทานอาหารที่เหมาะสมกับเป้าหมายควบคุมน้ำหนักของผู้ใช้",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ข้อมูลที่ใช้บันทึกในแอปจะถูกนำไปใช้เพื่อการทำงานของระบบ เช่น การติดตามพฤติกรรมการรับประทานอาหาร และการแสดงผลข้อมูลสุขภาพของผู้ใช้ ทั้งนี้ข้อมูลจะถูกจัดเก็บอย่างเหมาะสมและใช้ภายในระบบของแอปพลิเคชันเท่านั้น",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              
              // Custom Checkbox Section
              InkWell(
                onTap: () {
                  setState(() {
                    _isAccepted = !_isAccepted;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _isAccepted ? primaryGreen : Colors.white,
                        border: Border.all(
                          color: primaryGreen,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _isAccepted
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "ฉันยอมรับเงื่อนไขการใช้ข้อมูล",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_isAccepted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GenderSelectionScreen()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณายอมรับเงื่อนไขก่อน')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "บันทึก",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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