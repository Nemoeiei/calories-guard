import 'package:flutter/material.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE7DDD1),
              Color(0xFFFFFFFF),
              Color(0xFFE7DDD1),
            ],
            stops: [0.0, 0.5061, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 9, top: 12),
                    child: Image.network(
                      'https://api.builder.io/api/v1/image/assets/TEMP/63b58034e129f3fabd1182d751daa5314f9c7bcb?width=154',
                      width: 77,
                      height: 73,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Title
                const Text(
                  'กรอกข้อมูลส่วนตัว',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Subtitle
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  child: Text(
                    'เพื่อนำไปคำนวณแคลอรี่ที่เหมาะสมกับตัวบุคคล',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 44),

                // Illustration
                Center(
                  child: Image.network(
                    'https://api.builder.io/api/v1/image/assets/TEMP/1954e238a987282746e33d33deb711b2c911f3d3?width=554',
                    width: 277,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 47),

                // Form Fields - Horizontal Layout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Column(
                    children: [
                      _buildFormField(
                        label: 'ชื่อ',
                        controller: _nameController,
                        hintText: 'กรอกข้อมูล',
                      ),

                      const SizedBox(height: 28),

                      _buildFormField(
                        label: 'วันเกิด',
                        controller: _birthdayController,
                        hintText: 'วว/ดด/ปปปป',
                      ),

                      const SizedBox(height: 28),

                      _buildFormField(
                        label: 'ส่วนสูง',
                        controller: _heightController,
                        hintText: 'กรอกข้อมูล',
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 28),

                      _buildFormField(
                        label: 'นํ้าหนัก',
                        controller: _weightController,
                        hintText: 'กรอกข้อมูล',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Next Button
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to next screen or save data
                    print('Name: ${_nameController.text}');
                    print('Birthday: ${_birthdayController.text}');
                    print('Height: ${_heightController.text}');
                    print('Weight: ${_weightController.text}');
                  },
                  child: Container(
                    width: 259,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C6414),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'ถัดไป',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 29,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEDED),
              borderRadius: BorderRadius.circular(100),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xB3000000),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
