import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/providers/user_data_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // ฟังก์ชันยิง API อัปเดตข้อมูล
  Future<void> _updateUserData(Map<String, dynamic> updateData) async {
    final userId = ref.read(userDataProvider).userId;
    // ⚠️ อย่าลืมเช็ค IP ให้ตรงกับเครื่องที่รัน (10.0.2.2 สำหรับ Android Emulator)
    final url = Uri.parse(
        'https://unshirred-wendolyn-audiometrically.ngrok-free.dev/users/$userId');

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        // อัปเดตสำเร็จ -> อัปเดตข้อมูลในแอปทันที
        final user = ref.read(userDataProvider);

        // เช็คว่าแก้อะไรแล้วอัปเดต Provider ตามนั้น
        if (updateData.containsKey('username')) {
          ref.read(userDataProvider.notifier).setPersonalInfo(
              name: updateData['username'],
              birthDate: user.birthDate ?? DateTime.now(),
              height: user.height,
              weight: user.weight);
        }
        if (updateData.containsKey('height_cm')) {
          ref.read(userDataProvider.notifier).setPersonalInfo(
              name: user.name,
              birthDate: user.birthDate ?? DateTime.now(),
              height: double.parse(updateData['height_cm'].toString()),
              weight: user.weight);
        }
        if (updateData.containsKey('current_weight_kg')) {
          ref.read(userDataProvider.notifier).setPersonalInfo(
              name: user.name,
              birthDate: user.birthDate ?? DateTime.now(),
              height: user.height,
              weight: double.parse(updateData['current_weight_kg'].toString()));
        }
        if (updateData.containsKey('target_weight_kg')) {
          ref.read(userDataProvider.notifier).setGoalInfo(
              targetWeight:
                  double.parse(updateData['target_weight_kg'].toString()),
              duration: user.duration);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('บันทึกข้อมูลเรียบร้อยแล้ว ✅'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Failed to update');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Dialog แก้ไขข้อความทั่วไป (ชื่อ, น้ำหนัก, ส่วนสูง)
  void _showEditDialog(String title, String key, String currentValue,
      {bool isNumber = false}) {
    TextEditingController controller =
        TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('แก้ไข$title'),
        content: TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(hintText: 'กรอก$titleใหม่'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                dynamic value = isNumber
                    ? double.tryParse(controller.text)
                    : controller.text;
                if (value != null) {
                  _updateUserData({key: value});
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider); // ดึงข้อมูล Real-time

    // ✅ คำนวณวันที่เหลือให้ถูกต้องตาม Logic ของ ProfileScreen
    String daysLeftText = "0";
    if (userData.targetDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(userData.targetDate!.year,
          userData.targetDate!.month, userData.targetDate!.day);

      final difference = target.difference(today).inDays;
      daysLeftText = difference > 0 ? difference.toString() : "0";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF), // พื้นหลังสีครีมเขียว
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 36), // Top margin

            // --- 1. Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 40),
                      child: Text(
                        'แก้ไขโปรไฟล์',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 2. รูปโปรไฟล์ ---
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 121,
                  height: 121,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    image: DecorationImage(
                        image: AssetImage('assets/images/profile/profile.png'),
                        fit: BoxFit.cover),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- 3. การ์ดข้อมูลส่วนตัว ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Column(
                children: [
                  // ชื่อ (แก้ไขได้)
                  GestureDetector(
                    onTap: () => _showEditDialog(
                        'ชื่อผู้ใช้', 'username', userData.name),
                    child: _buildEditRow(
                        label: userData.name,
                        fontSize: 20,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),

                  // อายุ / ส่วนสูง (แก้ไขส่วนสูงได้)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('อายุ ${userData.age}',
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w200)),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => _showEditDialog(
                            'ส่วนสูง', 'height_cm', userData.height.toString(),
                            isNumber: true),
                        child: Row(
                          children: [
                            Text('สูง ${userData.height.toInt()} ซม.',
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w200)),
                            const SizedBox(width: 5),
                            const Icon(Icons.edit,
                                size: 12, color: Color(0xFF6E6A6A)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // ข้อมูลสถิติ (น้ำหนักปัจจุบัน / เป้าหมาย) แก้ไขได้
                  GestureDetector(
                    onTap: () => _showEditDialog('น้ำหนักปัจจุบัน',
                        'current_weight_kg', userData.weight.toString(),
                        isNumber: true),
                    child: _buildStatRow('น้ำหนักปัจจุบัน',
                        '${userData.weight.toInt()}', const Color(0xFF47DB67)),
                  ),
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () => _showEditDialog('น้ำหนักเป้าหมาย',
                        'target_weight_kg', userData.targetWeight.toString(),
                        isNumber: true),
                    child: _buildStatRow(
                        'เป้าหมาย',
                        '${userData.targetWeight.toInt()}',
                        const Color(0xFFB74D4D)),
                  ),
                  const SizedBox(height: 10),

                  // ✅ ส่ง daysLeftText ไปแสดงผล
                  _buildStatRow(
                      'วันที่เหลือ', daysLeftText, const Color(0xFF344CE6),
                      isEditable: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildEditRow(
      {required String label,
      required double fontSize,
      required FontWeight fontWeight}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: Colors.black)),
        const SizedBox(width: 8),
        const Icon(Icons.edit, size: 14, color: Color(0xFF6E6A6A)),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor,
      {bool isEditable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 14, color: Colors.black),
                textAlign: TextAlign.right),
          ),
          const SizedBox(width: 15),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: valueColor)),
                if (isEditable) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.edit, size: 14, color: Color(0xFF6E6A6A)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
