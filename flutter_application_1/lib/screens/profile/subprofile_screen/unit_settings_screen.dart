import 'package:flutter/material.dart';

class UnitSettingsScreen extends StatelessWidget {
  const UnitSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF), // พื้นหลังสีครีมเขียว
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ยูนิต',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- Group 1: น้ำหนัก ---
            _buildSectionHeader('น้ำหนัก'),
            _buildUnitGroup([
              _buildUnitItem('ปอนด์'),
              _buildUnitItem('กิโลกรัม', showDivider: false),
            ]),

            // --- Group 2: ส่วนสูง ---
            _buildSectionHeader('ส่วนสูง'),
            _buildUnitGroup([
              _buildUnitItem('ฟุต'),
              _buildUnitItem('เซนติเมตร', showDivider: false),
            ]),

            // --- Group 3: ระยะทาง ---
            _buildSectionHeader('ระยะทาง'),
            _buildUnitGroup([
              _buildUnitItem('ไมล์'),
              _buildUnitItem('กิโลเมตร', showDivider: false),
            ]),

            // --- Group 4: พลังงาน ---
            _buildSectionHeader('พลังงาน'),
            _buildUnitGroup([
              _buildUnitItem('แคลอรี่'),
              _buildUnitItem('กิโลจูล', showDivider: false),
            ]),

            // --- Group 5: น้ำ ---
            _buildSectionHeader('น้ำ'),
            _buildUnitGroup([
              _buildUnitItem('ขวด'),
              _buildUnitItem('มิลลิเมตร', showDivider: false),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Helper: สร้างหัวข้อหมวดหมู่ ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 20, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: Color(0xFF6E6A6A), // สีเทาตาม CSS
          ),
        ),
      ),
    );
  }

  // --- Helper: สร้างกลุ่มตัวเลือก (กล่องขาว + ขอบดำ) ---
  Widget _buildUnitGroup(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black), // ขอบสีดำรอบกล่อง
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // --- Helper: สร้างรายการตัวเลือก ---
  Widget _buildUnitItem(String title, {bool showDivider = true}) {
    return Container(
      decoration: BoxDecoration(
        // เส้นคั่นระหว่างรายการ
        border: showDivider
            ? const Border(bottom: BorderSide(color: Colors.black, width: 1))
            : null,
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        onTap: () {
          // ใส่ action เมื่อเลือกหน่วย (เช่น เปลี่ยน state)
        },
      ),
    );
  }
}