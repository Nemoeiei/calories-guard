import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_application_1/constants/constants.dart';
import '/providers/user_data_provider.dart';

// ─────────────────────────────────────────────
//  Models
// ─────────────────────────────────────────────
class LoggedFood {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int? foodId;
  final bool isPending;
  LoggedFood({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.foodId,
    this.isPending = false,
  });
}

class MealSlot {
  final String id;
  final String name;
  final String emoji;
  final String timeHint;
  List<LoggedFood> foods;
  MealSlot({
    required this.id,
    required this.name,
    required this.emoji,
    required this.timeHint,
    List<LoggedFood>? foods,
  }) : foods = foods ?? [];

  double get totalCalories => foods.fold(0, (s, f) => s + f.calories);
  double get totalProtein => foods.fold(0, (s, f) => s + f.protein);
  double get totalCarbs => foods.fold(0, (s, f) => s + f.carbs);
  double get totalFat => foods.fold(0, (s, f) => s + f.fat);
}

class Activity {
  final String name;
  final String emoji;
  final int durationMin;
  final double caloriesBurned;
  Activity({
    required this.name,
    required this.emoji,
    required this.durationMin,
    required this.caloriesBurned,
  });
}

// ─────────────────────────────────────────────
//  FoodLogScreen
// ─────────────────────────────────────────────
class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen>
    with TickerProviderStateMixin {
  static const _green = Color(0xFF628141);
  static const _greenL = Color(0xFFE8EFCF);
  static const _greenM = Color(0xFFAFD198);
  static const _orange = Color(0xFFD76A3C);
  static const _blue = Color(0xFF1565C0);
  static const _bg = Color(0xFFF2F7F4);

  DateTime _selectedDate = DateTime.now();
  int _waterGlasses = 0;
  static const _waterGoal = 8;
  late List<MealSlot> _meals;
  List<Activity> _activities = [];
  late AnimationController _waterAnim;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initMeals();
    _waterAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fetchDailyLog();
  }

  @override
  void dispose() {
    _waterAnim.dispose();
    super.dispose();
  }

  void _initMeals() {
    _meals = [
      MealSlot(
          id: 'breakfast',
          name: 'มื้อเช้า',
          emoji: '🌅',
          timeHint: '06:00–10:00'),
      MealSlot(
          id: 'lunch',
          name: 'มื้อกลางวัน',
          emoji: '☀️',
          timeHint: '11:00–14:00'),
      MealSlot(
          id: 'dinner', name: 'มื้อเย็น', emoji: '🌙', timeHint: '17:00–21:00'),
      MealSlot(id: 'snack', name: 'ของว่าง', emoji: '🍎', timeHint: 'ตลอดวัน'),
    ];
  }

  Future<void> _fetchDailyLog() async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final res = await http.get(Uri.parse(
          '${AppConstants.baseUrl}/daily_logs/$userId?date_query=$dateStr'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // โหลดข้อมูลมื้ออาหาร
        if (data['meals'] != null) {
          final mealsData = data['meals'] as Map<String, dynamic>;

          setState(() {
            // Clear ข้อมูลเก่า
            for (var meal in _meals) {
              meal.foods.clear();
            }

            // โหลดข้อมูลแต่ละมื้อ
            for (var mealType in ['breakfast', 'lunch', 'dinner', 'snack']) {
              if (mealsData[mealType] != null && mealsData[mealType] is List) {
                final items = mealsData[mealType] as List;
                final targetMeal = _meals.firstWhere(
                  (m) => m.id == mealType,
                  orElse: () => _meals.last, // fallback to snack
                );

                for (var item in items) {
                  targetMeal.foods.add(LoggedFood(
                    name: item['food_name'] ?? '',
                    calories: (item['cal_per_unit'] ?? 0).toDouble(),
                    protein: (item['protein_per_unit'] ?? 0).toDouble(),
                    carbs: (item['carbs_per_unit'] ?? 0).toDouble(),
                    fat: (item['fat_per_unit'] ?? 0).toDouble(),
                    foodId: item['food_id'],
                  ));
                }
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching daily log: $e');
    }
  }

  double get _totalCalIn => _meals.fold(0, (s, m) => s + m.totalCalories);
  double get _totalCalBurned =>
      _activities.fold(0, (s, a) => s + a.caloriesBurned);
  double get _totalProtein => _meals.fold(0, (s, m) => s + m.totalProtein);
  double get _totalCarbs => _meals.fold(0, (s, m) => s + m.totalCarbs);
  double get _totalFat => _meals.fold(0, (s, m) => s + m.totalFat);

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final targetCal = userData.targetCalories.toDouble();
    final netCal = _totalCalIn - _totalCalBurned;
    final remaining = targetCal - netCal;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              _buildCalorieSummary(targetCal, netCal, remaining, userData),
              _buildWaterTracker(),
              ..._meals
                  .asMap()
                  .entries
                  .map((e) => _buildMealCard(e.value, e.key)),
              _buildAddCustomMealBtn(),
              _buildActivitiesSection(),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 52, bottom: 14, left: 16, right: 16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dateNavBtn(Icons.chevron_left, () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                _initMeals();
                _fetchDailyLog();
              });
            }),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                          colorScheme:
                              const ColorScheme.light(primary: _green)),
                      child: child!),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _initMeals();
                    _fetchDailyLog();
                  });
                }
              },
              child: Column(children: [
                Text(_formatDateTh(_selectedDate),
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                Text(_isToday(_selectedDate) ? 'วันนี้' : '',
                    style: const TextStyle(fontSize: 11, color: _green)),
              ]),
            ),
            const SizedBox(width: 8),
            _dateNavBtn(
                Icons.chevron_right,
                _isToday(_selectedDate)
                    ? null
                    : () {
                        setState(() {
                          _selectedDate =
                              _selectedDate.add(const Duration(days: 1));
                          _initMeals();
                          _fetchDailyLog();
                        });
                      }),
          ],
        ),
      ),
    );
  }

  Widget _dateNavBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: onTap == null ? Colors.grey.shade200 : _greenL,
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon,
            size: 18, color: onTap == null ? Colors.grey.shade400 : _green),
      ),
    );
  }

  Widget _buildCalorieSummary(
      double target, double net, double remaining, UserData userData) {
    final pct = target > 0 ? (net / target).clamp(0.0, 1.0) : 0.0;
    final isOver = net > target;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Row(children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 10,
                  backgroundColor: _greenL,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(isOver ? _orange : _green),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${net.toInt()}',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1)),
                const Text('kcal',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _calRow('🎯 เป้าหมาย', '${target.toInt()} kcal', Colors.black87),
              _calRow('🍽️ กินแล้ว', '${_totalCalIn.toInt()} kcal', _green),
              _calRow('🏃 เผาผลาญ', '${_totalCalBurned.toInt()} kcal', _orange),
              const Divider(height: 12),
              _calRow(
                isOver ? '⚠️ เกินเป้า' : '✅ เหลืออีก',
                '${remaining.abs().toInt()} kcal',
                isOver ? _orange : _blue,
                isBold: true,
              ),
            ],
          )),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _macroBar('โปรตีน', _totalProtein, userData.targetProtein.toDouble(),
              const Color(0xFF628141)),
          const SizedBox(width: 8),
          _macroBar('คาร์บ', _totalCarbs, userData.targetCarbs.toDouble(),
              const Color(0xFFFFB800)),
          const SizedBox(width: 8),
          _macroBar('ไขมัน', _totalFat, userData.targetFat.toDouble(),
              const Color(0xFFD76A3C)),
        ]),
      ]),
    );
  }

  Widget _calRow(String label, String val, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const Spacer(),
        Text(val,
            style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: color,
                fontFamily: 'Inter')),
      ]),
    );
  }

  Widget _macroBar(String label, double val, double target, Color color) {
    final pct = target > 0 ? (val / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
        child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        Text('${val.toInt()}g',
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 7,
          backgroundColor: color.withOpacity(0.15),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
      Text('/${target.toInt()}g',
          style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
    ]));
  }

  Widget _buildWaterTracker() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [const Color(0xFF1565C0), const Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Row(children: [
          const Text('💧', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ดื่มน้ำวันนี้',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'Inter')),
            Text(
                '$_waterGlasses/$_waterGoal แก้ว (${(_waterGlasses * 250)} ml)',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
          const Spacer(),
          Row(children: [
            _waterBtn(Icons.remove, () {
              if (_waterGlasses > 0) setState(() => _waterGlasses--);
            }),
            const SizedBox(width: 8),
            Text('$_waterGlasses',
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            _waterBtn(Icons.add, () {
              if (_waterGlasses < 20) setState(() => _waterGlasses++);
            }),
          ]),
        ]),
        const SizedBox(height: 12),
        Row(
            children: List.generate(
                _waterGoal,
                (i) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _waterGlasses = i + 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 28,
                          decoration: BoxDecoration(
                            color: i < _waterGlasses
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(i < _waterGlasses ? '💧' : '○',
                                style: TextStyle(
                                    fontSize: i < _waterGlasses ? 14 : 12,
                                    color: Colors.white70)),
                          ),
                        ),
                      ),
                    ))),
      ]),
    );
  }

  Widget _waterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildMealCard(MealSlot meal, int index) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: _greenL, borderRadius: BorderRadius.circular(13)),
              alignment: Alignment.center,
              child: Text(meal.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(meal.name,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Text(meal.timeHint,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${meal.totalCalories.toInt()} kcal',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _green)),
              Text(
                  'P:${meal.totalProtein.toInt()}g  C:${meal.totalCarbs.toInt()}g  F:${meal.totalFat.toInt()}g',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ]),
          ]),
        ),
        if (meal.foods.isNotEmpty) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...meal.foods
              .asMap()
              .entries
              .map((e) => _buildFoodItem(e.value, meal, e.key)),
        ],
        const Divider(height: 1, indent: 16, endIndent: 16),
        GestureDetector(
          onTap: () => _showAddFoodSheet(meal),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 24,
                height: 24,
                decoration:
                    BoxDecoration(color: _greenL, shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 16, color: _green),
              ),
              const SizedBox(width: 8),
              Text('เพิ่มอาหาร${meal.name.replaceAll('มื้อ', '')}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _green,
                      fontFamily: 'Inter')),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildFoodItem(LoggedFood food, MealSlot meal, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: food.isPending ? _orange : _greenM,
              shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(food.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              if (food.isPending) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(99)),
                  child: const Text('รอตรวจสอบ',
                      style: TextStyle(
                          fontSize: 9,
                          color: _orange,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
            Text(
                'P:${food.protein.toInt()}g  C:${food.carbs.toInt()}g  F:${food.fat.toInt()}g',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        )),
        Text('${food.calories.toInt()} kcal',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _green,
                fontFamily: 'Inter')),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            setState(() => meal.foods.removeAt(index));
            // บันทึกทันทีหลังลบ
            await _saveSingleMeal(meal);
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close, size: 16, color: Colors.red.shade400),
          ),
        ),
      ]),
    );
  }

  Widget _buildAddCustomMealBtn() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: _showAddCustomMealDialog,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _greenM, style: BorderStyle.solid),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.add_circle_outline, color: _green, size: 20),
            const SizedBox(width: 8),
            const Text('เพิ่มมื้ออาหารเอง',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _green,
                    fontFamily: 'Inter')),
          ]),
        ),
      ),
    );
  }

  void _showAddCustomMealDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('เพิ่มมื้ออาหาร',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'เช่น มื้อดึก, ก่อนนอน',
            filled: true,
            fillColor: _greenL,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _meals.add(MealSlot(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: ctrl.text.trim(),
                    emoji: '🍴',
                    timeHint: 'มื้อเพิ่มเติม')));
                Navigator.pop(ctx);
              }
            },
            child: const Text('เพิ่ม', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(13)),
              alignment: Alignment.center,
              child: const Text('🏃', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('กิจกรรมวันนี้',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Text('เผาผลาญรวม ${_totalCalBurned.toInt()} kcal',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
          ]),
        ),
        if (_activities.isNotEmpty) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          ..._activities.asMap().entries.map((e) {
            final a = e.value;
            return Dismissible(
              key: Key('act_${e.key}'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red.shade50,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              onDismissed: (_) => setState(() => _activities.removeAt(e.key)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Text(a.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${a.durationMin} นาที',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  )),
                  Text('-${a.caloriesBurned.toInt()} kcal',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _orange,
                          fontFamily: 'Inter')),
                ]),
              ),
            );
          }),
        ],
        const Divider(height: 1, indent: 16, endIndent: 16),
        GestureDetector(
          onTap: _showAddActivitySheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0), shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 16, color: _orange),
              ),
              const SizedBox(width: 8),
              const Text('เพิ่มกิจกรรม',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _orange,
                      fontFamily: 'Inter')),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showAddFoodSheet(MealSlot meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddFoodSheet(
        meal: meal,
        onFoodAdded: (food) async {
          setState(() => meal.foods.add(food));
          // Auto-save ทันทีเมื่อเพิ่มอาหาร
          await _saveSingleMeal(meal);
        },
      ),
    );
  }

  void _showAddActivitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddActivitySheet(
        onActivityAdded: (act) => setState(() => _activities.add(act)),
      ),
    );
  }

  Future<void> _saveSingleMeal(MealSlot meal) async {
    // ป้องกันการบันทึกซ้ำซ้อน
    if (_isSaving) {
      debugPrint('⚠️ BLOCKED: Already saving, skipping...');
      return;
    }

    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;

    setState(() => _isSaving = true);

    debugPrint('🔵 START SAVE: ${meal.id} with ${meal.foods.length} items');
    for (var f in meal.foods) {
      debugPrint('  - ${f.name}: ${f.calories} kcal');
    }

    try {
      final mealType =
          ['breakfast', 'lunch', 'dinner', 'snack'].contains(meal.id)
              ? meal.id
              : 'snack';

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // 1. ลบข้อมูลเก่าของมื้อนี้ก่อน (เหมือนโค้ดที่ใช้งานได้)
      final clearUrl = Uri.parse('${AppConstants.baseUrl}/meals/clear/$userId')
          .replace(queryParameters: {
        'date_record': dateStr,
        'meal_type': mealType,
      });
      debugPrint('🗑️ DELETE: $clearUrl');
      final delRes = await http.delete(clearUrl);
      debugPrint('🗑️ DELETE Response: ${delRes.statusCode}');

      // 2. บันทึกข้อมูลใหม่ทั้งมื้อ (ถ้ามีอาหาร)
      if (meal.foods.isNotEmpty) {
        final items = meal.foods
            .map((f) => {
                  'food_id': f.foodId ?? 0,
                  'food_name': f.name,
                  'amount': 1.0,
                  'cal_per_unit': f.calories,
                  'protein_per_unit': f.protein,
                  'carbs_per_unit': f.carbs,
                  'fat_per_unit': f.fat,
                })
            .toList();

        debugPrint('💾 POST: ${items.length} items');
        final postRes = await http.post(
          Uri.parse('${AppConstants.baseUrl}/meals/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'date': dateStr,
            'meal_type': mealType,
            'items': items,
          }),
        );
        debugPrint('💾 POST Response: ${postRes.statusCode}');
      } else {
        debugPrint(
            '💾 No items to POST (meal is empty - only DELETE was executed)');
      }
      debugPrint('✅ SAVE COMPLETE');
    } catch (e) {
      debugPrint('❌ Error saving meal: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _formatDateTh(DateTime d) {
    final months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year + 543}';
  }
}

