import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/constants/constants.dart';
import '../macro/macro_detail_screen.dart';
import 'recipe_detail_screen.dart';

class RecommendedFoodScreen extends StatefulWidget {
  const RecommendedFoodScreen({super.key});

  @override
  State<RecommendedFoodScreen> createState() => _RecommendedFoodScreenState();
}

class _RecommendedFoodScreenState extends State<RecommendedFoodScreen> {
  int _foodFilterIndex = 0;
  List<Map<String, dynamic>> _allFood = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendedFood();
  }

  Future<void> _fetchRecommendedFood() async {
    try {
      final res = await http.get(Uri.parse('${AppConstants.baseUrl}/recommended-food'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _allFood = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _displayedFood {
    if (_searchQuery.isEmpty) return _allFood;
    return _allFood.where((item) {
      final name = item['food_name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // --- ข้อมูลจำลอง (Mock Data) ---
  static const List<Map<String, String>> _drinkMenu = [
    {'name': 'ชามะนาว', 'sub': '80 kcal', 'image': 'assets/images/food/drink1.png'},
    {'name': 'น้ำส้มคั้น', 'sub': '120 kcal', 'image': 'assets/images/food/drink2.png'},
  ];
  static const List<Map<String, String>> _dessertMenu = [
    {'name': 'พุดดิ้ง', 'sub': '150 kcal', 'image': 'assets/images/food/dessert1.png'},
  ];

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ---------- ช่อง search หาอาหาร ----------
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
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: const InputDecoration(
                            hintText: 'ค้นหาอาหาร',
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w100,
                              color: Colors.black54,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Icon(Icons.search, size: 24, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (isSearching)
                ...[
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                     child: Text('ผลการค้นหา: "$_searchQuery"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   ),
                   _displayedFood.isEmpty 
                      ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('ไม่พบเมนูที่ค้นหา')))
                      : _buildGridCustom(_displayedFood),
                ]
              else ...[
                // ---------- โภชนาการ ----------
                if (_allFood.isNotEmpty)
                  _buildMacroBlockNew(context, 'อาหารแนะนำ (ทั้งหมด)', 'protein', _allFood.take(2).toList()),
                
                const SizedBox(height: 32),

                // ---------- แถบสีแดง แนะนำสำหรับคุณ ----------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: const Color(0xFFD76A3C),
                  alignment: Alignment.center,
                  child: const Text('แนะนำสำหรับคุณ', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 24),

                // ---------- อาหาร, เครื่องดื่ม, ของหวาน ----------
                _buildSectionHeader('สูตรอาหารแนะนำสำหรับคุณ'),
                _buildFilterChips(
                  labels: const ['ทั้งหมด', 'อาหารทั่วไป', 'อาหารคลีน'],
                  selectedIndex: _foodFilterIndex,
                  onTap: (i) => setState(() => _foodFilterIndex = i),
                ),
                _buildGridCustom(_allFood),
                _buildSeeMoreButton(),

                _buildSectionHeader('สูตรเครื่องดื่มแนะนำสำหรับคุณ'),
                _buildGridMock(_drinkMenu),
                _buildSeeMoreButton(),

                _buildSectionHeader('สูตรของหวานแนะนำสำหรับคุณ'),
                _buildGridMock(_dessertMenu),
                _buildSeeMoreButton(),
              ],
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroBlockNew(BuildContext context, String title, String macroType, List<Map<String, dynamic>> items) {
    const lightGreen = Color(0xFFE8EFCF); 
    const darkGreen = Color(0xFF628141);  

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => MacroDetailScreen(macroType: macroType)));
            },
            child: IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(width: 24, height: 24, decoration: const BoxDecoration(color: darkGreen, shape: BoxShape.circle), child: const Icon(Icons.chevron_right, color: Colors.white, size: 18)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < items.length; i++) ...[
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

  Widget _buildMacroCardNew(Map<String, dynamic> item) {
    final foodName = item['food_name']?.toString() ?? 'ไม่มีชื่อ';
    final calories = item['calories']?.toString() ?? '0';
    final imageUrl = item['image_url']?.toString();
    final foodId = item['food_id'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder())
                : _imagePlaceholder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(foodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
        Text('$calories kcal', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const Spacer(),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            if (foodId != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(foodId: foodId)));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFAFD198), borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 3))],
            ),
            child: const Text('วิธีการทำ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildGridCustom(List<Map<String, dynamic>> items) {
    return Container(
      width: double.infinity, color: const Color(0xFFE8EFCF), padding: const EdgeInsets.fromLTRB(25, 14, 25, 0),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 23, mainAxisSpacing: 21, childAspectRatio: 0.62,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildCardCustom(items[index]),
      ),
    );
  }

  Widget _buildCardCustom(Map<String, dynamic> item) {
    final foodName = item['food_name']?.toString() ?? 'ไม่มีชื่อ';
    final calories = item['calories']?.toString() ?? '0';
    final imageUrl = item['image_url']?.toString();
    final foodId = item['food_id'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 160, height: 160, child: (imageUrl != null && imageUrl.isNotEmpty) ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder()) : _imagePlaceholder()),
        ),
        const SizedBox(height: 10),
        Text(foodName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text('$calories kcal', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const Spacer(),
        GestureDetector(
          onTap: () {
            if (foodId != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(foodId: foodId)));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFAFD198), borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 4))],
            ),
            child: const Text('วิธีการทำ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildGridMock(List<Map<String, String>> items) {
    return Container(
      width: double.infinity, color: const Color(0xFFE8EFCF), padding: const EdgeInsets.fromLTRB(25, 14, 25, 0),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 23, mainAxisSpacing: 21, childAspectRatio: 0.62,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildMockCard(items[index]),
      ),
    );
  }

  Widget _buildMockCard(Map<String, String> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 160, height: 160, child: _imagePlaceholder()),
        ),
        const SizedBox(height: 10),
        Text(item['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
        Text(item['sub']!, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const Spacer(),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กำลังพัฒนาสูตรสำหรับหมวดหมู่นี้')));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFAFD198), borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 4))],
            ),
            child: const Text('วิธีการทำ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(color: Colors.grey[300], child: Icon(Icons.restaurant, color: Colors.grey[500], size: 48));
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10), color: const Color(0xFF628141),
      alignment: Alignment.center, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: Colors.white)),
    );
  }

  Widget _buildFilterChips({required List<String> labels, required int selectedIndex, required ValueChanged<int> onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 10), 
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(labels.length, (i) {
            final isSelected = i == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                onTap: () => onTap(i), borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: isSelected ? const Color(0xFFAFD198) : Colors.white, borderRadius: BorderRadius.circular(100), border: isSelected ? null : Border.all(color: const Color(0xFF4C6414))),
                  child: Text(labels[i], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSeeMoreButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กำลังโหลดเมนูเพิ่มเติม...')));
      },
      child: Container(
        width: double.infinity, color: const Color(0xFFE8EFCF), padding: const EdgeInsets.only(right: 25, top: 12, bottom: 20),
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF628141), borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 4))]),
          child: const Text('ดูเพิ่มเติม', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.white)),
        ),
      ),
    );
  }
}