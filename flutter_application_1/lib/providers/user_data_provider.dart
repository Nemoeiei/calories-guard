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
  final String activityLevel; // ระดับกิจกรรม

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
    this.activityLevel = 'ไม่ออกกำลังกายเลย',
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
    double activityMultiplier = 1.2; // Default: ไม่ออกกำลังกายเลย

    if (activityLevel.contains('เบาๆ')) {
      activityMultiplier = 1.375;
    } else if (activityLevel.contains('ปานกลาง')) {
      activityMultiplier = 1.55;
    } else if (activityLevel.contains('หนัก')) {
      activityMultiplier = 1.725; // 6-7 ครั้ง
    } else if (activityLevel.contains('หนักมาก')) {
      activityMultiplier = 1.9; // ทุกวันเช้าเย็น
    }

    return bmr * activityMultiplier;
  }

  // --- 🎯 Logic 4: คำนวณแคลอรี่เป้าหมาย ---
  double get targetCalories {
    double maintenance = tdee;
    
    if (goal == GoalOption.loseWeight) {
      return maintenance - 500; // ลดน้ำหนัก: กินน้อยกว่าใช้ 500 kcal
    } else if (goal == GoalOption.buildMuscle) {
      return maintenance + 300; // เพิ่มกล้าม: กินมากกว่าใช้ 300 kcal
    }
    
    return maintenance; // รักษาน้ำหนัก
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
  void setGoalInfo({required double targetWeight, required int duration}) {
    state = state.copyWith(targetWeight: targetWeight, duration: duration);
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
}

// --- Provider: ตัวกลางสำหรับเรียกใช้ทั่วแอป ---
final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData>((ref) {
  return UserDataNotifier();
});