import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';

class FoodLoggingScreen extends ConsumerStatefulWidget {
  const FoodLoggingScreen({super.key});

  @override
  ConsumerState<FoodLoggingScreen> createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends ConsumerState<FoodLoggingScreen> {
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
    {'name': 'ผัดไทย', 'cal': 500, 'p': 15, 'c': 70, 'f': 20},
    {'name': 'แกงเขียวหวานไก่', 'cal': 450, 'p': 20, 'c': 15, 'f': 35},
  ];

  @override
  Widget build(BuildContext context) {
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

  // --- 🔥 ส่วนที่แก้ไขให้สวยงามและตรงปก ---
  Widget _buildSearchableFoodRow(String label, Function(String) onSaved) {
    return Row(
      // ✅ ใช้ spaceBetween เพื่อดันช่องกรอกไปขวาสุด (ให้ตรงกันทุกแถว)
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
          alignment: Alignment.center, // จัดกลางแนวตั้งและนอน
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return _foodDatabase
                  .where((food) => food['name']
                      .toString()
                      .contains(textEditingValue.text))
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
                textAlignVertical: TextAlignVertical.center, // ✅ จัดข้อความให้อยู่กลางบรรทัด
                style: const TextStyle(
                  fontSize: 10, 
                  fontFamily: 'Inter', 
                  color: Colors.black, 
                  height: 1.0 // ✅ Fix line height ให้พอดีกับกล่องเล็ก
                ),
                decoration: const InputDecoration(
                  hintText: 'กรอกเมนูอาหารที่ทาน',
                  hintStyle: TextStyle(fontSize: 10, color: Color(0xFF979797), fontFamily: 'Inter'),
                  border: InputBorder.none,
                  isDense: true, // ✅ ลดระยะ Padding ของ TextField
                  contentPadding: EdgeInsets.zero, // ✅ ลบ Padding ออกให้หมดเพื่อให้จัดกลางได้เอง
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

  void _calculateAndSave() {
    int totalCal = 0;
    int totalP = 0;
    int totalC = 0;
    int totalF = 0;

    void addNutrients(String menuName) {
      if (menuName.isEmpty) return;
      final food = _foodDatabase.firstWhere(
        (f) => f['name'] == menuName,
        orElse: () => {'cal': 300, 'p': 10, 'c': 30, 'f': 10}, 
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