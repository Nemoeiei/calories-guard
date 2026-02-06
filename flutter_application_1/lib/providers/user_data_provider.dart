import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

// Enum สำหรับเป้าหมาย
enum GoalOption {
  loseWeight,
  maintainWeight,
  buildMuscle,
}

class UserData {
  // --- 1. ส่วนข้อมูลพื้นฐาน (Login & Profile) ---
  final int userId;
  final String email;
  final String password;
  final String name;
  final String gender;
  final DateTime? birthDate;
  final double height;
  final double weight;

  // --- 2. ส่วนเป้าหมาย (Goal) ---
  final GoalOption? goal;
  final double targetWeight;
  final int duration;
  final String activityLevel;
  final DateTime? targetDate;

  // --- 3. ส่วนข้อมูลโภชนาการรายวัน (Nutrition) ---
  final int consumedCalories;
  final int consumedProtein;
  final int consumedCarbs;
  final int consumedFat;

  // --- 4. ส่วนชื่อเมนูอาหาร (Food Menu Names) ---
  final String breakfastMenu;
  final String lunchMenu;
  final String dinnerMenu;
  final String snackMenu;

  // --- 5. หน่วยนับ (Unit) ---
  final String unitWeight;
  final String unitHeight;
  final String unitEnergy;
  final String unitWater;

  UserData({
    this.userId = 0,
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
    this.activityLevel = 'sedentary',
    this.targetDate,
    this.consumedCalories = 0,
    this.consumedProtein = 0,
    this.consumedCarbs = 0,
    this.consumedFat = 0,
    this.breakfastMenu = '',
    this.lunchMenu = '',
    this.dinnerMenu = '',
    this.snackMenu = '',
    this.unitWeight = 'kg',
    this.unitHeight = 'cm',
    this.unitEnergy = 'kcal',
    this.unitWater = 'ml',
  });

  // --- 🧮 Logic 1: คำนวณอายุ ---
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

  // --- 🔥 Logic 2: คำนวณ BMR ---
  double get bmr {
    if (weight == 0 || height == 0) return 1500;
    double base = (10 * weight) + (6.25 * height) - (5 * age);
    if (gender == 'male') {
      return base + 5;
    } else {
      return base - 161;
    }
  }

  // --- 🏃‍♂️ Logic 3: คำนวณ TDEE (แก้ให้ตรงกับ Database ใหม่) ---
  double get tdee {
    double activityMultiplier = 1.2; // sedentary

    // ✅ แก้ไข: ใช้ string ให้ตรงกับ Enum ใน Database ใหม่
    if (activityLevel == 'lightly_active') {
      // เดิม light
      activityMultiplier = 1.375;
    } else if (activityLevel == 'moderately_active') {
      // เดิม moderate
      activityMultiplier = 1.55;
    } else if (activityLevel == 'very_active') {
      // เดิม active
      activityMultiplier = 1.725;
    }

    return bmr * activityMultiplier;
  }

  // --- 🎯 Logic 4: คำนวณแคลอรี่เป้าหมาย ---
  double get targetCalories {
    double maintenance = tdee;
    if (goal == GoalOption.loseWeight) {
      return maintenance - 500;
    } else if (goal == GoalOption.buildMuscle) {
      return maintenance + 300;
    }
    return maintenance;
  }

  // ✅ Logic 5: คำนวณสารอาหาร (Macros)
  int get targetProtein {
    double proteinCals = targetCalories * 0.30;
    return (proteinCals / 4).round();
  }

  int get targetCarbs {
    double carbsCals = targetCalories * 0.40;
    return (carbsCals / 4).round();
  }

  int get targetFat {
    double fatCals = targetCalories * 0.30;
    return (fatCals / 9).round();
  }

  // --- CopyWith ---
  UserData copyWith({
    int? userId,
    String? email,
    String? password,
    String? name,
    String? gender,
    DateTime? birthDate,
    double? height,
    double? weight,
    GoalOption? goal,
    double? targetWeight,
    DateTime? targetDate,
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
    String? unitWeight,
    String? unitHeight,
    String? unitEnergy,
    String? unitWater,
  }) {
    return UserData(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      targetWeight: targetWeight ?? this.targetWeight,
      targetDate: targetDate ?? this.targetDate,
      duration: duration ?? this.duration,
      activityLevel: activityLevel ?? this.activityLevel,
      consumedCalories: consumedCalories ?? this.consumedCalories,
      consumedProtein: consumedProtein ?? this.consumedProtein,
      consumedCarbs: consumedCarbs ?? this.consumedCarbs,
      consumedFat: consumedFat ?? this.consumedFat,
      breakfastMenu: breakfastMenu ?? this.breakfastMenu,
      lunchMenu: lunchMenu ?? this.lunchMenu,
      dinnerMenu: dinnerMenu ?? this.dinnerMenu,
      snackMenu: snackMenu ?? this.snackMenu,
      unitWeight: unitWeight ?? this.unitWeight,
      unitHeight: unitHeight ?? this.unitHeight,
      unitEnergy: unitEnergy ?? this.unitEnergy,
      unitWater: unitWater ?? this.unitWater,
    );
  }
}

