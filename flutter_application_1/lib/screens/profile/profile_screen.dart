import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ใช้ Scaffold และกำหนดสีพื้นหลังตาม CSS: background: #E8EFCF;
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 37), // Top margin

              // --- 1. Header (ปุ่มย้อนกลับ + ชื่อหน้า) ---
              // CSS: Top 37px
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context); // คำสั่งย้อนกลับ
                    },
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 40), // จัดกึ่งกลาง
                      child: Text(
                        'โปรไฟล์ส่วนตัว',
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

              const SizedBox(height: 30),

              // --- 2. Profile Section (รูป + ข้อมูล) ---
              // CSS Reference: Rectangle 11 (Image), หวาน, อายุ...
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // รูปโปรไฟล์ (วงกลม)
                  Container(
                    width: 121,
                    height: 121,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      image: DecorationImage(
                        // 👇 แก้ไขตรงนี้ครับ เปลี่ยนจาก NetworkImage เป็น AssetImage
                        image: AssetImage('assets/images/profile/profile.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20), // ระยะห่าง

                  // ข้อมูลด้านขวา
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'หวาน',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'อายุ 22 • สูง 170 ซม.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w200, // Thin
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // กล่องเป้าหมาย (Rectangle 36)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'เป้าหมาย: ลดน้ำหนัก',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // --- 3. Stats Card (น้ำหนัก/เป้าหมาย/วัน) ---
              // CSS Reference: Rectangle 37
              Container(
                height: 103,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('70', 'น้ำหนักปัจจุบัน',
                        const Color(0xFF47DB67)), // เขียว
                    _buildVerticalDivider(),
                    _buildStatItem(
                        '50', 'เป้าหมาย', const Color(0xFFB74D4D)), // แดง
                    _buildVerticalDivider(),
                    _buildStatItem('54', 'วันที่เหลือ',
                        const Color(0xFF344CE6)), // น้ำเงิน
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --- 4. Menu Group 1: ข้อมูลส่วนตัว ---
              const Text(
                'ข้อมูลส่วนตัว',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF6E6A6A), // สีเทาตาม CSS
                ),
              ),
              const SizedBox(height: 10),

              // กล่องเมนู 1 (Rectangle 38)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(Icons.edit, 'แก้ไขโปรไฟล์',
                        showDivider: true),
                    _buildMenuItem(Icons.flag, 'เป้าหมาย',
                        showDivider: true), // image 29
                    _buildMenuItem(Icons.directions_run, 'กิจกรรม',
                        showDivider: false), // image 30
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- 5. Menu Group 2: การแสดงผลข้อมูล ---
              const Text(
                'การเเสดงผลข้อมูล',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF6E6A6A),
                ),
              ),
              const SizedBox(height: 10),

              // กล่องเมนู 2 (Rectangle 39)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(Icons.sync, 'ยูนิต', showDivider: true),
                    _buildMenuItem(Icons.bar_chart, 'ความคืบหน้า',
                        showDivider: true),
                    _buildMenuItem(
                        Icons.pie_chart, 'เป้าหมายแคลอรี่และสารอาหารหลัก',
                        showDivider: false),
                  ],
                ),
              ),

              const SizedBox(height: 40), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (ตัวช่วยสร้าง UI ซ้ำๆ) ---

  // 1. สร้างตัวเลขสถิติ (Stats)
  Widget _buildStatItem(String value, String label, Color valueColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24, // ปรับให้ใหญ่นิดนึงให้อ่านง่าย
            fontWeight: FontWeight.w400,
            color: valueColor, // สีตาม CSS
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w100, // Thin styling
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // 2. เส้นคั่นแนวตั้ง
  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.black,
    );
  }

  // 3. สร้างรายการเมนู (Menu Item)
  Widget _buildMenuItem(IconData icon, String title,
      {required bool showDivider}) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 30,
            height: 30,
            // ถ้าอยากใส่รูปไอคอน PNG ตาม CSS ให้แก้ตรงนี้เป็น Image.asset(...)
            decoration: const BoxDecoration(
                // color: Colors.grey[200], // ใส่สีเทารองพื้นถ้าต้องการ
                // shape: BoxShape.circle,
                ),
            child: Icon(icon, color: Colors.black, size: 26),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios,
              size: 16, color: Colors.black),
          onTap: () {
            // ใส่โค้ดกดปุ่มตรงนี้
          },
        ),
        if (showDivider)
          const Divider(
              height: 1, color: Colors.black, indent: 20, endIndent: 20),
      ],
    );
  }
}
