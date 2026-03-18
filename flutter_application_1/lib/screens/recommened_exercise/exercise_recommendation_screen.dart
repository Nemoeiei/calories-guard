import 'package:flutter/material.dart';

class ExerciseRecommendationScreen extends StatefulWidget {
  const ExerciseRecommendationScreen({super.key});

  @override
  State<ExerciseRecommendationScreen> createState() =>
      _ExerciseRecommendationScreenState();
}

class _ExerciseRecommendationScreenState
    extends State<ExerciseRecommendationScreen> {
  
  // ข้อมูลวิดีโอจำลอง (ตาม Text ใน CSS)
  final List<Map<String, String>> _videoList = [
    {
      'title': 'ออกกำลัง 20 นาที ตามคลิปนี้แค่วันละครั้ง!!',
      'image': 'assets/images/exercise/video_cardio_20min.png', 
    },
    {
      'title': 'ออกกำลังกาย ลดพุงท่ายืน 15 นาที',
      'image': 'assets/images/exercise/ex_belly.png', 
    },
    {
      'title': '25นาที cardioลดไขมัน ไม่กระทบเข่า',
      'image': 'assets/images/exercise/ex_cardio.png', 
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังหลักเป็นสีขาว (สำหรับส่วนบน)
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            // ==========================================
            // ส่วนที่ 1: Infographics (พื้นหลังขาว)
            // ==========================================
            
            // Header 1
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: const Color(0xFF628141),
              alignment: Alignment.center,
              child: const Text(
                'ออกกำลังกายอย่างไรดี ?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // รูปภาพ Infographics 2 รูป
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // รูปซ้าย (คนอ้วน)
                  Container(
                    width: 170, 
                    height: 243,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: const DecorationImage(
                        // หมายเหตุ: ถ้าภาพไม่ขึ้น แนะนำให้เปลี่ยนเป็น AssetImage ที่อยู่ในเครื่อง
                        image: AssetImage('assets/images/exercise/exercise1.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // รูปขวา (ตาราง)
                  Container(
                    width: 170,
                    height: 243,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: const DecorationImage(
                        // หมายเหตุ: ถ้าภาพไม่ขึ้น แนะนำให้เปลี่ยนเป็น AssetImage ที่อยู่ในเครื่อง
                        image: AssetImage('assets/images/exercise/exercise2.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ปุ่ม "เพิ่มเติม" (สีเขียวอ่อน)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(right: 25, top: 15, bottom: 25),
                width: 65,
                height: 25,
                decoration: BoxDecoration(
                  color: const Color(0xFFAFD198),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'เพิ่มเติม',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            // ==========================================
            // ส่วนที่ 2: วิดีโอ (พื้นหลังเขียวอ่อน)
            // ==========================================
            Container(
              color: const Color(0xFFE8EFCF), // เปลี่ยนพื้นหลังส่วนล่าง
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 120), // เผื่อพื้นที่ด้านล่าง
              child: Column(
                children: [
                  // Header 2
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: const Color(0xFF628141),
                    alignment: Alignment.center,
                    child: const Text(
                      'วิดีโอสอนออกกำลังกาย',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // รายการวิดีโอ
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // ให้ Scroll ไปกับ Parent
                    itemCount: _videoList.length,
                    itemBuilder: (context, index) {
                      return _buildVideoCard(_videoList[index]);
                    },
                  ),

                  // ปุ่ม "ดูเพิ่มเติม" (สีเขียวเข้ม)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(right: 25, top: 10),
                      width: 60,
                      height: 20, // ตาม CSS: 20px
                      decoration: BoxDecoration(
                        color: const Color(0xFF628141),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'ดูเพิ่มเติม',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget: การ์ดวิดีโอ
  Widget _buildVideoCard(Map<String, String> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30), // ระยะห่างระหว่างคลิป
      child: Column(
        children: [
          // ชื่อคลิป (อยู่ด้านบน)
          Text(
            item['title']!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          
          // ภาพปกคลิป (ขนาดตาม CSS ประมาณ 186x103)
          Container(
            width: 250, // ปรับให้กว้างขึ้นนิดนึงเพื่อให้เห็นชัดเจน (CSS เขียน 186 อาจจะเล็กไปสำหรับมือถือยุคนี้)
            height: 140, 
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(item['image']!), 
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // ไอคอน Play ตรงกลาง
            child: Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white.withOpacity(0.9),
                size: 50,
              ),
            ),
          ),
        ],
      ),
    );
  }
}