import 'package:flutter_riverpod/flutter_riverpod.dart';

// 0. ย้าย Enum มาไว้ที่นี่ (หรือสร้างไฟล์แยก) เพื่อป้องกันปัญหา Circular Import
enum GoalOption {
  loseWeight,
  maintainWeight,
  buildMuscle,
}

// 1. สร้าง Model ตามโครงสร้าง
class UserData {
  // --- ส่วน Login ---
  final String email;
  final String password;

  // --- ส่วนข้อมูลส่วนตัว ---
  final String name;
  final DateTime? birthDate;
  final double height;
  final double weight;

  // --- ส่วนเป้าหมาย (เพิ่มใหม่) ---
  final GoalOption? goal; // 👈 เพิ่มตัวแปร goal
  final double targetWeight;
  final int duration;

  // --- ส่วนเพิ่มเติม ---
  final String activityLevel;

  UserData({
    this.email = '',
    this.password = '',
    this.name = '',
    this.birthDate,
    this.height = 0.0,
    this.weight = 0.0,
    this.goal, // 👈 เพิ่มใน Constructor
    this.targetWeight = 0.0,
    this.duration = 0,
    this.activityLevel = 'ไม่ออกกำลังกายเลย',
  });

  // ฟังก์ชัน CopyWith
  UserData copyWith({
    String? email,
    String? password,
    String? name,
    DateTime? birthDate,
    double? height,
    double? weight,
    GoalOption? goal, // 👈 เพิ่มใน CopyWith
    double? targetWeight,
    int? duration,
    String? activityLevel,
  }) {
    return UserData(
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal, // 👈 อัปเดตค่า goal
      targetWeight: targetWeight ?? this.targetWeight,
      duration: duration ?? this.duration,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }
}

// 2. สร้าง Notifier
class UserDataNotifier extends StateNotifier<UserData> {
  UserDataNotifier() : super(UserData());

  void setLoginInfo(String email, String password) {
    state = state.copyWith(email: email, password: password);
    print("Updated Login: ${state.email}");
  }

  void setPersonalInfo({
    required String name,
    required DateTime birthDate,
    required double height,
    required double weight,
  }) {
    state = state.copyWith(
      name: name,
      birthDate: birthDate,
      height: height,
      weight: weight,
    );
    print("Updated Personal Info: ${state.name}, H:${state.height}, W:${state.weight}");
  }

  // 👇 เพิ่มฟังก์ชันบันทึกเป้าหมาย (Goal)
  void setGoal(GoalOption goal) {
    state = state.copyWith(goal: goal);
    print("Updated Goal Option: $goal");
  }

  void setGoalInfo({
    required double targetWeight,
    required int duration,
  }) {
    state = state.copyWith(
      targetWeight: targetWeight,
      duration: duration,
    );
    print("Updated Goal Info: Target ${state.targetWeight}, Duration ${state.duration}");
  }

  void clearData() {
    state = UserData();
  }
}

// 3. สร้าง Provider
final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData>((ref) {
  return UserDataNotifier();
});