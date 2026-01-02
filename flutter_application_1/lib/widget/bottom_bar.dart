import 'package:flutter/material.dart';

// --- Import หน้าต่างๆ ---
import '../screens/app_home_screen.dart';
import '../screens/record/record_food_screen.dart'; 
import '../screens/recommened_exercise/exercise_recommendation_screen.dart';
import '../screens/recommend_food/recommend_food_screen.dart'; 

// Import หน้าโปรไฟล์ (สำหรับปุ่มกดที่ Top Bar)
import '../screens/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // รายชื่อหน้า (Body)
  final List<Widget> _pages = [
    const AppHomeScreen(),              // Index 0
    const FoodLoggingScreen(),          // Index 1
    const RecommendedFoodScreen(),      // Index 2
    const ExerciseRecommendationScreen(), // Index 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF), // สีพื้นหลังรวม
      
      // ใช้ Column เพื่อแบ่งส่วน Top Bar และ เนื้อหา
      body: Column(
        children: [
          // ------------------------------
          // 1. ส่วน Top Bar (แสดงเหมือนกันทุกหน้า)
          // ------------------------------
          _buildTopBar(),

          // ------------------------------
          // 2. ส่วนเนื้อหา (เปลี่ยนตาม Tab)
          // ------------------------------
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),

      // ------------------------------
      // 3. ส่วน Bottom Bar (แสดงทุกหน้า)
      // ------------------------------
      bottomNavigationBar: Container(
        height: 80,
        color: const Color(0xFFE8EFCF),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home_outlined, "หน้าหลัก", 0),
            _buildBottomNavItem(Icons.food_bank_outlined, "บันทึก", 1),
            _buildBottomNavItem(Icons.restaurant, "อาหาร", 2),
            _buildBottomNavItem(Icons.directions_run, "ออกกำลัง", 3),
          ],
        ),
      ),
    );
  }

  // --- Widget: Top Bar (แก้ไขใหม่: ให้แสดงโลโก้และไอคอนคนทุกหน้า) ---
  Widget _buildTopBar() {
    return Container(
      // ความสูงรวม Status bar
      height: 110, 
      padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF628141), // สีเขียวเข้ม
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- ส่วนซ้าย: โลโก้ + ชื่อแอป (แสดงตลอด) ---
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/icon/icon.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Calorie',
                style: TextStyle(
                  fontFamily: 'Itim',
                  fontSize: 16,
                  color: Color(0xFFE8EFCF),
                  height: 1,
                ),
              ),
              Text(
                'Guard',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),

          const Spacer(), // ดันไอคอนไปขวาสุด

          // --- ส่วนขวา: ปุ่มแจ้งเตือน & โปรไฟล์ (แสดงตลอด) ---
          IconButton(
            onPressed: () {
              // Logic แจ้งเตือน
            },
            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 32),
          ),
          
          // 🔥 เปลี่ยนจากเมนู 3 ขีด เป็นไอคอนคน (Person Outline)
          IconButton(
            onPressed: () {
              // ไปหน้าโปรไฟล์
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            icon: const Icon(Icons.person_outline, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  // --- Widget: Bottom Bar Item ---
  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;
    Color color = isActive ? const Color(0xFF4C6414) : const Color(0xFF8F8F8F);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔥 ส่วนที่เพิ่ม: Container เพื่อทำเงา (Glow Effect)
          Container(
            padding: const EdgeInsets.all(8.0), // เพิ่มพื้นที่รอบไอคอนนิดนึงให้เงาออก
            decoration: isActive
                ? BoxDecoration(
                    color: Colors.white.withOpacity(0.5), // (Optional) พื้นหลังขาวจางๆ
                    borderRadius: BorderRadius.circular(12), // ขอบมน
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4C6414).withOpacity(0.4), // สีเงาเขียว
                        blurRadius: 12, // ความฟุ้งของเงา
                        spreadRadius: 1, // ขนาดของเงา
                        offset: const Offset(0, 3), // ตำแหน่งเงา (ลงมาข้างล่างนิดนึง)
                      ),
                    ],
                  )
                : null, // ถ้าไม่เลือก ก็ไม่มีเงา
            child: Icon(icon, color: color, size: 30), // ปรับขนาดไอคอนตามชอบ
          ),
          
          // const SizedBox(height: 2), // ลดระยะห่างลงนิดนึงเพราะมี padding ที่ container แล้ว
          
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}