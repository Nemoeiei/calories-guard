import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../providers/user_data_provider.dart';

class UnitSettingsScreen extends ConsumerStatefulWidget {
  const UnitSettingsScreen({super.key});

  @override
  ConsumerState<UnitSettingsScreen> createState() => _UnitSettingsScreenState();
}

class _UnitSettingsScreenState extends ConsumerState<UnitSettingsScreen> {
  
  // ฟังก์ชันยิง API อัปเดตหน่วย
  Future<void> _updateUnit(String key, String value) async {
    final userId = ref.read(userDataProvider).userId;
    
    // 1. อัปเดตในแอปทันที (ให้ลื่นไหล)
    if (key == 'unit_weight') ref.read(userDataProvider.notifier).updateUnit(weight: value);
    if (key == 'unit_height') ref.read(userDataProvider.notifier).updateUnit(height: value);
    if (key == 'unit_energy') ref.read(userDataProvider.notifier).updateUnit(energy: value);
    if (key == 'unit_water') ref.read(userDataProvider.notifier).updateUnit(water: value);

    // 2. ยิง API บันทึกลง Database
    try {
      final url = Uri.parse('http://10.0.2.2:8000/users/$userId');
      await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({key: value}),
      );
    } catch (e) {
      print("Error updating unit: $e");
      // ถ้า Error อาจจะ SnackBar บอกก็ได้
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider); // ดึงค่าปัจจุบันมาเช็ค

    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ยูนิต', style: TextStyle(fontFamily: 'Inter', color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            _buildSectionHeader('น้ำหนัก'),
            _buildUnitGroup([
              _buildUnitOption('ปอนด์ (lbs)', 'lbs', userData.unitWeight, 'unit_weight'),
              _buildUnitOption('กิโลกรัม (kg)', 'kg', userData.unitWeight, 'unit_weight', showDivider: false),
            ]),

            _buildSectionHeader('ส่วนสูง'),
            _buildUnitGroup([
              _buildUnitOption('ฟุต (ft)', 'ft', userData.unitHeight, 'unit_height'),
              _buildUnitOption('เซนติเมตร (cm)', 'cm', userData.unitHeight, 'unit_height', showDivider: false),
            ]),

            _buildSectionHeader('พลังงาน'),
            _buildUnitGroup([
              _buildUnitOption('แคลอรี่ (kcal)', 'kcal', userData.unitEnergy, 'unit_energy'),
              _buildUnitOption('กิโลจูล (kj)', 'kj', userData.unitEnergy, 'unit_energy', showDivider: false),
            ]),

            _buildSectionHeader('น้ำ'),
            _buildUnitGroup([
              _buildUnitOption('ขวด', 'bottle', userData.unitWater, 'unit_water'),
              _buildUnitOption('มิลลิลิตร (ml)', 'ml', userData.unitWater, 'unit_water', showDivider: false),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 20, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Color(0xFF6E6A6A))),
      ),
    );
  }

  Widget _buildUnitGroup(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Column(children: children),
    );
  }

  // สร้างตัวเลือกที่มีเครื่องหมายถูก (Checkmark) ถ้าถูกเลือก
  Widget _buildUnitOption(String title, String value, String currentValue, String dbKey, {bool showDivider = true}) {
    bool isSelected = (value == currentValue);
    
    return InkWell( // ใช้ InkWell ให้กดได้
      onTap: () => _updateUnit(dbKey, value),
      child: Container(
        decoration: BoxDecoration(
          border: showDivider ? const Border(bottom: BorderSide(color: Colors.black, width: 1)) : null,
        ),
        child: ListTile(
          title: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black)),
          trailing: isSelected 
            ? const Icon(Icons.check, color: Color(0xFF4C6414)) // ✅ โชว์เครื่องหมายถูกถ้าเลือกอยู่
            : null, 
        ),
      ),
    );
  }
}