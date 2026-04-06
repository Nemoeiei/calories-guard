/// lifecycle_service.dart
/// ตรวจสภาพ user lifecycle และยิง notification ที่เหมาะสม
/// - ทุก 2 สัปดาห์ : เตือนบันทึกน้ำหนัก
/// - ทุกวันเกิด    : recalc TDEE + แจ้งเตือน
/// - ทุก 30 วัน    : สรุปรายเดือน + on_track status
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/constants/constants.dart';
import 'notification_helper.dart';

class LifecycleService {
  /// เรียกหลัง login สำเร็จ หรือเมื่อเปิดแอปขึ้นมา
  static Future<void> runChecks(int userId) async {
    if (userId == 0) return;
    try {
      // ── Step 1: lifecycle_check ───────────────────────────
      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId/lifecycle_check'),
      );
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      final weightOverdue = data['weight_overdue'] == true;
      final daysSince = data['days_since_weight'] as int?;
      final isBirthday = data['is_birthday'] == true;
      final tdeeNeedsUpdate = data['tdee_needs_update'] == true;
      final monthlySummary = data['monthly_summary'] == true;
      final goalDaysLeft = data['goal_days_left'] as int?;
      final onTrack = data['on_track'] as bool?;

      // ── Step 2: น้ำหนัก overdue ──────────────────────────
      await NotificationHelper.showWeightReminderIfOverdue(
        overdue: weightOverdue,
        daysSince: daysSince,
      );

      // ── Step 3: Birthday / TDEE recalc ───────────────────
      int? newTargetCal;
      if (isBirthday || tdeeNeedsUpdate) {
        final recalcRes = await http.post(
          Uri.parse('${AppConstants.baseUrl}/users/$userId/recalc_tdee'),
        );
        if (recalcRes.statusCode == 200) {
          final rd = jsonDecode(recalcRes.body);
          newTargetCal = (rd['new_target_calories'] as num?)?.toInt();
        }
      }
      await NotificationHelper.showBirthdayAndTdeeUpdate(
        isBirthday: isBirthday,
        tdeeNeedsUpdate: tdeeNeedsUpdate,
        newTargetCalories: newTargetCal,
      );

      // ── Step 4: Monthly summary ───────────────────────────
      await NotificationHelper.showMonthlySummary(
        trigger: monthlySummary,
        goalDaysLeft: goalDaysLeft,
        onTrack: onTrack,
      );
    } catch (_) {
      // silent — ไม่ให้ lifecycle check ทำให้แอปพัง
    }
  }
}
