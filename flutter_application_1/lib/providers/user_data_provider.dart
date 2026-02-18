import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  // ❌ ลบตัวแปรแยก (Breakfast, Lunch...) ออก
  // ✅ ใช้ Map เพื่อเก็บมื้ออาหารแบบ Dynamic (เช่น {'meal_1': 'ข้าวมันไก่', 'meal_2': 'สุกี้'})
  final Map<String, String> dailyMeals;

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
    this.dailyMeals = const {}, // ✅ Default เป็น Map ว่าง
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

  // --- 🏃‍♂️ Logic 3: คำนวณ TDEE ---
  double get tdee {
    double activityMultiplier = 1.2; // sedentary
    if (activityLevel == 'lightly_active') {
      activityMultiplier = 1.375;
    } else if (activityLevel == 'moderately_active') {
      activityMultiplier = 1.55;
    } else if (activityLevel == 'very_active') {
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
    Map<String, String>? dailyMeals, // ✅ รับ Map แทน String แยก
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
      dailyMeals: dailyMeals ?? this.dailyMeals, // ✅ Copy Map
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
  
  void logout() {
    state = UserData(); 
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

  // ✅ อัปเดตข้อมูลอาหารรายวัน (Manual) แบบรับ Map
  void updateDailyFood({
    required int cal,
    required int protein,
    required int carbs,
    required int fat,
    // รับเป็น Map แทนที่จะเป็น String แยก
    Map<String, String> dailyMeals = const {}, 
  }) {
    state = state.copyWith(
      consumedCalories: cal,
      consumedProtein: protein,
      consumedCarbs: carbs,
      consumedFat: fat,
      dailyMeals: dailyMeals, // ✅ บันทึก Map
    );
  }
  
  // ✅ รับค่าจาก API /daily_summary มาใส่ Provider
  void setDailySummaryFromApi(Map<String, dynamic> data) {
    // แปลงข้อมูลจาก API ('meals': {...}) มาเป็น Map<String, String>
    Map<String, String> meals = {};
    if (data['meals'] != null) {
       meals = Map<String, String>.from(data['meals']);
    }

    state = state.copyWith(
      consumedCalories: (data['total_calories_intake'] as num?)?.toInt() ?? 0,
      consumedProtein: (data['total_protein'] as num?)?.toInt() ?? 0,
      consumedCarbs: (data['total_carbs'] as num?)?.toInt() ?? 0,
      consumedFat: (data['total_fat'] as num?)?.toInt() ?? 0,
      dailyMeals: meals, // ✅ อัปเดต Map จาก API
    );
  }

  void resetDailyFood() {
    state = state.copyWith(
      consumedCalories: 0,
      consumedProtein: 0,
      consumedCarbs: 0,
      consumedFat: 0,
      dailyMeals: {}, // ✅ Reset เป็น Map ว่าง
    );
  }

  void updateUnit({String? weight, String? height, String? energy, String? water}) {
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
    if (data['goal_type'] == 'maintain_weight') userGoal = GoalOption.maintainWeight;
    if (data['goal_type'] == 'gain_muscle') userGoal = GoalOption.buildMuscle;

    // หน่วย (unit_*) backend schema ใหม่ไม่มีใน users — ใช้ค่าเดิมในแอปหรือ default
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
      unitWeight: data['unit_weight'] ?? state.unitWeight,
      unitHeight: data['unit_height'] ?? state.unitHeight,
      unitEnergy: data['unit_energy'] ?? state.unitEnergy,
      unitWater: data['unit_water'] ?? state.unitWater,
    );
  }
}

final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData>((ref) {
  return UserDataNotifier();
});
final navIndexProvider = StateProvider<int>((ref) => 0);