import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/user_data_provider.dart';
import '../../services/auth_service.dart';
import '../../services/meal_service.dart';
import '../../services/food_service.dart';

class FoodLoggingScreen extends ConsumerStatefulWidget {
  const FoodLoggingScreen({super.key});

  @override
  ConsumerState<FoodLoggingScreen> createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends ConsumerState<FoodLoggingScreen> {
  String _breakfast = '';
  String _lunch = '';
  String _dinner = '';
  String _snack1 = '';
  String _snack2 = '';

  bool _isSaving = false; // เอาไว้โชว์ Loading Overlay

  final Map<String, String> _activityMap = {
    'ไม่ออกกำลังกายเลย': 'sedentary',
    'ออกกำลังกายเบาๆ (1-3 ครั้ง/สัปดาห์)': 'lightly_active',
    'ออกกำลังกายปานกลาง (3-5 ครั้ง/สัปดาห์)': 'moderately_active',
    'ออกกำลังกายหนัก (6-7 ครั้ง/สัปดาห์)': 'very_active',
  };
  
  String _selectedActivityLabel = 'ไม่ออกกำลังกายเลย'; 
  List<dynamic> _foodDatabase = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now(); 

  @override
  void initState() {
    super.initState();
    _fetchFoodsFromApi();
  }

  double _safeParse(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _fetchFoodsFromApi() async {
    final foodService = FoodService();
    final data = await foodService.getAllFoods();
    
    if (data != null && mounted) {
      setState(() {
        _foodDatabase = data;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMealToBackend(String mealType, String menuName, String token) async {
    if (menuName.isEmpty) return;

    final food = _foodDatabase.firstWhere(
      (f) => f['food_name'].toString().toLowerCase() == menuName.toLowerCase().trim(),
      orElse: () => null, 
    );

    if (food == null) return; 

    // แปลง selectedDate เป็น ISO8601 string สำหรับ meal_time
    // สมมติเวลา 12:00:00 เพื่อให้เป็นกลางวัน หรือใช้เวลาปัจจุบันร่วมด้วยได้
    final now = DateTime.now();
    final mealDateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day, 
      now.hour, now.minute, now.second
    );
    
    final mealData = {
      "meal_type": mealType,
      "meal_time": mealDateTime.toIso8601String(), // ✅ ส่ง meal_time ตาม Schema
      "items": [
        {
          "food_id": food['food_id'],
          "amount": 1.0, 
        }
      ]
    };

    final mealService = MealService();
    await mealService.logMeal(token, mealData);
  }

  void _calculateAndSave() async {
    FocusScope.of(context).unfocus(); // ปิดคีย์บอร์ด
    
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;

    setState(() => _isSaving = true); // เปิด Overlay

    // คำนวณสารอาหาร Local เพื่ออัปเดตหน้า Home ทันที
    int totalCal = 0;
    int totalP = 0;
    int totalC = 0;
    int totalF = 0;

    void addLocalNutrients(String menuName) {
      if (menuName.isEmpty) return;
      final food = _foodDatabase.firstWhere(
        (f) => f['food_name'].toString().toLowerCase() == menuName.toLowerCase().trim(),
        orElse: () => null, 
      );
      if (food != null) {
        totalCal += _safeParse(food['calories']).toInt();
        totalP += _safeParse(food['protein']).toInt();
        totalC += _safeParse(food['carbs']).toInt();
        totalF += _safeParse(food['fat']).toInt();
      }
    }

    // 1. รวมยอด Local
    addLocalNutrients(_breakfast);
    addLocalNutrients(_lunch);
    addLocalNutrients(_dinner);
    addLocalNutrients(_snack1);
    addLocalNutrients(_snack2);

    try {
      // 2. บันทึกลง Backend
      final token = ref.read(userDataProvider).token;
      if (token != null) {
        await _saveMealToBackend('breakfast', _breakfast, token);
        await _saveMealToBackend('lunch', _lunch, token);
        await _saveMealToBackend('dinner', _dinner, token);
        await _saveMealToBackend('snack', _snack1, token);
        await _saveMealToBackend('snack', _snack2, token);

        // 3. อัปเดต Activity
        String activityValue = _activityMap[_selectedActivityLabel] ?? 'sedentary';
        final authService = AuthService();
        await authService.updateProfile(token, {"activity_level": activityValue});
        
        ref.read(userDataProvider.notifier).setActivityLevel(activityValue);
      }

      // ✅ 4. อัปเดต Provider ทันที! (หน้า Home จะเปลี่ยนเอง)
      String combinedSnacks = [_snack1, _snack2].where((s) => s.isNotEmpty).join(", ");
      
      // ต้องมั่นใจว่าใน Provider มีฟังก์ชันนี้ที่รับ String name
      ref.read(userDataProvider.notifier).updateDailyFood(
        cal: totalCal, protein: totalP, carbs: totalC, fat: totalF,
        breakfast: _breakfast, lunch: _lunch, dinner: _dinner, snack: combinedSnacks
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกเรียบร้อย!'), backgroundColor: Colors.green),
        );
        
        // รอแป๊บนึง
        await Future.delayed(const Duration(milliseconds: 200));
        
        // ✅ 5. สั่งเปลี่ยน Tab กลับไปหน้าแรก (Index 0)
        ref.read(navIndexProvider.notifier).state = 0; 
        
        // ล้างค่า (ถ้าต้องการ)
        setState(() {
           _breakfast = ''; _lunch = ''; _dinner = ''; _snack1 = ''; _snack2 = '';
           _isSaving = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    // Header
                    Container(
                      width: double.infinity, height: 50, color: const Color(0xFF628141),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            // ✅ ปุ่ม Back: สั่งกลับหน้าแรก (Index 0)
                            onTap: () {
                               FocusScope.of(context).unfocus();
                               ref.read(navIndexProvider.notifier).state = 0;
                            }, 
                            child: const Icon(Icons.arrow_back_ios, color: Colors.white)
                          ),
                          const Text('บันทึกการกิน', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white)),
                          GestureDetector(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context, initialDate: _selectedDate,
                                firstDate: DateTime(2020), lastDate: DateTime.now(),
                                builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF628141), onPrimary: Colors.white, onSurface: Colors.black)), child: child!),
                              );
                              if (picked != null) setState(() => _selectedDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                              child: Row(children: [const Icon(Icons.calendar_today, size: 16, color: Color(0xFF628141)), const SizedBox(width: 5), Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year + 543}", style: const TextStyle(color: Color(0xFF628141), fontWeight: FontWeight.bold))]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Form Container
                    Container(
                      width: 330, padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                      decoration: BoxDecoration(color: const Color(0xFFE8EFCF), borderRadius: BorderRadius.circular(10)),
                      child: Column(children: [
                        _buildSearchableFoodRow('อาหารเช้า*', (val) => _breakfast = val), const SizedBox(height: 15),
                        _buildSearchableFoodRow('มื้อว่าง', (val) => _snack1 = val), const SizedBox(height: 15),
                        _buildSearchableFoodRow('อาหารกลางวัน*', (val) => _lunch = val), const SizedBox(height: 15),
                        _buildSearchableFoodRow('มื้อว่าง', (val) => _snack2 = val), const SizedBox(height: 15),
                        _buildSearchableFoodRow('อาหารเย็น*', (val) => _dinner = val),
                      ]),
                    ),
                    const SizedBox(height: 30),

                    // Activity
                    Container(
                      width: 330, height: 50, padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedActivityLabel, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down),
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                          onChanged: (val) => setState(() => _selectedActivityLabel = val!),
                          items: _activityMap.keys.map((k) => DropdownMenuItem(value: k, child: Text(k, overflow: TextOverflow.ellipsis))).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    GestureDetector(
                      onTap: _isSaving ? null : _calculateAndSave, 
                      child: Container(
                        width: 200, height: 50,
                        decoration: BoxDecoration(color: const Color(0xFF4C6414), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))]),
                        child: const Center(child: Text('บันทึกข้อมูล', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
        ),
        
        // Loading Overlay
        if (_isSaving) ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.5)),
        if (_isSaving) const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }

  Widget _buildSearchableFoodRow(String label, Function(String) onSaved) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
        Container(
          width: 143, height: 23,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') return const Iterable<String>.empty();
              return _foodDatabase
                  .where((food) => food['food_name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()))
                  .map((food) => food['food_name'].toString());
            },
            onSelected: (String selection) => onSaved(selection),
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              controller.addListener(() => onSaved(controller.text));
              return TextField(
                controller: controller, focusNode: focusNode, textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 10, fontFamily: 'Inter', color: Colors.black, height: 1.0),
                decoration: const InputDecoration(hintText: 'กรอกเมนูอาหาร', hintStyle: TextStyle(fontSize: 10, color: Color(0xFF979797)), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: Container(
                    width: 143, color: Colors.white,
                    child: ListView.builder(
                      padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length,
                      itemBuilder: (context, index) {
                        final String option = options.elementAt(index);
                        return InkWell(onTap: () => onSelected(option), child: Padding(padding: const EdgeInsets.all(8.0), child: Text(option, style: const TextStyle(fontSize: 12))));
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}