// ═══════════════════════════════════════════════════════════
//  _AddFoodSheet — Bottom sheet สำหรับเพิ่มอาหาร
//  มี 2 tab: เลือกจาก DB | บันทึกด่วน
// ═══════════════════════════════════════════════════════════
class _AddFoodSheet extends ConsumerStatefulWidget {
  final MealSlot meal;
  final void Function(LoggedFood) onFoodAdded;
  const _AddFoodSheet({required this.meal, required this.onFoodAdded});

  @override
  ConsumerState<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<_AddFoodSheet>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF628141);
  static const _greenL = Color(0xFFE8EFCF);

  late TabController _tab;
  List<Map<String, dynamic>> _dbResults = [];
  bool _dbLoading = false;
  final _searchCtrl = TextEditingController();

  final _qNameCtrl = TextEditingController();
  final _qCalCtrl = TextEditingController();
  final _qProtCtrl = TextEditingController();
  final _qCarbCtrl = TextEditingController();
  final _qFatCtrl = TextEditingController();
  bool _qSending = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadAllFoods();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    _qNameCtrl.dispose();
    _qCalCtrl.dispose();
    _qProtCtrl.dispose();
    _qCarbCtrl.dispose();
    _qFatCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllFoods() async {
    setState(() => _dbLoading = true);
    try {
      final res = await http.get(Uri.parse('${AppConstants.baseUrl}/foods'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() => _dbResults = data.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
    setState(() => _dbLoading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchCtrl.text.isEmpty) return _dbResults;
    final q = _searchCtrl.text.toLowerCase();
    return _dbResults
        .where(
            (f) => (f['food_name']?.toString().toLowerCase() ?? '').contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scroll) => Column(children: [
        const SizedBox(height: 8),
        Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99)))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('เพิ่มอาหาร — ${widget.meal.name}',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
              color: _greenL, borderRadius: BorderRadius.circular(12)),
          child: TabBar(
            controller: _tab,
            indicator: BoxDecoration(
                color: _green, borderRadius: BorderRadius.circular(10)),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black54,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Inter'),
            tabs: const [
              Tab(text: '🔍 เลือกจากฐานข้อมูล'),
              Tab(text: '⚡ บันทึกด่วน'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildDBTab(scroll),
              _buildQuickAddTab(),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildDBTab(ScrollController scroll) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'ค้นหาเมนูอาหาร...',
            prefixIcon: const Icon(Icons.search, color: _green),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {});
                    })
                : null,
            filled: true,
            fillColor: _greenL,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      Expanded(
        child: _dbLoading
            ? const Center(child: CircularProgressIndicator(color: _green))
            : _filtered.isEmpty
                ? const Center(
                    child: Text('ไม่พบเมนูที่ค้นหา',
                        style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    controller: scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final f = _filtered[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                              width: 48,
                              height: 48,
                              child: (f['image_url'] != null &&
                                      (f['image_url'] as String).isNotEmpty)
                                  ? Image.network(f['image_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.restaurant,
                                              size: 24)))
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.restaurant,
                                          size: 24))),
                        ),
                        title: Text(f['food_name'] ?? '',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${f['calories']?.toStringAsFixed(0) ?? 0} kcal  •  '
                            'P:${f['protein']?.toStringAsFixed(0) ?? 0}g  '
                            'C:${f['carbs']?.toStringAsFixed(0) ?? 0}g  '
                            'F:${f['fat']?.toStringAsFixed(0) ?? 0}g',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                        trailing: GestureDetector(
                          onTap: () {
                            widget.onFoodAdded(LoggedFood(
                              name: f['food_name'] ?? '',
                              calories: double.tryParse(
                                      f['calories']?.toString() ?? '0') ??
                                  0,
                              protein: double.tryParse(
                                      f['protein']?.toString() ?? '0') ??
                                  0,
                              carbs: double.tryParse(
                                      f['carbs']?.toString() ?? '0') ??
                                  0,
                              fat: double.tryParse(
                                      f['fat']?.toString() ?? '0') ??
                                  0,
                              foodId: f['food_id'],
                            ));
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: _green, shape: BoxShape.circle),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }

  Widget _buildQuickAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Text('ℹ️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    'กรอกข้อมูลเมนูที่ไม่มีในระบบ จะถูกส่งให้ Admin ตรวจสอบ '
                    'และเพิ่มลงฐานข้อมูลในภายหลัง',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        height: 1.4))),
          ]),
        ),
        const SizedBox(height: 16),
        _qLabel('ชื่อเมนู *'),
        _qField(_qNameCtrl, 'เช่น ข้าวผัดปู, ลาบหมู'),
        const SizedBox(height: 12),
        _qLabel('แคลอรี่ (kcal) *'),
        _qField(_qCalCtrl, '0', isNumber: true),
        const SizedBox(height: 12),
        _qLabel('ข้อมูลโภชนาการ (กรัม)'),
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _qLabel('โปรตีน'),
                _qField(_qProtCtrl, '0', isNumber: true)
              ])),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _qLabel('คาร์โบไฮเดรต'),
                _qField(_qCarbCtrl, '0', isNumber: true)
              ])),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _qLabel('ไขมัน'),
                _qField(_qFatCtrl, '0', isNumber: true)
              ])),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _qSending ? null : _quickAddAndSubmit,
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _qSending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text('เพิ่ม + ส่งให้ Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
          ),
        ),
      ]),
    );
  }

  Widget _qLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600)));

  Widget _qField(TextEditingController ctrl, String hint,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : [],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: _greenL,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }

  bool _validateQuick() {
    if (_qNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อเมนู')));
      return false;
    }
    if (_qCalCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณากรอกแคลอรี่')));
      return false;
    }
    return true;
  }

  Future<void> _quickAddAndSubmit() async {
    if (!_validateQuick()) return;
    setState(() => _qSending = true);

    final food = LoggedFood(
      name: _qNameCtrl.text.trim(),
      calories: double.tryParse(_qCalCtrl.text) ?? 0,
      protein: double.tryParse(_qProtCtrl.text) ?? 0,
      carbs: double.tryParse(_qCarbCtrl.text) ?? 0,
      fat: double.tryParse(_qFatCtrl.text) ?? 0,
      isPending: true,
    );

    try {
      final userData = ref.read(userDataProvider);
      final userId = userData.userId;

      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/foods/auto-add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'food_name': food.name,
          'calories': food.calories,
          'protein': food.protein,
          'carbs': food.carbs,
          'fat': food.fat,
        }),
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to submit: ${res.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
      }
      setState(() => _qSending = false);
      return;
    }

    widget.onFoodAdded(food);
    setState(() => _qSending = false);
    if (mounted) Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════
