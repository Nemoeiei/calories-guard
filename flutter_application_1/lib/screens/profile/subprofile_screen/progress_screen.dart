import 'package:flutter/material.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // State สำหรับ Toggle Bar (0: น้ำหนัก, 1: โภชนาการ, 2: ความสำเร็จ)
  int _selectedTabIndex = 0;

  // State สำหรับปฏิทิน
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- 1. พื้นหลังสีเขียว (Layer ล่างสุด) ---
          Positioned(
            top: 100, // เริ่มสีเขียวใต้ Header
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: const Color(0xFFAFD198),
            ),
          ),

          // --- 2. เนื้อหาหลัก (Foreground) ---
          Column(
            children: [
              // ==========================================
              // ส่วนที่ 1: Sticky Header (Fixed ด้านบน)
              // ==========================================
              Container(
                color: Colors.white, // พื้นหลังขาวทึบ บัง content เวลาเลื่อน
                padding: const EdgeInsets.only(
                    top: 50, bottom: 15, left: 20, right: 20),
                child: Row(
                  children: [
                    // ปุ่มย้อนกลับ
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 18, color: Colors.black),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'ความคืบหน้า',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Dummy space เพื่อให้ Text กลาง
                  ],
                ),
              ),

              // ==========================================
              // ส่วนที่ 2: Scrollable Content (เลื่อนได้)
              // ==========================================
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // --- 3. Cards แถวบน ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTopCard(
                              title: 'น้ำหนักปัจจุบัน',
                              value: '70',
                              unit: 'กิโลกรัม',
                              icon: Icons.person,
                              iconColor: const Color(0xFF91E47E),
                            ),
                            _buildTopCard(
                              title: 'น้ำหนักเป้าหมาย',
                              value: '60',
                              unit: 'กิโลกรัม',
                              icon: Icons.flag,
                              iconColor: const Color(0xFF465396),
                            ),
                            _buildTopCard(
                              title: 'ความต่อเนื่อง',
                              value: '3',
                              unit: 'วัน',
                              icon: Icons.local_fire_department,
                              iconColor: const Color(0xFFE4A47E),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- 4. Interactive Toggle Bar ---
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 13),
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF628141),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          children: [
                            _buildTabItem(0, 'น้ำหนัก'),
                            _buildTabItem(1, 'โภชนาการ'),
                            _buildTabItem(2, 'ความสำเร็จ'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- 5. Graph Card ---
                      _buildWhiteCard(
                        height: 218,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('เฉลี่ยโภชนาการรายสัปดาห์',
                                style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 12)),
                            Expanded(
                              child: Center(
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      top: 20, bottom: 10, right: 20),
                                  width: double.infinity,
                                  height: 100,
                                  alignment: Alignment.bottomRight,
                                  decoration: BoxDecoration(
                                    border: Border(
                                        left: BorderSide(
                                            color: Colors.grey.shade300),
                                        bottom: BorderSide(
                                            color: Colors.grey.shade300)),
                                  ),
                                  child: Container(
                                    width: 30,
                                    height: 80,
                                    margin: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00C853),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('เฉลี่ยต่อวัน',
                                    style: TextStyle(
                                        fontFamily: 'Inter', fontSize: 12)),
                                Text('0/1250 kcal',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Color(0xFF61D721))),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // --- 6. Dynamic Calendar Card ---
                      _buildWhiteCard(
  height: null, // <--- แก้ตรงนี้: ให้มัน Auto Height ตามเนื้อหา
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
                            const Text('สถิติบันทึกต่อเนื่อง',
                                style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 12)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department,
                                    color: Colors.red, size: 24),
                                const SizedBox(width: 5),
                                const Text('1',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 5),
                                const Text('วัน',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // ตัวเลือกเดือน (Month Selector)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: () {
                                    setState(() {
                                      _currentMonth = DateTime(_currentMonth.year,
                                          _currentMonth.month - 1);
                                    });
                                  },
                                ),
                                Text(
                                  _formatMonthYear(_currentMonth),
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: () {
                                    setState(() {
                                      _currentMonth = DateTime(_currentMonth.year,
                                          _currentMonth.month + 1);
                                    });
                                  },
                                ),
                              ],
                            ),

                            // ตารางปฏิทินจริง
                            _buildRealCalendar(_currentMonth),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- 7. BMI Card ---
                      _buildWhiteCard(
                        height: 130,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('BMI',
                                    style: TextStyle(
                                        fontSize: 12, fontFamily: 'Inter')),
                                const SizedBox(width: 20),
                                const Text('26.0',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0C395)
                                        .withOpacity(0.54),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    'น้ำหนักเกินระดับ 1',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFF29638)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1710ED),
                                        Color(0xFF69AE6D),
                                        Color(0xFFD3D347),
                                        Color(0xFFCAAC58),
                                        Color(0xFFFF0000),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 230,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: Colors.black26),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'ค่า BMI ของคุณแสดงว่าการลดน้ำหนักจะช่วยส่งเสริมสุขภาพของคุณได้ โปรดเลือกเป้าหมายที่ต่ำลง',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40), // Padding ล่างสุด
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widget: ปุ่ม Toggle Bar ---
  Widget _buildTabItem(int index, String title) {
    bool isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13, // ลดขนาดลงนิดนึงกันล้น
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget: สร้างตารางปฏิทินจริง ---
  Widget _buildRealCalendar(DateTime month) {
    // 1. หาจำนวนวันในเดือน
    int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // 2. หาวันแรกของเดือนว่าเป็นวันอะไร (Mon=1, ... Sun=7)
    int firstWeekday = DateTime(month.year, month.month, 1).weekday;

    // สร้าง Header วัน (จ-อา)
    List<Widget> dayHeaders = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา']
        .map((day) => Center(
              child: Text(day,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ))
        .toList();

    // สร้างช่องวันที่
    List<Widget> dayCells = [];

    // เติมช่องว่างก่อนวันที่ 1
    for (int i = 1; i < firstWeekday; i++) {
      dayCells.add(Container());
    }

    // เติมวันที่ 1 ถึงวันสุดท้าย
    for (int day = 1; day <= daysInMonth; day++) {
      bool isToday = day == DateTime.now().day &&
          month.month == DateTime.now().month &&
          month.year == DateTime.now().year;

      dayCells.add(
        Center(
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: isToday ? Colors.green : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday ? null : Border.all(color: Colors.transparent),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: isToday ? Colors.white : Colors.black,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // แถวชื่อวัน
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayHeaders.map((w) => Expanded(child: w)).toList(),
        ),
        const SizedBox(height: 10),
        // ตารางวันที่
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // ไม่ให้ Grid เลื่อนเอง
          children: dayCells,
        ),
      ],
    );
  }

  // Helper function แปลงเดือนเป็นภาษาไทยง่ายๆ (ไม่ต้องลง lib เพิ่ม)
  String _formatMonthYear(DateTime date) {
    List<String> months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return '${months[date.month - 1]} ${date.year + 543}'; // +543 เป็น พ.ศ.
  }

  // --- Helper Widgets เดิม ---
  Widget _buildTopCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 110,
      height: 169,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const Spacer(),
          Text(title,
              style: const TextStyle(
                  fontSize: 12, height: 1.2, fontFamily: 'Inter')),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter')),
          Text(unit,
              style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
        ],
      ),
    );
  }

  // แก้ไขฟังก์ชันนี้
Widget _buildWhiteCard({double? height, required Widget child}) { // เปลี่ยน height เป็น nullable
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 13),
    width: double.infinity,
    // ถ้า height มีค่าก็ใช้ค่านั้น ถ้าไม่มีก็ null (ให้ยืดตาม child)
    height: height, 
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
    ),
    child: child,
  );
}
}