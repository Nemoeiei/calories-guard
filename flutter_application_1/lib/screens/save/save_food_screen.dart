import 'package:flutter/material.dart';

class FoodLoggingScreen extends StatefulWidget {
  const FoodLoggingScreen({super.key});

  @override
  State<FoodLoggingScreen> createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends State<FoodLoggingScreen> {
  // State สำหรับ Dropdown กิจกรรม
  String _selectedActivity = 'ไม่ออกกำลังกายเลย';
  final List<String> _activities = [
    'ไม่ออกกำลังกายเลย',
    'ออกกำลังกายเบาๆ (1-3 ครั้ง/สัปดาห์)',
    'ออกกำลังกายปานกลาง (3-5 ครั้ง/สัปดาห์)',
    'ออกกำลังกายหนัก (6-7 ครั้ง/สัปดาห์)',
    'ออกกำลังกายหนักมาก (ทุกวันเช้า-เย็น)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 36), // SafeArea top

            // --- Header (แก้ไข: ลบปุ่มกลับ + จัดกึ่งกลาง) ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                child: Text(
                  'บันทึกข้อมูลรายวัน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- ส่วนที่ 1: ข้อมูลการทานอาหาร ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF628141),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Center(
                child: Text(
                  'ข้อมูลการทานอาหารวันนี้',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.only(left: 30, right: 30, top: 10),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildFoodInputRow('อาหารเช้า*', true),
                  const SizedBox(height: 15),
                  _buildFoodInputRow('มื้อว่าง', false),
                  const SizedBox(height: 15),
                  _buildFoodInputRow('อาหารกลางวัน*', true),
                  const SizedBox(height: 15),
                  _buildFoodInputRow('มื้อว่าง', false),
                  const SizedBox(height: 15),
                  _buildFoodInputRow('อาหารเย็น*', true),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- ส่วนที่ 2: กิจกรรม ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF628141),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Center(
                child: Text(
                  'กิจกรรมที่ทำวันนี้',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.only(left: 32, right: 32, top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedActivity,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedActivity = newValue!;
                    });
                  },
                  items: _activities.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodInputRow(String label, bool isRequired) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Container(
          width: 143,
          height: 23,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEDED),
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Text(
            'กรอกเมนูอาหารที่ทาน',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: Color(0xFF979797),
            ),
          ),
        ),
      ],
    );
  }
}