//  _AddActivitySheet — Bottom sheet สำหรับเพิ่มกิจกรรม
// ═══════════════════════════════════════════════════════════
class _AddActivitySheet extends StatefulWidget {
  final void Function(Activity) onActivityAdded;
  const _AddActivitySheet({required this.onActivityAdded});

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  static const _orange = Color(0xFFD76A3C);
  static const _orangeL = Color(0xFFFFF3E0);
  static const _green = Color(0xFF628141);
  static const _greenL = Color(0xFFE8EFCF);

  static const _presets = [
    {'name': 'เดิน', 'emoji': '🚶', 'met': 3.5},
    {'name': 'วิ่ง', 'emoji': '🏃', 'met': 9.8},
    {'name': 'ปั่นจักรยาน', 'emoji': '🚴', 'met': 7.5},
    {'name': 'ว่ายน้ำ', 'emoji': '🏊', 'met': 8.0},
    {'name': 'เต้น Zumba', 'emoji': '💃', 'met': 6.0},
    {'name': 'โยคะ', 'emoji': '🧘', 'met': 3.0},
    {'name': 'ยกน้ำหนัก', 'emoji': '🏋️', 'met': 5.0},
    {'name': 'ฟุตบอล', 'emoji': '⚽', 'met': 7.0},
    {'name': 'บาสเกตบอล', 'emoji': '🏀', 'met': 6.5},
    {'name': 'กระโดดเชือก', 'emoji': '🪢', 'met': 11.0},
    {'name': 'HIIT', 'emoji': '🔥', 'met': 12.0},
    {'name': 'เดินขึ้นบันได', 'emoji': '🪜', 'met': 4.0},
  ];

