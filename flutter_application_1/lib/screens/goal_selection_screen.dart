import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. import riverpod
import '../providers/user_data_provider.dart'; // import provider
import 'target_weight_screen.dart';



// 2. เปลี่ยนเป็น ConsumerStatefulWidget
class GoalSelectionScreen extends ConsumerStatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  ConsumerState<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends ConsumerState<GoalSelectionScreen> {
  GoalOption? selectedGoal = GoalOption.loseWeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFE8EFCF),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                Padding(
                  padding: const EdgeInsets.only(left: 19, top: 31),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.chevron_left,
                      size: 40,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ),

                const SizedBox(height: 37),

                const Padding(
                  padding: EdgeInsets.only(left: 33),
                  child: Text(
                    'เป้าหมายของคุณคืออะไร?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  child: Text(
                    'เลือกเป้าหมายเพื่อให้เราช่วยวางแผนที่เหมาะสม',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 67),

                // Goal Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Column(
                    children: [
                      _buildGoalOption(
                        goal: GoalOption.loseWeight,
                        title: 'ลดน้ำหนัก',
                        subtitle: 'ควบคุมแคลอรี่',
                        iconUrl: 'https://api.builder.io/api/v1/image/assets/TEMP/2b36cbc83f6282347dd67152d454841cc595df15',
                        defaultGradient: const LinearGradient(colors: [Colors.white, Colors.white]),
                        selectedGradient: const LinearGradient(colors: [Color(0xFFDBA979), Color(0xFFD76A3C)]),
                      ),
                      const SizedBox(height: 36),
                      _buildGoalOption(
                        goal: GoalOption.maintainWeight,
                        title: 'รักษาน้ำหนัก',
                        subtitle: 'รักษาสมดุล สุขภาพดี',
                        iconUrl: 'https://api.builder.io/api/v1/image/assets/TEMP/caa3690bf64691cf18159ea72b5ec46944c37e66',
                        defaultGradient: const LinearGradient(colors: [Colors.white, Colors.white]),
                        selectedGradient: const LinearGradient(
                          colors: [Color(0xFF10337F), Color(0xFF2D58B6), Color(0xFF497CEA)],
                          stops: [0.0, 0.36, 1.0],
                        ),
                      ),
                      const SizedBox(height: 36),
                      _buildGoalOption(
                        goal: GoalOption.buildMuscle,
                        title: 'เพิ่มกล้ามเนื้อ',
                        subtitle: 'ลดไขมัน',
                        iconUrl: 'https://api.builder.io/api/v1/image/assets/TEMP/3ac072bc08b89b53ec34785b4a25b0021535bdd8',
                        defaultGradient: const LinearGradient(colors: [Colors.white, Colors.white]),
                        selectedGradient: const LinearGradient(
                          colors: [Color(0xFFB4AC15), Color(0xFFFFEA4B), Color(0xFFFAFC83)],
                          stops: [0.0, 0.63, 1.0],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- ปุ่มถัดไป ---
                Center(
                  child: GestureDetector(
                    onTap: () {
                      if (selectedGoal != null) {
                        // 1. บันทึกข้อมูลลง Provider (ถังกลาง)
                        // หมายเหตุ: ต้องไปเพิ่มฟังก์ชัน setGoal ใน UserDataNotifier ก่อนนะ
                        // ถ้ายังไม่ได้เพิ่ม ให้ comment บรรทัดข้างล่างนี้ไว้ก่อน
                         ref.read(userDataProvider.notifier).setGoal(selectedGoal!); 

                        // 2. ไปหน้าถัดไป (ส่งค่า goal ไปด้วยเพื่อใช้แสดงผล UI)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TargetWeightScreen(
                              selectedGoal: selectedGoal!,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 259,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4C6414),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'ถัดไป',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalOption({
    required GoalOption goal,
    required String title,
    required String subtitle,
    required String iconUrl,
    required LinearGradient defaultGradient,
    required LinearGradient selectedGradient,
  }) {
    final bool isSelected = selectedGoal == goal;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGoal = goal;
        });
      },
      child: Container(
        width: 356,
        height: 116,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: isSelected ? selectedGradient : defaultGradient,
          boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 29,
              top: 29,
              child: Container(
                width: 59,
                height: 58,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Center(
                  child: Image.network(
                    iconUrl,
                    width: 43, height: 43, fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.fitness_center, size: 43),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 108,
              top: 39,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w300, color: isSelected ? Colors.white : Colors.black)),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                right: 19, top: 41,
                child: Container(
                  width: 35, height: 35,
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 29),
                ),
              ),
          ],
        ),
      ),
    );
  }
}