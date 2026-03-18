import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/constants/constants.dart';
import 'admin_addmenu_screen.dart'; 

class AdminRequestScreen extends StatefulWidget {
  const AdminRequestScreen({super.key});

  @override
  State<AdminRequestScreen> createState() => _AdminRequestScreenState();
}

class _AdminRequestScreenState extends State<AdminRequestScreen> {
  late Future<List<dynamic>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  void _fetchRequests() {
    setState(() {
      _requestsFuture = http.get(Uri.parse('${AppConstants.baseUrl}/admin/food-requests'))
        .then((res) {
          if (res.statusCode == 200) {
            return jsonDecode(res.body);
          } else {
            throw Exception('Failed to load requests');
          }
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF), // พื้นหลังสีเขียวอ่อน
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Title + Back Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ปุ่มย้อนกลับ
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
                      ),
                    ),
                  ),
                  // หัวข้อหน้า
                  const Text(
                    'ดูคำขอเพิ่มเมนู',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 2. รายการคำขอ (List View + FutureBuilder)
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _requestsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('ไม่มีคำขอเพิ่มเมนูในขณะนี้', style: TextStyle(fontSize: 16)));
                  }

                  final requests = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: requests.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final item = requests[index];
                      return _buildRequestCard(
                        context: context, 
                        requestData: item,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สร้างการ์ดแต่ละรายการ
  Widget _buildRequestCard({
    required BuildContext context, 
    required Map<String, dynamic> requestData,
  }) {
    final menuName = requestData['food_name'] ?? 'ไม่มีชื่อเมนู';
    final requesterName = requestData['requester_name'] ?? 'ผู้ใช้ไม่ระบุชื่อ';

    return Container(
      width: double.infinity,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4C6414), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar (วงกลมซ้ายสุด)
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFEADDFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF6E6A6A), size: 30),
          ),
          
          const SizedBox(width: 15),

          // ข้อความ (ชื่อคนขอ + ชื่อเมนู)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ชื่อคนขอ
                Text(
                  requesterName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // ชื่อเมนูที่ขอ
                Text(
                  'เพิ่ม $menuName',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6E6A6A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ปุ่ม Action (วงกลมสีเขียวขวาสุด) - กดแล้วไปหน้าเพิ่มเมนู
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFAFD198),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
              onPressed: () async {
                // ✅ ส่งข้อมูลคำขอที่เลือกไปหน้าถัดไป ให้แอดมินแก้ไขโภชนาการ
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminAddMenuScreen(
                      initialMenuName: menuName,
                      requestData: requestData,
                    ),
                  ),
                );
                // Refresh data if admin approved/rejected it
                if (result == true) {
                  _fetchRequests();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}