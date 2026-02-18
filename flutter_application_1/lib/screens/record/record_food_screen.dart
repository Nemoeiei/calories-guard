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
  // ข้อมูลมื้ออาหาร: selectedMealIndex = null หมายถึงยังไม่เลือกช่วงเวลา
  final List<Map<String, dynamic>> _meals = [
    {'selectedMealIndex': null, 'items': ['']}
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
  }

  double _safeParse(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Future<void> _fetchFoodsFromApi() async {
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:8000/foods'));
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

  // ✅ แก้ไข: Map Index เป็น meal_type แบบ Dynamic (meal_1, meal_2...)
  String _mapIndexToMealType(int i) {
    // i เริ่มจาก 0 ดังนั้น +1 ให้เป็น meal_1
    return 'meal_${i + 1}';
  }

  // ✅ บันทึกหนึ่งมื้อลง Backend (ส่ง items ทั้งมื้อครั้งเดียว — ไม่ส่งทีละรายการเพื่อกันซ้ำ)
  Future<void> _saveMealToBackend(String mealType, List<String> menuNames) async {
    if (menuNames.isEmpty) return;

    final userId = ref.read(userDataProvider).userId;
    final List<Map<String, dynamic>> itemsPayload = [];

    for (final menuName in menuNames) {
      final name = menuName.toString().trim();
      if (name.isEmpty) continue;
      Map<String, dynamic>? food;
      for (final f in _foodDatabase) {
        final m = f as Map<String, dynamic>?;
        if (m != null && m['food_name'].toString().toLowerCase() == name.toLowerCase()) {
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
    final url = Uri.parse('http://10.0.2.2:8000/meals/$userId');
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

  // ✅ ฟังก์ชันคำนวณและบันทึกทั้งหมด
  void _calculateAndSave() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();

    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;

    setState(() => _isSaving = true);

    int totalCal = 0;
    int totalP = 0;
    int totalC = 0;
    int totalF = 0;

    // ✅ เก็บข้อมูลมื้ออาหารแบบ Map เพื่อส่งให้ Provider ใหม่
    Map<String, String> recordedMeals = {};

    // วนลูปบันทึกทีละมื้อ — ส่งหนึ่ง POST ต่อมื้อ (รวม items ทั้งมื้อ) เพื่อไม่ให้ backend สร้างหลาย meal / บวกแคลซ้ำ
    for (int i = 0; i < _meals.length; i++) {
      List<String> items = List<String>.from(_meals[i]['items']);
      String mealType = _mealTypeForCard(i);

      List<String> foodNamesInThisMeal = [];

      for (String menu in items) {
        final name = menu.trim();
        if (name.isEmpty) continue;
        final food = _foodDatabase.firstWhere(
            (f) =>
                f['food_name'].toString().toLowerCase() == name.toLowerCase(),
            orElse: () => null);

        if (food != null) {
          totalCal += _safeParse(food['calories']).toInt();
          totalP += _safeParse(food['protein']).toInt();
          totalC += _safeParse(food['carbs']).toInt();
          totalF += _safeParse(food['fat']).toInt();
          foodNamesInThisMeal.add(name);
        }
      }

      if (foodNamesInThisMeal.isNotEmpty) {
        recordedMeals[mealType] = foodNamesInThisMeal.join(", ");
        await _saveMealToBackend(mealType, foodNamesInThisMeal);
      }
    }

    try {
      // Update Activity
      String activityValue =
          _activityMap[_selectedActivityLabel] ?? 'sedentary';
      try {
        final userUrl = Uri.parse('http://10.0.2.2:8000/users/$userId');
        await http.put(
          userUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"activity_level": activityValue}),
        );
        ref.read(userDataProvider.notifier).setActivityLevel(activityValue);
      } catch (e) {
        print("Activity Update Error: $e");
      }

      // ✅ Update Provider ด้วย Map ใหม่
      ref.read(userDataProvider.notifier).updateDailyFood(
            cal: totalCal, protein: totalP, carbs: totalC, fat: totalF,
            dailyMeals: recordedMeals, // ส่ง Map แทน
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('บันทึกเรียบร้อย!'), backgroundColor: Colors.green));
        await Future.delayed(const Duration(milliseconds: 200));
        ref.read(navIndexProvider.notifier).state = 0; // กลับหน้าแรก
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // --- UI Logic ---
  void _addNextMeal() {
    setState(() {
      _meals.add({'selectedMealIndex': null, 'items': ['']});
    });
  }

  String _mealTypeForCard(int i) {
    final idx = _meals[i]['selectedMealIndex'] as int?;
    if (idx != null && idx >= 0 && idx < _mealTimeOptions.length) {
      return _mealTimeOptions[idx]['mealType']!;
    }
    return _mapIndexToMealType(i);
  }

  void _addFoodItemInMeal(int index) {
    setState(() => _meals[index]['items'].add(''));
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
              onTap: () => ref.read(navIndexProvider.notifier).state = 0,
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
              if (d != null) setState(() => _selectedDate = d);
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

  Widget _buildMealCard(int mealIndex) {
    final items = List<String>.from(_meals[mealIndex]['items']);
    final selectedIndex = _meals[mealIndex]['selectedMealIndex'] as int?;
    final hasTimeSelected = selectedIndex != null && selectedIndex >= 0 && selectedIndex < _mealTimeOptions.length;
    // หัวข้อ: ยังไม่เลือกช่วงเวลา = "เลือกมื้ออาหาร", เลือกแล้ว = "มื้อที่ N"
    final title = hasTimeSelected ? 'มื้อที่ ${mealIndex + 1}' : 'เลือกมื้ออาหาร';

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
            // แถวบน: ซ้าย = หัวข้อ + ช่วงเวลาที่ทาน + dropdown, ขวา = chips + ปุ่ม +
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ช่วงเวลาที่ทาน',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
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
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            ),
                            onChanged: (v) => setState(() => _meals[mealIndex]['selectedMealIndex'] = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          ...items.where((s) => s.trim().isNotEmpty).map((name) => _buildFoodChip(mealIndex, name, items)),
                          InkWell(
                            onTap: () => _addFoodItemInMeal(mealIndex),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, size: 22, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ช่องกรอกอาหารเพิ่ม (สำหรับ slot ว่าง)
            for (int j = 0; j < items.length; j++)
              if (items[j].trim().isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildFoodField(mealIndex, j, items),
                ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _isSaving ? null : _calculateAndSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF628141),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    _isSaving ? '...' : 'บันทึก',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodChip(int mealIndex, String name, List<String> items) {
    final idx = items.indexOf(name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis, maxLines: 1),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                final i = _meals[mealIndex]['items'] as List;
                if (idx >= 0 && idx < i.length) i[idx] = '';
              });
            },
            child: const Icon(Icons.close, size: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodField(int mealIndex, int itemIndex, List<String> items) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Autocomplete<String>(
        optionsBuilder: (t) {
          if (t.text.isEmpty) return const Iterable.empty();
          return _foodDatabase
              .where((f) => f['food_name']
                  .toString()
                  .toLowerCase()
                  .contains(t.text.toLowerCase()))
              .map((f) => f['food_name'].toString());
        },
        onSelected: (s) =>
            setState(() => _meals[mealIndex]['items'][itemIndex] = s),
        fieldViewBuilder: (_, controller, focusNode, __) {
          controller.text = items[itemIndex];
          controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length));
          controller.addListener(() {
            _meals[mealIndex]['items'][itemIndex] = controller.text;
          });
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
                hintText: 'กรอกอาหารที่ทาน',
                border: InputBorder.none,
                isDense: true),
            style: const TextStyle(fontSize: 12),
          );
        },
      ),
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
