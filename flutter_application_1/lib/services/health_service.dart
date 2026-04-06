import 'package:health/health.dart';

/// Service สำหรับซิงค์ข้อมูลสุขภาพจาก Samsung Health / Google Fit / Apple Health
class HealthService {
  static final _health = Health();

  // ประเภทข้อมูลที่ต้องการ (calories burned + steps)
  static const _types = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.STEPS,
    HealthDataType.WORKOUT,
  ];

  static const _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  /// ขอ permission และตรวจว่า authorized
  static Future<bool> requestPermissions() async {
    try {
      final requested = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      return requested;
    } catch (_) {
      return false;
    }
  }

  /// ดึงแคลอรี่ที่เผาผลาญในวันที่กำหนด (kcal)
  static Future<double> fetchCaloriesBurned(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );
      double total = 0;
      for (final point in data) {
        final v = point.value;
        if (v is NumericHealthValue) {
          total += v.numericValue.toDouble();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// ดึงจำนวนก้าวในวันที่กำหนด
  static Future<int> fetchSteps(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// ดึง workouts ในวันที่กำหนด
  static Future<List<HealthDataPoint>> fetchWorkouts(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      return await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.WORKOUT],
      );
    } catch (_) {
      return [];
    }
  }
}
