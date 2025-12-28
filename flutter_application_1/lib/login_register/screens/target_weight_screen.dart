import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Import Riverpod
import '../../providers/user_data_provider.dart'; // Import Provider
import '../../screens/app_home_screen.dart';


// 2. เปลี่ยนเป็น ConsumerStatefulWidget
class TargetWeightScreen extends ConsumerStatefulWidget {
  final GoalOption selectedGoal;

  const TargetWeightScreen({
    super.key,
    required this.selectedGoal,
  });

  @override
  ConsumerState<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends ConsumerState<TargetWeightScreen> {
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
    // กำหนดตัวแปรสำหรับ UI (เหมือนเดิม)
    String titleText = '';
    Color subTitleColor = Colors.black;
    String imageUrl = '';

    switch (widget.selectedGoal) {
      case GoalOption.loseWeight:
        titleText = 'การลดน้ำหนัก ควบคุมแคลอรี่';
        subTitleColor = const Color(0xFFD76A3C);
        imageUrl = 'https://api.builder.io/api/v1/image/assets/TEMP/2b36cbc83f6282347dd67152d454841cc595df15';
        break;
      case GoalOption.maintainWeight:
        titleText = 'รักษาน้ำหนัก รักษาสมดุล';
        subTitleColor = const Color(0xFF2D58B6);
        imageUrl = 'https://api.builder.io/api/v1/image/assets/TEMP/caa3690bf64691cf18159ea72b5ec46944c37e66';
        break;
      case GoalOption.buildMuscle:
        titleText = 'เพิ่มกล้ามเนื้อ ลดไขมัน';
        subTitleColor = const Color(0xFFB4AC15);
        imageUrl = 'https://api.builder.io/api/v1/image/assets/TEMP/3ac072bc08b89b53ec34785b4a25b0021535bdd8';
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

                // Title
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

                // Subtitle (Dynamic)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    titleText,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: subTitleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),

                // Image Circle
                Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(25),
                  child: Image.network(
                    imageUrl,
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
                        label: 'เป้าหมายน้ำหนัก',
                        controller: _targetWeightController,
                        hintText: 'กรอกข้อมูล',
                        isNumber: true,
                      ),
                      const SizedBox(height: 30),
                      _buildFormField(
                        label: 'ระยะเวลาที่ต้องการ',
                        controller: _durationController,
                        hintText: 'กรอกข้อมูล',
                        isNumber: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // --- Confirm Button (ส่วนสำคัญ) ---
                GestureDetector(
                  onTap: () {
                    // 1. ตรวจสอบข้อมูลว่ากรอกครบไหม
                    if (_targetWeightController.text.isEmpty || _durationController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // 2. แปลงค่าเป็นตัวเลข
                    double targetW = double.tryParse(_targetWeightController.text) ?? 0.0;
                    int dur = int.tryParse(_durationController.text) ?? 0;

                    // 3. บันทึกลง Provider
                    ref.read(userDataProvider.notifier).setGoalInfo(
                          targetWeight: targetW,
                          duration: dur,
                        );

                    // 4. (Optional) เช็คข้อมูลทั้งหมดใน Console ก่อนจบ
                    final allData = ref.read(userDataProvider);
                    print("--- Registration Complete ---");
                    print("Name: ${allData.name}");
                    print("Goal: ${allData.goal}");
                    print("Target Weight: ${allData.targetWeight}");
                    print("Duration: ${allData.duration} weeks");

                    // 5. ไปหน้า Home (จบ Flow สมัครสมาชิก)
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
                      color: const Color(0xFF435D17),
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
          width: 150,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
