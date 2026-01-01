import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF), // พื้นหลังสีครีมเขียว
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 36), // Top margin

            // --- 1. Header (ปุ่มย้อนกลับ + ชื่อหน้า) ---
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
                          color: Colors.black,
                        ),
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
                      image: AssetImage('assets/images/profile/profile.png'), // เปลี่ยนเป็นรูปของคุณ
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // (Optional) อาจเพิ่มปุ่มกล้องถ่ายรูปเล็กๆ ตรงมุมได้ถ้าต้องการ
              ],
            ),

            const SizedBox(height: 40),

            // --- 3. การ์ดข้อมูลส่วนตัว (Rectangle 37) ---
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
                  // ชื่อ
                  _buildEditRow(
                    label: 'หวาน',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    iconRight: true,
                  ),
                  const SizedBox(height: 10),

                  // อายุ / ส่วนสูง
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'อายุ 22',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w200),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.edit, size: 12, color: Color(0xFF6E6A6A)),
                      const SizedBox(width: 15),
                      const Text(
                        'สูง 170 ซม.',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w200),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.edit, size: 12, color: Color(0xFF6E6A6A)),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // เป้าหมาย: ลดน้ำหนัก
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'เป้าหมาย: ',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 16),
                      ),
                      const Text(
                        'ลดน้ำหนัก',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.edit, size: 12, color: Color(0xFF6E6A6A)),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // ข้อมูลสถิติ (แนวตั้ง) - ปรับปรุงใหม่ให้ตรงกัน
                  _buildStatRow('น้ำหนักปัจจุบัน', '70', const Color(0xFF47DB67)),
                  const SizedBox(height: 10),
                  _buildStatRow('เป้าหมาย', '50', const Color(0xFFB74D4D)),
                  const SizedBox(height: 10),
                  _buildStatRow('วันที่เหลือ', '54', const Color(0xFF344CE6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: สร้างแถวข้อความพร้อมไอคอนแก้ไข ---
  Widget _buildEditRow({
    required String label,
    required double fontSize,
    required FontWeight fontWeight,
    bool iconRight = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: Colors.black,
          ),
        ),
        if (iconRight) ...[
          const SizedBox(width: 8),
          const Icon(Icons.edit, size: 14, color: Color(0xFF6E6A6A)),
        ],
      ],
    );
  }

  // --- Helper: สร้างแถวสถิติ (Label + Value + Icon) ---
  // แก้ไข: ใช้ SizedBox และ TextAlign เพื่อบังคับให้ข้อความชนกันที่กึ่งกลางพอดี
  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ฝั่งซ้าย: Label (บังคับชิดขวา วิ่งเข้าหาแกนกลาง)
          SizedBox(
            width: 120, // ความกว้างคงที่สำหรับ Label
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14, // ลดขนาดลงนิดหน่อยเพื่อให้พอดีกับพื้นที่
                color: Colors.black,
              ),
              textAlign: TextAlign.right, // ชิดขวา
            ),
          ),
          
          const SizedBox(width: 15), // ช่องว่างตรงกลาง
          
          // ฝั่งขวา: Value + Icon (บังคับชิดซ้าย วิ่งออกจากแกนกลาง)
          SizedBox(
            width: 80, // ความกว้างคงที่สำหรับ Value
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // ชิดซ้าย
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20, 
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.edit, size: 14, color: Color(0xFF6E6A6A)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}