import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '/providers/user_data_provider.dart'; // ปรับ Path ให้ตรงกับโครงสร้างของคุณ

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _selectedTabIndex = 0;
  DateTime _currentMonth = DateTime.now();
  
  List<dynamic> _weeklyData = [];
  // ✅ เปลี่ยนจาก List<DateTime> เป็น List<Map> เพื่อเก็บทั้ง date และ calories
  List<Map<String, dynamic>> _calendarData = []; 
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
    await Future.wait([
      _fetchWeeklyData(),
      _fetchCalendarData(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  // ดึงข้อมูลกราฟ 7 วัน
  Future<void> _fetchWeeklyData() async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;
    // ⚠️ แก้ IP ให้ตรง (10.0.2.2 หรือ localhost)
    final url = Uri.parse('http://10.0.2.2:8000/daily_logs/$userId/weekly');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _weeklyData = json.decode(response.body);
        });
      }
    } catch (e) {
      print("Error fetching weekly: $e");
    }
  }

  // ดึงข้อมูลปฏิทิน
  Future<void> _fetchCalendarData() async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;
    // URL นี้ควร return list ของ { "date": "YYYY-MM-DD", "calories": 1500 }
    final url = Uri.parse(
        'http://10.0.2.2:8000/daily_logs/$userId/calendar?month=${_currentMonth.month}&year=${_currentMonth.year}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          // ✅ แปลงข้อมูลและเก็บทั้ง date และ calories
          _calendarData = data.map((e) => {
            'date': DateTime.parse(e['date']),
            'calories': e['calories'] ?? 0, // กันเหนียวถ้าไม่มี field นี้
          }).toList();
        });
      }
    } catch (e) {
      print("Error fetching calendar: $e");
    }
  }

  // แสดงรายละเอียดเมื่อกดวันที่ในปฏิทิน
  Future<void> _showDayDetails(DateTime date) async {
    final userId = ref.read(userDataProvider).userId;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final url = Uri.parse('http://10.0.2.2:8000/daily_logs/$userId?date_query=$dateStr');
    
    showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator()));

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

  void _buildDayDetailSheet(DateTime date, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('บันทึกวันที่ ${_formatDateTh(date)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
              const SizedBox(height: 15),
              _buildDetailRow('แคลอรี่รวม', '${data['calories']} kcal'),
              const Divider(),
              _buildDetailRow('โปรตีน', '${data['protein']} g'),
              _buildDetailRow('คาร์บ', '${data['carbs']} g'),
              _buildDetailRow('ไขมัน', '${data['fat']} g'),
              const SizedBox(height: 15),
              const Text("เมนูที่ทาน:", style: TextStyle(fontWeight: FontWeight.bold)),
              if (data['breakfast_menu'] != null && data['breakfast_menu'] != "") Text("เช้า: ${data['breakfast_menu']}"),
              if (data['lunch_menu'] != null && data['lunch_menu'] != "") Text("เที่ยง: ${data['lunch_menu']}"),
              if (data['dinner_menu'] != null && data['dinner_menu'] != "") Text("เย็น: ${data['dinner_menu']}"),
              if (data['snack_menu'] != null && data['snack_menu'] != "") Text("ว่าง: ${data['snack_menu']}"),
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
          Text(value, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // --- Helper Functions for BMI & Streak ---
  double _calculateBMI(double weight, double height) {
    if (height <= 0) return 0;
    double h = height / 100;
    return weight / (h * h);
  }

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
    DateTime checkDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
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

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    double bmi = _calculateBMI(userData.weight, userData.height);
    String bmiStatus = _getBMIStatus(bmi);
    Color bmiColor = _getBMIColor(bmi);
    int streak = _calculateStreak();
    double targetCal = userData.targetCalories.toDouble();
    if (targetCal <= 0) targetCal = 2000;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(top: 100, left: 0, right: 0, bottom: 0, child: Container(color: const Color(0xFFAFD198))),
          Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(top: 50, bottom: 15, left: 20, right: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
                      ),
                    ),
                    const Expanded(child: Text('ความคืบหน้า', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w400, color: Colors.black))),
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
                            _buildTopCard(title: 'น้ำหนักปัจจุบัน', value: '${userData.weight.toInt()}', unit: 'กิโลกรัม', icon: Icons.person, iconColor: const Color(0xFF91E47E)),
                            _buildTopCard(title: 'น้ำหนักเป้าหมาย', value: '${userData.targetWeight.toInt()}', unit: 'กิโลกรัม', icon: Icons.flag, iconColor: const Color(0xFF465396)),
                            _buildTopCard(title: 'ความต่อเนื่อง', value: '$streak', unit: 'วัน', icon: Icons.local_fire_department, iconColor: const Color(0xFFE4A47E)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 13),
                        height: 42,
                        decoration: BoxDecoration(color: const Color(0xFF628141), borderRadius: BorderRadius.circular(50)),
                        child: Row(
                          children: [
                            _buildTabItem(0, 'ภาพรวม'),
                            _buildTabItem(1, 'โภชนาการ'),
                            _buildTabItem(2, 'ความสำเร็จ'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- 1. กราฟรายสัปดาห์ ---
                      _buildWhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('แคลอรี่รายสัปดาห์', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('เป้าหมาย: ${targetCal.toInt()}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _WeeklyBarChart(
                              weeklyData: _weeklyData,
                              targetCal: targetCal,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // --- 2. BMI Card ---
                      _buildWhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('BMI', style: TextStyle(fontSize: 12, fontFamily: 'Inter')),
                                const SizedBox(width: 20),
                                Text(bmi.toStringAsFixed(1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: bmiColor.withOpacity(0.2), borderRadius: BorderRadius.circular(5)),
                                  child: Text(bmiStatus, style: TextStyle(fontSize: 10, color: bmiColor, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            
                            LayoutBuilder(
                              builder: (context, constraints) {
                                double width = constraints.maxWidth;
                                double minBMI = 15;
                                double maxBMI = 35;
                                double normalizedBMI = (bmi - minBMI) / (maxBMI - minBMI);
                                double position = normalizedBMI * width;
                                if (position < 0) position = 0;
                                if (position > width - 10) position = width - 10;

                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF1710ED), Color(0xFF69AE6D), Color(0xFFD3D347), Color(0xFFCAAC58), Color(0xFFFF0000),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: position,
                                      top: -2,
                                      child: Container(
                                        width: 14, height: 14,
                                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black54, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)]),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            const Text('ค่า BMI ของคุณแสดงผลตามเกณฑ์มาตรฐาน', style: TextStyle(fontSize: 10, color: Colors.black87)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // --- 3. Calendar Card ---
                      _buildWhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('สถิติบันทึกต่อเนื่อง', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department, color: Colors.red, size: 24),
                                const SizedBox(width: 5),
                                Text('$streak', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                                    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));
                                    _fetchCalendarData();
                                  },
                                ),
                                Text(_formatMonthYear(_currentMonth), style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: () {
                                    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));
                                    _fetchCalendarData();
                                  },
                                ),
                              ],
                            ),
                            _buildRealCalendar(_currentMonth),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
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
  Widget _buildRealCalendar(DateTime month) {
    int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    int firstWeekday = DateTime(month.year, month.month, 1).weekday;
    List<Widget> dayHeaders = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา']
        .map((day) => Center(child: Text(day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList();
    List<Widget> dayCells = [];
    
    for (int i = 1; i < firstWeekday; i++) {
      dayCells.add(Container());
    }
    
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime date = DateTime(month.year, month.month, day);
      
      // ✅ Logic ใหม่: หาข้อมูลของวันนั้นๆ เพื่อเช็ค Calories
      Map<String, dynamic>? logData = _calendarData.firstWhere(
        (data) => isSameDay(data['date'], date),
        orElse: () => {},
      );

      bool isLogged = logData.isNotEmpty; // มี record ใน DB ไหม
      double cal = isLogged ? (logData['calories'] as num).toDouble() : 0.0;
      bool isToday = isSameDay(date, DateTime.now());

      // ✅ เงื่อนไขสี: เขียวถ้าแคล > 0, แดงถ้าแคล = 0 (และมี record)
      Color? circleColor;
      if (isLogged) {
        if (cal > 0) {
          circleColor = const Color(0xFF628141); // เขียว
        } else {
          circleColor = Colors.red; // แดง
        }
      } else if (isToday) {
        circleColor = Colors.grey.shade300;
      } else {
        circleColor = Colors.transparent;
      }

      dayCells.add(GestureDetector(
        onTap: isLogged ? () => _showDayDetails(date) : null,
        child: Center(
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: isToday ? Border.all(color: Colors.black) : null,
            ),
            alignment: Alignment.center,
            child: Text('$day', style: TextStyle(
              color: isLogged ? Colors.white : Colors.black, 
              fontWeight: isLogged || isToday ? FontWeight.bold : FontWeight.normal, 
              fontSize: 12
            )),
          ),
        ),
      ));
    }
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: dayHeaders.map((w) => Expanded(child: w)).toList()),
        const SizedBox(height: 10),
        GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: dayCells),
      ],
    );
  }

  String _formatDateTh(DateTime date) => '${date.day}/${date.month}/${date.year + 543}';
  
  String _formatMonthYear(DateTime date) {
    List<String> months = ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'];
    return '${months[date.month - 1]} ${date.year + 543}';
  }

  Widget _buildTopCard({required String title, required String value, required String unit, required IconData icon, required Color iconColor}) {
    return Container(
      width: 110, height: 169,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 24)),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 12, height: 1.2, fontFamily: 'Inter')),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: child,
    );
  }

  Widget _buildTabItem(int index, String title) {
    bool isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(50)),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black : Colors.white)),
        ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<dynamic> weeklyData;
  final double targetCal;

  const _WeeklyBarChart({
    required this.weeklyData,
    required this.targetCal,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("ยังไม่มีข้อมูลสัปดาห์นี้", style: TextStyle(color: Colors.grey))),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: targetCal * 1.5,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black87, 
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} kcal',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                    DateTime date = DateTime.parse(weeklyData[value.toInt()]['date']);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _getDayName(date.weekday),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
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
                color: Colors.orange.withOpacity(0.5),
                strokeWidth: 2,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (line) => 'เป้าหมาย',
                  style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          barGroups: weeklyData.asMap().entries.map((entry) {
            int index = entry.key;
            double calories = (entry.value['calories'] as num).toDouble();
            bool isOverTarget = calories > targetCal;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: calories,
                  color: isOverTarget ? const Color(0xFFD76A3C) : const Color(0xFF628141),
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: targetCal * 1.5,
                    color: const Color(0xFFF0F0F0),
                  ),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    return days[weekday - 1];
  }
}