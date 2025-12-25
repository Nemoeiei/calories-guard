import 'package:flutter/material.dart';

class AppHomeScreen extends StatefulWidget {
  const AppHomeScreen({super.key});

  @override
  State<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends State<AppHomeScreen> {
  int _selectedIndex = 0; // สำหรับ BottomNavigationBar (ถ้ามีในอนาคต)

  @override
  Widget build(BuildContext context) {
    // ใช้สีพื้นหลังโทนเดียวกับหน้า Login เพื่อความสวยงาม
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar ใส
        elevation: 0,
        automaticallyImplyLeading: false, // ไม่แสดงปุ่มย้อนกลับ
        title: const Text(
          'หน้าหลัก',
          style: TextStyle(
            color: Color(0xFF435D17), // สีเขียวเข้ม
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        actions: [
           IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF435D17)),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ส่วนต้อนรับ
              const Text(
                'ยินดีต้อนรับ,',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              const Text(
                'เริ่มต้นดูแลสุขภาพกันเถอะ!',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF435D17),
                ),
              ),
              const SizedBox(height: 30),

              // ตัวอย่าง Card แสดงข้อมูลสรุป (Placeholder)
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "เป้าหมายวันนี้",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(Icons.local_fire_department, "แคลอรี่", "0 / 2000"),
                        _buildSummaryItem(Icons.directions_run, "ก้าวเดิน", "0 / 6000"),
                      ],
                    )
                  ],
                ),
              ),
              
              const Spacer(), // ดันทุกอย่างขึ้นด้านบน
              Center(
                 child: Text(
                  "นี่คือหน้าจอเริ่มต้น\n(แทนรูปภาพที่คุณต้องการ)",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                 ),
              )
            ],
          ),
        ),
      ),
      // ตัวอย่าง Bottom Navigation Bar (เผื่อใช้ในอนาคต)
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF435D17),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'อาหาร'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }

  // Widget ย่อยสำหรับสร้างไอเท็มสรุป
  Widget _buildSummaryItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF435D17), size: 30),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }
}