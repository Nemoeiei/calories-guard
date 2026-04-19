import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:http/http.dart' as http;

import 'package:flutter_application_1/constants/constants.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:intl/intl.dart';

import '/providers/user_data_provider.dart'; // ปรับ Path ให้ตรงกับโครงสร้างของคุณ
import '/services/error_reporter.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _selectedTabIndex = 0;

  DateTime _currentMonth = DateTime.now();

  /// ออฟเซ็ตสัปดาห์ของกราฟ: 0 = สัปดาห์นี้, -1 = สัปดาห์ก่อน, 1 = สัปดาห์ถัดไป

  int _chartWeekOffset = 0;

  /// แท่งที่ถูกแตะ (null = ไม่แสดงแคล, 0-6 = แสดงแคลวันนั้น + เน้นแท่ง)

  int? _selectedChartDayIndex;

  /// แท็บโภชนาการ: แมโครที่เลือกเน้น (0=โปรตีน, 1=คาร์บ, 2=ไขมัน), null=ไม่เน้น

  int? _selectedNutritionMacroIndex;

  /// แท็บโภชนาการ: วันที่เลือก (0–6) เพื่อแสดงค่ากินรายวัน; null = ไม่แสดงกล่อง

  int? _selectedNutritionDayIndex;

  List<dynamic> _weeklyData = [];
  List<Map<String, dynamic>> _calendarData = [];
  List<Map<String, dynamic>> _weightLogs = [];
  Map<String, dynamic> _goalProgress = {};

  bool _isLoading = true;

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
      _fetchWeightLogs(),
      _fetchGoalProgress(),
    ]);

    if (mounted) setState(() => _isLoading = false);
  }

  /// วันจันทร์ของสัปดาห์ที่เลือกสำหรับกราฟ

  DateTime _getChartWeekMonday() {
    final now = DateTime.now();

    final thisMonday = now.subtract(Duration(days: now.weekday - 1));

    return thisMonday.add(Duration(days: _chartWeekOffset * 7));
  }

  // ดึงข้อมูลกราฟ 7 วัน (รองรับ week_start ถ้า backend ส่งคืนตามช่วง)

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
        setState(() {
          _weeklyData = json.decode(response.body);
        });
      }
    } catch (e, st) {
      ErrorReporter.report('progress.fetch_weekly', e, st);
    }
  }

  // ดึงข้อมูลปฏิทิน

  Future<void> _fetchCalendarData() async {
    final userId = ref.read(userDataProvider).userId;

    if (userId == 0) return;

    // URL นี้ควร return list ของ { "date": "YYYY-MM-DD", "calories": 1500 }

    final url = Uri.parse(
        '${AppConstants.baseUrl}/daily_logs/$userId/calendar?month=${_currentMonth.month}&year=${_currentMonth.year}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          // ✅ แปลงข้อมูลและเก็บทั้ง date และ calories

          _calendarData = data
              .map((e) => {
                    'date': DateTime.parse(e['date']),

                    'calories':
                        e['calories'] ?? 0, // กันเหนียวถ้าไม่มี field นี้
                  })
              .toList();
        });
      }
    } catch (e, st) {
      ErrorReporter.report('progress.fetch_calendar', e, st);
    }
  }

  Future<void> _fetchWeightLogs() async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;
    try {
      final res = await http.get(
          Uri.parse('${AppConstants.baseUrl}/users/$userId/weight_logs'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        setState(() {
          _weightLogs =
              data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (e, st) {
      ErrorReporter.report('progress.fetch_weight_logs', e, st);
    }
  }

  Future<void> _fetchGoalProgress() async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;
    try {
      final res = await http.get(
          Uri.parse('${AppConstants.baseUrl}/users/$userId/goal_progress'));
      if (res.statusCode == 200) {
        setState(() {
          _goalProgress = Map<String, dynamic>.from(json.decode(res.body));
        });
      }
    } catch (e, st) {
      ErrorReporter.report('progress.fetch_goal', e, st);
    }
  }

  // แสดงรายละเอียดเมื่อกดวันที่ในปฏิทิน

  Future<void> _showDayDetails(DateTime date) async {
    final userId = ref.read(userDataProvider).userId;

    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final url = Uri.parse(
        '\${AppConstants.baseUrl}/daily_logs/$userId?date_query=$dateStr');

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

  // รองรับทั้ง data['meals'] (จาก API ใหม่) และ data['breakfast_menu'] (แบบเก่า)

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

  // ─── Bottom sheet เมื่อกดแท่งรายวันในกราฟภาพรวม ───
  Future<void> _showDayNutritionSheet(Map<String, dynamic> dayData) async {
    final userId = ref.read(userDataProvider).userId;
    final date   = dayData['date'] as DateTime;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // ข้อมูล macro จาก weekData (มีอยู่แล้ว)
    final double cal     = (dayData['calories'] as num?)?.toDouble() ?? 0;
    final double protein = (dayData['protein']  as num?)?.toDouble() ?? 0;
    final double carbs   = (dayData['carbs']    as num?)?.toDouble() ?? 0;
    final double fat     = (dayData['fat']      as num?)?.toDouble() ?? 0;

    // ดึงรายการอาหารแต่ละมื้อ
    List<Map<String, dynamic>> mealItems = [];
    try {
      for (final mealType in ['breakfast', 'lunch', 'dinner', 'snack']) {
        final res = await http.get(Uri.parse(
          '${AppConstants.baseUrl}/meals/$userId/detail?date_record=$dateStr&meal_type=$mealType',
        ));
        if (res.statusCode == 200) {
          final body = json.decode(res.body);
          final items = (body['items'] as List?) ?? [];
          if (items.isNotEmpty) {
            mealItems.add({'meal_type': mealType, 'items': items});
          }
        }
      }
    } catch (e, st) {
      ErrorReporter.report('progress.fetch_day_meal_items', e, st);
    }

    if (!mounted) return;

    const mealLabels = {
      'breakfast': '🌅 เช้า',
      'lunch':     '☀️ เที่ยง',
      'dinner':    '🌙 เย็น',
      'snack':     '🍎 ว่าง',
    };
    const green = Color(0xFF628141);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 10),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EFCF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dayData['dayName'] as String,
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: green, fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTh(date),
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Macro summary row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9EE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4E6B5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _macroSummaryItem('${cal.toInt()}', 'kcal', const Color(0xFF628141)),
                      _dividerV(),
                      _macroSummaryItem('${protein.toInt()}g', 'โปรตีน', const Color(0xFF4A7A20)),
                      _dividerV(),
                      _macroSummaryItem('${carbs.toInt()}g', 'คาร์บ', const Color(0xFFE8A020)),
                      _dividerV(),
                      _macroSummaryItem('${fat.toInt()}g', 'ไขมัน', const Color(0xFFD05030)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Divider(height: 1),

              // Meal list
              Expanded(
                child: mealItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.no_meals_rounded, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text('ไม่มีข้อมูลอาหาร', style: TextStyle(color: Colors.grey.shade400, fontFamily: 'Inter')),
                          ],
                        ),
                      )
                    : ListView(
                        controller: sc,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        children: mealItems.map((mealGroup) {
                          final mealType = mealGroup['meal_type'] as String;
                          final items    = mealGroup['items'] as List;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Meal type header
                              Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 8),
                                child: Text(
                                  mealLabels[mealType] ?? mealType,
                                  style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: green, fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              // Food items
                              ...items.map((item) {
                                final foodName = item['food_name'] ?? '-';
                                final totalCal = (item['total_cal'] as num?)?.toDouble() ?? 0;
                                final p = (item['total_protein'] as num?)?.toDouble() ?? 0;
                                final c = (item['total_carbs']   as num?)?.toDouble() ?? 0;
                                final f = (item['total_fat']     as num?)?.toDouble() ?? 0;
                                final imgUrl  = (item['image_url'] as String?) ?? '';
                                final amount  = (item['amount']   as num?)?.toDouble() ?? 1;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE8EFCF)),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0,2))
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // รูปอาหาร
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: imgUrl.isNotEmpty
                                            ? Image.network(
                                                imgUrl,
                                                width: 56, height: 56,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => _foodIconPlaceholder(),
                                              )
                                            : _foodIconPlaceholder(),
                                      ),
                                      const SizedBox(width: 12),
                                      // ชื่อ + macros
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              foodName,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'x${amount % 1 == 0 ? amount.toInt() : amount} หน่วย',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontFamily: 'Inter'),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                _miniMacroChip('P ${p.toInt()}g', const Color(0xFF4A7A20)),
                                                const SizedBox(width: 4),
                                                _miniMacroChip('C ${c.toInt()}g', const Color(0xFFD4920A)),
                                                const SizedBox(width: 4),
                                                _miniMacroChip('F ${f.toInt()}g', const Color(0xFFD05030)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // แคลอรี่
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${totalCal.toInt()}',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: green, fontFamily: 'Inter'),
                                          ),
                                          const Text('kcal', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Inter')),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroSummaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color, fontFamily: 'Inter')),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Inter')),
      ],
    );
  }

  Widget _dividerV() => Container(width: 1, height: 32, color: const Color(0xFFDDEECC));

  Widget _foodIconPlaceholder() => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
    child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 26),
  );

  Widget _miniMacroChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, fontFamily: 'Inter')),
  );

  void _buildDayDetailSheet(DateTime date, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('บันทึกวันที่ ${_formatDateTh(date)}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter')),
              const SizedBox(height: 15),
              _buildDetailRow('แคลอรี่รวม', '${data['calories']} kcal'),
              const Divider(),
              _buildDetailRow('โปรตีน', '${data['protein']} g'),
              _buildDetailRow('คาร์บ', '${data['carbs']} g'),
              _buildDetailRow('ไขมัน', '${data['fat']} g'),
              const SizedBox(height: 15),
              const Text("เมนูที่ทาน:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (_mealLabel(data, 'breakfast') != null)
                Text("เช้า: ${_mealLabel(data, 'breakfast')}"),
              if (_mealLabel(data, 'lunch') != null)
                Text("เที่ยง: ${_mealLabel(data, 'lunch')}"),
              if (_mealLabel(data, 'dinner') != null)
                Text("เย็น: ${_mealLabel(data, 'dinner')}"),
              if (_mealLabel(data, 'snack') != null)
                Text("ว่าง: ${_mealLabel(data, 'snack')}"),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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

  // --- Helper Functions for BMI & Streak ---

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

    // ดึงเฉพาะวันที่ที่มีแคลอรี่ > 0 มาคิด Streak

    List<DateTime> validDates = _calendarData
        .where((e) => (e['calories'] as num) > 0)
        .map((e) => e['date'] as DateTime)
        .toList();

    if (validDates.isEmpty) return 0;

    validDates.sort((a, b) => b.compareTo(a)); // เรียงจากใหม่ไปเก่า

    int streak = 0;

    DateTime checkDate =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // ถ้าวันนี้ยังไม่ได้บันทึก ให้เริ่มเช็คจากเมื่อวาน

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

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// สร้างข้อมูล 7 วัน (จ.–อา.) ของสัปดาห์ที่เลือก สำหรับกราฟแท่ง + โภชนาการ (มี protein, carbs, fat)

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

      double cal = 0;

      double protein = 0, carbs = 0, fat = 0;

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

                      const SizedBox(height: 20),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 13),
                        height: 42,
                        decoration: BoxDecoration(
                            color: const Color(0xFF628141),
                            borderRadius: BorderRadius.circular(50)),
                        child: Row(
                          children: [
                            _buildTabItem(0, 'ภาพรวม'),
                            _buildTabItem(1, 'ความสำเร็จ'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (_selectedTabIndex == 0) ...[
                        // --- แท็บภาพรวม: กราฟแคล + Quick Stats + BMI + ปฏิทิน ---

                        _buildWeeklyChartSection(targetCal, userData),

                        const SizedBox(height: 10),
                      ],

                      if (_selectedTabIndex == 0) ...[
                        // --- 2. BMI Card ---

                        _buildWhiteCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('BMI',
                                      style: TextStyle(
                                          fontSize: 12, fontFamily: 'Inter')),
                                  const SizedBox(width: 20),
                                  Text(bmi.toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
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

                                  double minBMI = 15;

                                  double maxBMI = 35;

                                  double normalizedBMI =
                                      (bmi - minBMI) / (maxBMI - minBMI);

                                  double position = normalizedBMI * width;

                                  if (position < 0) position = 0;

                                  if (position > width - 10)
                                    position = width - 10;

                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        height: 10,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF1710ED),
                                              Color(0xFF69AE6D),
                                              Color(0xFFD3D347),
                                              Color(0xFFCAAC58),
                                              Color(0xFFFF0000),
                                            ],
                                          ),
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
                                              border: Border.all(
                                                  color: Colors.black54,
                                                  width: 2),
                                              boxShadow: const [
                                                BoxShadow(
                                                    color: Colors.black26,
                                                    blurRadius: 2)
                                              ]),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              const Text('ค่า BMI ของคุณแสดงผลตามเกณฑ์มาตรฐาน',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.black87)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // --- 3. Calendar Card ---

                        _buildWhiteCard(
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
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 5),
                                  const Text('วัน',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: () {
                                      setState(() => _currentMonth = DateTime(
                                          _currentMonth.year,
                                          _currentMonth.month - 1));

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
                                      setState(() => _currentMonth = DateTime(
                                          _currentMonth.year,
                                          _currentMonth.month + 1));

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
                        ),

                        const SizedBox(height: 40),
                      ], // end if tab 0

                      if (_selectedTabIndex == 1) const SizedBox(height: 20),
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

  // --- Widgets ---

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
          Text('คาร์โบไฮเดรต ${c.toInt()}/${targetC.toInt()}',
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
          // ปุ่มเลื่อนสัปดาห์ (สัปดาห์ที่ X + ลูกศร)

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

                      _selectedNutritionMacroIndex = null;

                      _selectedNutritionDayIndex = null;

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

                            _selectedNutritionMacroIndex = null;

                            _selectedNutritionDayIndex = null;

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

          // การ์ดกราฟพื้นหลังขาว

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
                        const Text('ปริมาณแคลอรีรวมรายสัปดาห์',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF628141)))
                        : _WeeklyBarChart(
                            weekBarData: weekData,
                            targetCal: targetCal,
                            selectedBarIndex: _selectedChartDayIndex,
                            onBarTapped: (index) {
                              if (index == null) return;
                              setState(() {
                                _selectedChartDayIndex =
                                    _selectedChartDayIndex == index ? null : index;
                              });
                              if (weekData[index]['hasData'] == true) {
                                _showDayNutritionSheet(weekData[index]);
                              }
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
                        const Color(0xFF628141), 'แคลลอรีตรงตามเป้าหมาย'),
                    _chartLegendChipLight(const Color(0xFFD76A3C), 'แคลลอรีเกินเป้าหมาย'),
                    _chartLegendChipLight(
                        const Color(0xFF9E9E9E), 'ไม่ได้ใช้งาน'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _buildQuickStats(weekMonday, targetCal, userData),

          const SizedBox(height: 14),

          _buildGoalProgressCard(),

          const SizedBox(height: 14),

          _buildWeightChartCard(userData.targetWeight.toDouble()),
        ],
      ),
    );
  }

  /// Quick Stats: รวมสัปดาห์ (+ progress bar) และ วันที่ทานตามเป้า
  Widget _buildQuickStats(
      DateTime weekMonday, double targetCal, UserData userData) {
    final totalCal = _getWeekTotalCal(weekMonday);
    final daysMet  = _getWeekDaysMetGoal(weekMonday, targetCal);
    final weeklyTarget = targetCal * 7;
    final weekPct = weeklyTarget > 0
        ? (totalCal / weeklyTarget).clamp(0.0, 1.0)
        : 0.0;

    const orange = Color(0xFFE85D04);
    const green  = Color(0xFF628141);

    return Row(children: [
      // ── การ์ด 1: แคลฯ รวมสัปดาห์ + progress bar ──────────────────────
      Expanded(
        child: _statCardWithBar(
          icon: Icons.local_fire_department,
          iconBg: orange.withOpacity(0.15),
          iconColor: orange,
          value: _formatNumber(totalCal),
          unit: 'kcal',
          label: 'แคลฯ รวมสัปดาห์',
          subLabel: 'เป้า ${_formatNumber(weeklyTarget.toInt())} kcal',
          progress: weekPct,
          barColor: totalCal > weeklyTarget ? Colors.red : orange,
          pctText: '${(weekPct * 100).toInt()}%',
        ),
      ),
      const SizedBox(width: 10),
      // ── การ์ด 2: วันที่ทานตามเป้า ─────────────────────────────────────
      Expanded(
        child: _statCardWithBar(
          icon: Icons.gps_fixed,
          iconBg: green.withOpacity(0.15),
          iconColor: green,
          value: '$daysMet/7',
          unit: 'วัน',
          label: 'วันที่ทานตามเป้า',
          subLabel: 'ทานแคลฯ ≤ เป้าหมาย/วัน',
          progress: daysMet / 7,
          barColor: green,
          pctText: '${((daysMet / 7) * 100).toInt()}%',
        ),
      ),
    ]);
  }

  Widget _statCardWithBar({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String unit,
    required String label,
    required String subLabel,
    required double progress,
    required Color barColor,
    required String pctText,
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const Spacer(),
          Text(pctText,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: barColor)),
        ]),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                      fontFamily: 'Inter')),
              TextSpan(
                  text: '  $unit',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'Inter')),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Inter')),
        Text(subLabel,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontFamily: 'Inter')),
        const SizedBox(height: 10),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }

  // ── Goal Progress Card ────────────────────────────────────────────────────
  Widget _buildGoalProgressCard() {
    if (_goalProgress.isEmpty) return const SizedBox.shrink();

    final pct    = (_goalProgress['progress_pct'] as num?)?.toDouble() ?? 0.0;
    final curr   = (_goalProgress['current_weight'] as num?)?.toDouble() ?? 0.0;
    final target = (_goalProgress['target_weight'] as num?)?.toDouble() ?? 0.0;
    final start  = (_goalProgress['start_weight'] as num?)?.toDouble() ?? curr;
    final remKg  = (_goalProgress['remaining_kg'] as num?)?.toDouble() ?? 0.0;
    final goalType = _goalProgress['goal_type'] as String? ?? '';
    final estDays  = _goalProgress['estimated_days'] as int?;
    final targetDate = _goalProgress['goal_target_date'] as String?;

    // ชื่อเป้าหมาย
    String goalLabel;
    IconData goalIcon;
    Color goalColor;
    switch (goalType) {
      case 'lose_weight':
        goalLabel = 'ลดน้ำหนัก';
        goalIcon  = Icons.trending_down_rounded;
        goalColor = const Color(0xFFE85D04);
        break;
      case 'gain_weight':
      case 'gain_muscle':
        goalLabel = 'เพิ่มน้ำหนัก / กล้ามเนื้อ';
        goalIcon  = Icons.trending_up_rounded;
        goalColor = const Color(0xFF628141);
        break;
      default:
        goalLabel = 'รักษาน้ำหนัก';
        goalIcon  = Icons.balance_rounded;
        goalColor = const Color(0xFF3D5A27);
    }

    // วันที่เป้าหมาย
    String deadlineText = 'ไม่ได้กำหนด';
    if (targetDate != null) {
      try {
        final dt = DateTime.parse(targetDate);
        deadlineText = DateFormat('d MMM yyyy', 'th').format(dt);
        final daysLeft = dt.difference(DateTime.now()).inDays;
        if (daysLeft >= 0) deadlineText += ' (อีก $daysLeft วัน)';
      } catch (_) {}
    }

    // ประมาณการ
    String estimateText = '—';
    if (estDays != null && estDays > 0) {
      if (estDays < 30) {
        estimateText = 'อีก ~$estDays วัน';
      } else {
        final months = (estDays / 30).toStringAsFixed(1);
        estimateText = 'อีก ~$months เดือน';
      }
    }

    return _buildWhiteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: goalColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(goalIcon, size: 20, color: goalColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ความคืบหน้าเป้าหมาย',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              Text(goalLabel,
                  style: TextStyle(fontSize: 12, color: goalColor,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: goalColor,
                borderRadius: BorderRadius.circular(20)),
            child: Text('${pct.toStringAsFixed(1)}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 16),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(goalColor),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),

        // Weight row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _goalWeightChip('เริ่มต้น', '${start.toStringAsFixed(1)} กก.',
                Colors.grey.shade600),
            _goalWeightChip('ปัจจุบัน', '${curr.toStringAsFixed(1)} กก.',
                goalColor),
            _goalWeightChip('เป้าหมาย', '${target.toStringAsFixed(1)} กก.',
                const Color(0xFF3D5A27)),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Info grid
        Row(children: [
          Expanded(child: _infoChip(Icons.flag_rounded,
              'กำหนดเส้นตาย', deadlineText, const Color(0xFF465396))),
          const SizedBox(width: 8),
          Expanded(child: _infoChip(Icons.timer_outlined,
              'คาดการณ์', estimateText, const Color(0xFF628141))),
          const SizedBox(width: 8),
          Expanded(child: _infoChip(Icons.monitor_weight_outlined,
              'เหลืออีก', '${remKg.toStringAsFixed(1)} กก.',
              const Color(0xFFE85D04))),
        ]),
      ]),
    );
  }

  Widget _goalWeightChip(String label, String value, Color color) =>
      Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ]);

  Widget _infoChip(IconData icon, String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]),
      );

  // ── Weight Line Chart Card ────────────────────────────────────────────────
  Widget _buildWeightChartCard(double targetWeight) {
    if (_weightLogs.isEmpty) {
      return _buildWhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('กราฟน้ำหนัก',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Center(
              child: Column(children: [
                Icon(Icons.monitor_weight_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text('ยังไม่มีข้อมูลน้ำหนัก\nบันทึกน้ำหนักในโปรไฟล์เพื่อดูกราฟ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500)),
              ]),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    final spots = <FlSpot>[];
    double minW = double.infinity, maxW = 0;
    for (int i = 0; i < _weightLogs.length; i++) {
      final w = (_weightLogs[i]['weight'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), w));
      if (w < minW) minW = w;
      if (w > maxW) maxW = w;
    }
    minW = (minW - 2).floorToDouble();
    maxW = (maxW + 2).ceilToDouble();

    // Labels: show every N-th date
    final step = (_weightLogs.length / 5).ceil().clamp(1, 999);

    return _buildWhiteCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('กราฟน้ำหนัก',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: const Color(0xFFE8EFCF),
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.show_chart,
                  size: 14, color: Color(0xFF628141)),
              const SizedBox(width: 4),
              Text('${_weightLogs.length} จุด',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF3D5A27),
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: minW,
              maxY: maxW,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade200, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: step.toDouble(),
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= _weightLogs.length) return const SizedBox();
                      final raw = _weightLogs[idx]['date'] as String;
                      try {
                        final dt = DateTime.parse(raw);
                        return Text('${dt.day}/${dt.month}',
                            style: const TextStyle(
                                fontSize: 9, color: Colors.grey));
                      } catch (_) { return const SizedBox(); }
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                // Actual weight line
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF628141),
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (s, _, __, ___) =>
                        FlDotCirclePainter(
                            radius: 3,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF628141)),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF628141).withOpacity(0.08),
                  ),
                ),
                // Target weight dashed line
                if (targetWeight > minW && targetWeight < maxW)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, targetWeight),
                      FlSpot((spots.length - 1).toDouble(), targetWeight),
                    ],
                    isCurved: false,
                    color: Colors.red.shade300,
                    barWidth: 1.5,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          _chartLegendChipLight(const Color(0xFF628141), 'น้ำหนักจริง'),
          const SizedBox(width: 8),
          _chartLegendChipLight(Colors.red.shade300, 'เป้าหมาย'),
        ]),
      ]),
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

      // เขียว = ในเป้าหมาย, แดง = เกินเป้าหมาย, เทา = ไม่ได้กรอก/ไม่ได้ใช้งาน

      Color? circleColor;

      if (isLogged) {
        if (cal > targetCal) {
          circleColor = Colors.red; // แดง เกินเป้าหมาย
        } else {
          circleColor = const Color(0xFF628141); // เขียว ในเป้าหมาย
        }
      } else {
        circleColor = Colors.grey.shade400; // เทา ไม่ได้กรอก/ไม่ได้ใช้งาน
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
              border: isToday ? Border.all(color: Colors.black) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: isLogged || circleColor == Colors.grey.shade400
                    ? Colors.white
                    : Colors.black,
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
        _legendItem(const Color(0xFF628141), 'แคลลอรีตรงตามเป้าหมาย'),
        _legendItem(Colors.red, 'แคลลอรีเกินเป้าหมาย'),
        _legendItem(Colors.grey.shade400, 'ไม่ได้ใช้งาน'),
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

  /// เฉลี่ยแคลต่อวันของสัปดาห์ที่เลือก

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

  /// เปอร์เซ็นต์วันที่ควบคุมแคลได้ตรงเป้าของสัปดาห์ (จำนวนวันที่ไม่เกินเป้า / 7)

  int _getWeekOnTargetPercent(DateTime weekMonday, double targetCal) {
    final data = _getWeekBarData(weekMonday);

    int onTarget = 0;

    for (final d in data) {
      if (d['hasData'] == true &&
          (d['calories'] as num).toDouble() > 0 &&
          (d['calories'] as num).toDouble() <= targetCal) onTarget++;
    }

    return ((onTarget / 7) * 100).round();
  }

  /// รวมแคลทั้งสัปดาห์ (kcal)

  int _getWeekTotalCal(DateTime weekMonday) {
    final data = _getWeekBarData(weekMonday);

    int sum = 0;

    for (final d in data) {
      if (d['hasData'] == true) sum += (d['calories'] as num).toInt();
    }

    return sum;
  }

  /// จำนวนวันที่ผ่านเป้า (ไม่เกินเป้า) ของสัปดาห์

  int _getWeekDaysMetGoal(DateTime weekMonday, double targetCal) {
    final data = _getWeekBarData(weekMonday);

    int count = 0;

    for (final d in data) {
      if (d['hasData'] == true &&
          (d['calories'] as num).toDouble() > 0 &&
          (d['calories'] as num).toDouble() <= targetCal) count++;
    }

    return count;
  }

  /// หมายเลขสัปดาห์ของปี (1–53) สำหรับแสดง "สัปดาห์ที่ X"

  int _getWeekNumber(DateTime weekMonday) {
    final startOfYear = DateTime(weekMonday.year, 1, 1);

    final days = weekMonday.difference(startOfYear).inDays;

    return (days / 7).floor() + 1;
  }

  /// ช่วงวันที่ (จ.–อา.) สำหรับแสดงใน pill

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

  Widget _buildTopCard(
      {required String title,
      required String value,
      required String unit,
      required IconData icon,
      required Color iconColor}) {
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
}

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

            final groupIndex = response.spot!.touchedBarGroupIndex;

            onBarTapped!(groupIndex);
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
                  text,
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12));
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
                          Text(
                            calText,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                fontFamily: 'Inter'),
                          ),
                        if (showValueForSelected && isSelected)
                          const SizedBox(height: 2),
                        Text(
                          _getDayName(date.weekday),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color:
                                isSelected ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
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

          double calories = (d['calories'] as num?)?.toDouble() ?? 0;

          double toY = hasData ? calories : (targetCal * 0.06);

          Color color = _gray;

          if (hasData) {
            if (calories > targetCal) {
              color = _red; // เกินเป้าหมาย
            } else {
              color = _green; // ในเป้าหมาย
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

/// กราฟรวม 3 แมโคร (โปรตีน/คาร์บ/ไขมัน) 7 วัน แท่งกลุ่ม + เส้นเป้า + แตะเน้น

class _CombinedMacroChart extends StatelessWidget {
  final List<Map<String, dynamic>> weekData;

  final double targetProtein;

  final double targetCarbs;

  final double targetFat;

  final int? selectedMacroIndex;

  /// (dayIndex 0-6, macroIndex 0-2)

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
                  text,
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11));
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
