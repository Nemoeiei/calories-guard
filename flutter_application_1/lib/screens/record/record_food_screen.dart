import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/user_data_provider.dart';

class FoodLoggingScreen extends ConsumerStatefulWidget {
  const FoodLoggingScreen({super.key});

  @override
  ConsumerState<FoodLoggingScreen> createState() => _FoodLoggingScreenState();
}

/// ตัวเลือกช่วงเวลาที่ทาน (แสดงใน dropdown)
final List<Map<String, String>> _mealTimeOptions = [
  {'label': '05.00-11.00 น.', 'mealType': 'meal_1'},
  {'label': '11.00-17.00 น.', 'mealType': 'meal_2'},
  {'label': '17.00-23.00 น.', 'mealType': 'meal_3'},
  {'label': '23.00-05.00 น.', 'mealType': 'meal_4'},
];

class _FoodLoggingScreenState extends ConsumerState<FoodLoggingScreen> {
  // ข้อมูลมื้ออาหาร: selectedMealIndex, items, saved (หลังบันทึกแล้วแสดง "แก้ไข" แทน "บันทึก")
  final List<Map<String, dynamic>> _meals = [
    {
      'selectedMealIndex': null,
      'items': [''],
      'saved': false
    }
  ];

  bool _isSaving = false;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _foodDatabase = [];

  final Map<String, String> _activityMap = {
    'ไม่ออกกำลังกายเลย': 'sedentary',
    'ออกกำลังกายเบาๆ (1-3 ครั้ง/สัปดาห์)': 'lightly_active',
    'ออกกำลังกายปานกลาง (3-5 ครั้ง/สัปดาห์)': 'moderately_active',
    'ออกกำลังกายหนัก (6-7 ครั้ง/สัปดาห์)': 'very_active',
  };
  String _selectedActivityLabel = 'ไม่ออกกำลังกายเลย';

