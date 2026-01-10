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
  final String gender; // 'male' or 'female'
  final DateTime? birthDate;
  final double height;
  final double weight;

  // --- 2. ส่วนเป้าหมาย (Goal) ---
  final GoalOption? goal;
  final double targetWeight;
  final int duration;
  final String activityLevel; // ระดับกิจกรรม (sedentary, light, moderate...)
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
  final String snackMenu; // รวมมื้อว่าง 1+2

  // --- 5. หน่วยนับ (Unit) ---
  final String unitWeight; // 'kg', 'lbs'
  final String unitHeight; // 'cm', 'ft'
  final String unitEnergy; // 'kcal', 'kj'
  final String unitWater;  // 'ml', 'bottle'

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
    this.activityLevel = 'sedentary', // Default เป็นภาษาอังกฤษ
    this.targetDate,
    // Default values เริ่มต้นเป็น 0
    this.consumedCalories = 0,
    this.consumedProtein = 0,
    this.consumedCarbs = 0,
    this.consumedFat = 0,
    // Default ชื่อเมนูเป็นค่าว่าง
    this.breakfastMenu = '',
    this.lunchMenu = '',
    this.dinnerMenu = '',
    this.snackMenu = '',
    // Default หน่วยนับ
    this.unitWeight = 'kg',
    this.unitHeight = 'cm',
    this.unitEnergy = 'kcal',
    this.unitWater = 'ml',
  });

  // --- 🧮 Logic 1: คำนวณอายุ ---
  int get age {
    if (birthDate == null) return 20; // Default age
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  // --- 🔥 Logic 2: คำนวณ BMR (พลังงานพื้นฐาน) ---
  // สูตร Mifflin-St Jeor Equation
  double get bmr {
    if (weight == 0 || height == 0) return 1500; // ค่ากัน Error
    
    // สูตร: (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) + s
    double base = (10 * weight) + (6.25 * height) - (5 * age);
    
    if (gender == 'male') {
      return base + 5;
    } else {
      return base - 161;
    }
  }

  // --- 🏃‍♂️ Logic 3: คำนวณ TDEE (พลังงานรวมกิจกรรม) ---
  double get tdee {
    double activityMultiplier = 1.2; // Default: sedentary

    // ✅ เช็คจาก Value ภาษาอังกฤษ (ดูเป็นทางการ & จัดการง่าย)
    if (activityLevel == 'light') {
      activityMultiplier = 1.375;
    } else if (activityLevel == 'moderate') {
      activityMultiplier = 1.55;
    } else if (activityLevel == 'active') {
      activityMultiplier = 1.725;
    } else if (activityLevel == 'extreme') {
      activityMultiplier = 1.9;
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
  // สัดส่วนมาตรฐาน: Protein 30% / Carbs 40% / Fat 30% (ปรับเปลี่ยนได้ตามสูตรที่ต้องการ)
  
  int get targetProtein {
    // 1 กรัม = 4 kcal
    // สมมติให้กินโปรตีน 30% ของแคลอรี่ทั้งหมด
    double proteinCals = targetCalories * 0.30; 
    return (proteinCals / 4).round();
  }

  int get targetCarbs {
    // 1 กรัม = 4 kcal
    // สมมติให้กินคาร์บ 40% ของแคลอรี่ทั้งหมด
    double carbsCals = targetCalories * 0.40;
    return (carbsCals / 4).round();
  }

  int get targetFat {
    // 1 กรัม = 9 kcal
    // สมมติให้กินไขมัน 30% ของแคลอรี่ทั้งหมด
    double fatCals = targetCalories * 0.30;
    return (fatCals / 9).round();
  }

  // --- CopyWith: ฟังก์ชันสำหรับอัปเดตค่า ---
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

// --- Notifier: ตัวจัดการ State ---
class UserDataNotifier extends StateNotifier<UserData> {
  UserDataNotifier() : super(UserData());
  
  void setUserId(int id) {
    state = state.copyWith(userId: id);
  }

  // อัปเดตข้อมูล Login
  void setLoginInfo(String email, String password) {
    state = state.copyWith(email: email, password: password);
  }

  // อัปเดตเพศ
  void setGender(String gender) {
    state = state.copyWith(gender: gender);
  }

  // อัปเดตข้อมูลส่วนตัว
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

  // อัปเดตเป้าหมายหลัก
  void setGoal(GoalOption goal) {
    state = state.copyWith(goal: goal);
  }

  // อัปเดตรายละเอียดเป้าหมาย
  void setGoalInfo({
    required double targetWeight,
    DateTime? targetDate, // รับค่าวันที่
    int? duration,
  }) {
    state = state.copyWith(
      targetWeight: targetWeight,
      targetDate: targetDate, // บันทึกลง State
      duration: duration ?? state.duration,
    );
  }
  
  // อัปเดตระดับกิจกรรม
  void setActivityLevel(String level) {
    state = state.copyWith(activityLevel: level);
  }

  // 🔥 อัปเดตข้อมูลอาหารรายวัน (ทั้งแคลอรี่และชื่อเมนู)
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
  
  // ล้างค่าเมื่อขึ้นวันใหม่ (Reset)
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

  // ฟังก์ชันสำหรับอัปเดตหน่วยนับ
  void updateUnit({String? weight, String? height, String? energy, String? water}) {
    state = state.copyWith(
      unitWeight: weight ?? state.unitWeight,
      unitHeight: height ?? state.unitHeight,
      unitEnergy: energy ?? state.unitEnergy,
      unitWater: water ?? state.unitWater,
    );
  }

  // ✅ ฟังก์ชันใหม่: รับข้อมูลทั้งหมดจาก API มาใส่ Provider
  void setUserFromApi(Map<String, dynamic> data) {
    // แปลง String วันที่ เป็น DateTime
    DateTime? tDate;
    if (data['goal_target_date'] != null) {
      tDate = DateTime.parse(data['goal_target_date']);
    }
    
    DateTime? bDate;
    if (data['birth_date'] != null) {
      bDate = DateTime.parse(data['birth_date']);
    }

    // แปลง goal_type เป็น Enum
    GoalOption userGoal = GoalOption.loseWeight;
    if (data['goal_type'] == 'maintain_weight') userGoal = GoalOption.maintainWeight;
    if (data['goal_type'] == 'build_muscle') userGoal = GoalOption.buildMuscle;

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
      // ถ้ามี unit ใน DB ก็ดึงมาด้วย (ถ้าไม่มีให้ใช้ default)
      unitWeight: data['unit_weight'] ?? 'kg',
      unitHeight: data['unit_height'] ?? 'cm',
      unitEnergy: data['unit_energy'] ?? 'kcal',
      unitWater: data['unit_water'] ?? 'ml',
    );
  }
}

// --- Provider: ตัวกลางสำหรับเรียกใช้ทั่วแอป ---
final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData>((ref) {
  return UserDataNotifier();
});