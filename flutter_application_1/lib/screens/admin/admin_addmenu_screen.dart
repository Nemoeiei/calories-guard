import 'dart:convert';
import 'dart:io'; // จำเป็นสำหรับการจัดการไฟล์
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/constants/constants.dart';
import 'package:image_picker/image_picker.dart';

class AdminAddMenuScreen extends StatefulWidget {
  final String? initialMenuName;
  final Map<String, dynamic>? requestData;

  const AdminAddMenuScreen({super.key, this.initialMenuName, this.requestData});

  @override
  State<AdminAddMenuScreen> createState() => _AdminAddMenuScreenState();
}

class _AdminAddMenuScreenState extends State<AdminAddMenuScreen> {
  // Controller สำหรับรับค่าจาก TextField
  final TextEditingController _ingredientsCtrl = TextEditingController();
  final TextEditingController _instructionsCtrl = TextEditingController();
  final TextEditingController _proteinCtrl = TextEditingController();
  final TextEditingController _carbsCtrl = TextEditingController();
  final TextEditingController _fatCtrl = TextEditingController();
  final TextEditingController _caloriesCtrl = TextEditingController();

  File? _selectedImage; // ตัวแปรเก็บรูปที่เลือกจากเครื่อง
  bool _isUploading = false; // สถานะกำลังโหลด

  @override
  void initState() {
    super.initState();
    // ถ้าเป็นการเข้ามาเพื่อ Approve คำขอ (มี requestData)
    if (widget.requestData != null) {
      final req = widget.requestData!;
      // อ่านข้อมูลโภชนาการจากฟิลด์ที่ user กรอกมา
      _caloriesCtrl.text = req['calories']?.toString() ?? '';
      _proteinCtrl.text = req['protein']?.toString() ?? '';
      _carbsCtrl.text = req['carbs']?.toString() ?? '';
      _fatCtrl.text = req['fat']?.toString() ?? '';
    }
  }

