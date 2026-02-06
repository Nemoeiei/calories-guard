import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/screens/profile/subprofile_screen/progress_screen.dart'; 
import '../../services/notification_helper.dart'; 

class AppHomeScreen extends ConsumerStatefulWidget {
  const AppHomeScreen({super.key});

  @override
  ConsumerState<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends ConsumerState<AppHomeScreen> {
  bool _isLoading = true;
  bool _hasWarnedCalories = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllData();
    });
  }

  // --- Data Fetching Section ---

  Future<void> _fetchAllData() async {
    await _fetchUserData();
    await _fetchDailyData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchUserData() async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;

    try {
      final url = Uri.parse('http://10.0.2.2:8000/users/$userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        ref.read(userDataProvider.notifier).setUserFromApi(data);
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
    }
  }

  Future<void> _fetchDailyData() async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    final url = Uri.parse('http://10.0.2.2:8000/daily_summary/$userId?date_record=$dateStr');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final summaryData = json.decode(utf8.decode(response.bodyBytes));
        
        ref.read(userDataProvider.notifier).updateDailyFood(
          cal: (summaryData['total_calories_intake'] as num?)?.toInt() ?? 0,
          protein: (summaryData['total_protein'] as num?)?.toInt() ?? 0,
          carbs: (summaryData['total_carbs'] as num?)?.toInt() ?? 0,
          fat: (summaryData['total_fat'] as num?)?.toInt() ?? 0,
          breakfast: summaryData['breakfast_menu'] ?? '',
          lunch: summaryData['lunch_menu'] ?? '',
          dinner: summaryData['dinner_menu'] ?? '',
          snack: summaryData['snack_menu'] ?? '',
        );
      }
    } catch (e) {
      print("Error fetching daily summary: $e");
    }
  }

  // --- Logic การลบ/แก้ไข ---

  void _editMeal(String mealType, String currentMenu) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('กำลังจะแก้ไขเมนู: $currentMenu')),
    );
  }

  void _confirmDeleteMeal(String mealType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        content: Text('คุณต้องการลบรายการอาหารใน "$mealType" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              _deleteMeal(mealType);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMeal(String mealType) async {
    final userId = ref.read(userDataProvider).userId;
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final url = Uri.parse(
        'http://10.0.2.2:8000/meals/clear/$userId?date_record=$dateStr&meal_type=$mealType'
      );

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context); 
          await _fetchAllData(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบรายการเรียบร้อย'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Failed to delete: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        print("Delete Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Helper Functions ---

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
    double heightM = (heightInput > 3.0) ? heightInput / 100 : heightInput; 
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

  // --- Widgets ---

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

  // Widget สร้างแถวรายการอาหาร พร้อมปุ่มจัดการ (ตาม CSS ใหม่)
  Widget _buildMealRow(String label, String menu, String mealType) {
    bool hasMenu = menu.isNotEmpty && menu != '-' && menu != '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // เพิ่มระยะห่างแนวตั้ง
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ส่วนชื่อมื้อและรายการอาหาร
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label :', 
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black) // ปรับตาม CSS (Size 16, Weight 500)
                ),
                const SizedBox(height: 4),
                Text(
                  hasMenu ? menu : '-', 
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.black), // ปรับตาม CSS
                ),
              ],
            ),
          ),

          // ปุ่มแก้ไข (วงกลมตาม CSS Rectangle 157)
          if (hasMenu) 
            Row(
              children: [
                // Edit Button
                InkWell(
                  onTap: () => _editMeal(mealType, menu),
                  child: Container(
                    width: 30, // ปรับขนาดให้พอดีนิ้ว
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFCF), // สีพื้นหลังตาม CSS
                      shape: BoxShape.circle, // วงกลม (border-radius: 100000px)
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          offset: const Offset(0, 4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.black), // ไอคอนสีดำ
                  ),
                ),
                const SizedBox(width: 10), // ระยะห่างระหว่างปุ่ม
                // Delete Button (เพิ่มเองเพื่อให้ครบฟังก์ชัน แต่สไตล์คล้ายกัน)
                InkWell(
                  onTap: () => _confirmDeleteMeal(mealType),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFCF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          offset: const Offset(0, 4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.delete, size: 16, color: Colors.red),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    
    int targetCal = userData.targetCalories.toInt() > 0 ? userData.targetCalories.toInt() : 1500;
    int currentCal = userData.consumedCalories; 
    double progress = (targetCal > 0) ? currentCal / targetCal : 0.0;

    final macroTargets = calculateMacroTargets(targetCal.toDouble(), userData.goal ?? GoalOption.loseWeight);
    final targetP = macroTargets['protein']!;
    final targetC = macroTargets['carbs']!;
    final targetF = macroTargets['fat']!;

    bool isOverCalories = currentCal > targetCal;
    Color progressColor = isOverCalories ? Colors.red : const Color(0xFF628141);
    Color calorieTextColor = isOverCalories ? Colors.red : Colors.black;

    String getAdvice() {
      if (currentCal == 0) return "เริ่มบันทึกมื้อแรกของวันกันเลย!";
      if (isOverCalories) return "พลังงานเกินเป้าหมายแล้ว! ลองเดินย่อยดูนะ";
      if (progress >= 0.8) return "ใกล้ถึงเป้าหมายแล้ว มื้อหน้าเลือกทานเบาๆ นะ";
      return "รักษาวินัยได้ดีมาก วันนี้มาทำให้สำเร็จกัน!";
    }

    if (isOverCalories && !_hasWarnedCalories) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ แจ้งเตือน: แคลอรี่เกินเป้าหมายแล้ว!'), backgroundColor: Colors.redAccent));
        NotificationHelper.showCalorieAlert(currentCal, targetCal);
        setState(() => _hasWarnedCalories = true);
      });
    }

    double bmi = calculateBMI(userData.weight, userData.height);
    String bmiStatus = getBMIStatus(bmi);
    double weightDiff = (userData.weight - userData.targetWeight).abs();
    String weightAction = (userData.weight > userData.targetWeight) ? "ต้องลดอีก" : "ต้องเพิ่มอีก";
    
    double weightProgress = 0.0;
    if (userData.weight > 0 && userData.targetWeight > 0) {
       if (userData.goal == GoalOption.loseWeight && userData.weight >= userData.targetWeight) {
          double startWeight = userData.weight + 5; 
          double totalToLose = startWeight - userData.targetWeight;
          double lost = startWeight - userData.weight;
          weightProgress = (totalToLose > 0) ? (lost / totalToLose) : 0;
       }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: () async {
              await _fetchAllData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        // Date box
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Center(
                              child: Text(
                                // แสดงวัน/เดือน/ปี
                                "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Selected program box
                        Expanded(
                          flex: 2,
                          child: Builder(builder: (context) {
                            // Map GoalOption -> display data
                            GoalOption goal = userData.goal ?? GoalOption.loseWeight;
                            String title = 'ลดน้ำหนัก';
                            String subtitle = '';
                            String iconUrl = '';
                            LinearGradient gradient = const LinearGradient(colors: [Colors.white, Colors.white]);

                            if (goal == GoalOption.loseWeight) {
                              title = 'ลดน้ำหนัก';
                              subtitle = 'ควบคุมแคลอรี่';
                              iconUrl = 'https://api.builder.io/api/v1/image/assets/TEMP/2b36cbc83f6282347dd67152d454841cc595df15';
                              gradient = const LinearGradient(colors: [Color(0xFFDBA979), Color(0xFFD76A3C)]);
                            } else if (goal == GoalOption.maintainWeight) {
                              title = 'รักษาน้ำหนัก';
                              subtitle = 'รักษาสมดุล สุขภาพดี';
                              iconUrl = 'https://api.builder.io/api/v1/image/assets/TEMP/caa3690bf64691cf18159ea72b5ec46944c37e66';
                              gradient = const LinearGradient(colors: [Color(0xFF10337F), Color(0xFF2D58B6), Color(0xFF497CEA)], stops: [0.0, 0.36, 1.0]);
                            } else if (goal == GoalOption.buildMuscle) {
                              title = 'เพิ่มกล้ามเนื้อ';
                              subtitle = 'ลดไขมัน';
                              iconUrl = 'https://api.builder.io/api/v1/image/assets/TEMP/3ac072bc08b89b53ec34785b4a25b0021535bdd8';
                              gradient = const LinearGradient(colors: [Color(0xFFB4AC15), Color(0xFFFFEA4B), Color(0xFFFAFC83)], stops: [0.0, 0.63, 1.0]);
                            }

                            return Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: gradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  // Icon image
                                  if (iconUrl.isNotEmpty) ...[
                                    Image.network(iconUrl, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (c,e,s) => const SizedBox(width: 44, height: 44)),
                                    const SizedBox(width: 12),
                                  ],
                                  // Texts
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                        if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  // --- Dashboard ---
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
                              const Text('เเคลอรี่ที่ทานต่อวัน', style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
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
                              Positioned(left: 226, top: 41, child: _buildNutrientLabel('โปรตีน', userData.consumedProtein, targetP, 'assets/images/icon/meat.png')),
                              Positioned(left: 226, top: 102, child: _buildNutrientLabel('คาร์บ', userData.consumedCarbs, targetC, 'assets/images/icon/rice.png')),
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
                                Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                   const Text('Start', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)), 
                                   const SizedBox(height: 7), 
                                   const Text('ความคืบหน้า', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500)), 
                                   const SizedBox(height: 7), 
                                   Container(padding: const EdgeInsets.symmetric(horizontal: 4), color: Colors.white, child: Text('สู้ๆ นะ!', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFFB74D4D))))
                                ])),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Menu List Section (Updated with CSS) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Box ตาม CSS
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EFCF), // พื้นหลังเขียวอ่อน
                            borderRadius: BorderRadius.circular(10), // มุมโค้ง
                          ),
                          child: const Text(
                            'มื้ออาหารที่ทานวันนี้',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // กล่องรายการอาหาร (Rectangle 18)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EFCF), // พื้นหลัง E8EFCF
                            border: Border.all(color: const Color(0xFF4C6414), width: 1), // ขอบเขียวเข้ม
                            borderRadius: BorderRadius.circular(10), // มุมโค้ง 10px
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMealRow('มื้อเช้า', userData.breakfastMenu, 'breakfast'),
                              const Divider(color: Colors.black12), // เส้นคั่นบางๆ
                              _buildMealRow('อาหารว่าง', userData.snackMenu, 'snack'),
                              const Divider(color: Colors.black12),
                              _buildMealRow('มื้อเที่ยง', userData.lunchMenu, 'lunch'),
                              const Divider(color: Colors.black12),
                              _buildMealRow('มื้อเย็น', userData.dinnerMenu, 'dinner'),
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
          ),
    );
  }
}