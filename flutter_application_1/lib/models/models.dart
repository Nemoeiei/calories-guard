// lib/models/models.dart

enum MealType { breakfast, lunch, dinner, snack }

class Food {
  final int id; // ✅ แก้จาก String เป็น int ให้ตรง DB
  final String name;
  final double calories; // ✅ แก้เป็น double ให้รองรับทศนิยม
  final double protein;
  final double carbs;
  final double fat;
  final String? imageUrl; // ✅ เพิ่มตัวนี้ เพราะใน DB มี image_url

  Food({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
  });

  // 🔥 ฟังก์ชันสำคัญ! แปลง JSON จาก API ให้เป็น Food Object
  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['food_id'] ?? 0, // ชื่อต้องตรงกับคอลัมน์ใน DB
      name: json['name'] ?? '',
      // แปลงเป็น double อย่างปลอดภัย (กัน Error)
      calories: double.tryParse(json['calories'].toString()) ?? 0.0,
      protein: double.tryParse(json['protein'].toString()) ?? 0.0,
      carbs: double.tryParse(json['carbs'].toString()) ?? 0.0,
      fat: double.tryParse(json['fat'].toString()) ?? 0.0,
      imageUrl: json['image_url'], // รับค่ารูปภาพ
    );
  }
}

class FoodLog {
  final String id; // อันนี้เป็น ID ของการกิน เก็บไว้เป็น String หรือ int ก็ได้ตามการออกแบบ App
  final DateTime dateConsumed;
  final MealType meal;
  final Food food; 
  
  // Snapshot Values (ปรับเป็น double ตาม Food)
  final double loggedCalories;
  final double loggedProtein;
  final double loggedCarbs;
  final double loggedFat;

  FoodLog({
    required this.id,
    required this.dateConsumed,
    required this.meal,
    required this.food,
  }) : 
    // Auto Snapshot: ดึงค่าจาก Food มาเก็บไว้เลย
    loggedCalories = food.calories,
    loggedProtein = food.protein,
    loggedCarbs = food.carbs,
    loggedFat = food.fat;
}