import 'package:flutter/material.dart';
// อย่าลืม import หน้า add menu ให้ถูกต้อง
import 'admin_addmenu_screen.dart'; 

class AdminRequestScreen extends StatelessWidget {
  const AdminRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ข้อมูลจำลองสำหรับแสดงผล (Mock Data)
    final List<Map<String, String>> requests = [
      {
        'menu': 'ไข่เจียวกุ้งสับ',
        'requester': 'หวาน',
        'image': 'https://via.placeholder.com/150' 
      },
      {
        'menu': 'ข้าวผัดเบคอน',
        'requester': 'นีโม่',
        'image': 'https://via.placeholder.com/150'
      },
      {
        'menu': 'ก๋วยเตี๋ยวหมูตุ๋น',
        'requester': 'เฟรม',
        'image': 'https://via.placeholder.com/150'
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF), // พื้นหลังสีเขียวอ่อน
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Title + Back Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ปุ่มย้อนกลับ
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
                      ),
                    ),
                  ),
                  // หัวข้อหน้า
                  const Text(
                    'ดูคำขอเพิ่มเมนู',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 2. รายการคำขอ (List View)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: requests.length,
                separatorBuilder: (context, index) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  final item = requests[index];
                  return _buildRequestCard(
                    context: context, // ส่ง context เข้าไปเพื่อใช้ Navigator
                    menuName: item['menu']!,
                    requesterName: item['requester']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สร้างการ์ดแต่ละรายการ
  Widget _buildRequestCard({
    required BuildContext context, 
    required String menuName, 
    required String requesterName
  }) {
    return Container(
      width: double.infinity,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4C6414), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar (วงกลมซ้ายสุด)
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFEADDFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF6E6A6A), size: 30),
          ),
          
          const SizedBox(width: 15),

          // ข้อความ (ชื่อคนขอ + ชื่อเมนู)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ชื่อคนขอ
                Text(
                  requesterName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // ชื่อเมนูที่ขอ
                Text(
                  'เพิ่ม $menuName',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6E6A6A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ปุ่ม Action (วงกลมสีเขียวขวาสุด) - กดแล้วไปหน้าเพิ่มเมนู
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFAFD198),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
              onPressed: () {
                // ✅ ส่งชื่อเมนูที่เลือกไปหน้าถัดไป
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminAddMenuScreen(initialMenuName: menuName),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}