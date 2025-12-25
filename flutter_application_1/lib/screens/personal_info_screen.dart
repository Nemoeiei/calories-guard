import 'package:flutter/material.dart';
import 'goal_selection_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // ฟังก์ชันเลือกวันที่
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), // ตั้งค่าเริ่มต้นปี 2000
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4C6414), // สีหัวปฏิทิน
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // แปลงวันที่เป็นรูปแบบ วว/ดด/ปปปป
        _birthdayController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFE8EFCF), // พื้นหลังสีที่ต้องการ
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

                const SizedBox(height: 14),

                // Title
                const Text(
                  'กรอกข้อมูลส่วนตัว',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Subtitle
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  child: Text(
                    'เพื่อนำไปคำนวณแคลอรี่ที่เหมาะสมกับตัวบุคคล',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 44),

                // Illustration (รูปกราฟิกตรงกลาง)
                Center(
                  child: Image.network(
                    'https://api.builder.io/api/v1/image/assets/TEMP/1954e238a987282746e33d33deb711b2c911f3d3?width=554',
                    width: 277,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(height: 150), // กัน Error ถ้ารูปไม่โหลด
                  ),
                ),

                const SizedBox(height: 47),

                // Form Fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Column(
                    children: [
                      _buildFormField(
                        label: 'ชื่อ',
                        controller: _nameController,
                        hintText: 'กรอกข้อมูล',
                      ),

                      const SizedBox(height: 28),

                      _buildFormField(
                        label: 'วันเกิด',
                        controller: _birthdayController,
                        hintText: 'วว/ดด/ปปปป',
                        isDate: true, // เปิดโหมดเลือกวันที่
                      ),

                      const SizedBox(height: 28),

                      _buildFormField(
                        label: 'ส่วนสูง',
                        controller: _heightController,
                        hintText: 'กรอกข้อมูล',
                        isNumber: true, // บังคับตัวเลข
                      ),

                      const SizedBox(height: 28),

                      _buildFormField(
                        label: 'นํ้าหนัก',
                        controller: _weightController,
                        hintText: 'กรอกข้อมูล',
                        isNumber: true, // บังคับตัวเลข
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Next Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalSelectionScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 259,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C6414),
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

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ปรับปรุง Widget เพื่อรองรับโหมดวันที่และตัวเลข
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isNumber = false,
    bool isDate = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 29,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEDED),
              borderRadius: BorderRadius.circular(100),
            ),
            child: TextField(
              controller: controller,
              // ถ้าเป็นช่องวันเกิด ให้กดแล้วเปิดปฏิทิน (readOnly: true)
              readOnly: isDate, 
              onTap: isDate ? () => _selectDate(context) : null,
              
              // ถ้าเป็นตัวเลข ให้ขึ้นแป้นตัวเลข
              keyboardType: isNumber 
                  ? const TextInputType.numberWithOptions(decimal: true) 
                  : TextInputType.text,
                  
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xB3000000),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9), // ปรับ padding ให้ข้อความอยู่กลางแนวตั้ง
              ),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}