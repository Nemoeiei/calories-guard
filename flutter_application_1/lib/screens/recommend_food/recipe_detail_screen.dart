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
}
