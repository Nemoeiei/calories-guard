import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';

class FoodLoggingScreen extends ConsumerStatefulWidget {
  const FoodLoggingScreen({super.key});

  @override
  ConsumerState<FoodLoggingScreen> createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends ConsumerState<FoodLoggingScreen> {
  // ตัวแปรเก็บค่าที่เลือกจาก Dropdown/พิมพ์
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

  // 🔥 ฐานข้อมูลอาหารจำลอง (Mock Data)
  // คุณสามารถเพิ่มเมนูตรงนี้ได้เรื่อยๆ
  final List<Map<String, dynamic>> _foodDatabase = [
    {'name': 'ข้าวมันไก่', 'cal': 600, 'p': 20, 'c': 60, 'f': 25},
    {'name': 'ข้าวผัดกระเพราหมูสับ', 'cal': 550, 'p': 25, 'c': 50, 'f': 20},
    {'name': 'ข้าวไข่เจียว', 'cal': 450, 'p': 10, 'c': 40, 'f': 30},
    {'name': 'สลัดอกไก่', 'cal': 150, 'p': 25, 'c': 10, 'f': 2},
    {'name': 'ก๋วยเตี๋ยวเรือ', 'cal': 350, 'p': 15, 'c': 45, 'f': 10},
    {'name': 'ส้มตำไทย', 'cal': 120, 'p': 3, 'c': 20, 'f': 1},
    {'name': 'ต้มยำกุ้ง', 'cal': 180, 'p': 20, 'c': 10, 'f': 8},
    {'name': 'ข้าวเปล่า', 'cal': 80, 'p': 2, 'c': 18, 'f': 0},
    {'name': 'ไข่ต้ม', 'cal': 75, 'p': 7, 'c': 0, 'f': 5},
    {'name': 'นมอัลมอนด์', 'cal': 60, 'p': 1, 'c': 3, 'f': 2},
    {'name': 'กาแฟดำ', 'cal': 5, 'p': 0, 'c': 1, 'f': 0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 36),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                child: Text(
                  'บันทึกข้อมูลรายวัน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Header 1 ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF628141),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Center(
                child: Text(
                  'ข้อมูลการทานอาหารวันนี้',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.only(left: 30, right: 30, top: 10),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
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

            // --- Header 2 ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF628141),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Center(
                child: Text(
                  'กิจกรรมที่ทำวันนี้',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.only(left: 32, right: 32, top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              height: 60,
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
                    fontSize: 16,
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

            const SizedBox(height: 30),

            // --- ปุ่มบันทึก ---
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 🔥 Helper Function: สร้างช่องค้นหาอาหาร (Autocomplete)
  Widget _buildSearchableFoodRow(String label, Function(String) onSaved) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          width: 160, // กว้างขึ้นนิดนึงเพื่อให้เห็นชื่อชัด
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEDED),
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              // ค้นหาชื่อเมนูที่มีคำที่พิมพ์
              return _foodDatabase
                  .where((food) => food['name']
                      .toString()
                      .contains(textEditingValue.text))
                  .map((food) => food['name'].toString());
            },
            onSelected: (String selection) {
              onSaved(selection); // บันทึกค่าเมื่อเลือก
            },
            // Custom UI ช่องกรอก
            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
              // Hack: บันทึกค่าเมื่อพิมพ์เองด้วย (เผื่อไม่กดเลือก)
              textController.addListener(() {
                onSaved(textController.text);
              });
              
              return TextField(
                controller: textController,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'ค้นหา/กรอกเมนู',
                  hintStyle: TextStyle(fontSize: 10, color: Color(0xFF979797)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 12),
                ),
                style: const TextStyle(fontSize: 12, fontFamily: 'Inter'),
              );
            },
            // Custom UI รายการที่เด้งขึ้นมา
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: Container(
                    width: 160,
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
                            padding: const EdgeInsets.all(10.0),
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

  // ฟังก์ชันคำนวณแคลอรี่และบันทึก
  void _calculateAndSave() {
    int totalCal = 0;
    int totalP = 0;
    int totalC = 0;
    int totalF = 0;

    // Helper ในการหาแคลอรี่จากชื่อ
    void addNutrients(String menuName) {
      if (menuName.isEmpty) return;
      
      // ค้นหาใน DB
      final food = _foodDatabase.firstWhere(
        (f) => f['name'] == menuName,
        orElse: () => {'cal': 300, 'p': 10, 'c': 30, 'f': 10}, // ค่า Default ถ้าหาไม่เจอ
      );
      
      totalCal += (food['cal'] as int);
      totalP += (food['p'] as int);
      totalC += (food['c'] as int);
      totalF += (food['f'] as int);
    }

    addNutrients(_breakfast);
    addNutrients(_lunch);
    addNutrients(_dinner);
    addNutrients(_snack1);
    addNutrients(_snack2);

    // รวมชื่อมื้อว่าง
    String combinedSnacks = [_snack1, _snack2].where((s) => s.isNotEmpty).join(", ");

    // บันทึกลง Provider
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
    
    // อัปเดตกิจกรรม
    ref.read(userDataProvider.notifier).setActivityLevel(_selectedActivity);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย!'), backgroundColor: Colors.green),
    );
  }
}