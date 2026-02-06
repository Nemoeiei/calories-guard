import 'package:flutter/material.dart';
import '../../services/recommendation_service.dart';

class RecommendedFoodScreen extends StatefulWidget {
  const RecommendedFoodScreen({super.key});

  @override
  State<RecommendedFoodScreen> createState() => _RecommendedFoodScreenState();
}

class _RecommendedFoodScreenState extends State<RecommendedFoodScreen> {
  List<Map<String, String>> _foodMenu = [];
  List<Map<String, String>> _drinkMenu = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    final service = RecommendationService();
    final foods = await service.getRecommendedFoods();
    final drinks = await service.getRecommendedDrinks();

    if (mounted) {
      setState(() {
        if (foods != null) _foodMenu = foods;
        if (drinks != null) _drinkMenu = drinks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.only(top: 100), child: CircularProgressIndicator()))
            : Column(
          children: [
            const SizedBox(height: 30),

            _buildSectionHeader('แนะนำอาหารสำหรับคุณ'),
            const SizedBox(height: 15),
            
            _buildCategoryButtons(['ทั้งหมด', 'อาหารทั่วไป', 'อาหารคลีน']),
            const SizedBox(height: 15),

            _buildGridMenu(_foodMenu),
            
            _buildSeeMoreButton(),

            const SizedBox(height: 30),

            _buildSectionHeader('แนะนำเครื่องดื่มสำหรับคุณ'),
            const SizedBox(height: 15),

            _buildCategoryButtons(['ทั้งหมด', 'น้ำผักผลไม้', 'ชา', 'กาแฟ']),
            const SizedBox(height: 15),

            _buildGridMenu(_drinkMenu),

            _buildSeeMoreButton(),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // ... (Widget Header และ CategoryButtons เหมือนเดิม) ...
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      height: 34,
      color: const Color(0xFF628141),
      alignment: Alignment.center,
      child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white)),
    );
  }

  Widget _buildCategoryButtons(List<String> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: categories.map((text) {
          bool isFirst = text == categories.first;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFirst ? const Color(0xFFAFD198) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isFirst ? null : Border.all(color: const Color(0xFF4C6414)),
            ),
            child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridMenu(List<Map<String, String>> menuList) {
    return Container(
      color: const Color(0xFFE8EFCF),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 23,
          mainAxisSpacing: 21,
          childAspectRatio: 0.60, // 👈 ปรับสัดส่วนให้ยาวขึ้นนิดนึง เพื่อรองรับ 2 บรรทัด
        ),
        itemCount: menuList.length,
        itemBuilder: (context, index) {
          return _buildMenuCard(menuList[index]);
        },
      ),
    );
  }

  // --- 2. ✅ แก้ไข Widget การ์ดเมนู ให้แสดง 2 บรรทัด ---
  Widget _buildMenuCard(Map<String, String> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // รูปภาพ
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: AssetImage(item['image']!), 
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // ชื่อเมนู (บรรทัดที่ 1)
        Text(
          item['name']!,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600, // หนาหน่อย
            color: Colors.black,
            height: 1.2,
          ),
          maxLines: 1, // บังคับ 1 บรรทัด
          overflow: TextOverflow.ellipsis,
        ),
        
        // แคลอรี่ (บรรทัดที่ 2)
        Text(
          item['cal']!,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12, // เล็กลงนิดนึง
            fontWeight: FontWeight.w400,
            color: Color(0xFF4C6414), // ใส่สีเขียวให้ดูเด่นขึ้น (หรือใช้สีดำก็ได้)
          ),
        ),
        
        const SizedBox(height: 8),
        
        // ปุ่มวิธีการทำ
        Container(
          width: 71,
          height: 25,
          decoration: BoxDecoration(
            color: const Color(0xFFAFD198),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4)),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('วิธีการทำ', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildSeeMoreButton() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 25, bottom: 20),
      color: const Color(0xFFE8EFCF),
      child: Container(
        width: 60,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF628141),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: const Text('ดูเพิ่มเติม', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
      ),
    );
  }
}