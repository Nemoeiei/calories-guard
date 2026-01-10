import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';
import '../../services/auth_service.dart'; // ✅ 1. Import AuthService
import 'goal_selection_screen.dart';

class ActivityLevelScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  const ActivityLevelScreen({
    super.key, 
    this.isEditing = false, // ถ้าไม่ส่งมา จะถือว่าเป็น false (โหมดสมัคร)
  });

  @override
  ConsumerState<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends ConsumerState<ActivityLevelScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService(); // ✅ 2. สร้าง instance
  bool _isLoading = false; // สถานะโหลด

  final List<Map<String, dynamic>> _activities = [
    {
      "title": "ไม่ออกกำลังกายเลย",
      "subtitle": "นั่งทำงานตลอดวัน ไม่ค่อยขยับตัว",
      "value": "sedentary",
      "icon": Icons.weekend_outlined,
    },
    {
      "title": "ออกกำลังกายเบาๆ",
      "subtitle": "1-3 วันต่อสัปดาห์ หรือเดินบ่อย",
      "value": "light",
      "icon": Icons.directions_walk,
    },
    {
      "title": "ออกกำลังกายปานกลาง",
      "subtitle": "3-5 วันต่อสัปดาห์ (แอโรบิค, วิ่ง)",
      "value": "moderate",
      "icon": Icons.run_circle_outlined,
    },
    {
      "title": "ออกกำลังกายหนัก",
      "subtitle": "6-7 วันต่อสัปดาห์",
      "value": "active",
      "icon": Icons.fitness_center,
    },
    {
      "title": "ออกกำลังกายหนักมาก",
      "subtitle": "ทุกวัน เช้า-เย็น หรือนักกีฬา",
      "value": "extreme",
      "icon": Icons.emoji_events_outlined,
    },
  ];

  // ✅ 3. ปรับปรุงฟังก์ชัน Submit ให้ยิง API
  void _submit() async {
    setState(() => _isLoading = true); // เริ่มโหลด

    // ดึงค่าภาษาอังกฤษ เช่น 'sedentary', 'light'
    final selectedValue = _activities[_selectedIndex]['value'];
    
    // ดึง userId ปัจจุบัน
    final userId = ref.read(userDataProvider).userId;

    // --- ยิง API บันทึกลง Database ---
    bool success = await _authService.updateProfile(userId, {
      "activity_level": selectedValue,
    });

    setState(() => _isLoading = false); // หยุดโหลด

    if (success) {
      // บันทึกลง Provider เพื่อใช้ในแอป
      ref.read(userDataProvider.notifier).setActivityLevel(selectedValue);

      // ไปหน้าถัดไป
      if (mounted) {
        // ✅ 2. เช็ค Logic การไปต่อ
        if (widget.isEditing) {
          // ถ้ามาจากการแก้ไข -> ให้ย้อนกลับไปหน้า Profile
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปเดตระดับกิจกรรมเรียบร้อย'), backgroundColor: Colors.green),
          );
        } else {
          // ถ้ามาจากการสมัคร -> ไปหน้าเลือกเป้าหมายต่อ (Flow เดิม)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GoalSelectionScreen()),
          );
        }
      }
    } else {
      // แจ้งเตือนถ้าบันทึกไม่ผ่าน
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลไม่สำเร็จ กรุณาลองใหม่'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 30, right: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1D1B20)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ระดับกิจกรรม',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'ข้อมูลนี้ช่วยให้เราคำนวณการเผาผลาญพลังงาน (TDEE) ได้แม่นยำขึ้น',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 30),

            // --- List of Cards ---
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: _activities.length,
                separatorBuilder: (c, i) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  final item = _activities[index];
                  final isSelected = _selectedIndex == index;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4C6414) : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE8EFCF) : const Color(0xFFF5F5F5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item['icon'], color: isSelected ? const Color(0xFF4C6414) : Colors.grey, size: 28),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title'], style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF4C6414) : Colors.black)),
                                const SizedBox(height: 4),
                                Text(item['subtitle'], style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.black.withOpacity(0.6))),
                              ],
                            ),
                          ),
                          if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF4C6414)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- Button ---
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit, // ถ้าโหลดอยู่กดไม่ได้
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF628141),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ถัดไป', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}