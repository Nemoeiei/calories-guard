import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/constants/constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '/providers/user_data_provider.dart';

// ─────────────────────────────────────────────
//  Model: สำหรับ Achievement Badge
// ─────────────────────────────────────────────
class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final int current;
  final int total;
  final bool unlocked;

  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.current,
    required this.total,
    required this.unlocked,
  });
}

// ─────────────────────────────────────────────
//  ProgressScreen
// ─────────────────────────────────────────────
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _selectedTabIndex = 0;
  DateTime _currentMonth = DateTime.now();

  int _chartWeekOffset = 0;
  int? _selectedChartDayIndex;
  int? _selectedNutritionMacroIndex;
  int? _selectedNutritionDayIndex;

  List<dynamic> _weeklyData = [];
  List<Map<String, dynamic>> _calendarData = [];

  // ── NEW: Weight History (จาก API หรือคำนวณ) ──
  // ❗ ต้องการ API: GET /users/{userId}/weight_history?limit=8
  // Response: [{ "date": "YYYY-MM-DD", "weight": 70.5 }, ...]
  List<Map<String, dynamic>> _weightHistory = [];

  // ── NEW: Top 5 Foods ──
  // ❗ ต้องการ API: GET /daily_logs/{userId}/top_foods?days=7
  // Response: [{ "name": "ข้าวมันไก่", "count": 5, "avg_calories": 480, "protein": 28, "carbs": 55, "fat": 14 }]
  List<Map<String, dynamic>> _topFoods = [];

  bool _isLoading = true;

  // ── NEW: Achievement definitions (คำนวณจาก local data) ──
  List<AchievementBadge> _badges = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllData();
    });
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    final monday = _getChartWeekMonday();
    await Future.wait([
      _fetchWeeklyData(weekStart: monday),
      _fetchCalendarData(),
      _fetchWeightHistory(),
      _fetchTopFoods(),
    ]);
    if (mounted) {
      _computeBadges();
      setState(() => _isLoading = false);
    }
  }

  DateTime _getChartWeekMonday() {
    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    return thisMonday.add(Duration(days: _chartWeekOffset * 7));
  }

  Future<void> _fetchWeeklyData({DateTime? weekStart}) async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;
    var url = Uri.parse('${AppConstants.baseUrl}/daily_logs/$userId/weekly');
    if (weekStart != null) {
      final q = DateFormat('yyyy-MM-dd').format(weekStart);
      url = url.replace(queryParameters: {'week_start': q});
    }
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() => _weeklyData = json.decode(response.body));
      }
    } catch (e) {
      debugPrint("Error fetching weekly: $e");
    }
  }

  Future<void> _fetchCalendarData() async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;
    final url = Uri.parse(
        '${AppConstants.baseUrl}/daily_logs/$userId/calendar?month=${_currentMonth.month}&year=${_currentMonth.year}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _calendarData = data
              .map((e) => {
                    'date': DateTime.parse(e['date']),
                    'calories': e['calories'] ?? 0,
                  })
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching calendar: $e");
    }
  }

  // ── NEW: Fetch Weight History ──
  Future<void> _fetchWeightHistory() async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;

    // ❗ เพิ่ม endpoint นี้ใน backend:
    // GET /users/{userId}/weight_history?limit=8
    final url = Uri.parse(
        '${AppConstants.baseUrl}/users/$userId/weight_history?limit=8');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _weightHistory = data
              .map((e) => {
                    'date': DateTime.parse(e['date']),
                    'weight': (e['weight'] as num).toDouble(),
                  })
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching weight history: $e");
      // ถ้า API ยังไม่มี: ใช้ข้อมูลจำลองเพื่อ dev
      // _weightHistory = _getMockWeightHistory();
    }
  }

  // ── NEW: Fetch Top Foods ──
  Future<void> _fetchTopFoods() async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;

    // ❗ เพิ่ม endpoint นี้ใน backend:
    // GET /daily_logs/{userId}/top_foods?days=7
    final url = Uri.parse(
        '${AppConstants.baseUrl}/daily_logs/$userId/top_foods?days=7');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _topFoods = data
              .map((e) => {
                    'name': e['name'] ?? '',
                    'count': e['count'] ?? 0,
                    'avg_calories':
                        (e['avg_calories'] as num?)?.toDouble() ?? 0,
                    'protein': (e['protein'] as num?)?.toDouble() ?? 0,
                    'carbs': (e['carbs'] as num?)?.toDouble() ?? 0,
                    'fat': (e['fat'] as num?)?.toDouble() ?? 0,
                  })
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching top foods: $e");
    }
  }

  // ── NEW: คำนวณ Badges จากข้อมูลที่มี ──
  void _computeBadges() {
    final streak = _calculateStreak();
    final userData = ref.read(userDataProvider);
    final targetCal = userData.targetCalories.toDouble();
    final weekMonday = _getChartWeekMonday();
    final daysMet = _getWeekDaysMetGoal(weekMonday, targetCal);

    // คำนวณ % ความคืบหน้าน้ำหนัก
    double weightProgress = 0.0;
    if (_weightHistory.length >= 2) {
      final firstW = (_weightHistory.first['weight'] as num).toDouble();
      final currentW = (_weightHistory.last['weight'] as num).toDouble();
      final targetW = userData.targetWeight.toDouble();
      final totalDiff = (targetW - firstW).abs();
      final moved = (currentW - firstW).abs();
      if (totalDiff > 0) {
        weightProgress = (moved / totalDiff).clamp(0.0, 1.0);
      }
    }

    _badges = [
      AchievementBadge(
        id: 'streak7',
        title: 'Streak 7 วัน',
        description: 'บันทึกติดต่อกัน 7 วัน',
        emoji: '🔥',
        color: const Color(0xFFF9A825),
        current: streak.clamp(0, 7),
        total: 7,
        unlocked: streak >= 7,
      ),
      AchievementBadge(
        id: 'streak30',
        title: 'Streak 30 วัน',
        description: 'บันทึกติดต่อกัน 30 วัน',
        emoji: '🌙',
        color: const Color(0xFF4CAF79),
        current: streak.clamp(0, 30),
        total: 30,
        unlocked: streak >= 30,
      ),
      AchievementBadge(
        id: 'ontarget',
        title: 'On Target',
        description: 'แคลอรี่พอดีเป้า 3 วันติด',
        emoji: '🎯',
        color: const Color(0xFF628141),
        current: daysMet.clamp(0, 3),
        total: 3,
        unlocked: daysMet >= 3,
      ),
      AchievementBadge(
        id: 'firstgoal',
        title: 'First Goal',
        description: 'ลดน้ำหนักครั้งแรกสำเร็จ',
        emoji: '⚖️',
        color: const Color(0xFF1565C0),
        current: weightProgress >= 0.1 ? 1 : 0,
        total: 1,
        unlocked: weightProgress >= 0.1,
      ),
      AchievementBadge(
        id: 'halfgoal',
        title: 'Half Way',
        description: 'ลดน้ำหนักถึง 50% ของเป้าหมาย',
        emoji: '🏅',
        color: const Color(0xFF6A1B9A),
        current: (weightProgress * 100).toInt().clamp(0, 50),
        total: 50,
        unlocked: weightProgress >= 0.5,
      ),
      AchievementBadge(
        id: 'perfectweek',
        title: 'Perfect Week',
        description: 'Macro + แคลอรี่ครบ 7 วัน',
        emoji: '⭐',
        color: const Color(0xFFF9A825),
        current: daysMet.clamp(0, 7),
        total: 7,
        unlocked: daysMet == 7,
      ),
      AchievementBadge(
        id: 'foodexplorer',
        title: 'Food Explorer',
        description: 'กินอาหาร 10 ชนิด/สัปดาห์',
        emoji: '🥗',
        color: const Color(0xFF8B6FD4),
        current: _topFoods.length.clamp(0, 10),
        total: 10,
        unlocked: _topFoods.length >= 10,
      ),
      AchievementBadge(
        id: 'cardioking',
        title: 'Cardio King',
        description: 'ออกกำลังกาย 5 ครั้ง/สัปดาห์',
        emoji: '🏃',
        color: const Color(0xFFF57C00),
        current: 0,
        total: 5,
        unlocked: false,
        // ❗ ต้องการ API exercise logging
      ),
    ];
  }

  // ── NEW: คำนวณวันถึงเป้า ──
  int _estimateDaysToGoal(UserData userData) {
    final weekMonday = _getChartWeekMonday();
    final avgCal = _getWeekAverageCal(weekMonday);
    final targetCal = userData.targetCalories.toDouble();
    final weightToLose = userData.weight - userData.targetWeight;
    if (weightToLose <= 0) return 0;
    if (avgCal <= 0 || targetCal <= 0) return -1;
    // 7700 kcal = 1 kg fat
    // deficit = kcal ที่กินน้อยกว่า TDEE จริง (ใช้ targetCal เป็น proxy)
    final calDeficitPerDay = userData.tdee - avgCal;
    if (calDeficitPerDay <= 0) return -1;
    return ((weightToLose * 7700) / calDeficitPerDay).ceil();
  }

  // ── NEW: XP คำนวณจาก streak + days met ──
  int _calculateXP(int streak, int daysMet) {
    return (streak * 10) + (daysMet * 15);
  }

  int _calculateLevel(int xp) {
    if (xp < 100) return 1;
    if (xp < 300) return 2;
    if (xp < 600) return 3;
    if (xp < 1000) return 4;
    return 5;
  }

  // ─────────────────────────────────────────────
  // Day Details (existing, unchanged)
  // ─────────────────────────────────────────────
  Future<void> _showDayDetails(DateTime date) async {
    final userId = ref.read(userDataProvider).userId;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final url = Uri.parse(
        '${AppConstants.baseUrl}/daily_logs/$userId?date_query=$dateStr');

    showDialog(
        context: context,
        builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      final response = await http.get(url);
      Navigator.pop(context);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _buildDayDetailSheet(date, data);
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  String? _mealLabel(Map<String, dynamic> data, String type) {
    final meals = data['meals'];
    if (meals is Map &&
        meals[type] != null &&
        meals[type].toString().trim().isNotEmpty) {
      return meals[type].toString();
    }
    final key = '${type}_menu';
    final v = data[key];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    return null;
  }

  void _buildDayDetailSheet(DateTime date, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── NEW: Handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 14),
              Text('บันทึกวันที่ ${_formatDateTh(date)}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter')),
              const SizedBox(height: 14),
              // ── NEW: Macro chips ──
              Row(
                children: [
                  _macroChip('🔥', '${data['calories']} kcal',
                      const Color(0xFFF57C00)),
                  const SizedBox(width: 8),
                  _macroChip(
                      '💪', '${data['protein']}g', const Color(0xFF628141)),
                  const SizedBox(width: 8),
                  _macroChip(
                      '🍚', '${data['carbs']}g', const Color(0xFFFFB800)),
                  const SizedBox(width: 8),
                  _macroChip('🧈', '${data['fat']}g', const Color(0xFFD76A3C)),
                ],
              ),
              const SizedBox(height: 14),
              const Text("เมนูที่ทาน:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              if (_mealLabel(data, 'breakfast') != null)
                _mealRow('🌅', 'เช้า', _mealLabel(data, 'breakfast')!),
              if (_mealLabel(data, 'lunch') != null)
                _mealRow('☀️', 'เที่ยง', _mealLabel(data, 'lunch')!),
              if (_mealLabel(data, 'dinner') != null)
                _mealRow('🌙', 'เย็น', _mealLabel(data, 'dinner')!),
              if (_mealLabel(data, 'snack') != null)
                _mealRow('🍎', 'ว่าง', _mealLabel(data, 'snack')!),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _macroChip(String emoji, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }

  Widget _mealRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontFamily: 'Inter')),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontFamily: 'Inter', height: 1.3))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter')),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BMI & Streak Helpers (unchanged)
  // ─────────────────────────────────────────────
  String _getBMIStatus(double bmi) {
    if (bmi < 18.5) return 'น้ำหนักน้อย';
    if (bmi < 22.9) return 'ปกติ';
    if (bmi < 24.9) return 'ท้วม';
    if (bmi < 29.9) return 'อ้วน';
    return 'อ้วนมาก';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF1710ED);
    if (bmi < 22.9) return const Color(0xFF69AE6D);
    if (bmi < 24.9) return const Color(0xFFD3D347);
    if (bmi < 29.9) return const Color(0xFFCAAC58);
    return const Color(0xFFFF0000);
  }

  int _calculateStreak() {
    if (_calendarData.isEmpty) return 0;
    List<DateTime> validDates = _calendarData
        .where((e) => (e['calories'] as num) > 0)
        .map((e) => e['date'] as DateTime)
        .toList();
    if (validDates.isEmpty) return 0;
    validDates.sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime checkDate =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (!validDates.any((d) => isSameDay(d, checkDate))) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    while (true) {
      if (validDates.any((d) => isSameDay(d, checkDate))) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Map<String, dynamic>> _getWeekBarData(DateTime weekMonday) {
    final List<Map<String, dynamic>> result = [];
    final today = DateTime.now();
    const dayNames = [
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัส',
      'ศุกร์',
      'เสาร์',
      'อาทิตย์'
    ];
    for (int i = 0; i < 7; i++) {
      final d = weekMonday.add(Duration(days: i));
      double cal = 0, protein = 0, carbs = 0, fat = 0;
      bool hasData = false;
      for (final e in _weeklyData) {
        final map = e as Map<String, dynamic>;
        final dateVal = map['date'];
        DateTime? docDate;
        if (dateVal is DateTime)
          docDate = dateVal;
        else if (dateVal != null)
          docDate = DateTime.tryParse(dateVal.toString());
        if (docDate != null && isSameDay(docDate, d)) {
          cal = (map['calories'] as num?)?.toDouble() ?? 0;
          protein = (map['protein'] as num?)?.toDouble() ?? 0;
          carbs = (map['carbs'] as num?)?.toDouble() ?? 0;
          fat = (map['fat'] as num?)?.toDouble() ?? 0;
          hasData = true;
          break;
        }
      }
      result.add({
        'date': d,
        'calories': cal,
        'hasData': hasData,
        'isToday': isSameDay(d, today),
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'dayName': dayNames[i],
      });
    }
    return result;
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    double bmi = userData.bmi;
    String bmiStatus = _getBMIStatus(bmi);
    Color bmiColor = _getBMIColor(bmi);
    int streak = userData.currentStreak > 0
        ? userData.currentStreak
        : _calculateStreak();
    double targetCal = userData.targetCalories.toDouble();
    if (targetCal <= 0) targetCal = 2000;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _buildWeightFAB(),
      body: Stack(
        children: [
          Positioned(
              top: 100,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(color: const Color(0xFFAFD198))),
          Column(
            children: [
              // Top Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(
                    top: 50, bottom: 15, left: 20, right: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5)
                            ]),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 18, color: Colors.black),
                      ),
                    ),
                    const Expanded(
                        child: Text('ความคืบหน้า',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                color: Colors.black))),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Summary Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTopCard(
                                title: 'น้ำหนักปัจจุบัน',
                                value: '${userData.weight.toInt()}',
                                unit: 'กิโลกรัม',
                                icon: Icons.person,
                                iconColor: const Color(0xFF91E47E)),
                            _buildTopCard(
                                title: 'น้ำหนักเป้าหมาย',
                                value: '${userData.targetWeight.toInt()}',
                                unit: 'กิโลกรัม',
                                icon: Icons.flag,
                                iconColor: const Color(0xFF465396)),
                            _buildTopCard(
                                title: 'ความต่อเนื่อง',
                                value: '$streak',
                                unit: 'วัน',
                                icon: Icons.local_fire_department,
                                iconColor: const Color(0xFFE4A47E)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── NEW: Prediction Banner ──
                      _buildPredictionBanner(userData, streak),

                      const SizedBox(height: 16),

                      // Tabs
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 13),
                        height: 42,
                        decoration: BoxDecoration(
                            color: const Color(0xFF628141),
                            borderRadius: BorderRadius.circular(50)),
                        child: Row(
                          children: [
                            _buildTabItem(0, 'ภาพรวม'),
                            _buildTabItem(1, 'โภชนาการ'),
                            _buildTabItem(2, 'ความสำเร็จ'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Tab: ภาพรวม ──
                      if (_selectedTabIndex == 0) ...[
                        _buildWeeklyChartSection(targetCal, userData),
                        const SizedBox(height: 10),
                        _buildWeightTrendSection(),
                        const SizedBox(height: 10),
                        _buildBMICard(bmi, bmiStatus, bmiColor, userData),
                        const SizedBox(height: 10),
                        _buildCalendarCard(streak, targetCal),
                        const SizedBox(height: 40),
                      ],

                      // ── Tab: โภชนาการ ──
                      if (_selectedTabIndex == 1) ...[
                        _buildNutritionSection(
                          targetCal,
                          userData.targetProtein.toDouble(),
                          userData.targetCarbs.toDouble(),
                          userData.targetFat.toDouble(),
                        ),
                        const SizedBox(height: 10),
                        _buildTop5FoodsSection(),
                        const SizedBox(height: 40),
                      ],

                      // ── Tab: ความสำเร็จ ──
                      if (_selectedTabIndex == 2) ...[
                        _buildAchievementTab(userData, streak),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ── NEW: Prediction Banner ──
  // ─────────────────────────────────────────────
  Widget _buildPredictionBanner(UserData userData, int streak) {
    final days = _estimateDaysToGoal(userData);
    final weightToLose = (userData.weight - userData.targetWeight);
    if (weightToLose <= 0) {
      // ถึงเป้าแล้ว!
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 13),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF1B5E35), Color(0xFF2E7D52)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF2E7D52).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ยินดีด้วย! คุณถึงเป้าหมายแล้ว',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          fontFamily: 'Inter')),
                  SizedBox(height: 2),
                  Text('รักษาน้ำหนักให้คงที่ต่อไปนะ 💪',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Inter')),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 13),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1B5E35), Color(0xFF2E7D52)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2E7D52).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          const Text('🚀', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'คาดการณ์',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      fontFamily: 'Inter'),
                ),
                const SizedBox(height: 2),
                Text(
                  days > 0
                      ? 'ถ้าทำแบบนี้ต่อ คุณจะถึงเป้าใน...'
                      : 'เพิ่มการขาดดุลแคลอรี่เพื่อลดน้ำหนัก',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      fontFamily: 'Inter'),
                ),
                if (days > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ยังเหลืออีก ${weightToLose.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'Inter'),
                  ),
                ],
              ],
            ),
          ),
          if (days > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    '~$days',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1),
                  ),
                  const Text('วัน',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontFamily: 'Inter')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ── NEW: Weight Trend Section ──
  // ─────────────────────────────────────────────
  Widget _buildWeightTrendSection() {
    if (_weightHistory.isEmpty) {
      return _buildWhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('กราฟน้ำหนัก',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter')),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.show_chart, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'ยังไม่มีข้อมูลน้ำหนัก\nบันทึกน้ำหนักอย่างน้อย 2 ครั้งเพื่อดูกราฟ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    final userData = ref.read(userDataProvider);
    final targetWeight = userData.targetWeight;

    // เตรียม spots สำหรับ LineChart
    final spots = _weightHistory.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['weight'] as num).toDouble());
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 1;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1;
    final weightChange = spots.last.y - spots.first.y;
    final isLosing = weightChange < 0;

    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('กราฟน้ำหนัก',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter')),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isLosing
                      ? const Color(0xFF628141).withOpacity(0.12)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLosing ? Icons.trending_down : Icons.trending_up,
                      size: 14,
                      color: isLosing ? const Color(0xFF628141) : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${weightChange.abs().toStringAsFixed(1)} kg',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              isLosing ? const Color(0xFF628141) : Colors.red,
                          fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()} kg',
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade500,
                            fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i < 0 || i >= _weightHistory.length)
                          return const Text('');
                        final d = _weightHistory[i]['date'] as DateTime;
                        return Text(
                          '${d.day}/${d.month}',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                              fontFamily: 'Inter'),
                        );
                      },
                    ),
                  ),
                ),
                // เส้น Target Weight
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: targetWeight,
                      color: Colors.orange.withOpacity(0.6),
                      strokeWidth: 1.5,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (_) =>
                            'เป้า ${targetWeight.toStringAsFixed(1)}',
                        style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFF628141),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: const Color(0xFF628141),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF628141).withOpacity(0.15),
                          const Color(0xFF628141).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${s.y.toStringAsFixed(1)} kg',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ── UPDATED: BMI Card with History + Goal Hint ──
  // ─────────────────────────────────────────────
  Widget _buildBMICard(
      double bmi, String bmiStatus, Color bmiColor, UserData userData) {
    final weightToNormal = bmi > 22.9
        ? ((bmi - 22.9) * (userData.weight / bmi)).toStringAsFixed(1)
        : null;

    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('BMI',
                  style: TextStyle(fontSize: 12, fontFamily: 'Inter')),
              const SizedBox(width: 20),
              Text(bmi.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: bmiColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5)),
                child: Text(bmiStatus,
                    style: TextStyle(
                        fontSize: 10,
                        color: bmiColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              double width = constraints.maxWidth;
              double minBMI = 15, maxBMI = 35;
              double normalizedBMI = (bmi - minBMI) / (maxBMI - minBMI);
              double position = normalizedBMI * width;
              position = position.clamp(0, width - 10);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(colors: [
                        Color(0xFF1710ED),
                        Color(0xFF69AE6D),
                        Color(0xFFD3D347),
                        Color(0xFFCAAC58),
                        Color(0xFFFF0000),
                      ]),
                    ),
                  ),
                  Positioned(
                    left: position,
                    top: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black54, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 2)
                          ]),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          // เพิ่ม scale labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ผอม\n<18.5',
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontFamily: 'Inter'),
                  textAlign: TextAlign.center),
              Text('ปกติ\n18.5–22.9',
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontFamily: 'Inter'),
                  textAlign: TextAlign.center),
              Text('ท้วม\n23–27.5',
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontFamily: 'Inter'),
                  textAlign: TextAlign.center),
              Text('อ้วน\n>27.5',
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontFamily: 'Inter'),
                  textAlign: TextAlign.center),
            ],
          ),

          // ── NEW: Goal Hint ──
          if (weightToNormal != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF628141).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF628141).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ลดอีก $weightToNormal kg จะเข้าเกณฑ์ BMI ปกติ!',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF628141),
                          fontFamily: 'Inter'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Text('ค่า BMI ของคุณแสดงผลตามเกณฑ์มาตรฐาน',
              style: TextStyle(fontSize: 10, color: Colors.black87)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ── Calendar Card (refactored from build) ──
  // ─────────────────────────────────────────────
  Widget _buildCalendarCard(int streak, double targetCal) {
    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('สถิติบันทึกต่อเนื่อง',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: Colors.red, size: 24),
              const SizedBox(width: 5),
              Text('$streak',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 5),
              const Text('วัน', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() => _currentMonth =
                      DateTime(_currentMonth.year, _currentMonth.month - 1));
                  _fetchCalendarData();
                },
              ),
              Text(_formatMonthYear(_currentMonth),
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() => _currentMonth =
                      DateTime(_currentMonth.year, _currentMonth.month + 1));
                  _fetchCalendarData();
                },
              ),
            ],
          ),
          _buildRealCalendar(_currentMonth, targetCal),
          const SizedBox(height: 16),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ── NEW: Top 5 Foods Section ──
  // ─────────────────────────────────────────────
  Widget _buildTop5FoodsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE8EFCF)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('อาหารที่กินบ่อยสุด',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter')),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EFCF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text('7 วันล่าสุด',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4C6414),
                          fontFamily: 'Inter')),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_topFoods.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.restaurant_menu,
                          size: 40, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('ยังไม่มีข้อมูล',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
              )
            else
              ...(_topFoods.take(5).toList().asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final food = entry.value;
                return _buildFoodRankRow(rank, food);
              }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodRankRow(int rank, Map<String, dynamic> food) {
    final colors = [
      const Color(0xFFF9A825),
      const Color(0xFF9E9E9E),
      const Color(0xFFCD7F32),
      const Color(0xFF628141),
      const Color(0xFF628141),
    ];
    final color = colors[rank - 1];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: rank < 5 ? Colors.grey.shade100 : Colors.transparent)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFamily: 'Inter'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text(
                  '~${(food['avg_calories'] as num).toInt()} kcal  •  P:${(food['protein'] as num).toInt()}g  C:${(food['carbs'] as num).toInt()}g  F:${(food['fat'] as num).toInt()}g',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontFamily: 'Inter'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${food['count']} ครั้ง',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ── NEW: Achievement Tab ──
  // ─────────────────────────────────────────────
  Widget _buildAchievementTab(UserData userData, int streak) {
    final weekMonday = _getChartWeekMonday();
    final targetCal = userData.targetCalories.toDouble();
    final daysMet = _getWeekDaysMetGoal(weekMonday, targetCal);
    final xp = _calculateXP(streak, daysMet);
    final level = _calculateLevel(xp);
    final nextLevelXp = [0, 100, 300, 600, 1000, 1500][level.clamp(0, 5)];
    final prevLevelXp = [0, 0, 100, 300, 600, 1000][level.clamp(0, 5)];
    final progress =
        (xp - prevLevelXp) / (nextLevelXp - prevLevelXp).clamp(1, 9999);

    final unlockedCount = _badges.where((b) => b.unlocked).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Level Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E35), Color(0xFF2E7D52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF2E7D52).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ระดับปัจจุบัน',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                letterSpacing: 0.5,
                                fontFamily: 'Inter')),
                        const SizedBox(height: 4),
                        Text(
                          _getLevelTitle(level),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'อีก ${nextLevelXp - xp} XP จะถึงระดับ ${_getLevelTitle(level + 1)}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                    Text(
                      _getLevelEmoji(level),
                      style: const TextStyle(fontSize: 44),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$xp XP',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'Inter')),
                    Text('Level $level',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'Inter')),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Badge Count ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ความสำเร็จ',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFCF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('$unlockedCount/${_badges.length} ปลดล็อค',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4C6414),
                        fontFamily: 'Inter')),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Badge Grid ──
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: _badges.map((b) => _buildBadgeCard(b)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(AchievementBadge badge) {
    return Opacity(
      opacity: badge.unlocked ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: badge.unlocked
                ? badge.color.withOpacity(0.3)
                : Colors.grey.shade200,
            width: badge.unlocked ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: badge.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child:
                      Text(badge.emoji, style: const TextStyle(fontSize: 20)),
                ),
                if (badge.unlocked)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF628141),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child:
                        const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
              ],
            ),
            const Spacer(),
            Text(badge.title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(badge.description,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontFamily: 'Inter'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (badge.current / badge.total).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: badge.color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(badge.color),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              badge.unlocked
                  ? 'ปลดล็อคแล้ว ✅'
                  : '${badge.current}/${badge.total}',
              style: TextStyle(
                  fontSize: 10,
                  color: badge.unlocked ? badge.color : Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter'),
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelTitle(int level) {
    const titles = [
      'มือใหม่',
      'ผู้เริ่มต้น',
      'นักโภชนาการ',
      'ผู้เชี่ยวชาญ',
      'แชมป์สุขภาพ',
      'ตำนาน'
    ];
    return titles[level.clamp(0, titles.length - 1)];
  }

  String _getLevelEmoji(int level) {
    const emojis = ['🌱', '🌿', '🌳', '⚡', '🏆', '👑'];
    return emojis[level.clamp(0, emojis.length - 1)];
  }

  // ─────────────────────────────────────────────
  // Nutrition Section (UPDATED: เพิ่ม macro summary ด้านบน)
  // ─────────────────────────────────────────────
  Widget _buildNutritionSection(double targetCal, double targetProtein,
      double targetCarbs, double targetFat) {
    final weekMonday = _getChartWeekMonday();
    final weekData = _getWeekBarData(weekMonday);
    final weekNum = _getWeekNumber(weekMonday);

    // คำนวณค่าเฉลี่ยโภชนาการสัปดาห์
    double avgP = 0, avgC = 0, avgF = 0;
    int daysWithData = 0;
    for (final d in weekData) {
      if (d['hasData'] == true) {
        avgP += (d['protein'] as num?)?.toDouble() ?? 0;
        avgC += (d['carbs'] as num?)?.toDouble() ?? 0;
        avgF += (d['fat'] as num?)?.toDouble() ?? 0;
        daysWithData++;
      }
    }
    if (daysWithData > 0) {
      avgP /= daysWithData;
      avgC /= daysWithData;
      avgF /= daysWithData;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeekPill(weekMonday, weekNum),
          const SizedBox(height: 14),

          // ── NEW: Macro Avg Summary ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EFCF)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('โภชนาการเฉลี่ยสัปดาห์นี้',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                        fontFamily: 'Inter')),
                const SizedBox(height: 12),
                _buildMacroAvgRow('🥩', 'โปรตีน', avgP, targetProtein,
                    const Color(0xFF628141)),
                const SizedBox(height: 8),
                _buildMacroAvgRow(
                    '🍚', 'คาร์บ', avgC, targetCarbs, const Color(0xFFFFB800)),
                const SizedBox(height: 8),
                _buildMacroAvgRow(
                    '🧈', 'ไขมัน', avgF, targetFat, const Color(0xFFD76A3C)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Chart Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE8EFCF)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('โภชนาการรายสัปดาห์',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter')),
                    if (_selectedNutritionDayIndex != null &&
                        _selectedNutritionDayIndex! < weekData.length) ...[
                      const SizedBox(width: 12),
                      _buildDayNutritionBox(
                        weekData[_selectedNutritionDayIndex!],
                        targetProtein,
                        targetCarbs,
                        targetFat,
                        _selectedNutritionDayIndex!,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: _CombinedMacroChart(
                    weekData: weekData,
                    targetProtein: targetProtein,
                    targetCarbs: targetCarbs,
                    targetFat: targetFat,
                    selectedMacroIndex: _selectedNutritionMacroIndex,
                    onTapped: (dayIndex, macroIndex) {
                      setState(() {
                        final sameDay = _selectedNutritionDayIndex == dayIndex;
                        _selectedNutritionDayIndex = sameDay ? null : dayIndex;
                        _selectedNutritionMacroIndex =
                            sameDay ? null : macroIndex;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _macroLegendChip(const Color(0xFF628141), 'โปรตีน',
                        _selectedNutritionMacroIndex == 0),
                    const SizedBox(width: 12),
                    _macroLegendChip(const Color(0xFFFFB800), 'คาร์บ',
                        _selectedNutritionMacroIndex == 1),
                    const SizedBox(width: 12),
                    _macroLegendChip(const Color(0xFFD76A3C), 'ไขมัน',
                        _selectedNutritionMacroIndex == 2),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroAvgRow(
      String emoji, String label, double avg, double target, Color color) {
    final pct = target > 0 ? (avg / target).clamp(0.0, 1.0) : 0.0;
    final isLow = pct < 0.7;
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        SizedBox(
            width: 52,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter'))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            '${avg.toInt()}/${target.toInt()}g',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isLow ? Colors.orange : color,
                fontFamily: 'Inter'),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isLow ? '⚠️' : '✓',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Existing Widgets (unchanged)
  // ─────────────────────────────────────────────
  Widget _buildDayNutritionBox(Map<String, dynamic> dayData, double targetP,
      double targetC, double targetF, int dayIndex) {
    final hasData = dayData['hasData'] == true;
    final p = hasData ? (dayData['protein'] as num?)?.toDouble() ?? 0 : 0.0;
    final c = hasData ? (dayData['carbs'] as num?)?.toDouble() ?? 0 : 0.0;
    final f = hasData ? (dayData['fat'] as num?)?.toDouble() ?? 0 : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EFCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Text('โปรตีน ${p.toInt()}/${targetP.toInt()}',
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF628141),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter')),
          Text('คาร์บ ${c.toInt()}/${targetC.toInt()}',
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFFFB800),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter')),
          Text('ไขมัน ${f.toInt()}/${targetF.toInt()}',
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFD76A3C),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Widget _macroLegendChip(Color color, String label, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          final idx = label == 'โปรตีน' ? 0 : (label == 'คาร์บ' ? 1 : 2);
          _selectedNutritionMacroIndex =
              _selectedNutritionMacroIndex == idx ? null : idx;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: selected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : color,
                    fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekPill(DateTime weekMonday, int weekNum) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE8EFCF)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _chartWeekOffset--;
                _selectedChartDayIndex = null;
                _selectedNutritionMacroIndex = null;
                _selectedNutritionDayIndex = null;
                _fetchWeeklyData(weekStart: _getChartWeekMonday());
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF628141),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text('สัปดาห์ที่ $weekNum',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        fontFamily: 'Inter')),
                const SizedBox(height: 2),
                Text(_getWeekRangeText(weekMonday),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                        fontFamily: 'Inter')),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _chartWeekOffset >= 0
                ? null
                : () {
                    setState(() {
                      _chartWeekOffset++;
                      _selectedChartDayIndex = null;
                      _selectedNutritionMacroIndex = null;
                      _selectedNutritionDayIndex = null;
                      _fetchWeeklyData(weekStart: _getChartWeekMonday());
                    });
                  },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            style: IconButton.styleFrom(
              backgroundColor: _chartWeekOffset >= 0
                  ? Colors.grey.shade300
                  : const Color(0xFF628141),
              foregroundColor:
                  _chartWeekOffset >= 0 ? Colors.grey.shade600 : Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChartSection(double targetCal, UserData userData) {
    final weekMonday = _getChartWeekMonday();
    final weekData = _getWeekBarData(weekMonday);
    final weekNum = _getWeekNumber(weekMonday);
    final avgCal = _getWeekAverageCal(weekMonday);
    final onTargetPct = _getWeekOnTargetPercent(weekMonday, targetCal);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFFE8EFCF)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _chartWeekOffset--;
                      _selectedChartDayIndex = null;
                      _fetchWeeklyData(weekStart: _getChartWeekMonday());
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF628141),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('สัปดาห์ที่ $weekNum',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              fontFamily: 'Inter')),
                      const SizedBox(height: 2),
                      Text(_getWeekRangeText(weekMonday),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _chartWeekOffset >= 0
                      ? null
                      : () {
                          setState(() {
                            _chartWeekOffset++;
                            _selectedChartDayIndex = null;
                            _fetchWeeklyData(weekStart: _getChartWeekMonday());
                          });
                        },
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  style: IconButton.styleFrom(
                    backgroundColor: _chartWeekOffset >= 0
                        ? Colors.grey.shade300
                        : const Color(0xFF628141),
                    foregroundColor: _chartWeekOffset >= 0
                        ? Colors.grey.shade600
                        : Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE8EFCF)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('เฉลี่ยรายสัปดาห์',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: Colors.grey[600],
                                fontFamily: 'Inter')),
                        const SizedBox(height: 4),
                        Text('${avgCal.toInt()}',
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                fontFamily: 'Inter',
                                letterSpacing: -0.5)),
                        Text('kcal/วัน',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                                fontFamily: 'Inter')),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EFCF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF628141).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('▲ ',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF4C6414),
                                  fontFamily: 'Inter')),
                          Text('$onTargetPct%',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF4C6414),
                                  fontFamily: 'Inter')),
                          const Text(' เป้าหมาย',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4C6414),
                                  fontFamily: 'Inter')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRect(
                  child: SizedBox(
                    height: 228,
                    child: _WeeklyBarChart(
                      weekBarData: weekData,
                      targetCal: targetCal,
                      selectedBarIndex: _selectedChartDayIndex,
                      onBarTapped: (index) {
                        setState(() {
                          _selectedChartDayIndex =
                              _selectedChartDayIndex == index ? null : index;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _chartLegendChipLight(
                        const Color(0xFF628141), 'ในเป้าหมาย'),
                    _chartLegendChipLight(const Color(0xFFD76A3C), 'เกินเป้า'),
                    _chartLegendChipLight(
                        const Color(0xFF9E9E9E), 'ไม่ได้กรอก'),
                    _chartLegendChipLight(
                        const Color(0xFFA78BFA), 'ต่ำกว่าเป้า'),
                    _chartLegendChipLight(const Color(0xFFFFB800), 'วันนี้'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildQuickStats(weekMonday, targetCal, userData),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
      DateTime weekMonday, double targetCal, UserData userData) {
    final totalCal = _getWeekTotalCal(weekMonday);
    final daysMet = _getWeekDaysMetGoal(weekMonday, targetCal);
    final avgCal = _getWeekAverageCal(weekMonday);
    const Color orange = Color(0xFFE85D04);
    const Color green = Color(0xFF628141);
    const Color yellow = Color(0xFFE6A800);
    const Color purple = Color(0xFFA78BFA);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _quickStatCard(
          icon: Icons.local_fire_department,
          iconBg: orange.withOpacity(0.2),
          iconColor: orange,
          value: _formatNumber(totalCal),
          valueColor: orange,
          label: 'รวมสัปดาห์ (kcal)',
        ),
        _quickStatCard(
          icon: Icons.gps_fixed,
          iconBg: green.withOpacity(0.2),
          iconColor: green,
          value: '$daysMet/7',
          valueColor: green,
          label: 'วันที่ผ่านเป้า',
        ),
        _quickStatCard(
          icon: Icons.bolt,
          iconBg: yellow.withOpacity(0.2),
          iconColor: yellow,
          value: _formatNumber(avgCal.toInt()),
          valueColor: yellow,
          label: 'ค่าเฉลี่ย/วัน',
        ),
        _quickStatCard(
          icon: Icons.show_chart,
          iconBg: purple.withOpacity(0.2),
          iconColor: purple,
          value: () {
            if (_weightHistory.length >= 2) {
              final first = (_weightHistory.first['weight'] as num).toDouble();
              final last = (_weightHistory.last['weight'] as num).toDouble();
              final diff = last - first;
              final sign = diff > 0 ? '+' : '';
              return '$sign${diff.toStringAsFixed(1)} kg';
            }
            return '— kg';
          }(),
          valueColor: purple,
          label: 'เปลี่ยนแปลงน้ำหนัก',
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n.abs() < 1000) return '$n';
    final sign = n < 0 ? '-' : '';
    n = n.abs();
    final parts = <String>[];
    while (n >= 1000) {
      parts.insert(0, (n % 1000).toString().padLeft(3, '0'));
      n ~/= 1000;
    }
    parts.insert(0, '$n');
    return sign + parts.join(',');
  }

  Widget _quickStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required Color valueColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EFCF)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  fontFamily: 'Inter',
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Widget _chartLegendChipLight(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Widget _buildRealCalendar(DateTime month, double targetCal) {
    int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    int firstWeekday = DateTime(month.year, month.month, 1).weekday;
    List<Widget> dayHeaders = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา']
        .map((day) => Center(
            child: Text(day,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold))))
        .toList();
    List<Widget> dayCells = [];
    for (int i = 1; i < firstWeekday; i++) {
      dayCells.add(Container());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime date = DateTime(month.year, month.month, day);
      Map<String, dynamic> logData = _calendarData.firstWhere(
        (data) => isSameDay(data['date'], date),
        orElse: () => {},
      );
      bool isLogged = logData.isNotEmpty;
      double cal = isLogged ? (logData['calories'] as num).toDouble() : 0.0;
      bool isToday = isSameDay(date, DateTime.now());
      Color? circleColor;
      if (isLogged) {
        if (cal > targetCal) {
          circleColor = Colors.red;
        } else if (cal < targetCal * 0.9) {
          circleColor = const Color(0xFFA78BFA);
        } else {
          circleColor = const Color(0xFF628141);
        }
      } else {
        circleColor = Colors.grey.shade400;
      }
      dayCells.add(GestureDetector(
        onTap: isLogged ? () => _showDayDetails(date) : null,
        child: Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border:
                  isToday ? Border.all(color: Colors.black, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: isLogged || isToday ? Colors.white : Colors.white,
                fontWeight:
                    isLogged || isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ));
    }
    return Column(
      children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayHeaders.map((w) => Expanded(child: w)).toList()),
        const SizedBox(height: 10),
        GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: dayCells),
      ],
    );
  }

  Widget _buildCalendarLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendItem(const Color(0xFF628141), 'ในเป้าหมาย'),
        _legendItem(Colors.red, 'เกินเป้าหมาย'),
        _legendItem(const Color(0xFFA78BFA), 'ต่ำกว่าเป้า'),
        _legendItem(Colors.grey, 'ไม่ได้กรอก'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontFamily: 'Inter', color: Colors.black87)),
      ],
    );
  }

  String _formatDateTh(DateTime date) =>
      '${date.day}/${date.month}/${date.year + 543}';

  double _getWeekAverageCal(DateTime weekMonday) {
    final data = _getWeekBarData(weekMonday);
    double sum = 0;
    int count = 0;
    for (final d in data) {
      if (d['hasData'] == true) {
        sum += (d['calories'] as num).toDouble();
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  }

  int _getWeekOnTargetPercent(DateTime weekMonday, double targetCal) {
    final data = _getWeekBarData(weekMonday);
    int onTarget = 0;
    for (final d in data) {
      if (d['hasData'] == true &&
          (d['calories'] as num).toDouble() <= targetCal) onTarget++;
    }
    return ((onTarget / 7) * 100).round();
  }

  int _getWeekTotalCal(DateTime weekMonday) {
    final data = _getWeekBarData(weekMonday);
    int sum = 0;
    for (final d in data) {
      if (d['hasData'] == true) sum += (d['calories'] as num).toInt();
    }
    return sum;
  }

  int _getWeekDaysMetGoal(DateTime weekMonday, double targetCal) {
    final data = _getWeekBarData(weekMonday);
    int count = 0;
    for (final d in data) {
      if (d['hasData'] == true &&
          (d['calories'] as num).toDouble() <= targetCal) count++;
    }
    return count;
  }

  int _getWeekNumber(DateTime weekMonday) {
    final startOfYear = DateTime(weekMonday.year, 1, 1);
    final days = weekMonday.difference(startOfYear).inDays;
    return (days / 7).floor() + 1;
  }

  String _getWeekRangeText(DateTime weekMonday) {
    final sunday = weekMonday.add(const Duration(days: 6));
    List<String> months = [
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
    final m = months[weekMonday.month - 1];
    final y = weekMonday.year + 543;
    if (weekMonday.month == sunday.month)
      return '${weekMonday.day}–${sunday.day} $m $y';
    final m2 = months[sunday.month - 1];
    return '${weekMonday.day} $m – ${sunday.day} $m2 $y';
  }

  String _formatMonthYear(DateTime date) {
    List<String> months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม'
    ];
    return '${months[date.month - 1]} ${date.year + 543}';
  }

  Widget _buildTopCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 110,
      height: 169,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: iconColor, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24)),
          const Spacer(),
          Text(title,
              style: const TextStyle(
                  fontSize: 12, height: 1.2, fontFamily: 'Inter')),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter')),
          Text(unit, style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Widget _buildWhiteCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 13),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: child,
    );
  }

  Widget _buildTabItem(int index, String title) {
    bool isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
            if (index != 1) {
              _selectedNutritionMacroIndex = null;
              _selectedNutritionDayIndex = null;
            }
          });
          if (index == 1) _fetchWeeklyData(weekStart: _getChartWeekMonday());
          if (index == 2) _computeBadges();
        },
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(50)),
          alignment: Alignment.center,
          child: Text(title,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.black : Colors.white)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Weight Logging FAB & Bottom Sheet
  // ─────────────────────────────────────────────
  Widget _buildWeightFAB() {
    return FloatingActionButton.extended(
      onPressed: _showWeightLogSheet,
      backgroundColor: const Color(0xFF628141),
      icon: const Icon(Icons.monitor_weight_outlined, color: Colors.white),
      label: const Text(
        'บันทึกน้ำหนัก',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showWeightLogSheet() {
    final userData = ref.read(userDataProvider);
    // ตั้งค่าเริ่มต้น = น้ำหนักปัจจุบัน
    final controller = TextEditingController(
      text: userData.weight > 0 ? userData.weight.toStringAsFixed(1) : '',
    );
    bool _isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ให้ขยายได้เมื่อ keyboard ขึ้น
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              // กัน keyboard บัง input
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Handle ──
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Title ──
                    const Text(
                      '⚖️ บันทึกน้ำหนักวันนี้',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'น้ำหนักล่าสุด: ${userData.weight.toStringAsFixed(1)} kg  •  เป้าหมาย: ${userData.targetWeight.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Input ──
                    TextField(
                      controller: controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        color: Color(0xFF628141),
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0.0',
                        hintStyle: TextStyle(
                          fontSize: 32,
                          color: Colors.grey.shade300,
                          fontFamily: 'Inter',
                        ),
                        suffixText: 'kg',
                        suffixStyle: const TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                          fontFamily: 'Inter',
                        ),
                        filled: true,
                        fillColor: const Color(0xFF628141).withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF628141),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Save Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final val = double.tryParse(controller.text);
                                if (val == null || val <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('กรุณากรอกน้ำหนักให้ถูกต้อง'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(() => _isSaving = true);

                                // ── ยิง API เดิม (PUT /users/{id}) ──
                                final userId =
                                    ref.read(userDataProvider).userId;
                                final url = Uri.parse(
                                  '${AppConstants.baseUrl}/users/$userId',
                                );
                                try {
                                  final response = await http.put(
                                    url,
                                    headers: {
                                      'Content-Type': 'application/json'
                                    },
                                    body:
                                        jsonEncode({'current_weight_kg': val}),
                                  );

                                  if (response.statusCode == 200) {
                                    // ── อัปเดต Provider ──
                                    final user = ref.read(userDataProvider);
                                    ref
                                        .read(userDataProvider.notifier)
                                        .setPersonalInfo(
                                          name: user.name,
                                          birthDate:
                                              user.birthDate ?? DateTime.now(),
                                          height: user.height,
                                          weight: val,
                                        );

                                    // ── Refresh กราฟน้ำหนัก ──
                                    await _fetchWeightHistory();

                                    if (mounted) {
                                      Navigator.pop(context); // ปิด sheet
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '✅ บันทึกน้ำหนัก ${val.toStringAsFixed(1)} kg แล้ว!',
                                          ),
                                          backgroundColor:
                                              const Color(0xFF628141),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    throw Exception(
                                        'Server error ${response.statusCode}');
                                  }
                                } catch (e) {
                                  setSheetState(() => _isSaving = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('เกิดข้อผิดพลาด: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF628141),
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'บันทึก',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Chart Widgets (unchanged from original)
// ─────────────────────────────────────────────
class _WeeklyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> weekBarData;
  final double targetCal;
  final int? selectedBarIndex;
  final ValueChanged<int?>? onBarTapped;

  const _WeeklyBarChart({
    required this.weekBarData,
    required this.targetCal,
    this.selectedBarIndex,
    this.onBarTapped,
  });

  static const Color _green = Color(0xFF628141);
  static const Color _red = Color(0xFFD76A3C);
  static const Color _gray = Color(0xFF9E9E9E);
  static const Color _yellow = Color(0xFFFFB800);
  static const Color _belowTarget = Color(0xFFA78BFA);

  @override
  Widget build(BuildContext context) {
    if (weekBarData.length != 7) {
      return const SizedBox(
        height: 228,
        child: Center(
            child: Text("กำลังโหลด...", style: TextStyle(color: Colors.grey))),
      );
    }
    double maxCal = targetCal;
    for (final d in weekBarData) {
      if (d['hasData'] == true) {
        double c = (d['calories'] as num).toDouble();
        if (c > maxCal) maxCal = c;
      }
    }
    double maxY = (maxCal * 1.12).clamp(targetCal * 1.0, double.infinity);
    if (maxY < 500) maxY = 500;

    final showValueForSelected = selectedBarIndex != null;
    final reservedBottom = showValueForSelected ? 40 : 22;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxY,
        minY: 0,
        groupsSpace: 6,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (response == null ||
                response.spot == null ||
                onBarTapped == null) return;
            onBarTapped!(response.spot!.touchedBarGroupIndex);
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = weekBarData[group.x];
              final dayName = d['dayName'] as String? ??
                  _getDayName((d['date'] as DateTime).weekday);
              final hasData = d['hasData'] == true;
              final cal = (d['calories'] as num?)?.toDouble() ?? 0;
              final text = hasData
                  ? '$dayName: ${cal.toInt()} kcal'
                  : '$dayName: ไม่ได้กรอก';
              return BarTooltipItem(
                  text, const TextStyle(color: Colors.white, fontSize: 12));
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: reservedBottom.toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= 0 && i < weekBarData.length) {
                  final d = weekBarData[i];
                  final date = d['date'] as DateTime;
                  final hasData = d['hasData'] == true;
                  final cal = (d['calories'] as num?)?.toDouble() ?? 0;
                  final calText = hasData ? '${cal.toInt()}' : '-';
                  final isSelected = selectedBarIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showValueForSelected && isSelected)
                          Text(calText,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                  fontFamily: 'Inter')),
                        if (showValueForSelected && isSelected)
                          const SizedBox(height: 2),
                        Text(_getDayName(date.weekday),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.black87
                                  : Colors.grey[600],
                            )),
                      ],
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: targetCal,
              color: Colors.orange.withOpacity(0.7),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => 'เป้า ${targetCal.toInt()}',
                style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        barGroups: weekBarData.asMap().entries.map((entry) {
          int index = entry.key;
          final d = entry.value;
          bool hasData = d['hasData'] == true;
          bool isToday = d['isToday'] == true;
          double calories = (d['calories'] as num?)?.toDouble() ?? 0;
          double toY = hasData ? calories : (targetCal * 0.06);
          Color color = _gray;
          if (hasData) {
            if (isToday) {
              color = _yellow;
            } else if (calories > targetCal) {
              color = _red;
            } else if (calories < targetCal * 0.9) {
              color = _belowTarget;
            } else {
              color = _green;
            }
          }
          final isSelected = selectedBarIndex == index;
          final barColor = isSelected ? color : color.withOpacity(0.35);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: toY,
                color: barColor,
                width: 28,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: const Color(0xFFF0F0F0),
                ),
              )
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    return days[weekday - 1];
  }
}

class _CombinedMacroChart extends StatelessWidget {
  final List<Map<String, dynamic>> weekData;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final int? selectedMacroIndex;
  final void Function(int dayIndex, int macroIndex) onTapped;

  const _CombinedMacroChart({
    required this.weekData,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.selectedMacroIndex,
    required this.onTapped,
  });

  static const List<String> _dayLabels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
  static const Color _colorProtein = Color(0xFF628141);
  static const Color _colorCarbs = Color(0xFFFFB800);
  static const Color _colorFat = Color(0xFFD76A3C);

  @override
  Widget build(BuildContext context) {
    if (weekData.length != 7) {
      return const SizedBox(
          height: 220,
          child: Center(
              child:
                  Text('กำลังโหลด...', style: TextStyle(color: Colors.grey))));
    }
    double maxVal = 0;
    for (final d in weekData) {
      if (d['hasData'] == true) {
        final p = (d['protein'] as num?)?.toDouble() ?? 0;
        final c = (d['carbs'] as num?)?.toDouble() ?? 0;
        final f = (d['fat'] as num?)?.toDouble() ?? 0;
        if (p > maxVal) maxVal = p;
        if (c > maxVal) maxVal = c;
        if (f > maxVal) maxVal = f;
      }
    }
    final targets = [targetProtein, targetCarbs, targetFat];
    for (final t in targets) {
      if (t > maxVal) maxVal = t;
    }
    double maxY = (maxVal * 1.2).clamp(20, double.infinity);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxY,
        minY: 0,
        groupsSpace: 8,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            final spot = response?.spot;
            if (spot == null) return;
            final dayIndex = spot.touchedBarGroupIndex;
            final macroIndex = spot.touchedRodDataIndex;
            if (dayIndex >= 0 &&
                dayIndex < 7 &&
                macroIndex >= 0 &&
                macroIndex <= 2) onTapped(dayIndex, macroIndex);
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = weekData[group.x];
              final hasData = d['hasData'] == true;
              final labels = ['โปรตีน', 'คาร์บ', 'ไขมัน'];
              final values = [
                (d['protein'] as num?)?.toDouble() ?? 0,
                (d['carbs'] as num?)?.toDouble() ?? 0,
                (d['fat'] as num?)?.toDouble() ?? 0,
              ];
              final v = rodIndex < values.length ? values[rodIndex] : 0.0;
              final text = hasData
                  ? '${_dayLabels[group.x]} ${labels[rodIndex]}: ${v.toInt()} g'
                  : '${_dayLabels[group.x]} ${labels[rodIndex]}: —';
              return BarTooltipItem(
                  text, const TextStyle(color: Colors.white, fontSize: 11));
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= 0 && i < _dayLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_dayLabels[i],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600])),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: targetProtein,
              color: _colorProtein.withOpacity(0.7),
              strokeWidth: 1.5,
              dashArray: [4, 4],
              label: HorizontalLineLabel(
                  show: true,
                  style: TextStyle(
                      fontSize: 9,
                      color: _colorProtein,
                      fontWeight: FontWeight.w600),
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 4),
                  labelResolver: (_) => 'โปรตีน'),
            ),
            HorizontalLine(
              y: targetCarbs,
              color: _colorCarbs.withOpacity(0.7),
              strokeWidth: 1.5,
              dashArray: [4, 4],
              label: HorizontalLineLabel(
                  show: true,
                  style: TextStyle(
                      fontSize: 9,
                      color: _colorCarbs,
                      fontWeight: FontWeight.w600),
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 4),
                  labelResolver: (_) => 'คาร์บ'),
            ),
            HorizontalLine(
              y: targetFat,
              color: _colorFat.withOpacity(0.7),
              strokeWidth: 1.5,
              dashArray: [4, 4],
              label: HorizontalLineLabel(
                  show: true,
                  style: TextStyle(
                      fontSize: 9,
                      color: _colorFat,
                      fontWeight: FontWeight.w600),
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 4),
                  labelResolver: (_) => 'ไขมัน'),
            ),
          ],
        ),
        barGroups: weekData.asMap().entries.map((entry) {
          int dayIndex = entry.key;
          final d = entry.value;
          final hasData = d['hasData'] == true;
          final p = hasData
              ? ((d['protein'] as num?)?.toDouble() ?? 0)
              : (targetProtein * 0.05);
          final c = hasData
              ? ((d['carbs'] as num?)?.toDouble() ?? 0)
              : (targetCarbs * 0.05);
          final f = hasData
              ? ((d['fat'] as num?)?.toDouble() ?? 0)
              : (targetFat * 0.05);
          Color colorP = _colorProtein;
          Color colorC = _colorCarbs;
          Color colorF = _colorFat;
          if (selectedMacroIndex != null) {
            if (selectedMacroIndex != 0)
              colorP = _colorProtein.withOpacity(0.35);
            if (selectedMacroIndex != 1) colorC = _colorCarbs.withOpacity(0.35);
            if (selectedMacroIndex != 2) colorF = _colorFat.withOpacity(0.35);
          }
          if (!hasData) {
            colorP = Colors.grey;
            colorC = Colors.grey;
            colorF = Colors.grey;
          }
          return BarChartGroupData(
            x: dayIndex,
            barRods: [
              BarChartRodData(
                  toY: p,
                  color: colorP,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                      show: true, toY: maxY, color: const Color(0xFFF5F5F5))),
              BarChartRodData(
                  toY: c,
                  color: colorC,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                      show: true, toY: maxY, color: const Color(0xFFF5F5F5))),
              BarChartRodData(
                  toY: f,
                  color: colorF,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                      show: true, toY: maxY, color: const Color(0xFFF5F5F5))),
            ],
            showingTooltipIndicators: [],
          );
        }).toList(),
      ),
    );
  }
}
