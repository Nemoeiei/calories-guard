import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile/subprofile_screen/progress_screen.dart';

class AppHomeScreen extends ConsumerStatefulWidget {
  const AppHomeScreen({super.key});

  @override
  ConsumerState<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends ConsumerState<AppHomeScreen> {
  bool _isLoading = true;
  bool _hasWarnedCalories = false; // ป้องกันการแจ้งเตือนเด้งรัวๆ

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDailyData();
    });
  }

  // ✅ ฟังก์ชันดึงข้อมูล (เหมือนเดิม)
  Future<void> _fetchDailyData() async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final logUrl = Uri.parse('http://10.0.2.2:8000/daily_logs/$userId?date_query=$dateStr');
    final userUrl = Uri.parse('http://10.0.2.2:8000/users/$userId'); 
    try {
      final userResponse = await http.get(userUrl);
      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        GoalOption goalEnum = GoalOption.loseWeight;
        if (userData['goal_type'] == 'maintain_weight') goalEnum = GoalOption.maintainWeight;
        if (userData['goal_type'] == 'build_muscle') goalEnum = GoalOption.buildMuscle;
        ref.read(userDataProvider.notifier).setPersonalInfo(
          name: userData['username'] ?? 'User',
          birthDate: DateTime.parse(userData['birth_date'] ?? '2000-01-01'), 
          height: (userData['height_cm'] ?? 0).toDouble(),
          weight: (userData['current_weight_kg'] ?? 0).toDouble(),
        );
        ref.read(userDataProvider.notifier).setGoal(goalEnum);
        ref.read(userDataProvider.notifier).setGoalInfo(targetWeight: (userData['target_weight_kg'] ?? 0).toDouble(), duration: 0);
      }
      final logResponse = await http.get(logUrl);
      if (logResponse.statusCode == 200) {
        final logData = jsonDecode(logResponse.body);
        ref.read(userDataProvider.notifier).updateDailyFood(
          cal: logData['calories'] ?? 0, protein: logData['protein'] ?? 0, carbs: logData['carbs'] ?? 0, fat: logData['fat'] ?? 0,
          breakfast: logData['breakfast_menu'] ?? '', lunch: logData['lunch_menu'] ?? '', dinner: logData['dinner_menu'] ?? '', snack: logData['snack_menu'] ?? '',
        );
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ ฟังก์ชันคำนวณเป้าหมาย สารอาหารหลัก (Macros)
  Map<String, int> calculateMacroTargets(double targetCalories, GoalOption goal) {
    double pRatio, cRatio, fRatio;
    switch (goal) {
      case GoalOption.loseWeight: pRatio = 0.30; cRatio = 0.40; fRatio = 0.30; break;
      case GoalOption.maintainWeight: pRatio = 0.25; cRatio = 0.45; fRatio = 0.30; break;
      case GoalOption.buildMuscle: pRatio = 0.30; cRatio = 0.50; fRatio = 0.20; break;
    }
    return {
      'protein': (targetCalories * pRatio / 4).round(),
      'carbs': (targetCalories * cRatio / 4).round(),
      'fat': (targetCalories * fRatio / 9).round(),
    };
  }

  double calculateBMI(double weight, double heightInput) {
    if (heightInput <= 0) return 0;
    double heightM = (heightInput < 3.0) ? heightInput : heightInput / 100;
    return weight / (heightM * heightM);
  }

  String getBMIStatus(double bmi) {
    if (bmi <= 0) return '-';
    if (bmi < 18.5) return 'น้ำหนักน้อย';
    if (bmi < 22.9) return 'ปกติ';
    if (bmi < 24.9) return 'ท้วม';
    if (bmi < 29.9) return 'อ้วน';
    return 'อ้วนมาก';
  }

  Widget _buildNutrientLabel(String label, int current, int total, String imagePath) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 25, height: 25, decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover))),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 4),
          Stack(children: [
            Container(width: 140, height: 2, decoration: BoxDecoration(color: const Color(0xFF979797).withOpacity(0.5), borderRadius: BorderRadius.circular(6))),
            Container(
              width: 140 * (total > 0 ? (current / total).clamp(0.0, 1.0) : 0),
              height: 2,
              decoration: BoxDecoration(color: const Color(0xFF1C1B1F).withOpacity(0.8), borderRadius: BorderRadius.circular(6)),
            ),
          ]),
          const SizedBox(height: 2),
          SizedBox(width: 140, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$current g', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500)),
            Text('$total g', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500)),
          ])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    int targetCal = userData.targetCalories.toInt() > 0 ? userData.targetCalories.toInt() : 1500;
    int currentCal = userData.consumedCalories; 
    double progress = currentCal / targetCal;

    // 🔥 แก้ Error: ใส่ ?? GoalOption.loseWeight เพื่อป้องกันค่า null
    final macroTargets = calculateMacroTargets(
      targetCal.toDouble(), 
      userData.goal ?? GoalOption.loseWeight 
    );
    final targetP = macroTargets['protein']!;
    final targetC = macroTargets['carbs']!;
    final targetF = macroTargets['fat']!;

    // 🔥 LOGIC สีแจ้งเตือน
    bool isOverCalories = currentCal > targetCal;
    Color progressColor = isOverCalories ? Colors.red : const Color(0xFF628141);
    Color calorieTextColor = isOverCalories ? Colors.red : Colors.black;

    // 🔥 ระบบคำแนะนำ
    String getAdvice() {
      if (currentCal == 0) return "เริ่มบันทึกมื้อแรกของวันกันเลย!";
      if (isOverCalories) return "พลังงานเกินเป้าหมายแล้ว! ลองเดินย่อยดูนะ";
      if (progress >= 0.8) return "ใกล้ถึงเป้าหมายแล้ว มื้อหน้าเลือกทานเบาๆ นะ";
      return "รักษาวินัยได้ดีมาก วันนี้มาทำให้สำเร็จกัน!";
    }

    if (isOverCalories && !_hasWarnedCalories) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ แจ้งเตือน: แคลอรี่เกินเป้าหมายแล้ว!'), backgroundColor: Colors.redAccent));
        setState(() => _hasWarnedCalories = true);
      });
    }

    double bmi = calculateBMI(userData.weight, userData.height);
    String bmiStatus = getBMIStatus(bmi);
    double weightDiff = (userData.weight - userData.targetWeight).abs();
    String weightAction = (userData.weight > userData.targetWeight) ? "ต้องลดอีก" : "ต้องเพิ่มอีก";

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 40, color: Colors.white),

            // --- Dashboard (กล่องสีเขียวรวม Header และ แคลอรี่) ---
            Container(
              width: double.infinity,
              color: const Color(0xFFE8EFCF),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ภาพรวมวันนี้', style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                        IconButton(icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFF628141), size: 32), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgressScreen()))),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 250,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 5, top: 18,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 170, height: 170,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(width: 150, height: 150, child: CircularProgressIndicator(value: 1.0, strokeWidth: 12, color: const Color(0xFF8BAE66))),
                                    SizedBox(width: 150, height: 150, child: CircularProgressIndicator(value: progress.clamp(0.0, 1.0), strokeWidth: 12, color: progressColor, strokeCap: StrokeCap.round)),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('$currentCal', style: TextStyle(fontFamily: 'Inter', fontSize: 48, fontWeight: FontWeight.w500, color: calorieTextColor, height: 1)),
                                        Text('/ $targetCal KCAL', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text(getAdvice(), style: TextStyle(color: calorieTextColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                        // รายการสารอาหารที่คำนวณเป้าหมายจริง
                        Positioned(left: 226, top: 41, child: _buildNutrientLabel('โปรตีน', userData.consumedProtein, targetP, 'assets/images/icon/meat.png')),
                        Positioned(left: 226, top: 102, child: _buildNutrientLabel('คาร์โบไฮเดรต', userData.consumedCarbs, targetC, 'assets/images/icon/rice.png')),
                        Positioned(left: 226, top: 166, child: _buildNutrientLabel('ไขมัน', userData.consumedFat, targetF, 'assets/images/icon/oil.png')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Container(height: 20, color: Colors.white),
            
            // --- Stats (น้ำหนัก & BMI) ---
            SizedBox(
              height: 119, width: double.infinity,
              child: Row(
                children: [
                  Container(
                    width: 159, color: const Color(0xFFDBA979),
                    child: Stack(
                      children: [
                        Positioned(left: 7, top: 5, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE8EFCF), borderRadius: BorderRadius.circular(5)), child: const Text('เป้าหมายน้ำหนักตัว', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)))),
                        Positioned(left: 29, top: 38, child: Text('${userData.weight.toInt()}', style: const TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w500))),
                        Positioned(left: 72, top: 52, child: Row(children: [const Text('/', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)), const SizedBox(width: 4), Text('${userData.targetWeight.toInt()} กก.', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54))])),
                        Positioned(left: 30, top: 92, child: Text('เหลือ ${weightDiff.toStringAsFixed(1)} กก.', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFB74D4D)))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFECCA9C),
                      child: Row(
                        children: [
                          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('BMI ${bmi.toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)), const SizedBox(height: 7), Text(bmiStatus, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 7), Container(padding: const EdgeInsets.symmetric(horizontal: 4), color: Colors.white, child: Text('$weightAction ${weightDiff.toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFFB74D4D))))])),
                          Container(width: 1, height: 119, color: Colors.white.withOpacity(0.3)),
                          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('30%', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)), const SizedBox(height: 7), const Text('ความคืบหน้า', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 7), Container(padding: const EdgeInsets.symmetric(horizontal: 4), color: Colors.white, child: const Text('เหลืออีก 70%', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFFB74D4D))))])),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Menu List ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('มื้ออาหารที่ทานวันนี้', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(15.0),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFF4C6414), width: 1), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('มื้อเช้า : ${userData.breakfastMenu.isEmpty ? '-' : userData.breakfastMenu}', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('อาหารว่าง : ${userData.snackMenu.isEmpty ? '-' : userData.snackMenu}', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('มื้อเที่ยง : ${userData.lunchMenu.isEmpty ? '-' : userData.lunchMenu}', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('มื้อเย็น : ${userData.dinnerMenu.isEmpty ? '-' : userData.dinnerMenu}', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}