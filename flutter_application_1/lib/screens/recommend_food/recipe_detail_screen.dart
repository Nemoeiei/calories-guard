import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/constants/constants.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int foodId;

  const RecipeDetailScreen({super.key, required this.foodId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<Map<String, dynamic>> _recipeFuture;

  @override
  void initState() {
    super.initState();
    _fetchRecipe();
  }

  void _fetchRecipe() {
    setState(() {
      _recipeFuture = http.get(Uri.parse('${AppConstants.baseUrl}/recipes/${widget.foodId}'))
        .then((res) {
          if (res.statusCode == 200) {
            return jsonDecode(res.body);
          } else {
            throw Exception('Recipe not found');
          }
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      appBar: AppBar(
        title: const Text('วิธีการทำ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _recipeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('ไม่พบข้อมูลสูตรอาหาร / ${snapshot.error}', style: const TextStyle(fontSize: 16)));
          }
          if (!snapshot.hasData) {
             return const Center(child: Text('ไม่มีข้อมูลสูตรอาหาร'));
          }

          final recipe = snapshot.data!;
          final foodName = recipe['food_name'] ?? 'ไม่มีชื่อ';
          final instructions = recipe['instructions'] ?? 'ยังไม่มีวิธีการทำ';
          final imageUrl = recipe['food_image_url'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(imageUrl, width: double.infinity, height: 250, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: double.infinity, height: 250, color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                      ),
                    ),
                  )
                else
                   Container(
                      width: double.infinity, height: 250, 
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(15)),
                      child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                   ),
                const SizedBox(height: 20),
                Text(
                  foodName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text('เวลาเตรียม: ${recipe['prep_time_minutes'] ?? 0} นาที', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(width: 16),
                    const Icon(Icons.microwave, size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text('เวลาปรุง: ${recipe['cooking_time_minutes'] ?? 0} นาที', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF628141))
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('วิธีการทำ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        instructions,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      )
    );
  }
<<<<<<< Updated upstream
}
=======

  // ────────────────────────────────────────────
  //  REVIEWS
  // ────────────────────────────────────────────
  Widget _buildReviews() {
    return Column(children: [
      // ── Comment input ──
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(99),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          const Expanded(child: Text('เขียนรีวิวของคุณ...',
            style: TextStyle(fontSize: 13, color: Colors.grey))),
          GestureDetector(
            onTap: () => _showReviewSheet(),
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 16)),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      // ── Review list ──
      if (_reviews.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text('ยังไม่มีรีวิว เป็นคนแรกที่รีวิวเลย! 🎉',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        )
      else
        ..._reviews.map((rv) => _buildReviewItem(rv)).toList(),
    ]);
  }

  Widget _buildReviewItem(Map<String, dynamic> rv) {
    final rating   = rv['rating'] ?? 0;
    final comment  = rv['comment']?.toString() ?? '';
    final username = rv['username']?.toString() ?? 'ผู้ใช้';
    final date     = rv['created_at']?.toString() ?? '';

    String dateShort = '';
    try {
      final d = DateTime.parse(date);
      final diff = DateTime.now().difference(d).inDays;
      dateShort = diff == 0 ? 'วันนี้' : '$diff วันที่แล้ว';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _greenMid,
            child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Text(username, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(dateShort, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ]),
        const SizedBox(height: 4),
        Row(children: List.generate(5, (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: _gold, size: 14))),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(comment, style: const TextStyle(
            fontSize: 13, color: Color(0xFF2E5040), height: 1.4)),
        ],
      ]),
    );
  }

  // ────────────────────────────────────────────
  //  REVIEW SHEET
  // ────────────────────────────────────────────
  void _showReviewSheet() {
    final userId = ref.read(userDataProvider).userId;
    if (userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนรีวิว')));
      return;
    }

    int selectedRating = 5;
    final commentCtrl  = TextEditingController();
    bool isSaving      = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 16),
              const Text('⭐ เขียนรีวิว',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setSheet(() => selectedRating = i + 1),
                  child: Icon(
                    i < selectedRating ? Icons.star : Icons.star_border,
                    color: _gold, size: 36),
                )),
              ),
              const SizedBox(height: 16),
              // Comment
              TextField(
                controller: commentCtrl,
                maxLines: 3, autofocus: true,
                decoration: InputDecoration(
                  hintText: 'บอกเล่าประสบการณ์ของคุณ...',
                  filled: true, fillColor: _greenL,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              // Submit
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setSheet(() => isSaving = true);
                    try {
                      final res = await http.post(
                        Uri.parse('${AppConstants.baseUrl}/recipes/${widget.foodId}/review'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'user_id': userId,
                          'rating':  selectedRating,
                          'comment': commentCtrl.text.trim(),
                        }),
                      );
                      if (res.statusCode == 200 && mounted) {
                        Navigator.pop(ctx);
                        _fetchRecipe(); // refresh
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ บันทึกรีวิวแล้ว!')));
                      }
                    } catch (_) {}
                    setSheet(() => isSaving = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
                  child: isSaving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('ส่งรีวิว',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  //  ADD TO MEAL BAR
  // ────────────────────────────────────────────
  Widget _buildAddMealBar(Map<String, dynamic> r) {
    final cal  = r['calories']?.toStringAsFixed(0) ?? '0';
    final name = r['recipe_name']?.toString() ?? '';

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E35), Color(0xFF2E7D52)],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: const Color(0xFF2E7D52).withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$cal kcal / จาน',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 15,
                fontWeight: FontWeight.w700, color: Colors.white)),
            Text('เพิ่ม "$name" ในบันทึกอาหาร',
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context, 
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('เลือกมื้ออาหารที่ต้องการบันทึก', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _mealOption(ctx, '☀️ อาหารเช้า', 'meal_1', r),
                    _mealOption(ctx, '🌤️ อาหารกลางวัน', 'meal_2', r),
                    _mealOption(ctx, '🌙 อาหารเย็น', 'meal_3', r),
                    _mealOption(ctx, '🥪 ของว่าง / อื่นๆ', 'meal_4', r),
                  ]),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B5E35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              elevation: 0,
            ),
            child: const Text('+ บันทึก',
              style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  // ────────────────────────────────────────────
  //  HELPER: Record to Meal Log
  // ────────────────────────────────────────────
  Widget _mealOption(BuildContext ctx, String label, String mealType, Map<String, dynamic> r) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.add_circle, color: _green),
      onTap: () async {
        Navigator.pop(ctx); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กำลังบันทึก...')));

        final userId = ref.read(userDataProvider).userId;
        if (userId == 0) return;

        final foodId = widget.foodId;
        final name   = r['recipe_name']?.toString() ?? r['food_name']?.toString() ?? '';
        final cal    = double.tryParse(r['calories']?.toString() ?? '0') ?? 0.0;
        final pro    = double.tryParse(r['protein']?.toString() ?? '0') ?? 0.0;
        final carb   = double.tryParse(r['carbs']?.toString() ?? '0') ?? 0.0;
        final fat    = double.tryParse(r['fat']?.toString() ?? '0') ?? 0.0;
        
        final now    = DateTime.now();
        final dateStr= "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";

        try {
          final res = await http.post(
            Uri.parse('${AppConstants.baseUrl}/meals/$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'date': dateStr,
              'meal_type': mealType,
              'items': [
                {
                  'food_id': foodId,
                  'food_name': name,
                  'amount': 1.0,
                  'cal_per_unit': cal,
                  'protein_per_unit': pro,
                  'carbs_per_unit': carb,
                  'fat_per_unit': fat
                }
              ]
            }),
          );
          if (res.statusCode == 200 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ เพิ่ม "$name" สำเร็จ')));
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ บันทึกไม่สำเร็จ')));
          }
        } catch (_) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ ระบบขัดข้อง')));
        }
      },
    );
  }

  // ────────────────────────────────────────────
  //  HELPER: Section wrapper
  // ────────────────────────────────────────────
  Widget _buildSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section title with accent line
        Row(children: [
          Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 16,
            fontWeight: FontWeight.w700, color: Color(0xFF0D2118))),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_greenMid, Colors.transparent]),
              borderRadius: BorderRadius.circular(99)))),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}
>>>>>>> Stashed changes
