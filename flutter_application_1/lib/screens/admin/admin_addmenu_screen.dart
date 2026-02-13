import 'package:flutter/material.dart';

class AdminAddMenuScreen extends StatelessWidget {
  // รับข้อมูลเบื้องต้นจากหน้าก่อนหน้า (ถ้ามี)
  final String? initialMenuName;

  const AdminAddMenuScreen({super.key, this.initialMenuName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF), // พื้นหลังสีเขียวอ่อน
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (ปุ่มย้อนกลับ + หัวข้อ)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
                        ),
                      ),
                    ),
                    const Text(
                      'เพิ่มเมนูอาหาร',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 2. ส่วนแสดงชื่อเมนูที่กำลังเพิ่ม (เหมือน Card เล็กๆ ด้านบน)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4C6414), width: 1),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEADDFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Color(0xFF6E6A6A)),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เพิ่ม ${initialMenuName ?? "เมนูใหม่"}', // ชื่อเมนู dynamic
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6E6A6A),
                            ),
                          ),
                          const Text(
                            'โดย: Admin', // หรือชื่อ user ที่ขอมา
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. แบบฟอร์มกรอกข้อมูล (กล่องใหญ่)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4C6414), width: 1),
                  ),
                  child: Column(
                    children: [
                      // ชื่อเมนู (แสดงผลเฉยๆ หรือให้แก้ได้)
                      Row(
                        children: [
                          const Text('ชื่อเมนู :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 10),
                          Text(initialMenuName ?? 'เมนูใหม่', style: const TextStyle(fontSize: 16, color: Color(0xFF6E6A6A))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Input Fields
                      _buildInputRow('วัตถุดิบ', 'เพิ่มวัตถุดิบ'),
                      const SizedBox(height: 15),
                      _buildInputRow('วิธีการทำ', 'เพิ่มวิธีทำ'),
                      const SizedBox(height: 15),
                      _buildImageUploadRow(),
                      const SizedBox(height: 15),
                      _buildNutrientInput('โปรตีน', '0 กรัม'),
                      const SizedBox(height: 15),
                      _buildNutrientInput('คาร์โบไฮเดรต', '0 กรัม'), // แก้คำผิดจาก คาร์โบไฮเครต
                      const SizedBox(height: 15),
                      _buildNutrientInput('ไขมัน', '0 กรัม'),
                      const SizedBox(height: 15),
                      _buildNutrientInput('แคลอรี่', '0 kcal'),

                      const SizedBox(height: 30),

                      // ปุ่ม "เพิ่มเมนูนี้"
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Logic บันทึกลง Database
                            print("บันทึกเมนูลง Database");
                            Navigator.pop(context); // กลับหน้าเดิมหลังบันทึก
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFAFD198),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text(
                            'เพิ่มเมนูนี้',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 50), // เผื่อที่ด้านล่าง
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget ย่อย: แถวกรอกข้อมูลทั่วไป (วัตถุดิบ, วิธีทำ)
  Widget _buildInputRow(String label, String placeholder) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
        ),
        Container(
          width: 150, // ปรับความกว้างตามความเหมาะสม
          height: 30, // ความสูงตามดีไซน์ปุ่มเล็กๆ
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EFCF), // พื้นหลังสีเขียวอ่อน
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: placeholder,
              hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Widget ย่อย: แถวอัปโหลดรูปภาพ
  Widget _buildImageUploadRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(
          width: 90,
          child: Text('รูปภาพ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
        ),
        Container(
          width: 150,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EFCF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_photo_alternate_outlined, size: 18, color: Colors.black54),
              SizedBox(width: 5),
              Text('เพิ่มรูปภาพ', style: TextStyle(fontSize: 12, color: Colors.black38)),
            ],
          ),
        ),
      ],
    );
  }

  // Widget ย่อย: แถวกรอกข้อมูลโภชนาการ
  Widget _buildNutrientInput(String label, String unitPlaceholder) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
        ),
        Container(
          width: 150,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EFCF),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: unitPlaceholder,
              hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}