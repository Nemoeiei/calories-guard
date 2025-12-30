import 'package:flutter/material.dart';
// Import หน้าต่างๆ ที่เราทำไว้ (ตรวจสอบ path ให้ถูกต้องนะครับ)
import '/screens/app_home_screen.dart';
import '/screens/save/save_food_screen.dart'; 
import '/screens/recommened_exercise/exercise_recommendation_screen.dart';
import '/screens/recommend_food/recommend_food_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // ตัวแปรเก็บว่าเราอยู่หน้าไหน (0=หน้าหลัก, 1=บันทึก, 2=อาหาร, 3=ออกกำลัง)
  int _selectedIndex = 0;

  // รายชื่อหน้าทั้งหมด เรียงตามลำดับปุ่ม
  final List<Widget> _pages = [
    const AppHomeScreen(),              // Index 0
    const FoodLoggingScreen(),          // Index 1
    const RecommendedFoodScreen(),      // Index 2
    const ExerciseRecommendationScreen(), // Index 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ส่วนเนื้อหา: จะเปลี่ยนไปตาม _selectedIndex
      // ใช้ IndexedStack เพื่อให้หน้าต่างๆ ไม่ถูกรีเซ็ตค่าใหม่เวลากดสลับไปมา
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // ส่วน Bottom Bar: เขียนที่นี่ครั้งเดียว ใช้ได้ตลอดไป
      bottomNavigationBar: Container(
        height: 80,
        color: const Color(0xFFE8EFCF), // สีพื้นหลังบาร์
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home, "หน้าหลัก", 0),
            _buildBottomNavItem(Icons.calendar_month, "บันทึก", 1),
            _buildBottomNavItem(Icons.restaurant, "อาหาร", 2),
            _buildBottomNavItem(Icons.directions_run, "ออกกำลัง", 3),
          ],
        ),
      ),
    );
  }

  // Helper สร้างปุ่ม (เหมือนเดิม แต่ใช้ logic ของ MainScreen)
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
          Icon(icon, color: color, size: 35),
          const SizedBox(height: 4),
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