  @override
  void initState() {
    super.initState();
    _fetchFoodsFromApi();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadDayData(_selectedDate));
  }

  /// โหลดข้อมูลมื้ออาหารของวันที่เลือกจาก API (ถ้ามี) แล้วใส่ในฟอร์ม
  Future<void> _loadDayData(DateTime forDate) async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(forDate);
    try {
      final url = Uri.parse(
          'https://unshirred-wendolyn-audiometrically.ngrok-free.dev/daily_summary/$userId?date_record=$dateStr');
      final res = await http.get(url);
      if (!mounted || res.statusCode != 200) return;
      final data =
          json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final meals = data['meals'];
      if (meals == null || meals is! Map) {
        _meals.clear();
        _meals.add({
          'selectedMealIndex': null,
          'items': [''],
          'saved': false
        });
        if (mounted) setState(() {});
        return;
      }
      final map = Map<String, String>.from(Map<String, dynamic>.from(meals));
      const order = ['breakfast', 'lunch', 'dinner', 'snack'];
      _meals.clear();
      for (int i = 0; i < order.length; i++) {
        final value = map[order[i]]?.toString().trim() ?? '';
        if (value.isEmpty) continue;
        final items = value
            .split(RegExp(r',\s*'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (items.isEmpty) continue;
        items.add('');
        _meals.add({
          'selectedMealIndex': i,
          'items': items,
          'saved': true,
        });
      }
      if (_meals.isEmpty) {
        _meals.add({
          'selectedMealIndex': null,
          'items': [''],
          'saved': false
        });
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        _meals.clear();
        _meals.add({
          'selectedMealIndex': null,
          'items': [''],
          'saved': false
        });
        setState(() {});
      }
    }
  }

  double _safeParse(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Future<void> _fetchFoodsFromApi() async {
    try {
      final res = await http.get(Uri.parse(
          'https://unshirred-wendolyn-audiometrically.ngrok-free.dev/foods'));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _foodDatabase = json.decode(utf8.decode(res.bodyBytes));
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ ฟังก์ชันส่งคำขอเมนูใหม่ (จำลอง)
  Future<void> _sendFoodRequest(String name) async {
    setState(() {
      _foodDatabase.add({
        "food_name": name,
        "calories": 0,
        "protein": 0,
        "carbs": 0,
        "fat": 0,
        "food_id": 9999
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ส่งคำขอเพิ่มเมนูเรียบร้อยแล้ว!'),
        backgroundColor: Colors.green));
  }

  // ✅ บันทึกหนึ่งมื้อลง Backend (ส่ง items ทั้งมื้อครั้งเดียว)
  Future<void> _saveMealToBackend(
      String mealType, List<String> menuNames) async {
    if (menuNames.isEmpty) return;

    final userId = ref.read(userDataProvider).userId;
    final List<Map<String, dynamic>> itemsPayload = [];

    for (final menuName in menuNames) {
      final name = menuName.toString().trim();
      if (name.isEmpty) continue;
      Map<String, dynamic>? food;
      for (final f in _foodDatabase) {
        final m = f as Map<String, dynamic>?;
        if (m != null &&
            m['food_name'].toString().toLowerCase() == name.toLowerCase()) {
          food = m;
          break;
        }
      }
      if (food == null) continue;
      itemsPayload.add({
        "food_id": food['food_id'] ?? 0,
        "amount": 1.0,
        "food_name": food['food_name'],
        "cal_per_unit": _safeParse(food['calories']),
        "protein_per_unit": _safeParse(food['protein']),
        "carbs_per_unit": _safeParse(food['carbs']),
        "fat_per_unit": _safeParse(food['fat']),
      });
    }

    if (itemsPayload.isEmpty) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final url = Uri.parse(
        'https://unshirred-wendolyn-audiometrically.ngrok-free.dev/meals/$userId');
    final body = jsonEncode({
      "date": dateStr,
      "meal_type": mealType,
      "items": itemsPayload,
    });

    try {
      await http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);
    } catch (e) {
      print("Error saving $mealType: $e");
    }
  }

  // --- UI Logic ---
  void _addNextMeal() {
    setState(() {
      _meals.add({
        'selectedMealIndex': null,
        'items': [''],
        'saved': false
      });
    });
  }

  /// บันทึกเฉพาะการ์ดนี้ (เคลียร์ meal_type นี้ของวันนั้น แล้ว POST ใหม่ แล้วเซ็ต saved = true)
  Future<void> _saveSingleCard(int mealIndex) async {
    if (_isSaving) return;
    final items = List<String>.from(_meals[mealIndex]['items']);
    final selectedIndex = _meals[mealIndex]['selectedMealIndex'] as int?;
    if (selectedIndex == null ||
        selectedIndex < 0 ||
        selectedIndex >= _mealTimeOptions.length) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('กรุณาเลือกช่วงเวลาที่ทาน'),
            backgroundColor: Colors.orange));
      return;
    }
    final foodNames = items.where((s) => s.trim().isNotEmpty).toList();
    setState(() => _isSaving = true);
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) {
      setState(() => _isSaving = false);
      return;
    }
    final mealType = _mealTimeOptions[selectedIndex]['mealType']!;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final base = Uri.parse(
          'https://unshirred-wendolyn-audiometrically.ngrok-free.dev/meals/clear/$userId');
      await http.delete(base.replace(
          queryParameters: {'date_record': dateStr, 'meal_type': mealType}));
      if (foodNames.isNotEmpty) await _saveMealToBackend(mealType, foodNames);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _meals[mealIndex]['saved'] = true;
          if (foodNames.isEmpty) {
            final list = _meals[mealIndex]['items'] as List;
            list.clear();
            list.add('');
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('บันทึกมื้อนี้เรียบร้อย'),
            backgroundColor: Colors.green));
        await _refreshHomeDailyData(_selectedDate);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// ดึง daily_summary ของวันที่เลือกแล้วอัปเดต provider + ตั้งวันให้หน้า Home แสดง
  Future<void> _refreshHomeDailyData(DateTime forDate) async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(forDate);
    try {
      final url = Uri.parse(
          'https://unshirred-wendolyn-audiometrically.ngrok-free.dev/daily_summary/$userId?date_record=$dateStr');
      final response = await http.get(url);
      if (response.statusCode == 200 && mounted) {
        final summaryData =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        Map<String, String> mealsMap = {};
        if (summaryData['meals'] != null) {
          mealsMap = Map<String, String>.from(summaryData['meals'] as Map);
        }
        ref.read(userDataProvider.notifier).updateDailyFood(
              cal: (summaryData['total_calories_intake'] as num?)?.toInt() ?? 0,
              protein: (summaryData['total_protein'] as num?)?.toInt() ?? 0,
              carbs: (summaryData['total_carbs'] as num?)?.toInt() ?? 0,
              fat: (summaryData['total_fat'] as num?)?.toInt() ?? 0,
              dailyMeals: mealsMap,
            );
        ref.read(homeViewDateProvider.notifier).state = forDate;
      }
    } catch (_) {}
  }

  /// ทำให้แต่ละมื้อมีช่องว่างสำหรับกรอกอาหารเพียง 1 ช่องเสมอ (รายการที่กรอกแล้ว + ช่องว่างเดียว)
  void _normalizeMealItems(int mealIndex) {
    final list = _meals[mealIndex]['items'] as List<String>;
    final nonEmpty = list.where((s) => s.trim().isNotEmpty).toList();
    list
      ..clear()
      ..addAll(nonEmpty)
      ..add('');
  }

  void _addFoodItemInMeal(int mealIndex) {
    setState(() {
      final list = _meals[mealIndex]['items'] as List<String>;
      list.add('');
    });
  }

  void _showFoodRequestDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(20),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.rate_review_outlined,
                    size: 40, color: Color(0xFF628141)),
                const SizedBox(height: 10),
                const Text("ขอเพิ่มเมนูใหม่",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                    "กรอกชื่อเมนูที่ต้องการเพื่อให้ระบบตรวจสอบและเพิ่มให้",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),
                Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "ชื่อเมนูอาหาร",
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("ยกเลิก",
                            style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        _sendFoodRequest(nameCtrl.text.trim());
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF628141),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: const Text("ส่งคำขอ",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
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
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 0),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _meals.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemBuilder: (_, i) => _buildMealCard(i),
                      ),

                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildAddMealButton(),
                        ),
                      ),

                      const SizedBox(height: 30),
                      _buildActivityDropdown(),
                      const SizedBox(height: 40),

                      // ปุ่มขอเพิ่มเมนู (ปุ่มบันทึกย้ายไปอยู่ในแต่ละกล่องมื้อแล้ว)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _showFoodRequestDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Row(
                                children: [
                                  Icon(Icons.add_comment,
                                      size: 18, color: Colors.black87),
                                  SizedBox(width: 8),
                                  Text('ขอเพิ่มเมนู',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
        ),
        if (_isSaving)
          ModalBarrier(
              dismissible: false, color: Colors.black.withOpacity(0.4)),
        if (_isSaving)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }

  // ... (Widget _buildHeader, _buildMealCard, _buildFoodField, _buildAddMealButton, _buildActivityDropdown เหมือนเดิม) ...
  // เพื่อประหยัดเนื้อที่ ผมขอละส่วน Widget ย่อยไว้เหมือนเดิมนะครับ เพราะ logic ไม่เปลี่ยน
  Widget _buildHeader() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFF628141),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
              onTap: () {
                ref.read(homeViewDateProvider.notifier).state = _selectedDate;
                ref.read(navIndexProvider.notifier).state = 0;
              },
              child: const Icon(Icons.arrow_back_ios, color: Colors.white)),
          const Text('บันทึกการกินวันนี้',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: Color(0xFF628141),
                            onPrimary: Colors.white,
                            onSurface: Colors.black)),
                    child: child!),
              );
              if (d != null) {
                setState(() => _selectedDate = d);
                _loadDayData(d);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Color(0xFF628141)),
                const SizedBox(width: 6),
                Text(
                    "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year + 543}",
                    style: const TextStyle(
                        color: Color(0xFF628141), fontWeight: FontWeight.bold))
              ]),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _deleteThisMeal(int mealIndex) async {
    final selectedIndex = _meals[mealIndex]['selectedMealIndex'] as int?;
    if (selectedIndex == null ||
        selectedIndex < 0 ||
        selectedIndex >= _mealTimeOptions.length) return;
    final mealType = _mealTimeOptions[selectedIndex]['mealType']!;
    final label = _mealTimeOptions[selectedIndex]['label']!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบมื้อ'),
        content: Text('ต้องการลบข้อมูลมื้อ "$label" ใช่หรือไม่?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ลบ')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final base = Uri.parse(
          'https://unshirred-wendolyn-audiometrically.ngrok-free.dev/meals/clear/$userId');
      await http.delete(base.replace(
          queryParameters: {'date_record': dateStr, 'meal_type': mealType}));
      if (mounted) {
        setState(() {
          _meals.removeAt(mealIndex);
          if (_meals.isEmpty)
            _meals.add({
              'selectedMealIndex': null,
              'items': [''],
              'saved': false
            });
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('ลบมื้อแล้ว'), backgroundColor: Colors.green));
        await _refreshHomeDailyData(_selectedDate);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildMealCard(int mealIndex) {
    final items = List<String>.from(_meals[mealIndex]['items']);
    final selectedIndex = _meals[mealIndex]['selectedMealIndex'] as int?;
    final hasTimeSelected = selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < _mealTimeOptions.length;
    final saved = _meals[mealIndex]['saved'] == true;
    // หัวข้อ: ยังไม่เลือกช่วงเวลา = "เลือกมื้ออาหาร", เลือกแล้ว = "มื้อที่ N"
    final title =
        hasTimeSelected ? 'มื้อที่ ${mealIndex + 1}' : 'เลือกมื้ออาหาร';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EFCF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวบน: ซ้าย = หัวข้อ, ขวา = ช่วงเวลาที่ทาน + dropdown
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ช่วงเวลาที่ทาน',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 180,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black26),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedIndex,
                          isExpanded: true,
                          hint: const Text(
                            'เลือกมื้ออาหาร',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          items: List.generate(
                            _mealTimeOptions.length,
                            (i) => DropdownMenuItem(
                              value: i,
                              child: Text(
                                _mealTimeOptions[i]['label']!,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black87),
                              ),
                            ),
                          ),
                          onChanged: saved
                              ? null
                              : (v) => setState(() =>
                                  _meals[mealIndex]['selectedMealIndex'] = v),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!hasTimeSelected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'กรุณาเลือกช่วงเวลาที่ทานก่อน จึงจะกรอกอาหารได้',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            if (hasTimeSelected) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...List.generate(items.length, (j) => j)
                      .where((j) => items[j].trim().isNotEmpty)
                      .map((j) => _buildFoodChip(mealIndex, j, items,
                          canDelete: !saved)),
                  if (!saved)
                    InkWell(
                      onTap: () => _addFoodItemInMeal(mealIndex),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFF628141).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add,
                                  size: 18, color: Color(0xFF628141)),
                              SizedBox(width: 4),
                              Text('เพิ่มเมนูอาหาร',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF628141))),
                            ]),
                      ),
                    ),
                ],
              ),
              if (!saved)
                for (int j = 0; j < items.length; j++)
                  if (items[j].trim().isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildFoodField(mealIndex, j, items),
                    ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!saved) ...[
                  GestureDetector(
                    onTap: _isSaving ? null : () => _deleteThisMeal(mealIndex),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.red.shade300,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('ลบมื้อ',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                GestureDetector(
                  onTap: _isSaving
                      ? null
                      : () {
                          if (saved) {
                            setState(() => _meals[mealIndex]['saved'] = false);
                          } else {
                            _saveSingleCard(mealIndex);
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: saved ? Colors.grey : const Color(0xFF628141),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: Text(
                      _isSaving ? '...' : (saved ? 'แก้ไข' : 'บันทึก'),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodChip(int mealIndex, int itemIndex, List<String> items,
      {bool canDelete = true}) {
    if (itemIndex >= items.length || items[itemIndex].trim().isEmpty)
      return const SizedBox.shrink();
    final name = items[itemIndex];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
          if (canDelete) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                setState(() {
                  final i = _meals[mealIndex]['items'] as List;
                  if (itemIndex >= 0 && itemIndex < i.length) {
                    i[itemIndex] = '';
                    _normalizeMealItems(mealIndex);
                  }
                });
              },
              child: const Icon(Icons.close, size: 16, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodField(int mealIndex, int itemIndex, List<String> items) {
    return _FoodSearchField(
      mealIndex: mealIndex,
      itemIndex: itemIndex,
      foodDatabase: _foodDatabase,
      onSelected: (String name) {
        final list = _meals[mealIndex]['items'] as List;
        if (itemIndex >= 0 && itemIndex < list.length) {
          list[itemIndex] = name;
          _normalizeMealItems(mealIndex);
          setState(() {});
        }
      },
    );
  }

  Widget _buildAddMealButton() {
    return GestureDetector(
      onTap: _addNextMeal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: const Color(0xFFAFD198),
            borderRadius: BorderRadius.circular(10)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add, size: 16),
          SizedBox(width: 6),
          Text('เพิ่มมื้อถัดไป', style: TextStyle(fontSize: 12))
        ]),
      ),
    );
  }

  Widget _buildActivityDropdown() {
    return Container(
      width: 330,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedActivityLabel,
          isExpanded: true,
          onChanged: (v) => setState(() => _selectedActivityLabel = v!),
          items: _activityMap.keys
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
        ),
      ),
    );
  }
}

/// ช่องค้นหาอาหาร: พิมพ์หรือวางข้อความ แล้วแสดงรายการให้เลือก เมื่อเลือกถึงจะกลายเป็นชิป
class _FoodSearchField extends StatefulWidget {
  final int mealIndex;
  final int itemIndex;
  final List<dynamic> foodDatabase;
  final void Function(String name) onSelected;

  const _FoodSearchField({
    required this.mealIndex,
    required this.itemIndex,
    required this.foodDatabase,
    required this.onSelected,
  });

  @override
  State<_FoodSearchField> createState() => _FoodSearchFieldState();
}

class _FoodSearchFieldState extends State<_FoodSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<String> _getMatches(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    return widget.foodDatabase
        .where((f) => f['food_name'].toString().toLowerCase().contains(q))
        .map((f) => f['food_name'].toString())
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text;
    final matches = _getMatches(query);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'พิมพ์หรือวางชื่ออาหาร แล้วเลือกจากรายการด้านล่าง',
              border: InputBorder.none,
              isDense: true,
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        if (matches.isNotEmpty) ...[
          const SizedBox(height: 6),
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: matches.length,
                itemBuilder: (context, i) {
                  final name = matches[i];
                  return ListTile(
                    dense: true,
                    title: Text(name, style: const TextStyle(fontSize: 13)),
                    onTap: () {
                      widget.onSelected(name);
                      _controller.clear();
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
