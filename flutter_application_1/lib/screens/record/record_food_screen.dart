import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';

class FoodLoggingScreen extends ConsumerStatefulWidget {
  const FoodLoggingScreen({super.key});

  @override
  ConsumerState<FoodLoggingScreen> createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends ConsumerState<FoodLoggingScreen> {
  // ตัวแปรเก็บค่าที่กรอก
  String _breakfast = '';
  String _lunch = '';
  String _dinner = '';
  String _snack1 = '';
  String _snack2 = '';

  // ✅ 1. Map จับคู่ภาษาไทย (โชว์) -> อังกฤษ (เก็บ)
  final Map<String, String> _activityMap = {
    'ไม่ออกกำลังกายเลย': 'sedentary',
    'ออกกำลังกายเบาๆ (1-3 ครั้ง/สัปดาห์)': 'light',
    'ออกกำลังกายปานกลาง (3-5 ครั้ง/สัปดาห์)': 'moderate',
    'ออกกำลังกายหนัก (6-7 ครั้ง/สัปดาห์)': 'active',
    'ออกกำลังกายหนักมาก (ทุกวันเช้า-เย็น)': 'extreme',
  };
  
  // เก็บค่าภาษาไทยที่เลือกเพื่อแสดงใน Dropdown
  String _selectedActivityLabel = 'ไม่ออกกำลังกายเลย'; 

  List<dynamic> _foodDatabase = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now(); 

  @override
  void initState() {
    super.initState();
    _fetchFoodsFromApi();
  }

  Future<void> _fetchFoodsFromApi() async {
    // ⚠️ อย่าลืมแก้ IP ให้ตรง
    final url = Uri.parse('http://10.0.2.2:8000/foods'); 

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _foodDatabase = data;
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

  Future<void> _saveToDatabase(Map<String, dynamic> dailyData) async {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) return;
    
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final url = Uri.parse('http://10.0.2.2:8000/daily_logs/$userId'); 

    final body = jsonEncode({
      "date": dateStr,
      "calories": dailyData['calories'],
      "protein": dailyData['protein'],
      "carbs": dailyData['carbs'],
      "fat": dailyData['fat'],
      "breakfast_menu": _breakfast,
      "lunch_menu": _lunch,
      "dinner_menu": _dinner,
      "snack_menu": dailyData['snack_menu'],
    });

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('บันทึกไม่สำเร็จ: ${response.body}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _calculateAndSave() async {
    // ⚠️ 1. เช็คก่อนว่า Login หรือยัง
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาด: ไม่พบข้อมูลผู้ใช้ (กรุณา Login ใหม่)'), backgroundColor: Colors.red),
      );
      return; // จบการทำงานทันที ไม่ไปต่อ
    }

    int totalCal = 0;
    int totalP = 0;
    int totalC = 0;
    int totalF = 0;

    void addNutrients(String menuName) {
      if (menuName.isEmpty) return;
      
      final food = _foodDatabase.firstWhere(
        (f) => f['name'].toString().toLowerCase() == menuName.toLowerCase().trim(),
        orElse: () => {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0}, 
      );

      totalCal += (food['calories'] as num).toInt();
      totalP += (food['protein'] as num).toInt();
      totalC += (food['carbs'] as num).toInt();
      totalF += (food['fat'] as num).toInt();
    }

    addNutrients(_breakfast);
    addNutrients(_lunch);
    addNutrients(_dinner);
    addNutrients(_snack1);
    addNutrients(_snack2);

    String combinedSnacks = [_snack1, _snack2].where((s) => s.isNotEmpty).join(", ");
    String activityValue = _activityMap[_selectedActivityLabel] ?? 'sedentary';

    // อัปเดต Provider
    ref.read(userDataProvider.notifier).updateDailyFood(
      cal: totalCal, protein: totalP, carbs: totalC, fat: totalF,
      breakfast: _breakfast, lunch: _lunch, dinner: _dinner, snack: combinedSnacks
    );
    ref.read(userDataProvider.notifier).setActivityLevel(activityValue);

    // ✅ 2. บันทึก Activity Level ลงตาราง users (ยิง API เพิ่ม)
    try {
      final userUrl = Uri.parse('http://10.0.2.2:8000/users/$userId');
      await http.put(
        userUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"activity_level": activityValue}), // ส่งไปอัปเดต
      );
      print("อัปเดต Activity Level สำเร็จ");
    } catch (e) {
      print("อัปเดต Activity Level ไม่สำเร็จ: $e");
    }

    // 3. บันทึกเมนูอาหารลงตาราง daily_logs
    await _saveToDatabase({
      "calories": totalCal,
      "protein": totalP,
      "carbs": totalC,
      "fat": totalF,
      "snack_menu": combinedSnacks
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Header
            Container(
              width: double.infinity,
              height: 50,
              color: const Color(0xFF628141),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const Text(
                    'บันทึกการกิน',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF628141),
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF628141)),
                          const SizedBox(width: 5),
                          Text(
                            "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year + 543}",
                            style: const TextStyle(color: Color(0xFF628141), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Form Container
            Container(
              width: 330,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EFCF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildSearchableFoodRow('อาหารเช้า*', (val) => _breakfast = val),
                  const SizedBox(height: 15),
                  _buildSearchableFoodRow('มื้อว่าง', (val) => _snack1 = val),
                  const SizedBox(height: 15),
                  _buildSearchableFoodRow('อาหารกลางวัน*', (val) => _lunch = val),
                  const SizedBox(height: 15),
                  _buildSearchableFoodRow('มื้อว่าง', (val) => _snack2 = val),
                  const SizedBox(height: 15),
                  _buildSearchableFoodRow('อาหารเย็น*', (val) => _dinner = val),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Header กิจกรรม
            Container(
              width: double.infinity,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: const Color(0xFF628141),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: const Text(
                'กิจกรรมที่ทำวันนี้',
                style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            // ✅ Dropdown Activity (ใช้ข้อมูลจาก Map)
            Container(
              width: 330,
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedActivityLabel,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedActivityLabel = newValue!;
                    });
                  },
                  // สร้างรายการจาก Key ของ Map (ภาษาไทย)
                  items: _activityMap.keys.map<DropdownMenuItem<String>>((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(key, overflow: TextOverflow.ellipsis), // กันข้อความยาวเกิน
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Save Button
            GestureDetector(
              onTap: _calculateAndSave,
              child: Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF4C6414),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3)),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'บันทึกข้อมูล',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // --- Search Row ---
  Widget _buildSearchableFoodRow(String label, Function(String) onSaved) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        
        Container(
          width: 143,
          height: 23,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center, 
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') return const Iterable<String>.empty();
              return _foodDatabase
                  .where((food) => food['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()))
                  .map((food) => food['name'].toString());
            },
            onSelected: (String selection) {
              onSaved(selection);
            },
            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
              textController.addListener(() => onSaved(textController.text));
              return TextField(
                controller: textController,
                focusNode: focusNode,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 10, fontFamily: 'Inter', color: Colors.black, height: 1.0),
                decoration: const InputDecoration(
                  hintText: 'กรอกเมนูอาหารที่ทาน',
                  hintStyle: TextStyle(fontSize: 10, color: Color(0xFF979797), fontFamily: 'Inter'),
                  border: InputBorder.none,
                  isDense: true, 
                  contentPadding: EdgeInsets.zero, 
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: Container(
                    width: 143,
                    color: Colors.white,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(option, style: const TextStyle(fontSize: 12)),
                          ),
                        );
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