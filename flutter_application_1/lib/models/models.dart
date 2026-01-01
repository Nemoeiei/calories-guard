// lib/models/models.dart

enum MealType { breakfast, lunch, dinner, snack }

class Food {
  final String id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  Food({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class FoodLog {
  final String id;
  final DateTime dateConsumed;
  final MealType meal;
  final Food food; // Link ไปยัง Food
  
  // Snapshot Values (ค่า ณ เวลาที่บันทึก ตาม ER Diagram)
  final int loggedCalories;
  final int loggedProtein;
  final int loggedCarbs;
  final int loggedFat;

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