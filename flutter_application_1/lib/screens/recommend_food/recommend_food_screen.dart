import 'package:flutter/material.dart';

class RecommendedFoodScreen extends StatefulWidget {
  const RecommendedFoodScreen({super.key});

  @override
  State<RecommendedFoodScreen> createState() => _RecommendedFoodScreenState();
}

class _RecommendedFoodScreenState extends State<RecommendedFoodScreen> {
  final List<Map<String, String>> _foodMenu = [
    {
      'title': 'เมนู หมูพันเห็ดเข็มทองคลีน',
      'image': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500', 
    },
    {
      'title': 'เมนู ผักหมูลวกจิ้มคลีน',
      'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500',
    },
    {
      'title': 'เมนู ลาบวุ้นเส้นคลีน',
      'image': 'https://images.unsplash.com/photo-1594998893017-3614795c3e45?w=500',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      body: Column(
        children: [
          const SizedBox(height: 36), // SafeArea Top

          // --- Header (แก้ไข: ลบปุ่มกลับ + จัดกึ่งกลาง) ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Center(
              child: Text(
                'แนะนำอาหาร',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- 2. Green Banner ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: const Color(0xFF628141),
            child: const Center(
              child: Text(
                'แนะนำอาหารสำหรับคุณ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // --- 3. รายการอาหาร ---
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 15, right: 15),
              itemCount: _foodMenu.length,
              itemBuilder: (context, index) {
                return _buildFoodCard(_foodMenu[index]);
              },
            ),
          ),

          // --- 4. ปุ่มลูกศร ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Icon(Icons.chevron_left, size: 30, color: Colors.black54),
                Icon(Icons.chevron_right, size: 30, color: Colors.black54),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFoodCard(Map<String, String> item) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(item['image']!),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item['title']!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFAFD198),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              'วิธีการทำ',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}