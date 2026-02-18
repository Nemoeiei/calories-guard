import 'package:flutter/material.dart';
import '../macro/macro_detail_screen.dart'; // ตรวจสอบ path นี้ให้ถูกต้องตามโปรเจกต์ของคุณ

class RecommendedFoodScreen extends StatefulWidget {
  const RecommendedFoodScreen({super.key});

  @override
  State<RecommendedFoodScreen> createState() => _RecommendedFoodScreenState();
}

class _RecommendedFoodScreenState extends State<RecommendedFoodScreen> {
  int _foodFilterIndex = 0;
  int _drinkFilterIndex = 0;
  int _dessertFilterIndex = 0;

  // --- ข้อมูลจำลอง (Mock Data) ---
  static const List<Map<String, String>> _foodMenu = [
    {'name': 'เมนู หมูพันเห็ดเข็มของคลีน โปรตีน 30 กรัม', 'sub': '120–150 kcal', 'image': 'assets/images/food/หมูพันเห็ดเข็มของคลีน.png'},
    {'name': 'เมนู ผักหมูลวกจิ้มคลีน โปรตีน 20 กรัม', 'sub': '180–220 kcal', 'image': 'assets/images/food/ผักหมูลวกจิ้มคลีน.png'},
    {'name': 'เมนู ข้าวผัดน้ำพริกกะปิ คาร์โบไฮเดรต 50 กรัม', 'sub': '450–550 kcal', 'image': 'assets/images/food/ข้าวผัดน้ำพริกกะปิ.png'},
    {'name': 'เมนู ข้าวผัดตับบด โปรตีน 45 กรัม', 'sub': '380–450 kcal', 'image': 'assets/images/food/ข้าวผัดตับบด.png'},
    {'name': 'เมนู สลัดอโวคะโดไข่ ไขมัน 20 กรัม', 'sub': '250–300 kcal', 'image': 'assets/images/food/สลัดอโวคะโดไข่.png'},
    {'name': 'เมนู ฟักทองผัดไข่ โปรตีน 45 กรัม', 'sub': '200–250 kcal', 'image': 'assets/images/food/ฟักทองผัดไข่.png'},
  ];

  static const List<Map<String, String>> _drinkMenu = [
    {'name': 'เมนู นํ้ามะม่วงสมูทตี้ 180–250 kcal', 'sub': '', 'image': 'assets/images/food/นํ้ามะม่วงสมูทตี้.png'},
    {'name': 'เมนู นํ้าสตอเบอรี่สมูทตี้ 140–200 kcal', 'sub': '', 'image': 'assets/images/food/นํ้าสตอเบอรี่สมูทตี้.png'},
    {'name': 'เมนู มัจฉะลาเต้ 180–250 kcal', 'sub': '', 'image': 'assets/images/food/มัจฉะลาเต้.png'},
    {'name': 'เมนู มัจฉะลาเต้สตอเบอรี่ 220–300 kcal', 'sub': '', 'image': 'assets/images/food/มัจฉะลาเต้สตอเบอรี่.png'},
  ];

  static const List<Map<String, String>> _dessertMenu = [
    {'name': 'เมนู เค้กกล้วยหอม 180–250 kcal', 'sub': '', 'image': 'assets/images/food/เค้กกล้วยหอม.png'},
    {'name': 'เมนู เค้กไข่ใต้หวัน 140–200 kcal', 'sub': '', 'image': 'assets/images/food/เค้กไข่ใต้หวัน.png'},
    {'name': 'เมนู ชูครีม 180–250 kcal', 'sub': '', 'image': 'assets/images/food/ชูครีม.png'},
    {'name': 'เมนู เค้กมันม่วง 220–300 kcal', 'sub': '', 'image': 'assets/images/food/เค้กมันม่วง.png'},
  ];

