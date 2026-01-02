import 'dart:convert'; // ✅ เพิ่ม: เพื่อแปลง JSON
import 'package:http/http.dart' as http; // ✅ เพิ่ม: เพื่อยิง API
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

  String _selectedActivity = 'ไม่ออกกำลังกายเลย';
  final List<String> _activities = [
    'ไม่ออกกำลังกายเลย',
    'ออกกำลังกายเบาๆ (1-3 ครั้ง/สัปดาห์)',
    'ออกกำลังกายปานกลาง (3-5 ครั้ง/สัปดาห์)',
    'ออกกำลังกายหนัก (6-7 ครั้ง/สัปดาห์)',
    'ออกกำลังกายหนักมาก (ทุกวันเช้า-เย็น)',
  ];

  // ✅ 1. ตัวแปรสำหรับเก็บข้อมูลจาก Database (เริ่มเป็น List ว่าง)
  List<dynamic> _foodDatabase = [];
  bool _isLoading = true; // เอาไว้เช็คว่าโหลดเสร็จยัง

  // ✅ 2. สั่งให้ดึงข้อมูลทันทีที่เปิดหน้านี้
  @override
  void initState() {
    super.initState();
    _fetchFoodsFromApi();
  }

  // ✅ 3. ฟังก์ชันดึงข้อมูลจาก Python API
  Future<void> _fetchFoodsFromApi() async {
    // ⚠️ ถ้าใช้ Android Emulator ให้ใช้ 10.0.2.2
    // ⚠️ ถ้าใช้ iOS Simulator ให้ใช้ 127.0.0.1
    // ⚠️ ถ้าใช้เครื่องจริง ให้ใช้ IP ของคอม (เช่น 192.168.1.45)
    final url = Uri.parse('http://10.0.2.2:8000/foods'); 

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // แปลง JSON เป็น List
        final List<dynamic> data = json.decode(response.body);
        
        setState(() {
          _foodDatabase = data; // เอาข้อมูลจริงยัดใส่ตัวแปร
          _isLoading = false;   // ปิดสถานะโหลด
        });
        print("โหลดเมนูสำเร็จ: ${_foodDatabase.length} รายการ");
      } else {
        print('Error: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ถ้ายังโหลดไม่เสร็จ ให้ขึ้นหมุนๆ
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
              height: 34,
              color: const Color(0xFF628141),
              alignment: Alignment.center,
              child: const Text(
                'บันทึกข้อมูลการทานอาหารวันนี้',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
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
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Dropdown
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
                  value: _selectedActivity,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedActivity = newValue!;
                    });
                  },
                  items: _activities.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
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
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'บันทึกข้อมูล',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        
        Container(
          width: 143,
          height: 23,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center, 
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              // ✅ กรองข้อมูลจาก _foodDatabase ที่โหลดมาจริง
              return _foodDatabase
                  .where((food) => food['name']
                      .toString()
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()))
                  .map((food) => food['name'].toString());
            },
            onSelected: (String selection) {
              onSaved(selection);
            },
            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
              textController.addListener(() {
                onSaved(textController.text);
              });
              
              return TextField(
                controller: textController,
                focusNode: focusNode,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  fontSize: 10, 
                  fontFamily: 'Inter', 
                  color: Colors.black, 
                  height: 1.0 
                ),
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

  // --- Calculate Logic ---
  void _calculateAndSave() {
    int totalCal = 0;
    int totalP = 0;
    int totalC = 0;
    int totalF = 0;

    void addNutrients(String menuName) {
      if (menuName.isEmpty) return;
      
      // ✅ ค้นหาเมนูในรายการที่โหลดมาจาก DB
      final food = _foodDatabase.firstWhere(
        (f) => f['name'] == menuName,
        // ถ้าหาไม่เจอ ให้ใช้ค่า Default (อันนี้อาจจะต้องปรับปรุงในอนาคต)
        orElse: () => {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0}, 
      );

      // ✅ แก้ชื่อ Key ให้ตรงกับ Database (calories, protein, carbs, fat)
      // และใช้ num เพื่อรองรับทศนิยมจาก Database
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

    ref.read(userDataProvider.notifier).updateDailyFood(
      cal: totalCal, 
      protein: totalP, 
      carbs: totalC, 
      fat: totalF,
      breakfast: _breakfast,
      lunch: _lunch,
      dinner: _dinner,
      snack: combinedSnacks
    );
    
    ref.read(userDataProvider.notifier).setActivityLevel(_selectedActivity);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย!'), backgroundColor: Colors.green),
    );
  }
}