// --- Notifier ---
class UserDataNotifier extends StateNotifier<UserData> {
  UserDataNotifier() : super(UserData());

  // ✅ เพิ่มฟังก์ชัน Logout
  void logout() {
    state = UserData(); // Reset กลับเป็นค่าเริ่มต้นทั้งหมด
  }

  void setUserId(int id) {
    state = state.copyWith(userId: id);
  }

  void setLoginInfo(String email, String password) {
    state = state.copyWith(email: email, password: password);
  }

  void setGender(String gender) {
    state = state.copyWith(gender: gender);
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
  }

  void setGoal(GoalOption goal) {
    state = state.copyWith(goal: goal);
  }

  void setGoalInfo({
    required double targetWeight,
    DateTime? targetDate,
    int? duration,
  }) {
    state = state.copyWith(
      targetWeight: targetWeight,
      targetDate: targetDate,
      duration: duration ?? state.duration,
    );
  }

  void setActivityLevel(String level) {
    state = state.copyWith(activityLevel: level);
  }

  // อัปเดตข้อมูลอาหารรายวัน (Manual)
  void updateDailyFood({
    required int cal,
    required int protein,
    required int carbs,
    required int fat,
    // เพิ่มพารามิเตอร์ชื่อเมนู (ใส่ default เป็นค่าว่าง)
    String breakfast = '',
    String lunch = '',
    String dinner = '',
    String snack = '',
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

  // ✅ เพิ่มฟังก์ชันนี้: รับค่าจาก API /daily_summary มาใส่ Provider
  void setDailySummaryFromApi(Map<String, dynamic> data) {
    state = state.copyWith(
      consumedCalories: (data['total_calories_intake'] as num?)?.toInt() ?? 0,
      consumedProtein: (data['total_protein'] as num?)?.toInt() ?? 0,
      consumedCarbs: (data['total_carbs'] as num?)?.toInt() ?? 0,
      consumedFat: (data['total_fat'] as num?)?.toInt() ?? 0,

      // ✅ [เพิ่มส่วนนี้] รับค่าชื่อเมนูจาก API มาใส่ใน State
      breakfastMenu: data['breakfast_menu'] ?? '',
      lunchMenu: data['lunch_menu'] ?? '',
      dinnerMenu: data['dinner_menu'] ?? '',
      snackMenu: data['snack_menu'] ?? '',
    );
  }

  void resetDailyFood() {
    state = state.copyWith(
      consumedCalories: 0,
      consumedProtein: 0,
      consumedCarbs: 0,
      consumedFat: 0,
      breakfastMenu: '',
      lunchMenu: '',
      dinnerMenu: '',
      snackMenu: '',
    );
  }

  void updateUnit(
      {String? weight, String? height, String? energy, String? water}) {
    state = state.copyWith(
      unitWeight: weight ?? state.unitWeight,
      unitHeight: height ?? state.unitHeight,
      unitEnergy: energy ?? state.unitEnergy,
      unitWater: water ?? state.unitWater,
    );
  }

  void setUserFromApi(Map<String, dynamic> data) {
    DateTime? tDate;
    if (data['goal_target_date'] != null) {
      tDate = DateTime.parse(data['goal_target_date']);
    }

    DateTime? bDate;
    if (data['birth_date'] != null) {
      bDate = DateTime.parse(data['birth_date']);
    }

    GoalOption userGoal = GoalOption.loseWeight;
    if (data['goal_type'] == 'maintain_weight')
      userGoal = GoalOption.maintainWeight;
    if (data['goal_type'] == 'gain_muscle')
      userGoal = GoalOption
          .buildMuscle; // แก้ build_muscle เป็น gain_muscle ตาม DB ใหม่

    state = state.copyWith(
      userId: data['user_id'] ?? 0,
      name: data['username'] ?? 'User',
      email: data['email'] ?? '',
      gender: data['gender'] ?? 'male',
      birthDate: bDate,
      height: (data['height_cm'] as num?)?.toDouble() ?? 0.0,
      weight: (data['current_weight_kg'] as num?)?.toDouble() ?? 0.0,
      targetWeight: (data['target_weight_kg'] as num?)?.toDouble() ?? 0.0,
      targetDate: tDate,
      goal: userGoal,
      activityLevel: data['activity_level'] ?? 'sedentary',
      unitWeight: data['unit_weight'] ?? 'kg',
      unitHeight: data['unit_height'] ?? 'cm',
      unitEnergy: data['unit_energy'] ?? 'kcal',
      unitWater: data['unit_water'] ?? 'ml',
    );
  }
}

final userDataProvider =
    StateNotifierProvider<UserDataNotifier, UserData>((ref) {
  return UserDataNotifier();
});
final navIndexProvider = StateProvider<int>((ref) => 0);
