import 'package:flutter/material.dart';

class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF), // พื้นหลังสีครีมเขียว
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 37), // Top margin

            // --- Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 40),
                      child: Text(
                        'บทความ',
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
                ],
              ),
            ),

            // --- ปุ่ม "ทั้งหมด" ---
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(right: 20, top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4C6414), // สีเขียวเข้ม
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'ทั้งหมด',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // --- หมวด 1: การกิน ---
            _buildSectionHeader('การกิน'),
            _buildHorizontalList([
              _buildArticleCard(
                // ใช้รูปสลัดจากเน็ต
                imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500', 
                title: '20 อาหารคลีนที่คนนิยมบริโภค',
              ),
              _buildArticleCard(
                // รูปอาหารดอง
                imageUrl: 'https://images.unsplash.com/photo-1626343729937-2e228964522a?w=500',
                title: 'อาหารดองมีผลเสียอะไรหรือไม่',
              ),
            ]),

            const SizedBox(height: 20),

            // --- หมวด 2: การออกกำลังกาย ---
            _buildSectionHeader('การออกกำลังกาย'),
            _buildHorizontalList([
              _buildArticleCard(
                // รูปคนวิ่ง
                imageUrl: 'https://images.unsplash.com/photo-1552674605-469523f70091?w=500',
                title: 'ประโยชน์ของการเดินตอนเช้า',
              ),
              _buildArticleCard(
                // รูปโยคะ
                imageUrl: 'https://images.unsplash.com/photo-1544367563-12123d8959bd?w=500',
                title: 'โยคะช่วยอะไร???',
              ),
            ]),

            const SizedBox(height: 20),

            // --- หมวด 3: อื่นๆ ---
            _buildSectionHeader('อื่นๆ'),
            _buildHorizontalList([
              _buildArticleCard(
                // รูปคนทำงานออฟฟิศ
                imageUrl: 'https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=500',
                title: 'สาเหตุของอาการออฟฟิศซินโดรม',
              ),
              _buildArticleCard(
                // รูปการแพทย์
                imageUrl: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=500',
                title: 'การตรวจเบาหวาน',
              ),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Helper: หัวข้อหมวดหมู่ ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 31, top: 10, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }

  // --- Helper: รายการแนวนอน ---
  Widget _buildHorizontalList(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 21), 
      child: Row(
        children: children.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 15), 
            child: item,
          );
        }).toList(),
      ),
    );
  }

  // --- Helper: การ์ดบทความ ---
  Widget _buildArticleCard({required String imageUrl, required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // กล่องรูปภาพ
        Container(
          width: 224,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            image: DecorationImage(
              // ใช้ NetworkImage เพื่อดึงรูปจากลิ้งค์
              image: NetworkImage(imageUrl), 
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        // แถบชื่อเรื่อง
        Container(
          width: 224,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}