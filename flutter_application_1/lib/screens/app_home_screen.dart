import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';

import 'profile/profile_screen.dart'; 
import 'profile/subprofile_screen/setting_screen.dart';
import 'profile/subprofile_screen/article_screen.dart';

class AppHomeScreen extends ConsumerStatefulWidget {
  const AppHomeScreen({super.key});

  @override
  ConsumerState<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends ConsumerState<AppHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black12,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: 80, right: 20,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 280,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNotificationItem("คุณลืมกรอกข้อมูล “มื้อกลางวัน”"),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      _buildNotificationItem("เย้ !!! น้ำหนักคุณลดไปแล้ว 1 กิโลกรัม"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.black))),
        ],
      ),
    );
  }

  double calculateBMI(double weight, double heightCm) {
    if (heightCm == 0) return 0;
    double heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  String getBMIStatus(double bmi) {
    if (bmi < 18.5) return 'น้ำหนักน้อย';
    if (bmi < 22.9) return 'ปกติ';
    if (bmi < 24.9) return 'ท้วม';
    if (bmi < 29.9) return 'อ้วน';
    return 'อ้วนมาก';
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);

    int targetCal = userData.targetCalories.toInt();
    int currentCal = userData.consumedCalories; // ค่าจริง
    double progress = (targetCal > 0) ? currentCal / targetCal : 0.0;

    double bmi = calculateBMI(userData.weight, userData.height);
    String bmiStatus = getBMIStatus(bmi);
    
    double weightDiff = (userData.weight - userData.targetWeight).abs();
    String weightAction = (userData.weight > userData.targetWeight) ? "ต้องลดอีก" : "ต้องเพิ่มอีก";

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: Drawer(
        width: 250,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            SafeArea(
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            const Divider(height: 1, color: Colors.black),
            _buildDrawerItem(Icons.person_outline, "โปรไฟล์", onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            }),
            const Divider(height: 1, color: Colors.black),
            _buildDrawerItem(Icons.settings_outlined, "ตั้งค่า", onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }),
            const Divider(height: 1, color: Colors.black),
            _buildDrawerItem(Icons.article_outlined, "บทความ", onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ArticleScreen()));
            }),
            const Divider(height: 1, color: Colors.black),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 98,
            color: const Color(0xFF628141),
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/icon/icon.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Calorie', style: TextStyle(fontFamily: 'Itim', fontSize: 16, color: Color(0xFFE8EFCF), height: 1)),
                    Text('Guard', style: TextStyle(fontFamily: 'Karla', fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white, height: 1)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showNotifications(context),
                  icon: const Icon(Icons.notifications, color: Colors.white, size: 32),
                ),
                IconButton(
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  icon: const Icon(Icons.menu, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 205,
                    color: const Color(0xFFE8EFCF),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
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
                                  color: const Color(0xFF8BAE66),
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: CircularProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  strokeWidth: 12,
                                  color: const Color(0xFF628141),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('$currentCal', style: const TextStyle(fontFamily: 'Inter', fontSize: 48, fontWeight: FontWeight.w500, color: Colors.black, height: 1)),
                                  Text('/ $targetCal KCAL', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildNutrientRow("โปรตีน", userData.consumedProtein, 111, "https://cdn-icons-png.flaticon.com/512/1046/1046751.png", Colors.redAccent),
                              const SizedBox(height: 15),
                              _buildNutrientRow("คาร์บ", userData.consumedCarbs, 104, "https://cdn-icons-png.flaticon.com/512/2619/2619567.png", Colors.blueAccent),
                              const SizedBox(height: 15),
                              _buildNutrientRow("ไขมัน", userData.consumedFat, 41, "https://cdn-icons-png.flaticon.com/512/2553/2553591.png", Colors.amber),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 119,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Container(
                            color: const Color(0xFFDBA979),
                            padding: const EdgeInsets.only(left: 20, top: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('เป้าหมายน้ำหนักตัว', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 5),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text('${userData.targetWeight.toInt()}', style: const TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 4),
                                    const Text('/', style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
                                    const SizedBox(width: 4),
                                    Text('${userData.weight.toInt()} กก.', style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.black.withOpacity(0.7))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('เหลือ ${weightDiff.toStringAsFixed(1)} กก.', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            color: const Color(0xFFECCA9C),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('BMI ${bmi.toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(bmiStatus, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                                  child: Text('$weightAction ${weightDiff.toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.black)),
                                )
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFECCA9C),
                              border: Border(left: BorderSide(color: Colors.white30, width: 1)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('30%', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                const Text('ความคืบหน้า', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('เหลืออีก 70%', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.black)),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🔥 ส่วนรายการอาหาร (ดึงค่าจริงจาก userData)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: const Text('มื้ออาหารที่ทานวันนี้', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('มื้อเช้า : ${userData.breakfastMenu.isEmpty ? '-' : userData.breakfastMenu}', 
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Text('อาหารว่าง : ${userData.snackMenu.isEmpty ? '-' : userData.snackMenu}', 
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Text('มื้อเที่ยง : ${userData.lunchMenu.isEmpty ? '-' : userData.lunchMenu}', 
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              // อาหารว่างมี 2 ช่องในหน้าบันทึก แต่ผมรวมเป็น string เดียวใน provider เพื่อความง่าย
                              // ถ้าอยากโชว์แยก ต้องแก้ provider ให้เก็บ snack1, snack2 แยกกัน
                              // อันนี้ใช้ค่าเดิมไปก่อน
                              const Text('อาหารว่าง : -', 
                                style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)), 
                              const SizedBox(height: 8),
                              Text('มื้อเย็น : ${userData.dinnerMenu.isEmpty ? '-' : userData.dinnerMenu}', 
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
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
    );
  }

  Widget _buildNutrientRow(String label, int current, int total, String iconUrl, Color progressColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: NetworkImage(iconUrl), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFF979797).withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                  ),
                  FractionallySizedBox(
                    widthFactor: (current / total).clamp(0.0, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(color: const Color(0xFF1C1B1F).withOpacity(0.8), borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${current}g', style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                  Text('${total}g', style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black, size: 30),
      title: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black)),
      onTap: onTap,
    );
  }
}