import 'package:flutter/material.dart';
import 'activity_level_screen.dart';

class FoodAllergyScreen extends StatefulWidget {
  const FoodAllergyScreen({super.key});

  @override
  State<FoodAllergyScreen> createState() => _FoodAllergyScreenState();
}

class _FoodAllergyScreenState extends State<FoodAllergyScreen> {
  // เก็บรายการที่เลือก
  final Set<String> _selectedAllergies = {};
  bool _noAllergies = false;

  // ธีมสีเดิม
  final Color primaryGreen = const Color(0xFF628141);
  final Color lightBgGreen = const Color(0xFFF7FBF2);

  // ข้อมูลตัวอย่างสำหรับแสดงผล
  final List<Map<String, dynamic>> _allergyOptions = [
    {'id': 'milk', 'label': 'นมวัว', 'icon': Icons.coffee},
    {'id': 'egg', 'label': 'ไข่ไก่', 'icon': Icons.egg},
    {'id': 'peanut', 'label': 'ถั่วลิสง', 'icon': Icons.bakery_dining},
    {'id': 'seafood', 'label': 'อาหารทะเล', 'icon': Icons.restaurant},
    {'id': 'soy', 'label': 'ถั่วเหลือง', 'icon': Icons.grass},
    {'id': 'wheat', 'label': 'แป้งสาลี', 'icon': Icons.breakfast_dining},
    {'id': 'sesame', 'label': 'งา', 'icon': Icons.grain},
    {'id': 'shellfish', 'label': 'สัตว์น้ำเปลือกแข็ง', 'icon': Icons.set_meal},
  ];

  void _toggleAllergy(String id) {
    setState(() {
      _noAllergies = false;
      if (_selectedAllergies.contains(id)) {
        _selectedAllergies.remove(id);
      } else {
        _selectedAllergies.add(id);
      }
    });
  }

  void _toggleNoAllergies() {
    setState(() {
      _noAllergies = !_noAllergies;
      if (_noAllergies) {
        _selectedAllergies.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBgGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 200,
            height: 8,
            child: LinearProgressIndicator(
              value: 0.5, // แสดงความคืบหน้า 40%
              backgroundColor: Colors.grey.shade200,
              color: primaryGreen,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "คุณแพ้อาหารประเภทไหน?",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "เลือกอาหารที่คุณแพ้เพื่อให้เราแนะนำเมนูที่ปลอดภัยสำหรับคุณ",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: _allergyOptions.length,
                itemBuilder: (context, index) {
                  final item = _allergyOptions[index];
                  final isSelected = _selectedAllergies.contains(item['id']);
                  return _buildAllergyCard(item, isSelected);
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildNoAllergyOption(),
            const SizedBox(height: 24),
            _buildNextButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergyCard(Map<String, dynamic> item, bool isSelected) {
    return InkWell(
      onTap: () => _toggleAllergy(item['id']),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryGreen.withOpacity(0.1) : Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item['icon'],
                size: 32,
                color: isSelected ? primaryGreen : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item['label'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryGreen : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAllergyOption() {
    return InkWell(
      onTap: _toggleNoAllergies,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _noAllergies ? primaryGreen : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "ไม่มีอาหารที่ฉันแพ้",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _noAllergies ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _noAllergies ? primaryGreen : Colors.grey.shade300,
                  width: 2,
                ),
                color: _noAllergies ? primaryGreen : Colors.transparent,
              ),
              child: _noAllergies
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    bool canProceed = _selectedAllergies.isNotEmpty || _noAllergies;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canProceed ? () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ActivityLevelScreen()),
          );
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          "ถัดไป",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
