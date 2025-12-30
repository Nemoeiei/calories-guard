import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GoalOption {
  loseWeight,
  maintainWeight,
  buildMuscle,
}

class UserData {
  // ... (ตัวแปรเดิม Login / Personal Info / Goal) ...
  final String email;
  final String password;
  final String name;
  final String gender;
  final DateTime? birthDate;
  final double height;
  final double weight;
  final GoalOption? goal;
  final double targetWeight;
  final int duration;
  final String activityLevel;

  // --- ข้อมูลโภชนาการ (ตัวเลข) ---
  final int consumedCalories;
  final int consumedProtein;
  final int consumedCarbs;
  final int consumedFat;

  // --- 🔥 เพิ่มใหม่: ชื่อเมนูอาหาร (String) ---
  final String breakfastMenu;
  final String lunchMenu;
  final String dinnerMenu;
  final String snackMenu; // รวมมื้อว่าง 1+2

  UserData({
    this.email = '',
    this.password = '',
    this.name = 'User',
    this.gender = 'male',
    this.birthDate,
    this.height = 0.0,
    this.weight = 0.0,
    this.goal,
    this.targetWeight = 0.0,
    this.duration = 0,
    this.activityLevel = 'ไม่ออกกำลังกายเลย',
    this.consumedCalories = 0,
    this.consumedProtein = 0,
    this.consumedCarbs = 0,
    this.consumedFat = 0,
    // Default เมนูเป็นว่าง
    this.breakfastMenu = '',
    this.lunchMenu = '',
    this.dinnerMenu = '',
    this.snackMenu = '',
  });

  // ... (Getters: age, bmr, tdee, targetCalories เหมือนเดิม ไม่ต้องแก้) ...
  int get age {
    if (birthDate == null) return 20;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  double get bmr {
    if (weight == 0 || height == 0) return 1500;
    double base = (10 * weight) + (6.25 * height) - (5 * age);
    return (gender == 'male') ? base + 5 : base - 161;
  }

  double get tdee {
    double activityMultiplier = 1.2;
    if (activityLevel.contains('เบาๆ')) activityMultiplier = 1.375;
    else if (activityLevel.contains('ปานกลาง')) activityMultiplier = 1.55;
    else if (activityLevel.contains('หนัก')) activityMultiplier = 1.725;
    else if (activityLevel.contains('หนักมาก')) activityMultiplier = 1.9;
    return bmr * activityMultiplier;
  }

  double get targetCalories {
    double maintenance = tdee;
    if (goal == GoalOption.loseWeight) return maintenance - 500;
    else if (goal == GoalOption.buildMuscle) return maintenance + 300;
    return maintenance;
  }

  UserData copyWith({
    String? email,
    String? password,
    String? name,
    String? gender,
    DateTime? birthDate,
    double? height,
    double? weight,
    GoalOption? goal,
    double? targetWeight,
    int? duration,
    String? activityLevel,
    int? consumedCalories,
    int? consumedProtein,
    int? consumedCarbs,
    int? consumedFat,
    String? breakfastMenu,
    String? lunchMenu,
    String? dinnerMenu,
    String? snackMenu,
  }) {
    return UserData(
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      targetWeight: targetWeight ?? this.targetWeight,
      duration: duration ?? this.duration,
      activityLevel: activityLevel ?? this.activityLevel,
      consumedCalories: consumedCalories ?? this.consumedCalories,
      consumedProtein: consumedProtein ?? this.consumedProtein,
      consumedCarbs: consumedCarbs ?? this.consumedCarbs,
      consumedFat: consumedFat ?? this.consumedFat,
      // Update Menu Names
      breakfastMenu: breakfastMenu ?? this.breakfastMenu,
      lunchMenu: lunchMenu ?? this.lunchMenu,
      dinnerMenu: dinnerMenu ?? this.dinnerMenu,
      snackMenu: snackMenu ?? this.snackMenu,
    );
  }
}

class UserDataNotifier extends StateNotifier<UserData> {
  UserDataNotifier() : super(UserData());

  // ... (Functions เดิม setLoginInfo...setGoalInfo...setActivityLevel) ...
  void setLoginInfo(String email, String password) {
    state = state.copyWith(email: email, password: password);
  }
  void setGender(String gender) {
    state = state.copyWith(gender: gender);
  }
  void setPersonalInfo({required String name, required DateTime birthDate, required double height, required double weight}) {
    state = state.copyWith(name: name, birthDate: birthDate, height: height, weight: weight);
  }
  void setGoal(GoalOption goal) {
    state = state.copyWith(goal: goal);
  }
  void setGoalInfo({required double targetWeight, required int duration}) {
    state = state.copyWith(targetWeight: targetWeight, duration: duration);
  }
  void setActivityLevel(String level) {
    state = state.copyWith(activityLevel: level);
  }

  // 🔥 อัปเดตทั้งแคลอรี่และชื่อเมนู
  void updateDailyFood({
    required int cal, 
    required int protein, 
    required int carbs, 
    required int fat,
    required String breakfast,
    required String lunch,
    required String dinner,
    required String snack,
  }) {
    state = state.copyWith(
      consumedCalories: cal,
      consumedProtein: protein,
      consumedCarbs: carbs,
      consumedFat: fat,
      breakfastMenu: breakfast,
      lunchMenu: lunch,
      dinnerMenu: dinner,
      snackMenu: snack,
    );
  }
}

final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData>((ref) {
  return UserDataNotifier();
});