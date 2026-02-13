import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';
import '../../services/auth_service.dart';
import '/widget/bottom_bar.dart';
import 'target_weight_slider_screen.dart';
import 'duration_slider_screen.dart';

class TargetWeightScreen extends ConsumerStatefulWidget {
  final GoalOption selectedGoal;

  const TargetWeightScreen({super.key, required this.selectedGoal});

  @override
  ConsumerState<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends ConsumerState<TargetWeightScreen> {
  final AuthService _authService = AuthService();

  // Slider values
  double _selectedWeight = 0;
  int _selectedDurationDays = 90;
  bool _showWeightScreen = true;

  double _calculateRecommendedWeight(double currentWeight) {
    if (widget.selectedGoal == GoalOption.loseWeight) return currentWeight * 0.9;
    if (widget.selectedGoal == GoalOption.buildMuscle) return currentWeight * 1.1;
    return currentWeight;
  }

  int _calculateRecommendedDuration(double currentWeight, double targetWeight) {
    final weightDifference = (currentWeight - targetWeight).abs();
    if (widget.selectedGoal == GoalOption.loseWeight) {
      return (weightDifference * 30).ceil(); // ~1 kg per month
    }
    if (widget.selectedGoal == GoalOption.buildMuscle) {
      return (weightDifference * 60).ceil(); // ~0.5 kg per month
    }
    return 90; // Default for maintain weight
  }

  void _submit() async {
    if (_selectedWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')));
      return;
    }

    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: _selectedDurationDays));

    final userId = ref.read(userDataProvider).userId;
    
    bool success = await _authService.updateProfile(userId, {
      "target_weight_kg": _selectedWeight,
      "goal_target_date": "${targetDate.year}-${targetDate.month.toString().padLeft(2,'0')}-${targetDate.day.toString().padLeft(2,'0')}",
    });

    if (success) {
      ref.read(userDataProvider.notifier).setGoalInfo(targetWeight: _selectedWeight, duration: _selectedDurationDays, targetDate: targetDate);
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

    // Initialize selected weight on first build
    if (_selectedWeight == 0) {
      _selectedWeight = recommendedWeight;
    }

    // Initialize selected duration based on weight difference
    int recommendedDuration = _calculateRecommendedDuration(currentWeight, _selectedWeight);
    if (_selectedDurationDays == 90 && recommendedDuration != 90) {
      _selectedDurationDays = recommendedDuration;
    }

    if (_showWeightScreen) {
      return TargetWeightSliderScreen(
        selectedGoal: widget.selectedGoal,
        currentWeight: currentWeight,
        recommendedWeight: recommendedWeight,
        onWeightSelected: (weight) {
          setState(() {
            _selectedWeight = weight;
          });
        },
        onNext: () {
          setState(() {
            _showWeightScreen = false;
          });
        },
      );
    } else {
      return DurationSliderScreen(
        selectedGoal: widget.selectedGoal,
        currentDate: DateTime.now(),
        recommendedDurationDays: _calculateRecommendedDuration(currentWeight, _selectedWeight),
        onBack: () {
          setState(() {
            _showWeightScreen = true;
          });
        },
        onSubmit: _submit,
        onDurationSelected: (days) {
          setState(() {
            _selectedDurationDays = days;
          });
        },
      );
    }
  }
}