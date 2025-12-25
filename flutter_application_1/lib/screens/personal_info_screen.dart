import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Import Riverpod
import '../providers/user_data_provider.dart'; // 2. Import Provider ที่เราสร้าง
import 'goal_selection_screen.dart';

// 3. เปลี่ยนเป็น ConsumerStatefulWidget
class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // ตัวแปรเก็บวันที่แบบ DateTime เพื่อส่งให้ Provider
  DateTime? _selectedDate;

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
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4C6414),
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
        _selectedDate = picked; // เก็บค่า DateTime จริง
        _birthdayController.text = "${picked.day}/${picked.month}/${picked.year}"; // โชว์ข้อความ
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFE8EFCF),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ปุ่มย้อนกลับ
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

                // Illustration
                Center(
                  child: Image.network(
                    'https://api.builder.io/api/v1/image/assets/TEMP/1954e238a987282746e33d33deb711b2c911f3d3?width=554',
                    width: 277,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(height: 150),
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
                        isDate: true,
                      ),
                      const SizedBox(height: 28),
                      _buildFormField(
                        label: 'ส่วนสูง',
                        controller: _heightController,
                        hintText: 'กรอกข้อมูล',
                        isNumber: true,
                      ),
                      const SizedBox(height: 28),
                      _buildFormField(
                        label: 'นํ้าหนัก',
                        controller: _weightController,
                        hintText: 'กรอกข้อมูล',
                        isNumber: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // --- ปุ่มถัดไป (ส่วนสำคัญ) ---
                GestureDetector(
                  onTap: () {
                    // 1. ตรวจสอบว่ากรอกข้อมูลครบไหม
                    if (_nameController.text.isEmpty ||
                        _selectedDate == null ||
                        _heightController.text.isEmpty ||
                        _weightController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // 2. แปลงข้อมูลตัวเลข
                    double heightVal = double.tryParse(_heightController.text) ?? 0.0;
                    double weightVal = double.tryParse(_weightController.text) ?? 0.0;

                    // 3. บันทึกข้อมูลลง Provider
                    ref.read(userDataProvider.notifier).setPersonalInfo(
                          name: _nameController.text,
                          birthDate: _selectedDate!,
                          height: heightVal,
                          weight: weightVal,
                        );

                    // 4. ไปหน้าถัดไป
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
              readOnly: isDate,
              onTap: isDate ? () => _selectDate(context) : null,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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