  // 📸 ฟังก์ชัน 1: เลือกรูปจาก Gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // 🚀 ฟังก์ชัน 2: บันทึกข้อมูล (อัปโหลดรูป -> ได้ URL -> บันทึกเมนู/อนุมัติ)
  Future<void> _saveMenu() async {
    setState(() => _isUploading = true);

    String? imageUrl;

    try {
      // 1. ถ้ามีการเลือกรูป ให้อัปโหลดไปที่ API /upload-image/ ก่อน
      if (_selectedImage != null) {
        var request = http.MultipartRequest(
            'POST', Uri.parse('${AppConstants.baseUrl}/upload-image/'));
        request.files.add(
            await http.MultipartFile.fromPath('file', _selectedImage!.path));

        var streamRes = await request.send();
        if (streamRes.statusCode == 200) {
          var responseData = await streamRes.stream.bytesToString();
          var json = jsonDecode(responseData);
          imageUrl = json['url'];
        }
      }

      http.Response res;
      bool isApproval = widget.requestData != null;

      if (isApproval) {
        // 2A. โหมดอนุมัติ (Approve Request)
        final requestId = widget.requestData!['request_id'];
        final body = jsonEncode({
          "admin_id": 1, // จำลอง admin_id
          "status": "approved",
          "calories": double.tryParse(_caloriesCtrl.text) ?? 0,
          "protein": double.tryParse(_proteinCtrl.text) ?? 0,
          "carbs": double.tryParse(_carbsCtrl.text) ?? 0,
          "fat": double.tryParse(_fatCtrl.text) ?? 0,
          "image_url": imageUrl
        });

        res = await http.put(
          Uri.parse('${AppConstants.baseUrl}/admin/food-requests/$requestId'),
          headers: {"Content-Type": "application/json"},
          body: body,
        );
      } else {
        // 2B. โหมดสร้างเมนูใหม่ (Create Food)
        final body = jsonEncode({
          "food_name": widget.initialMenuName ?? "เมนูใหม่",
          "calories": double.tryParse(_caloriesCtrl.text) ?? 0,
          "protein": double.tryParse(_proteinCtrl.text) ?? 0,
          "carbs": double.tryParse(_carbsCtrl.text) ?? 0,
          "fat": double.tryParse(_fatCtrl.text) ?? 0,
          "image_url": imageUrl
        });

        res = await http.post(
          Uri.parse('${AppConstants.baseUrl}/foods'),
          headers: {"Content-Type": "application/json"},
          body: body,
        );
      }

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(isApproval ? 'อนุมัติเมนูสำเร็จ!' : 'บันทึกเมนูสำเร็จ!'),
              backgroundColor: Colors.green));
          Navigator.pop(
              context, true); // ปิดหน้าจอพร้อมส่งค่า true กลับไป รีเฟรช
        }
      } else {
        throw Exception('Failed to save food: ${res.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFE8EFCF),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.arrow_back_ios_new,
                                  color: Colors.black, size: 24),
                            ),
                          ),
                        ),
                        const Text('เพิ่มเมนูอาหาร',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 24,
                                color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Card ชื่อเมนู
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF4C6414), width: 1)),
                      child: Row(
                        children: [
                          Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFEADDFF),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.person,
                                  color: Color(0xFF6E6A6A))),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'เพิ่ม ${widget.initialMenuName ?? "เมนูใหม่"}',
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6E6A6A))),
                              const Text('โดย: Admin',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF4C6414), width: 1)),
                      child: Column(
                        children: [
                          // ชื่อเมนู
                          Row(
                            children: [
                              const Text('ชื่อเมนู :',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(width: 10),
                              Text(widget.initialMenuName ?? 'เมนูใหม่',
                                  style: const TextStyle(
                                      fontSize: 16, color: Color(0xFF6E6A6A))),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Inputs
                          _buildInputRow(
                              'วัตถุดิบ', 'เพิ่มวัตถุดิบ', _ingredientsCtrl),
                          const SizedBox(height: 15),
                          _buildInputRow(
                              'วิธีการทำ', 'เพิ่มวิธีทำ', _instructionsCtrl),
                          const SizedBox(height: 15),

                          // ✅ ส่วนอัปโหลดรูปภาพ
                          _buildImageUploadRow(),

                          const SizedBox(height: 15),
                          _buildNutrientInput(
                              'โปรตีน', '0', _proteinCtrl, ' กรัม'),
                          const SizedBox(height: 15),
                          _buildNutrientInput(
                              'คาร์โบไฮเดรต', '0', _carbsCtrl, ' กรัม'),
                          const SizedBox(height: 15),
                          _buildNutrientInput('ไขมัน', '0', _fatCtrl, ' กรัม'),
                          const SizedBox(height: 15),
                          _buildNutrientInput(
                              'แคลอรี่', '0', _caloriesCtrl, ' kcal'),

                          const SizedBox(height: 30),

                          // ปุ่มบันทึก
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _isUploading
                                  ? null
                                  : _saveMenu, // ✅ กดเพื่อบันทึก
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFAFD198),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              child: _isUploading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.black))
                                  : const Text('เพิ่มเมนูนี้',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Loading Overlay
        if (_isUploading)
          ModalBarrier(
              dismissible: false, color: Colors.black.withOpacity(0.3)),
      ],
    );
  }

  // Widget: Input ทั่วไป
  Widget _buildInputRow(
      String label, String placeholder, TextEditingController ctrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w400))),
        Container(
          width: 150,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              color: const Color(0xFFE8EFCF),
              borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle:
                    const TextStyle(fontSize: 12, color: Colors.black38)),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ✅ Widget: เลือกรูปภาพ (แก้ไขให้กดได้จริง)
  Widget _buildImageUploadRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(
            width: 90,
            child: Text('รูปภาพ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400))),
        GestureDetector(
          onTap: _pickImage, // ✅ กดแล้วเปิด Gallery
          child: Container(
            width: 150, height: 100, // เพิ่มความสูงให้โชว์รูปได้
            decoration: BoxDecoration(
                color: const Color(0xFFE8EFCF),
                borderRadius: BorderRadius.circular(10),
                image: _selectedImage != null
                    ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover) // โชว์รูปที่เลือก
                    : null),
            child: _selectedImage == null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 18, color: Colors.black54),
                      SizedBox(width: 5),
                      Text('เพิ่มรูปภาพ',
                          style: TextStyle(fontSize: 12, color: Colors.black38))
                    ],
                  )
                : null, // ถ้ามีรูปแล้วไม่ต้องโชว์ข้อความ
          ),
        ),
      ],
    );
  }

  // Widget: Input ตัวเลข
  Widget _buildNutrientInput(String label, String placeholder,
      TextEditingController ctrl, String suffix) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w400))),
        Container(
          width: 150,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              color: const Color(0xFFE8EFCF),
              borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: placeholder,
                      hintStyle:
                          const TextStyle(fontSize: 12, color: Colors.black38)),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(suffix,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}
