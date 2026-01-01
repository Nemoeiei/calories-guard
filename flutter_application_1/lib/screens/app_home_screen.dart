import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';

class AppHomeScreen extends ConsumerStatefulWidget {
  const AppHomeScreen({super.key});

  @override
  ConsumerState<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends ConsumerState<AppHomeScreen> {
  // --- Helper: คำนวณ BMI ---
  double calculateBMI(double weight, double heightInput) {
    if (heightInput <= 0) return 0;
    double heightM = (heightInput < 3.0) ? heightInput : heightInput / 100;
    return weight / (heightM * heightM);
  }

  // --- Helper: แปลผล BMI ---
  String getBMIStatus(double bmi) {
    if (bmi <= 0) return '-';
    if (bmi < 18.5) return 'น้ำหนักน้อย';
    if (bmi < 22.9) return 'ปกติ';
    if (bmi < 24.9) return 'ท้วม';
    if (bmi < 29.9) return 'อ้วน';
    return 'อ้วนมาก';
  }

  // --- Widget: แถบสารอาหาร (Nutrient Label) ---
  Widget _buildNutrientLabel(String label, int current, int total, String imagePath) { // 1. เปลี่ยนชื่อตัวแปรให้สื่อความหมาย (optional)
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 25, height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    // 2. 🔥 แก้ตรงนี้: เปลี่ยนจาก NetworkImage เป็น AssetImage
                    image: AssetImage(imagePath), 
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                width: 140,
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF979797).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 140 * (current / total).clamp(0.0, 1.0),
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1B1F).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${current}g',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                Text('${total}g',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);

    int targetCal = userData.targetCalories.toInt();
    if (targetCal < 0) targetCal = 1500;

    int currentCal = userData.consumedCalories;
    double progress = (targetCal > 0) ? currentCal / targetCal : 0.0;

    double bmi = calculateBMI(userData.weight, userData.height);
    String bmiStatus = getBMIStatus(bmi);

    double weightDiff = (userData.weight - userData.targetWeight).abs();
    String weightAction = (userData.weight > userData.targetWeight)
        ? "ต้องลดอีก"
        : "ต้องเพิ่มอีก";

    return Scaffold(
      backgroundColor: Colors.white,

      // เนื้อหา Scrollable
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. ✅ กล่องสีขาวคั่น (Gap) ตามที่ขอ
            Container(
              height: 40,
              color: Colors.white,
            ),

            // --- Dashboard (วงกลมแคลอรี่) ---
            Container(
              height: 250,
              width: double.infinity,
              color: const Color(0xFFE8EFCF),
              child: Stack(
                children: [
                  // วงกลม
                  Positioned(
                    left: 21,
                    top: 18,
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 12,
                                color: const Color(0xFF8BAE66)),
                          ),
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                strokeWidth: 12,
                                color: const Color(0xFF628141),
                                strokeCap: StrokeCap.round),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$currentCal',
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 48,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                      height: 1)),
                              Text('/ $targetCal KCAL',
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // สารอาหาร (ตำแหน่งตาม CSS เดิม)
                  Positioned(
                      left: 226,
                      top: 41,
                      child: _buildNutrientLabel(
                          'โปรตีน',
                          userData.consumedProtein,
                          111,
                          'assets/images/icon/meat.png')),
                  Positioned(
                      left: 226,
                      top: 102,
                      child: _buildNutrientLabel(
                          'คาร์บ',
                          userData.consumedCarbs,
                          104,
                          'assets/images/icon/rice.png')),
                  Positioned(
                      left: 226,
                      top: 166,
                      child: _buildNutrientLabel(
                          'ไขมัน',
                          userData.consumedFat,
                          41,
                          'assets/images/icon/oil.png')),
                ],
              ),
            ),
            Container(
              height: 20,
              color: Colors.white,
            ),
            // --- Stats Row (น้ำหนัก, BMI, ความคืบหน้า) ---
            SizedBox(
              height: 119,
              width: double.infinity,
              child: Row(
                children: [
                  // กล่อง 1: เป้าหมายน้ำหนัก (สีส้ม)
                  Container(
                    width: 159,
                    color: const Color(0xFFDBA979),
                    child: Stack(
                      children: [
                        // 2. ✅ กรอบ Label สี E8EFCF สำหรับคำว่า "เป้าหมายน้ำหนักตัว"
                        Positioned(
                          left: 7,
                          top: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFE8EFCF), // สีพื้นหลังตามที่ขอ
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text('เป้าหมายน้ำหนักตัว',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black)),
                          ),
                        ),
                        // น้ำหนักปัจจุบัน (ตัวเลขใหญ่)
                        Positioned(
                          left: 29,
                          top: 38,
                          child: Text('${userData.weight.toInt()}',
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w500)),
                        ),
                        // / เป้าหมาย (ตัวเลขเล็ก)
                        Positioned(
                          left: 72,
                          top: 52,
                          child: Row(
                            children: [
                              const Text('/',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(width: 4),
                              Text('${userData.targetWeight.toInt()} กก.',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black.withOpacity(0.7))),
                            ],
                          ),
                        ),
                        // 3. ✅ ข้อความ "เหลือ..." เป็นสีแดง
                        Positioned(
                          left: 30,
                          top: 92,
                          child: Text(
                            'เหลือ ${weightDiff.toStringAsFixed(1)} กก.',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFB74D4D), // สีแดง
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // กล่อง 2 & 3: BMI และ Progress
                  Expanded(
                    child: Container(
                      color: const Color(0xFFECCA9C),
                      child: Row(
                        children: [
                          // กล่อง BMI
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('BMI ${bmi.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 7),
                                Text(bmiStatus,
                                    style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 7),
                                // 3. ✅ กล่อง "ต้องลดอีก..." ตัวหนังสือสีแดง
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 0),
                                  color: Colors.white,
                                  child: Text(
                                    '$weightAction ${weightDiff.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFB74D4D), // สีแดง
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Container(
                              width: 1,
                              height: 119,
                              color: Colors.white.withOpacity(0.3)),
                          // กล่อง Progress
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('30%',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 7),
                                const Text('ความคืบหน้า',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 7),
                                // 3. ✅ กล่อง "เหลืออีก..." ตัวหนังสือสีแดง
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 0),
                                  color: Colors.white,
                                  child: const Text(
                                    'เหลืออีก 70%',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFB74D4D), // สีแดง
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 4. ✅ ปรับกล่องมื้ออาหาร (ตาม CSS: หัวข้ออยู่นอกกรอบ + กรอบเขียว) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวข้อ (อยู่นอกกรอบ)
                  const Text('มื้ออาหารที่ทานวันนี้',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black)),

                  const SizedBox(height: 10),

                  // กรอบรายการอาหาร
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFF4C6414),
                          width: 1), // ขอบสีเขียวเข้ม
                      borderRadius: BorderRadius.circular(10), // มน 10px
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'มื้อเช้า : ${userData.breakfastMenu.isEmpty ? '-' : userData.breakfastMenu}',
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text(
                            'อาหารว่าง : ${userData.snackMenu.isEmpty ? '-' : userData.snackMenu}',
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text(
                            'มื้อเที่ยง : ${userData.lunchMenu.isEmpty ? '-' : userData.lunchMenu}',
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text(
                            'มื้อเย็น : ${userData.dinnerMenu.isEmpty ? '-' : userData.dinnerMenu}',
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100), // พื้นที่เผื่อ Bottom Bar
          ],
        ),
      ),
    );
  }
}
