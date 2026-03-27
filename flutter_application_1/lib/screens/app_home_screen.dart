import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/constants/constants.dart';
import '../../providers/user_data_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/notification_helper.dart';

// ─────────────────────────────────────────────
//  HomeScreen — หน้าหลักของ Calorie Guard
// ─────────────────────────────────────────────
class AppHomeScreen extends ConsumerStatefulWidget {
  const AppHomeScreen({super.key});

  @override
  ConsumerState<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends ConsumerState<AppHomeScreen>
    with TickerProviderStateMixin {
  // ── Color Palette ──
  static const _green = Color(0xFF628141);
  static const _greenL = Color(0xFFE8EFCF);
  static const _greenM = Color(0xFFAFD198);
  static const _orange = Color(0xFFD76A3C);
  static const _orangeL = Color(0xFFFFF3E0);
  static const _blue = Color(0xFF1565C0);
  static const _bg = Color(0xFFF2F7F4);

  // ── State ──
  bool _isLoading = true;
  bool _hasWarnedCalories = false;
  late DateTime _viewDate;
  int _waterGlasses = 0;
  static const int _waterGoal = 8;

  @override
  void initState() {
    super.initState();
    _viewDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncViewDateFromProvider();
      _fetchAllData();
    });
  }

  void _syncViewDateFromProvider() {
    final fromProvider = ref.read(homeViewDateProvider);
    if (fromProvider != null) {
      ref.read(homeViewDateProvider.notifier).state = null;
      setState(() => _viewDate = DateTime(fromProvider.year, fromProvider.month, fromProvider.day));
    }
  }

  Future<void> _fetchAllData() async {
    await _fetchUserData();
    await _fetchDailyData(_viewDate);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchUserData() async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;

    try {
      final url = Uri.parse('${AppConstants.baseUrl}/users/$userId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        ref.read(userDataProvider.notifier).setUserFromApi(data);
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
    }
  }

  Future<void> _fetchDailyData(DateTime forDate) async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;

    final dateStr = "${forDate.year}-${forDate.month.toString().padLeft(2, '0')}-${forDate.day.toString().padLeft(2, '0')}";
    final url = Uri.parse('${AppConstants.baseUrl}/daily_summary/$userId?date_record=$dateStr');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final summaryData = json.decode(utf8.decode(response.bodyBytes));
        Map<String, String> mealsMap = {};
        if (summaryData['meals'] != null) {
          mealsMap = Map<String, String>.from(summaryData['meals']);
        }

        ref.read(userDataProvider.notifier).updateDailyFood(
          cal: (summaryData['total_calories_intake'] as num?)?.toInt() ?? 0,
          protein: (summaryData['total_protein'] as num?)?.toInt() ?? 0,
          carbs: (summaryData['total_carbs'] as num?)?.toInt() ?? 0,
          fat: (summaryData['total_fat'] as num?)?.toInt() ?? 0,
          dailyMeals: mealsMap,
        );
      }
    } catch (e) {
      print("Error fetching daily summary: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);

    ref.listen<DateTime?>(homeViewDateProvider, (prev, next) {
      if (next != null && mounted) {
        ref.read(homeViewDateProvider.notifier).state = null;
        setState(() => _viewDate = DateTime(next.year, next.month, next.day));
        _fetchDailyData(_viewDate).then((_) {
          if (mounted) setState(() {});
        });
      }
    });

    final targetCal = userData.targetCalories.toInt() > 0 ? userData.targetCalories.toInt() : 1500;
    final currentCal = userData.consumedCalories;
    final burnedCal = 0;
    final netCal = currentCal - burnedCal;
    final remainingCal = targetCal - netCal;
    final calPct = (netCal / targetCal).clamp(0.0, 1.0);
    final burnPct = (burnedCal / targetCal).clamp(0.0, 1.0);
    final isOver = netCal > targetCal;

    final targetP = userData.targetProtein;
    final targetC = userData.targetCarbs;
    final targetF = userData.targetFat;
    final currentP = userData.consumedProtein;
    final currentC = userData.consumedCarbs;
    final currentF = userData.consumedFat;

    final currentWeight = userData.weight;
    final targetWeight = userData.targetWeight;
    final startWeight = currentWeight + 5;
    final weightLost = startWeight - currentWeight;
    final weightRemaining = currentWeight - targetWeight;
    final weightProgress = ((startWeight - currentWeight) / (startWeight - targetWeight)).clamp(0.0, 1.0);

    if (isOver && !_hasWarnedCalories) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('⚠️ แจ้งเตือน: แคลอรี่เกินเป้าหมายแล้ว!'),
            backgroundColor: Colors.redAccent));
        NotificationHelper.showCalorieAlert(currentCal, targetCal);
        setState(() => _hasWarnedCalories = true);
      });
    }

    return Scaffold(
      backgroundColor: _bg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : Column(
              children: [
                _buildTopBar(userData),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _fetchAllData();
                    },
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildDateStrip(userData),
                          _buildCalorieCard(targetCal, currentCal, burnedCal, netCal, remainingCal, calPct, burnPct, isOver, currentP, targetP, currentC, targetC, currentF, targetF),
                          _buildMealSummarySection(userData),
                          _buildWaterTracker(),
                          _buildProgressCard(currentWeight, startWeight, targetWeight, weightLost, weightRemaining, weightProgress),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────
  //  TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar(UserData userData) {
    final userName = userData.name.isNotEmpty ? userData.name : 'ผู้ใช้';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 52, bottom: 14, left: 16, right: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_greenM, _green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              userName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สวัสดี คุณ$userName 👋',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                const Text(
                  'มาดูแลสุขภาพวันนี้กัน!',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _greenL,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('🔔', style: TextStyle(fontSize: 18)),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
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
  //  DATE STRIP + PROGRAM BADGE
  // ─────────────────────────────────────────────
  Widget _buildDateStrip(UserData userData) {
    final thMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    final dateStr = '${_viewDate.day} ${thMonths[_viewDate.month - 1]} ${_viewDate.year + 543}';
    
    String programName = 'ลดน้ำหนัก';
    if (userData.goal == GoalOption.maintainWeight) programName = 'รักษาน้ำหนัก';
    if (userData.goal == GoalOption.buildMuscle) programName = 'เพิ่มกล้ามเนื้อ';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _greenL,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              dateStr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _green,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_green, Color(0xFF4a6b2a)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🎯 $programName',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _orangeL,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🔥 0 วัน',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CALORIE RING CARD
  // ─────────────────────────────────────────────
  Widget _buildCalorieCard(int targetCal, int currentCal, int burnedCal, int netCal, int remainingCal, double calPct, double burnPct, bool isOver, int currentP, int targetP, int currentC, int targetC, int currentF, int targetF) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CircularProgressIndicator(
                        value: calPct,
                        strokeWidth: 10,
                        backgroundColor: _greenL,
                        valueColor: AlwaysStoppedAnimation<Color>(isOver ? _orange : _green),
                      ),
                    ),
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: CircularProgressIndicator(
                        value: burnPct,
                        strokeWidth: 7,
                        backgroundColor: _orangeL,
                        valueColor: const AlwaysStoppedAnimation<Color>(_orange),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$netCal',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            height: 1,
                          ),
                        ),
                        const Text(
                          'kcal',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          remainingCal > 0 ? 'เหลือ ${remainingCal}' : 'เกิน ${(-remainingCal)}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: remainingCal > 0 ? _green : _orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _calStatRow('🎯 เป้าหมาย', '$targetCal kcal', Colors.black87),
                    _calStatRow('🍽️ กินแล้ว', '$currentCal kcal', _green),
                    _calStatRow('🏃 เผาผลาญ', '$burnedCal kcal', _orange),
                    const Divider(height: 12),
                    _calStatRow(
                      isOver ? '⚠️ เกินเป้า' : '✅ เหลืออีก',
                      '${remainingCal.abs()} kcal',
                      isOver ? _orange : _blue,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _macroBar('โปรตีน', currentP.toDouble(), targetP.toDouble(), _green),
              const SizedBox(width: 8),
              _macroBar('คาร์บ', currentC.toDouble(), targetC.toDouble(), const Color(0xFFFFB800)),
              const SizedBox(width: 8),
              _macroBar('ไขมัน', currentF.toDouble(), targetF.toDouble(), _orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calStatRow(String label, String val, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const Spacer(),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroBar(String label, double val, double target, Color color) {
    final pct = target > 0 ? (val / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              Text('${val.toInt()}g',
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter')),
            ],
          ),
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
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  MEAL SUMMARY SECTION
  // ─────────────────────────────────────────────
  Widget _buildMealSummarySection(UserData userData) {
    final meals = [
      {'id': 'breakfast', 'name': 'มื้อเช้า', 'emoji': '🌅', 'time': '06:00–10:00'},
      {'id': 'lunch', 'name': 'มื้อกลางวัน', 'emoji': '☀️', 'time': '11:00–14:00'},
      {'id': 'dinner', 'name': 'มื้อเย็น', 'emoji': '🌙', 'time': '17:00–21:00'},
      {'id': 'snack', 'name': 'ของว่าง', 'emoji': '🍎', 'time': 'ตลอดวัน'},
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              const Text(
                'บันทึกมื้ออาหาร',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
              ),
              const Spacer(),
              Text(
                'ดูทั้งหมด ›',
                style: TextStyle(fontSize: 13, color: _green, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: meals.map((meal) => _buildMealTile(meal, userData)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMealTile(Map<String, dynamic> meal, UserData userData) {
    final mealData = userData.dailyMeals[meal['id']] ?? '';
    final hasFood = mealData.isNotEmpty && mealData != '-';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _greenL,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(meal['emoji'], style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['name'],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      meal['time'],
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasFood) ...[
            Text(
              mealData,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: _greenL, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, size: 12, color: _green),
                ),
                const SizedBox(width: 6),
                const Text(
                  'เพิ่มอาหาร',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _green),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  WATER TRACKER
  // ─────────────────────────────────────────────
  Widget _buildWaterTracker() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ดื่มน้ำวันนี้',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    '$_waterGlasses/$_waterGoal แก้ว (${_waterGlasses * 250} ml)',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '$_waterGlasses',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
              const Text(
                ' แก้ว',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              _waterGoal,
              (i) => Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 26,
                  decoration: BoxDecoration(
                    color: i < _waterGlasses
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    i < _waterGlasses ? '💧' : '○',
                    style: TextStyle(
                      fontSize: i < _waterGlasses ? 12 : 11,
                      color: Colors.white70,
                    ),
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
  //  PROGRESS CARD
  // ─────────────────────────────────────────────
  Widget _buildProgressCard(double currentWeight, double startWeight, double targetWeight, double weightLost, double weightRemaining, double weightProgress) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _greenL,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('📈', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ความคืบหน้า',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter'),
                  ),
                  Text(
                    'เป้าหมาย: ${targetWeight.toInt()} kg ภายใน 3 เดือน',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _progressStat('${currentWeight.toStringAsFixed(1)}', 'น้ำหนักปัจจุบัน kg', Colors.black87),
              const SizedBox(width: 10),
              _progressStat('-${weightLost.toStringAsFixed(1)}', 'ลดไปแล้ว kg', _green),
              const SizedBox(width: 10),
              _progressStat('${weightRemaining.toStringAsFixed(1)}', 'เหลืออีก kg', _orange),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${startWeight.toInt()} kg → ${targetWeight.toInt()} kg',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                '${(weightProgress * 100).toInt()}% สำเร็จ',
                style: const TextStyle(
                    fontSize: 11, color: _green, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: weightProgress,
              minHeight: 9,
              backgroundColor: _greenL,
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressStat(String value, String label, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: valueColor,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
