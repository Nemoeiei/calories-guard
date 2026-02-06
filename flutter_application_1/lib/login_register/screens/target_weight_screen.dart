import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';
import '../../services/auth_service.dart';
import '/widget/bottom_bar.dart'; 

class TargetWeightScreen extends ConsumerStatefulWidget {
  final GoalOption selectedGoal;

  const TargetWeightScreen({super.key, required this.selectedGoal});

  @override
  ConsumerState<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends ConsumerState<TargetWeightScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  DateTime? _selectedTargetDate;

  // ... (ส่วน getter _goalTitle, _goalSubtitle, _goalColor เหมือนเดิม) ...
  String get _goalTitle {
    switch (widget.selectedGoal) {
      case GoalOption.loseWeight: return 'การลดน้ำหนัก';
      case GoalOption.maintainWeight: return 'การรักษาน้ำหนัก';
      case GoalOption.buildMuscle: return 'การเพิ่มกล้ามเนื้อ';
    }
  }
  
  String get _goalSubtitle {
    switch (widget.selectedGoal) {
      case GoalOption.loseWeight: return 'ควบคุมแคลอรี่';
      case GoalOption.maintainWeight: return 'รักษาสมดุล';
      case GoalOption.buildMuscle: return 'สร้างความแข็งแรง';
    }
  }

  Color get _goalColor {
    switch (widget.selectedGoal) {
      case GoalOption.loseWeight: return const Color(0xFFD76A3C);
      case GoalOption.maintainWeight: return const Color(0xFF497CEA);
      case GoalOption.buildMuscle: return const Color(0xFFB4AC15);
    }
  }

  double _calculateRecommendedWeight(double currentWeight) {
    if (widget.selectedGoal == GoalOption.loseWeight) return currentWeight * 0.9;
    if (widget.selectedGoal == GoalOption.buildMuscle) return currentWeight * 1.1;
    return currentWeight;
  }

  void _submit() async {
    // ... (Logic เดิม) ...
    final double? targetW = double.tryParse(_weightController.text);

    if (targetW == null || _selectedTargetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')));
      return;
    }

    // Ensure selected date is in the future (or at least today)
    final now = DateTime.now();
    final targetDate = DateTime(_selectedTargetDate!.year, _selectedTargetDate!.month, _selectedTargetDate!.day);
    if (targetDate.isBefore(DateTime(now.year, now.month, now.day))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกวันที่เท่าหรือหลังวันนี้')));
      return;
    }

    setState(() => _isLoading = true);
    final userId = ref.read(userDataProvider).userId;
    
    bool success = await _authService.updateProfile(userId, {
      "target_weight_kg": targetW,
      "goal_target_date": "${targetDate.year}-${targetDate.month.toString().padLeft(2,'0')}-${targetDate.day.toString().padLeft(2,'0')}",
    });

    setState(() => _isLoading = false);

    if (success) {
      final int durationDays = targetDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      ref.read(userDataProvider.notifier).setGoalInfo(targetWeight: targetW, duration: durationDays, targetDate: targetDate);
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกไม่สำเร็จ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final double currentWeight = userData.weight;
    final double recommendedWeight = _calculateRecommendedWeight(currentWeight);

    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 180),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // 1. Header (แสดงกลางหน้าจอ)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: const Text(
                          'เป้าหมายของคุณคือ',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: RichText( // ใช้ RichText หรือ Text.rich เพื่อรวมข้อความและให้ตัดคำสวยๆ
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$_goalTitle ', 
                              style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w500, color: _goalColor)
                            ),
                            TextSpan(
                              text: _goalSubtitle, 
                              style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w500, color: _goalColor)
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 2. Icon Circle
                    Center(
                      child: Container(
                        width: 100, height: 100,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Center(child: Icon(Icons.flag, size: 50, color: _goalColor)),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 3. Info Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // กล่องซ้าย
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('น้ำหนักปัจจุบัน', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 5),
                            Container(
                              width: 164, height: 37,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: _goalColor.withOpacity(0.54), borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                '${currentWeight.toStringAsFixed(1)} กก.',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        // กล่องขวา
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('น้ำหนักแนะนำ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 5),
                            Container(
                              width: 168, height: 37,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: _goalColor.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                '${recommendedWeight.toStringAsFixed(1)} กก.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _goalColor), 
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 4. Input Fields
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('เป้าหมายน้ำหนัก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 5),
                          Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
                            child: TextField(
                              controller: _weightController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.left,
                              style: const TextStyle(fontSize: 14, color: Colors.black),
                              decoration: const InputDecoration(
                                hintText: '0.00 กก.',
                                hintStyle: TextStyle(color: Colors.black54),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(bottom: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text('ระยะเวลาที่ต้องการลดน้ำหนัก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 5),
                          Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
                            child: Row(
                              children: [
                                  GestureDetector(
                                    onTap: _pickTargetDate,
                                    child: const Icon(Icons.calendar_month, color: Color(0xFF6E6A6A), size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _durationController,
                                      readOnly: true,
                                      onTap: _pickTargetDate,
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(fontSize: 14, color: Colors.black),
                                      decoration: const InputDecoration(
                                        hintText: 'เลือกวันที่',
                                        hintStyle: TextStyle(color: Colors.black54),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.only(bottom: 12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 31, left: 19,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.chevron_left, size: 40, color: Color(0xFF1D1B20)),
              ),
            ),
            Positioned(
              bottom: 50, left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: !_isLoading ? _submit : null,
                  child: Container(
                    width: 259,
                    height: 54,
                    decoration: BoxDecoration(color: const Color(0xFF628141), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4))]),
                    child: Center(child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ถัดไป', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white))),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTargetDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4C6414),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTargetDate = picked;
        _durationController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }
}