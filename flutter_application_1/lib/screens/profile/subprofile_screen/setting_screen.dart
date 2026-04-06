import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/constants/constants.dart';
import '../../../providers/user_data_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../login_register/screens/welcome_screen.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  static const _green = Color(0xFF628141);
  static const _greenDark = Color(0xFF3D5A27);

  bool _isNotificationOn = true;

  // ─── Delete Account ──────────────────────────────────────────────────────
  Future<void> _deleteAccount() async {
    final userId = ref.read(userDataProvider).userId;
    try {
      final response =
          await http.delete(Uri.parse('${AppConstants.baseUrl}/users/$userId'));
      if (response.statusCode == 200) {
        ref.read(userDataProvider.notifier).resetDailyFood();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('ลบบัญชีเรียบร้อยแล้ว'),
                backgroundColor: Colors.grey),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการลบบัญชี',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text(
            'การกระทำนี้ไม่สามารถย้อนกลับได้ ข้อมูลทั้งหมดของคุณจะหายไป ยืนยันหรือไม่?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('ยืนยันลบ',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('ปิด')),
        ],
      ),
    );
  }

  // ─── Language Selector (persisted) ──────────────────────────────────────
  void _showLanguageSelector() {
    final current = ref.read(appSettingsProvider).language;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('เลือกภาษา / Select Language',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _languageOption(
            flag: '🇹🇭',
            label: 'ไทย (Thai)',
            code: 'th',
            selected: current == 'th',
          ),
          const SizedBox(height: 10),
          _languageOption(
            flag: '🇬🇧',
            label: 'English',
            code: 'en',
            selected: current == 'en',
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _languageOption({
    required String flag,
    required String label,
    required String code,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(appSettingsProvider.notifier).setLanguage(code);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('เปลี่ยนภาษาเป็น $label แล้ว'),
          backgroundColor: _green,
          duration: const Duration(seconds: 2),
        ));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF2DB) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _green : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: _green, size: 22)
          else
            Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 22),
        ]),
      ),
    );
  }

  // ─── Theme Selector (persisted) ─────────────────────────────────────────
  void _showThemeSelector() {
    final current = ref.read(appSettingsProvider).theme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('เลือกธีม / Choose Theme',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _themeOption(
            icon: Icons.wb_sunny_rounded,
            label: 'สว่าง (Light)',
            code: 'light',
            color: const Color(0xFFF39C12),
            selected: current == 'light',
          ),
          const SizedBox(height: 10),
          _themeOption(
            icon: Icons.nightlight_round,
            label: 'มืด (Dark)',
            code: 'dark',
            color: const Color(0xFF2C3E50),
            selected: current == 'dark',
          ),
          const SizedBox(height: 10),
          _themeOption(
            icon: Icons.settings_system_daydream_rounded,
            label: 'ตามระบบ (System)',
            code: 'system',
            color: const Color(0xFF3498DB),
            selected: current == 'system',
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _themeOption({
    required IconData icon,
    required String label,
    required String code,
    required Color color,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(appSettingsProvider.notifier).setTheme(code);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('เปลี่ยนธีมเป็น $label แล้ว'),
          backgroundColor: _green,
          duration: const Duration(seconds: 2),
        ));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: color, size: 22)
          else
            Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 22),
        ]),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final langLabel = settings.language == 'en' ? 'English' : 'ไทย';
    final themeLabel = switch (settings.theme) {
      'dark' => 'มืด',
      'system' => 'ตามระบบ',
      _ => 'สว่าง',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F0),
      body: SingleChildScrollView(
        child: Column(children: [
          // ─── Header ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_greenDark, _green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const Expanded(
                child: Text('ตั้งค่า',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              const SizedBox(width: 40),
            ]),
          ),

          const SizedBox(height: 24),

          // ─── Group 1: ทั่วไป ──────────────────────────────────
          _buildSectionLabel('ทั่วไป'),
          const SizedBox(height: 10),
          _buildCard([
            _buildTile(
              icon: Icons.privacy_tip_outlined,
              iconColor: Colors.grey.shade500,
              title: 'ความเป็นส่วนตัว',
              onTap: () => _showInfoDialog('ความเป็นส่วนตัว',
                  'เราเก็บรักษาข้อมูลส่วนบุคคลของคุณอย่างปลอดภัยตามมาตรฐาน PDPA'),
            ),
            _buildNotificationTile(),
          ]),

          const SizedBox(height: 16),

          // ─── Group 2: การแสดงผล ───────────────────────────────
          _buildSectionLabel('การแสดงผล'),
          const SizedBox(height: 10),
          _buildCard([
            _buildTileWithValue(
              icon: Icons.language_rounded,
              iconColor: Colors.grey.shade500,
              title: 'ภาษา',
              value: langLabel,
              onTap: _showLanguageSelector,
            ),
            _buildTileWithValue(
              icon: Icons.palette_outlined,
              iconColor: Colors.grey.shade500,
              title: 'ธีม',
              value: themeLabel,
              isLast: true,
              onTap: _showThemeSelector,
            ),
          ]),

          const SizedBox(height: 16),

          // ─── Group 3: สนับสนุน ───────────────────────────────
          _buildSectionLabel('สนับสนุน'),
          const SizedBox(height: 10),
          _buildCard([
            _buildTile(
              icon: Icons.lightbulb_outline_rounded,
              iconColor: Colors.grey.shade500,
              title: 'เสนอฟีเจอร์ใหม่',
              onTap: () => _showInfoDialog('ติดต่อเรา',
                  'ส่งข้อเสนอแนะได้ที่ support@caloriesguard.com'),
            ),
            _buildTile(
              icon: Icons.help_outline_rounded,
              iconColor: Colors.grey.shade500,
              title: 'ขอความช่วยเหลือ',
              isLast: true,
              onTap: () =>
                  _showInfoDialog('ช่วยเหลือ', 'คู่มือการใช้งานเบื้องต้น...'),
            ),
          ]),

          const SizedBox(height: 16),

          // ─── Group 4: เกี่ยวกับ ───────────────────────────────
          _buildSectionLabel('เกี่ยวกับ'),
          const SizedBox(height: 10),
          _buildCard([
            _buildTile(
              icon: Icons.star_outline_rounded,
              iconColor: Colors.grey.shade500,
              title: 'ให้คะแนนเรา',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ขอบคุณที่ให้คะแนนเรา ❤️'))),
            ),
            _buildTile(
              icon: Icons.info_outline_rounded,
              iconColor: Colors.grey.shade500,
              title: 'เกี่ยวกับ',
              isLast: true,
              onTap: () => _showInfoDialog(
                  'เกี่ยวกับแอป', 'Calories Guard v1.0.0'),
            ),
          ]),

          const SizedBox(height: 16),

          // ─── Group 5: บัญชี ───────────────────────────────────
          _buildSectionLabel('บัญชี'),
          const SizedBox(height: 10),
          _buildCard([
            _buildTile(
              icon: Icons.swap_horiz_rounded,
              iconColor: Colors.grey.shade500,
              title: 'เปลี่ยนบัญชี',
              onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false),
            ),
            _buildTile(
              icon: Icons.delete_outline_rounded,
              iconColor: Colors.grey.shade500,
              title: 'ลบบัญชี',
              isDestructive: true,
              isLast: true,
              onTap: _showDeleteConfirmDialog,
            ),
          ]),

          const SizedBox(height: 32),

          // ─── Logout ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('ออกจากระบบ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE74C3C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  // ─── Helper Widgets ───────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    VoidCallback? onTap,
    bool isLast = false,
    bool isDestructive = false,
  }) {
    return Column(children: [
      ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : Colors.black87)),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Colors.grey.shade400),
        onTap: onTap,
      ),
      if (!isLast)
        Divider(
            height: 1,
            indent: 70,
            endIndent: 20,
            color: Colors.grey.shade100),
    ]);
  }

  Widget _buildTileWithValue({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Column(children: [
      ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.grey.shade400),
        ]),
        onTap: onTap,
      ),
      if (!isLast)
        Divider(
            height: 1,
            indent: 70,
            endIndent: 20,
            color: Colors.grey.shade100),
    ]);
  }

  Widget _buildNotificationTile() {
    return Column(children: [
      ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.notifications_outlined,
              color: Colors.grey.shade500, size: 20),
        ),
        title: const Text('การแจ้งเตือน',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        trailing: Switch(
          value: _isNotificationOn,
          activeColor: _green,
          onChanged: (val) => setState(() => _isNotificationOn = val),
        ),
      ),
      Divider(
          height: 1,
          indent: 70,
          endIndent: 20,
          color: Colors.grey.shade100),
    ]);
  }
}