  // รายการแสดงในส่วนโภชนาการแบบรูป (โปรตีน 2, คาร์บ 2, ไขมัน 2)
  static const List<Map<String, String>> _macroProteinItems = [
    {'name': 'เมนู หมูพันเห็ดเข็มของคลีน โปรตีน 30 กรัม', 'image': 'assets/images/food/หมูพันเห็ดเข็มของคลีน.png'},
    {'name': 'เมนู ผักหมูลวกจิ้มคลีน โปรตีน 20 กรัม', 'image': 'assets/images/food/ผักหมูลวกจิ้มคลีน.png'},
  ];
  static const List<Map<String, String>> _macroCarbsItems = [
    {'name': 'เมนู ข้าวผัดน้ำพริกกะปิ คาร์โบไฮเดรต 50 กรัม', 'image': 'assets/images/food/ข้าวผัดน้ำพริกกะปิ.png'},
    {'name': 'เมนู ข้าวผัดตับบด โปรตีน 45 กรัม', 'image': 'assets/images/food/ข้าวผัดตับบด.png'},
  ];
  static const List<Map<String, String>> _macroFatItems = [
    {'name': 'เมนู สลัดอโวคะโดไข่ ไขมัน 20 กรัม', 'image': 'assets/images/food/สลัดอโวคะโดไข่.png'},
    {'name': 'เมนู ฟักทองผัดไข่ โปรตีน 45 กรัม', 'image': 'assets/images/food/ฟักทองผัดไข่.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ---------- 2) ช่อง search หาอาหาร ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Container(
                  height: 43,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ค้นหาอาหาร',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w100,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      Icon(Icons.search, size: 24, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ---------- 3) โภชนาการ (ดีไซน์ใหม่: แคปซูล + การ์ดลอย + ปุ่มเท่ากัน) ----------
              
              const SizedBox(height: 12),
              
              _buildMacroBlockNew(context, 'อาหารประเภทโปรตีน', 'protein', _macroProteinItems),
              const SizedBox(height: 20),
              _buildMacroBlockNew(context, 'อาหารประเภทคาร์โบไฮเดรต', 'carbs', _macroCarbsItems),
              const SizedBox(height: 20),
              _buildMacroBlockNew(context, 'อาหารประเภทไขมัน', 'fat', _macroFatItems),
              
              const SizedBox(height: 32),

              // ---------- 4) แถบสีแดง แนะนำสำหรับคุณ ----------
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: const Color(0xFFD76A3C),
                alignment: Alignment.center,
                child: const Text(
                  'แนะนำสำหรับคุณ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ---------- 5) อาหาร, เครื่องดื่ม, ของหวาน ----------
              _buildSectionHeader('แนะนำอาหารสำหรับคุณ'),
              _buildFilterChips(
                labels: const ['ทั้งหมด', 'อาหารทั่วไป', 'อาหารคลีน'],
                selectedIndex: _foodFilterIndex,
                onTap: (i) => setState(() => _foodFilterIndex = i),
              ),
              _buildGrid(_foodMenu),
              _buildSeeMoreButton(),

              _buildSectionHeader('แนะนำเครื่องดื่มสำหรับคุณ'),
              _buildFilterChips(
                labels: const ['ทั้งหมด', 'น้ำผักผลไม้', 'ชา', 'กาแฟ'],
                selectedIndex: _drinkFilterIndex,
                onTap: (i) => setState(() => _drinkFilterIndex = i),
              ),
              _buildGrid(_drinkMenu),
              _buildSeeMoreButton(),

              _buildSectionHeader('แนะนำของหวานสำหรับคุณ'),
              _buildFilterChips(
                labels: const ['ทั้งหมด', 'เบเกอรี่', 'ขนมไทย', 'ขนมคลีน'],
                selectedIndex: _dessertFilterIndex,
                onTap: (i) => setState(() => _dessertFilterIndex = i),
              ),
              _buildGrid(_dessertMenu),
              _buildSeeMoreButton(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // ส่วนที่ปรับแก้ใหม่ (New UI Implementation with Fixed Alignment)
  // =========================================================================

  /// บล็อกโภชนาการดีไซน์ใหม่: ใช้ IntrinsicHeight เพื่อให้การ์ดสูงเท่ากัน
  Widget _buildMacroBlockNew(
    BuildContext context,
    String title,
    String macroType,
    List<Map<String, String>> items,
  ) {
    const lightGreen = Color(0xFFE8EFCF); // สีพื้นหลังบล็อก
    const darkGreen = Color(0xFF628141);  // สีปุ่ม >

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- หัวข้อแบบแคปซูล (Capsule Header) ---
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MacroDetailScreen(macroType: macroType),
                ),
              );
            },
            child: IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: darkGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // --- รายการอาหาร 2 อย่าง (Row) ---
          // ใช้ IntrinsicHeight + CrossAxisAlignment.stretch เพื่อให้สูงเท่ากัน
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < items.length && i < 2; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Expanded(child: _buildMacroCardNew(items[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// การ์ดอาหารดีไซน์ใหม่: ใช้ Spacer ดันปุ่มลงล่างสุด
  Widget _buildMacroCardNew(Map<String, String> item) {
    final rawName = item['name'] ?? '';
    final imagePath = item['image'];
    
    // Logic ตัดคำเพื่อแยกชื่อเมนู กับ ข้อมูลโภชนาการ
    String foodName = rawName;
    String nutrientInfo = 'ข้อมูลโภชนาการ';

    if (foodName.startsWith('เมนู ')) {
      foodName = foodName.replaceFirst('เมนู ', '');
    }

    if (foodName.contains('โปรตีน')) {
      final parts = foodName.split('โปรตีน');
      foodName = parts[0].trim();
      if (parts.length > 1) nutrientInfo = 'โปรตีน ${parts[1].trim()}';
    } else if (foodName.contains('คาร์โบไฮเดรต')) {
      final parts = foodName.split('คาร์โบไฮเดรต');
      foodName = parts[0].trim();
      if (parts.length > 1) nutrientInfo = 'คาร์โบไฮเดรต ${parts[1].trim()}';
    } else if (foodName.contains('ไขมัน')) {
      final parts = foodName.split('ไขมัน');
      foodName = parts[0].trim();
      if (parts.length > 1) nutrientInfo = 'ไขมัน ${parts[1].trim()}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // รูปภาพ
        AspectRatio(
          aspectRatio: 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: imagePath != null && imagePath.isNotEmpty
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
        ),
        const SizedBox(height: 12),
        
        // ชื่อเมนู (ตัวหนา)
        Text(
          'เมนู $foodName',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        // ข้อมูลโภชนาการ (สีเทา)
        Text(
          nutrientInfo,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),

        // --- ใช้ Spacer เพื่อดันปุ่มลงไปติดขอบล่าง ---
        const Spacer(),
        const SizedBox(height: 10),

        // ปุ่มวิธีการทำ (สีเขียว มีเงา)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFAFD198),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Text(
            'วิธีการทำ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // ส่วนประกอบเดิม (Helpers) ที่ยังใช้อยู่
  // =========================================================================

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFF628141),
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFilterChips({
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onTap,
  }) {
    return Padding(
      // Padding top = 24 เพื่อเว้นระยะจาก Header
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 10), 
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(labels.length, (i) {
            final isSelected = i == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFAFD198) : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: isSelected ? null : Border.all(color: const Color(0xFF4C6414)),
                    ),
                    child: Text(
                      labels[i],
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildGrid(List<Map<String, String>> items) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8EFCF),
      padding: const EdgeInsets.fromLTRB(25, 14, 25, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 23,
          mainAxisSpacing: 21,
          childAspectRatio: 0.62,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildCard(items[index]),
      ),
    );
  }

  Widget _buildCard(Map<String, String> item) {
    final imagePath = item['image'];
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 160,
            height: 160,
            child: hasImage
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item['name']!,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if ((item['sub'] ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item['sub']!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFAFD198),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'วิธีการทำ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.restaurant, color: Colors.grey[500], size: 48),
    );
  }

  Widget _buildSeeMoreButton() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8EFCF),
      padding: const EdgeInsets.only(right: 25, top: 12, bottom: 20),
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF628141),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'ดูเพิ่มเติม',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}