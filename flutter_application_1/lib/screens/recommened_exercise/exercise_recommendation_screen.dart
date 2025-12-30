import 'package:flutter/material.dart';

class ExerciseRecommendationScreen extends StatefulWidget {
  const ExerciseRecommendationScreen({super.key});

  @override
  State<ExerciseRecommendationScreen> createState() =>
      _ExerciseRecommendationScreenState();
}

class _ExerciseRecommendationScreenState
    extends State<ExerciseRecommendationScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 36), // SafeArea Top

            // --- Header (แก้ไข: ลบปุ่มกลับ + จัดกึ่งกลาง) ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                child: Text(
                  'แนะนำการออกกำลังกาย',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- 2. Section 1 ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: const Color(0xFF628141),
              child: const Center(
                child: Text(
                  'ออกกำลังกายอย่างไรดี ?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 195,
                    height: 243,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://i.pinimg.com/564x/27/f0/29/27f02967650570530500705296276067.jpg'), 
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    width: 190,
                    height: 243,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://i.pinimg.com/564x/8a/0a/60/8a0a6007050509070908090000000000.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(right: 20, top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFAFD198),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'เพิ่มเติม',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- 3. Section 2 ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: const Color(0xFF628141),
              child: const Center(
                child: Text(
                  'วิดีโอสอนออกกำลังกาย',
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
              width: double.infinity,
              height: 200,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ออกกำลัง 20 นาที ตามคลิปนี้แค่วันละครั้ง!!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: NetworkImage(
                              'https://img.youtube.com/vi/3p8EBPVZ2Iw/maxresdefault.jpg'), 
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.play_circle_fill,
                            color: Colors.white.withOpacity(0.8), size: 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.chevron_left, size: 30, color: Colors.black54),
                  Icon(Icons.chevron_right, size: 30, color: Colors.black54),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}