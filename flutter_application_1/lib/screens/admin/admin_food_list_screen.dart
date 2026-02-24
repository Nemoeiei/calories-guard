import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_edit_menu_screen.dart';

class AdminFoodListScreen extends StatefulWidget {
  const AdminFoodListScreen({super.key});

  @override
  State<AdminFoodListScreen> createState() => _AdminFoodListScreenState();
}

class _AdminFoodListScreenState extends State<AdminFoodListScreen> {
  List<dynamic> _allFoods = []; // เก็บข้อมูลทั้งหมด
  List<dynamic> _filteredFoods = []; // เก็บข้อมูลที่กรองแล้ว (สำหรับแสดงผล)
  bool _isLoading = true;

  // ตัวแปรสำหรับค้นหา
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFoods();

    // ฟังค่าการพิมพ์เพื่อกรองข้อมูล
    _searchController.addListener(() {
      _filterFoods(_searchController.text);
    });
  }

  Future<void> _fetchFoods() async {
    try {
      final res = await http.get(Uri.parse(
          'https://unshirred-wendolyn-audiometrically.ngrok-free.dev/foods'));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        setState(() {
          _allFoods = data;
          _filteredFoods = data; // เริ่มต้นให้แสดงทั้งหมด
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching foods: $e");
    }
  }

  // ฟังก์ชันกรองข้อมูล
  void _filterFoods(String query) {
    final filtered = _allFoods.where((food) {
      final name = food['food_name'].toString().toLowerCase();
      final input = query.toLowerCase();
      return name.contains(input);
    }).toList();

    setState(() {
      _filteredFoods = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            // ถ้ากำลังค้นหาอยู่ ให้กด back เพื่อปิดค้นหาก่อน
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _filteredFoods = _allFoods;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        // ✅ Logic สลับระหว่าง ชื่อหน้า กับ ช่องค้นหา
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'ค้นหาเมนูอาหาร...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              )
            : const Text("จัดการเมนูอาหาร",
                style: TextStyle(color: Colors.black)),
        actions: [
          // ✅ ปุ่มแว่นขยาย / ปุ่มปิด
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Colors.black),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  // ถ้ากดปิด -> ล้างค่าค้นหา และคืนค่ารายการทั้งหมด
                  _isSearching = false;
                  _searchController.clear();
                  _filteredFoods = _allFoods;
                } else {
                  // ถ้ากดเปิด -> เปลี่ยนเป็นโหมดค้นหา
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // แสดงจำนวนรายการที่พบ
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text("พบ ${_filteredFoods.length} รายการ",
                        style: const TextStyle(color: Colors.grey)),
                  ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredFoods.length, // ใช้ List ที่กรองแล้ว
                    itemBuilder: (context, index) {
                      final food = _filteredFoods[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                              image: (food['image_url'] != null &&
                                      food['image_url'].isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(food['image_url']),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: (food['image_url'] == null ||
                                    food['image_url'].isEmpty)
                                ? const Icon(Icons.fastfood, color: Colors.grey)
                                : null,
                          ),
                          title: Text(food['food_name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${food['calories']} kcal"),
                          trailing:
                              const Icon(Icons.edit, color: Color(0xFF628141)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdminEditMenuScreen(foodData: food),
                              ),
                            ).then((value) {
                              if (value == true) {
                                _fetchFoods(); // รีเฟรชข้อมูลเมื่อกลับมา
                                _searchController.clear(); // ล้างคำค้นหา
                                _isSearching = false; // ปิดโหมดค้นหา
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