  Map<String, dynamic>? _selectedPreset;
  int _duration = 30;
  double _userWeight = 65;
  final _customNameCtrl = TextEditingController();
  bool _isCustom = false;
  double _customMET = 4.0;

  double get _caloriesBurned {
    final met =
        _isCustom ? _customMET : (_selectedPreset?['met'] as double? ?? 4.0);
    return met * _userWeight * (_duration / 60);
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 16),
          Row(children: [
            const Text('🏃 เพิ่มกิจกรรม',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
          ]),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFD76A3C), Color(0xFFE85D04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('คาดว่าจะเผาผลาญ',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                Text('${_caloriesBurned.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('น้ำหนัก $_userWeight kg',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
                Text('$_duration นาที',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          const Text('เลือกกิจกรรม',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._presets.map((p) {
                final isSelected =
                    !_isCustom && _selectedPreset?['name'] == p['name'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedPreset = p;
                    _isCustom = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: isSelected ? _orange : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                isSelected ? _orange : Colors.grey.shade300)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(p['emoji'] as String,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(p['name'] as String,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected ? Colors.white : Colors.black87)),
                    ]),
                  ),
                );
              }),
              GestureDetector(
                onTap: () => setState(() => _isCustom = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: _isCustom ? _green : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _isCustom ? _green : Colors.grey.shade300)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('✏️',
                        style: TextStyle(
                            fontSize: 16,
                            color: _isCustom ? Colors.white : Colors.black)),
                    const SizedBox(width: 6),
                    Text('กำหนดเอง',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isCustom ? Colors.white : Colors.black87)),
                  ]),
                ),
              ),
            ],
          ),
          if (_isCustom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customNameCtrl,
              decoration: InputDecoration(
                hintText: 'ชื่อกิจกรรม',
                filled: true,
                fillColor: _greenL,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Text('MET Value:', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                  child: Slider(
                      value: _customMET,
                      min: 1,
                      max: 15,
                      divisions: 28,
                      activeColor: _green,
                      onChanged: (v) => setState(() => _customMET = v))),
              Text(_customMET.toStringAsFixed(1),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
            Text(
                'MET ต่ำ = เบา (เดิน~3.5), กลาง = ปานกลาง, สูง = หนัก (วิ่ง~10)',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
          const SizedBox(height: 16),
          Row(children: [
            const Text('ระยะเวลา',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: _orangeL, borderRadius: BorderRadius.circular(99)),
              child: Text('$_duration นาที',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _orange,
                      fontFamily: 'Inter')),
            ),
          ]),
          Slider(
              value: _duration.toDouble(),
              min: 5,
              max: 180,
              divisions: 35,
              activeColor: _orange,
              onChanged: (v) => setState(() => _duration = v.round())),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('5 นาที',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            Text('180 นาที',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            const Text('น้ำหนัก (สำหรับคำนวณ)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$_userWeight kg',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          Slider(
              value: _userWeight,
              min: 30,
              max: 150,
              divisions: 120,
              activeColor: _green,
              onChanged: (v) => setState(() => _userWeight = v)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_selectedPreset == null && !_isCustom)
                  ? null
                  : () {
                      final name = _isCustom
                          ? _customNameCtrl.text.trim().isEmpty
                              ? 'กิจกรรมที่กำหนดเอง'
                              : _customNameCtrl.text.trim()
                          : _selectedPreset!['name'] as String;
                      final emoji = _isCustom
                          ? '🏋️'
                          : _selectedPreset!['emoji'] as String;

                      widget.onActivityAdded(Activity(
                        name: name,
                        emoji: emoji,
                        durationMin: _duration,
                        caloriesBurned: _caloriesBurned,
                      ));
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: Text(
                  'บันทึกกิจกรรม (${_caloriesBurned.toStringAsFixed(0)} kcal)',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}