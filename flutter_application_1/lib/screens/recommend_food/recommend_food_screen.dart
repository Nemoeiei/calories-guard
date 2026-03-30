import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/constants/constants.dart';
import '/providers/user_data_provider.dart';
import '../macro/macro_detail_screen.dart';

import 'recipe_detail_screen.dart';

class RecommendedFoodScreen extends ConsumerStatefulWidget {
  const RecommendedFoodScreen({super.key});

  @override
  ConsumerState<RecommendedFoodScreen> createState() => _RecommendedFoodScreenState();
}

class _RecommendedFoodScreenState extends ConsumerState<RecommendedFoodScreen> {
  int _foodFilterIndex    = 0;
  int _drinkFilterIndex   = 0;
  int _dessertFilterIndex = 0;

  List<Map<String, dynamic>> _allFood    = [];
  List<Map<String, dynamic>> _allDrinks  = [];
  List<Map<String, dynamic>> _allDesserts = [];

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _hideAllergic = true; // กรองเมนูที่แพ้ออกโดยค่าเริ่มต้น

  @override
  void initState() {
    super.initState();
    _fetchAllFood();
  }

  // ────────────────────────────────────────────
  //  FETCH — ดึงอาหารทั้งหมดแล้วแยก category
  // ────────────────────────────────────────────
  Future<void> _fetchAllFood() async {
    try {
      final res = await http.get(Uri.parse('${AppConstants.baseUrl}/foods'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final all = data.cast<Map<String, dynamic>>();

        setState(() {
          // ✅ แยกตาม food_type จริงจาก DB
          _allFood     = all.where((f) => f['food_type'] == 'dish' || f['food_type'] == 'recipe_dish').toList();
          _allDrinks   = all.where((f) => f['food_type'] == 'beverage').toList();
          _allDesserts = all.where((f) => f['food_type'] == 'snack').toList();
          _isLoading   = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ────────────────────────────────────────────
  //  FILTER LOGIC
  // ────────────────────────────────────────────

  /// คืน true ถ้าควรซ่อนอาหารนี้เพราะผู้ใช้แพ้
  bool _isAllergicFood(Map<String, dynamic> food) {
    if (!_hideAllergic) return false;
    final userAllergies = ref.read(userDataProvider).allergyFlagIds;
    if (userAllergies.isEmpty) return false;
    final flags = (food['allergy_flag_ids'] as List?)?.cast<int>() ?? [];
    return flags.any((id) => userAllergies.contains(id));
  }

  // ✅ filter อาหาร ตาม chip ที่เลือก + กรองแพ้อาหาร
  List<Map<String, dynamic>> get _filteredFood {
    List<Map<String, dynamic>> base =
        _allFood.where((f) => !_isAllergicFood(f)).toList();
    switch (_foodFilterIndex) {
      case 1: // อาหารทั่วไป → calories > 400 (หนักหน่อย)
        base = base.where((f) => (f['calories'] as num? ?? 0) > 400).toList();
        break;
      case 2: // อาหารคลีน → calories <= 400
        base = base.where((f) => (f['calories'] as num? ?? 0) <= 400).toList();
        break;
    }
    return base;
  }

  // ✅ filter เครื่องดื่ม
  List<Map<String, dynamic>> get _filteredDrinks {
    switch (_drinkFilterIndex) {
      case 1: return _allDrinks.where((f) => (f['sugar'] as num? ?? 0) == 0).toList(); // ไม่มีน้ำตาล
      case 2: return _allDrinks.where((f) => (f['caffeine_mg'] as num? ?? 0) > 0).toList(); // มีคาเฟอีน
      case 3: return _allDrinks.where((f) => (f['is_alcoholic'] as bool? ?? false)).toList(); // มีแอลกอฮอล์
      default: return _allDrinks;
    }
  }

  // ✅ filter ของหวาน
  List<Map<String, dynamic>> get _filteredDesserts {
    switch (_dessertFilterIndex) {
      case 1: return _allDesserts.where((f) => (f['calories'] as num? ?? 0) <= 100).toList(); // คาลอรี่ต่ำ
      case 2: return _allDesserts.where((f) => (f['calories'] as num? ?? 0) > 100).toList(); // คาลอรี่สูง
      default: return _allDesserts;
    }
  }

  // ✅ ผลการค้นหา — ค้นจากทุกหมวด
  List<Map<String, dynamic>> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    final all = [..._allFood, ..._allDrinks, ..._allDesserts];
    return all.where((item) {
      final name = item['food_name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // ────────────────────────────────────────────
  //  BUILD
  // ────────────────────────────────────────────
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

              // ── Search Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Container(
                  height: 43,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
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
                              fontFamily: 'Inter', fontSize: 16,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w100, color: Colors.black54,
                            ),
                            border: InputBorder.none, isDense: true,
                          ),
                        ),
                      ),
                      // ✅ ปุ่ม clear search
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close, size: 20, color: Colors.grey),
                        )
                      else
                        Icon(Icons.search, size: 24, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Allergy Filter Toggle ──
              Builder(builder: (_) {
                final userAllergies = ref.watch(userDataProvider).allergyFlagIds;
                if (userAllergies.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: GestureDetector(
                    onTap: () => setState(() => _hideAllergic = !_hideAllergic),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _hideAllergic
                            ? const Color(0xFF628141).withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _hideAllergic
                              ? const Color(0xFF628141)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.no_meals,
                            size: 16,
                            color: _hideAllergic
                                ? const Color(0xFF628141)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _hideAllergic
                                ? 'ซ่อนเมนูที่แพ้อยู่'
                                : 'แสดงเมนูที่แพ้ทั้งหมด',
                            style: TextStyle(
                              fontSize: 13,
                              color: _hideAllergic
                                  ? const Color(0xFF628141)
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF628141))))

              // ── ผลการค้นหา ──
              else if (isSearching)
                ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'ผลการค้นหา: "$_searchQuery" (${_searchResults.length} รายการ)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  _searchResults.isEmpty
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('ไม่พบเมนูที่ค้นหา',
                            style: TextStyle(color: Colors.grey))))
                      : _buildGrid(_searchResults),
                ]

              // ── หน้าหลัก ──
              else ...[

                // ── Macro Block ──
                if (_allFood.isNotEmpty)
                  _buildMacroBlockNew(context, 'อาหารแนะนำ (ทั้งหมด)', 'protein',
                    _allFood.take(2).toList()),

                const SizedBox(height: 32),

                // ── แถบแนะนำสำหรับคุณ ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: const Color(0xFFD76A3C),
                  alignment: Alignment.center,
                  child: const Text('แนะนำสำหรับคุณ',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500,
                      fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 24),

                // ── อาหาร ──
                _buildSectionHeader('สูตรอาหารแนะนำสำหรับคุณ'),
                _buildFilterChips(
                  // ✅ labels ตรงกับ filter logic จริง
                  labels: const ['ทั้งหมด', 'อาหารทั่วไป', 'อาหารคลีน'],
                  selectedIndex: _foodFilterIndex,
                  onTap: (i) => setState(() => _foodFilterIndex = i),
                ),
                // ✅ ใช้ _filteredFood แทน _allFood
                _allFood.isEmpty
                    ? _buildEmptyState('ยังไม่มีเมนูอาหาร')
                    : _buildGrid(_filteredFood),
                _buildSeeMoreButton(),

                // ── เครื่องดื่ม ──
                _buildSectionHeader('สูตรเครื่องดื่มแนะนำสำหรับคุณ'),
                _buildFilterChips(
                  labels: const ['ทั้งหมด', 'ไม่มีน้ำตาล', 'ชา/กาแฟ', 'มีแอลกอฮอล์'],
                  selectedIndex: _drinkFilterIndex,
                  onTap: (i) => setState(() => _drinkFilterIndex = i),
                ),
                // ✅ ดึงจาก DB จริง ไม่ใช่ Mock
                _allDrinks.isEmpty
                    ? _buildEmptyState('ยังไม่มีข้อมูลเครื่องดื่ม')
                    : _buildGrid(_filteredDrinks),
                _buildSeeMoreButton(),

                // ── ของหวาน ──
                _buildSectionHeader('สูตรของหวานแนะนำสำหรับคุณ'),
                _buildFilterChips(
                  labels: const ['ทั้งหมด', 'แคลอรี่ต่ำ', 'แคลอรี่สูง'],
                  selectedIndex: _dessertFilterIndex,
                  onTap: (i) => setState(() => _dessertFilterIndex = i),
                ),
                // ✅ ดึงจาก DB จริง
                _allDesserts.isEmpty
                    ? _buildEmptyState('ยังไม่มีข้อมูลของหวาน')
                    : _buildGrid(_filteredDesserts),
                _buildSeeMoreButton(),

                const SizedBox(height: 100),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  //  WIDGETS
  // ────────────────────────────────────────────

  Widget _buildMacroBlockNew(BuildContext context, String title,
      String macroType, List<Map<String, dynamic>> items) {
    const lightGreen = Color(0xFFE8EFCF);
    const darkGreen  = Color(0xFF628141);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(color: lightGreen,
        borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => MacroDetailScreen(macroType: macroType))),
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(30)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Container(width: 24, height: 24,
                  decoration: const BoxDecoration(color: darkGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.chevron_right, color: Colors.white, size: 18)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: _buildMacroCard(items[i])),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildMacroCard(Map<String, dynamic> item) {
    final foodName = item['food_name']?.toString() ?? 'ไม่มีชื่อ';
    final calories = item['calories']?.toString() ?? '0';
    final imageUrl = item['image_url']?.toString();
    // ✅ แปลง foodId เป็น int ให้ถูกต้อง
    final foodId   = item['food_id'] != null
        ? int.tryParse(item['food_id'].toString())
        : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder())
              : _imagePlaceholder(),
        ),
      ),
      const SizedBox(height: 12),
      Text(foodName, style: const TextStyle(
        fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2,
        overflow: TextOverflow.ellipsis),
      Text('$calories kcal', style: TextStyle(
        fontSize: 13, color: Colors.grey[600])),
      const Spacer(),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () {
          if (foodId != null) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(foodId: foodId)));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFAFD198),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
              blurRadius: 4, offset: const Offset(0, 3))],
          ),
          child: const Text('วิธีการทำ',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        ),
      ),
    ]);
  }

  // ✅ Grid หลัก — รองรับทั้ง dish/beverage/snack
  Widget _buildGrid(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return _buildEmptyState('ไม่มีรายการในหมวดนี้');

    return Container(
      width: double.infinity,
      color: const Color(0xFFE8EFCF),
      padding: const EdgeInsets.fromLTRB(25, 14, 25, 0),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 23,
          mainAxisSpacing: 21, childAspectRatio: 0.62,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildFoodCard(items[index]),
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> item) {
    final foodName = item['food_name']?.toString() ?? 'ไม่มีชื่อ';
    final calories = item['calories']?.toString() ?? '0';
    final imageUrl = item['image_url']?.toString();
    // ✅ cast int ให้ถูกต้องทุกที่
    final foodId   = item['food_id'] != null
        ? int.tryParse(item['food_id'].toString())
        : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 160, height: 160,
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder())
              : _imagePlaceholder(),
        ),
      ),
      const SizedBox(height: 10),
      Text(foodName, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, height: 1.2),
        maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Text('$calories kcal', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      const Spacer(),
      GestureDetector(
        onTap: () {
          if (foodId != null) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(foodId: foodId)));
          } else {
            // ✅ แสดงแจ้งเตือนถ้ายังไม่มีสูตร
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('ยังไม่มีสูตรอาหารสำหรับเมนูนี้'),
              duration: Duration(seconds: 2)));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFAFD198),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25),
              blurRadius: 4, offset: const Offset(0, 4))],
          ),
          child: const Text('วิธีการทำ',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ),
      ),
    ]);
  }

  // ✅ Empty state widget
  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8EFCF),
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(children: [
        Icon(Icons.restaurant_menu, size: 40, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      ]),
    );
  }

  Widget _imagePlaceholder() {
    return Container(color: Colors.grey[300],
      child: Icon(Icons.restaurant, color: Colors.grey[500], size: 48));
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFF628141),
      alignment: Alignment.center,
      child: Text(title,
        style: const TextStyle(fontWeight: FontWeight.w500,
          fontSize: 20, color: Colors.white)),
    );
  }

  Widget _buildFilterChips({
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onTap,
  }) {
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
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFAFD198)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: isSelected
                        ? null
                        : Border.all(color: const Color(0xFF4C6414)),
                  ),
                  child: Text(labels[i],
                    style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 16)),
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
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำลังโหลดเมนูเพิ่มเติม...'))),
      child: Container(
        width: double.infinity,
        color: const Color(0xFFE8EFCF),
        padding: const EdgeInsets.only(right: 25, top: 12, bottom: 20),
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF628141),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25),
              blurRadius: 4, offset: const Offset(0, 4))],
          ),
          child: const Text('ดูเพิ่มเติม',
            style: TextStyle(fontWeight: FontWeight.w500,
              fontSize: 12, color: Colors.white)),
        ),
      ),
    );
  }
}