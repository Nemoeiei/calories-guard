import 'package:flutter/material.dart';
import 'app_home_screen.dart';
import 'goal_selection_screen.dart'; // 👈 สำคัญ: ต้อง import เพื่อให้รู้จัก GoalOption

class TargetWeightScreen extends StatefulWidget {
  // 1. รับค่าเป้าหมายที่เลือกมาจากหน้าก่อนหน้า
  final GoalOption selectedGoal;

  const TargetWeightScreen({
    super.key, 
    required this.selectedGoal, // บังคับให้ส่งค่ามา
  });

  @override
  State<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends State<TargetWeightScreen> {
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  @override
  void dispose() {
    _targetWeightController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 2. กำหนดตัวแปรสำหรับข้อมูลที่จะเปลี่ยนไปตามเป้าหมาย
    String titleText = '';
    String subTitleText = '';
    Color subTitleColor = Colors.black;
    String imageUrl = '';

    // 3. เช็คว่าเลือกอะไรมา แล้วเปลี่ยนข้อมูลตามนั้น
    switch (widget.selectedGoal) {
      case GoalOption.loseWeight:
        titleText = 'การลดน้ำหนัก ควบคุมแคลอรี่';
        subTitleColor = const Color(0xFFD76A3C); // สีส้ม
        imageUrl = 'https://api.builder.io/api/v1/image/assets/TEMP/2b36cbc83f6282347dd67152d454841cc595df15'; // รูปไฟ
        break;
      case GoalOption.maintainWeight:
        titleText = 'รักษาน้ำหนัก รักษาสมดุล'; // หรือข้อความที่คุณต้องการ
        subTitleColor = const Color(0xFF2D58B6); // สีน้ำเงิน
        imageUrl = 'https://api.builder.io/api/v1/image/assets/TEMP/caa3690bf64691cf18159ea72b5ec46944c37e66'; // รูปอาหาร
        break;
      case GoalOption.buildMuscle:
        titleText = 'เพิ่มกล้ามเนื้อ ลดไขมัน';
        subTitleColor = const Color(0xFFB4AC15); // สีเหลืองทอง
        imageUrl = 'https://api.builder.io/api/v1/image/assets/TEMP/3ac072bc08b89b53ec34785b4a25b0021535bdd8'; // รูปกล้าม
        break;
    }

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
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 19, top: 31),
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

                const SizedBox(height: 20),

                // Title (คงที่)
                const Text(
                  'เป้าหมายของคุณคือ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // Subtitle (เปลี่ยนตามเป้าหมาย)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    titleText, // 👈 ใช้ตัวแปรที่กำหนดไว้ข้างบน
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20, // ปรับขนาดให้เด่นขึ้นนิดนึง
                      fontWeight: FontWeight.w600,
                      color: subTitleColor, // 👈 เปลี่ยนสีตามเป้าหมาย
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),

                // Image Circle (เปลี่ยนรูปตามเป้าหมาย)
                Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(25), // เว้นระยะให้รูปข้างในสวยงาม
                  child: Image.network(
                    imageUrl, // 👈 ใช้ URL ตามเป้าหมาย
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported, size: 50),
                  ),
                ),

                const SizedBox(height: 50),

                // Form Fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      _buildFormField(
                        label: 'เป้าหมายน้ำหนัก', // แก้คำให้ตรงกับรูป
                        controller: _targetWeightController,
                        hintText: 'กรอกข้อมูล', // แก้ hint ให้ตรงกับรูป
                        isNumber: true,
                      ),
                      const SizedBox(height: 30),
                      _buildFormField(
                        label: 'ระยะเวลาที่ต้องการ', // แก้คำให้ตรงกับรูป
                        controller: _durationController,
                        hintText: 'กรอกข้อมูล',
                        isNumber: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Confirm Button
                GestureDetector(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppHomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Container(
                    width: 259,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF435D17), // ปรับสีปุ่มให้เขียวเข้มขึ้นตามรูป
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
                        'ถัดไป', // แก้คำให้ตรงกับรูป
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

                const SizedBox(height: 40),
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
  }) {
    return Row(
      children: [
        SizedBox(
          width: 150, // ปรับความกว้างให้พอดีกับข้อความภาษาไทยยาวๆ
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white, // เปลี่ยนพื้นหลังช่องกรอกเป็นสีขาวตามรูป
              borderRadius: BorderRadius.circular(20), // ปรับความมน
            ),
            child: TextField(
              controller: controller,
              keyboardType: isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF909090),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 8),
              ),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
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