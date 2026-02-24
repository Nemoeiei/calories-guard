import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http; // เพิ่ม http
import '../../../providers/user_data_provider.dart';
import '../../../login_register/screens/welcome_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // สถานะจำลองสำหรับ Switch (ในอนาคตเก็บลง SharedPreference ได้)
  bool _isNotificationOn = true;

  // --- ฟังก์ชัน 1: ลบบัญชีผู้ใช้ ---
  Future<void> _deleteAccount() async {
    final userId = ref.read(userDataProvider).userId;
    try {
      final url = Uri.parse(
          'https://unshirred-wendolyn-audiometrically.ngrok-free.dev/users/$userId');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        // ลบสำเร็จ -> เคลียร์ข้อมูล -> ไปหน้า Welcome
        ref
            .read(userDataProvider.notifier)
            .resetDailyFood(); // หรือฟังก์ชัน logout ที่สร้างไว้
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('ลบบัญชีเรียบร้อยแล้ว'),
                backgroundColor: Colors.grey),
          );
        }
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Helper: แสดง Dialog ยืนยันลบบัญชี ---
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบบัญชี',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text(
            'การกระทำนี้ไม่สามารถย้อนกลับได้ ข้อมูลทั้งหมดของคุณจะหายไป ยืนยันหรือไม่?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ปิด Dialog
              _deleteAccount(); // เรียกฟังก์ชันลบ
            },
            child: const Text('ยืนยันลบ',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Helper: แสดง Dialog ข้อมูลทั่วไป ---
  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด',
                  style: TextStyle(color: Color(0xFF4C6414)))),
        ],
      ),
    );
  }

  // --- Helper: แสดง BottomSheet เลือกภาษา ---
  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('เลือกภาษา',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
                title: const Text('ไทย (Thai)'),
                trailing: const Icon(Icons.check, color: Colors.green),
                onTap: () => Navigator.pop(context)),
            ListTile(
                title: const Text('English'),
                onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ตั้งค่า',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- Group 1: ทั่วไป ---
            _buildMenuGroup([
              _buildMenuItem('ความเป็นส่วนตัว',
                  onTap: () => _showInfoDialog('ความเป็นส่วนตัว',
                      'เราเก็บรักษาข้อมูลส่วนบุคคลของคุณอย่างปลอดภัยตามมาตรฐาน PDPA...')),
              // เปลี่ยนเป็น Switch
              Container(
                decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.black, width: 1))),
                child: SwitchListTile(
                  title: const Text('การแจ้งเตือน',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Colors.black)),
                  value: _isNotificationOn,
                  activeThumbColor: const Color(0xFF4C6414),
                  onChanged: (val) => setState(() => _isNotificationOn = val),
                ),
              ),
            ], isFirst: true),

            // --- Group 2: การแสดงผล ---
            _buildMenuGroup([
              _buildMenuItem('ภาษา', onTap: _showLanguageSelector),
              _buildMenuItem('ธีม',
                  showDivider: false,
                  onTap: () =>
                      _showInfoDialog('ธีม', 'ขณะนี้รองรับเฉพาะ Light Mode')),
            ]),

            // --- Group 3: สนับสนุน ---
            _buildMenuGroup([
              _buildMenuItem('เสนอฟีเจอร์ใหม่',
                  onTap: () => _showInfoDialog('ติดต่อเรา',
                      'ส่งข้อเสนอแนะได้ที่ support@cleangoal.com')),
              _buildMenuItem('ขอความช่วยเหลือ',
                  showDivider: false,
                  onTap: () => _showInfoDialog(
                      'ช่วยเหลือ', 'คู่มือการใช้งานเบื้องต้น...')),
            ]),

            // --- Group 4: เกี่ยวกับ ---
            _buildMenuGroup([
              _buildMenuItem('ให้คะแนนเรา',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('ขอบคุณที่ให้คะแนนเรา ❤️')))),
              _buildMenuItem('เกี่ยวกับ',
                  showDivider: false,
                  onTap: () => _showInfoDialog('เกี่ยวกับแอป',
                      'CleanGoal Version 1.0.0\nDeveloped by You')),
            ]),

            // --- Group 5: บัญชี ---
            _buildMenuGroup([
              _buildMenuItem('เปลี่ยนบัญชี', onTap: () {
                // Logout Logic
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WelcomeScreen()),
                    (route) => false);
              }),
              _buildMenuItem('ลบบัญชี',
                  showDivider: false,
                  isDestructive: true,
                  onTap: _showDeleteConfirmDialog), // ✅ เรียก Dialog ลบ
            ]),

            const SizedBox(height: 40),

            // --- ปุ่มออกจากระบบ ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 65),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WelcomeScreen()),
                      (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D4D),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                ),
                child: const Text('ออกจากระบบ',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildMenuGroup(List<Widget> children, {bool isFirst = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top:
              isFirst ? const BorderSide(color: Colors.black) : BorderSide.none,
          left: const BorderSide(color: Colors.black),
          right: const BorderSide(color: Colors.black),
          bottom: const BorderSide(color: Colors.black),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(String title,
      {bool showDivider = true,
      VoidCallback? onTap,
      bool isDestructive = false}) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: Colors.black, width: 1))
            : null,
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400,
            color: isDestructive
                ? Colors.red
                : Colors.black, // สีแดงถ้าเป็นปุ่มอันตราย
          ),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
        onTap: onTap,
      ),
    );
  }
}
