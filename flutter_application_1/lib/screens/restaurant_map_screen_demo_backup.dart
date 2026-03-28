import 'package:flutter/material.dart';

class RestaurantMapScreen extends StatefulWidget {
  final double remainingCalories;

  const RestaurantMapScreen({
    Key? key,
    required this.remainingCalories,
  }) : super(key: key);

  @override
  State<RestaurantMapScreen> createState() => _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends State<RestaurantMapScreen> {
  static const Color _green = Color(0xFF628141);
  static const Color _greenL = Color(0xFFE8EFCF);
  static const Color _greenM = Color(0xFFAFD198);
  static const Color _orange = Color(0xFFD76A3C);
  static const Color _orangeL = Color(0xFFFFF3E0);
  static const Color _blue = Color(0xFF1565C0);
  static const Color _bg = Color(0xFFF2F7F4);
  static const Color _red = Color(0xFFD32F2F);

  int _radiusMeters = 1000;
  String _selectedFilter = 'ทั้งหมด';
  String _selectedKeyword = 'ทั้งหมด';
  Map<String, dynamic>? _selectedRestaurant;

  final List<String> _filters = ['ทั้งหมด', 'เปิดอยู่', '⭐4.0+'];
  final List<String> _keywords = ['ทั้งหมด', 'สลัด', 'อาหารญี่ปุ่น', 'ข้าวต้ม', 'ผัดผัก'];

  // Mock restaurant data
  final List<Map<String, dynamic>> _mockRestaurants = [
    {
      'name': 'Clean Food Café',
      'vicinity': '123 ถนนสุขุมวิท แขวงคลองเตย',
      'rating': 4.5,
      'distance': 250.0,
      'open_now': true,
      'photo': '🥗',
    },
    {
      'name': 'Healthy Bowl',
      'vicinity': '456 ถนนพระราม 4 แขวงปทุมวัน',
      'rating': 4.2,
      'distance': 450.0,
      'open_now': true,
      'photo': '🥙',
    },
    {
      'name': 'Salad Bar Bangkok',
      'vicinity': '789 ถนนสีลม แขวงสีลม',
      'rating': 4.8,
      'distance': 680.0,
      'open_now': true,
      'photo': '🥗',
    },
    {
      'name': 'โจ๊กข้าวต้ม',
      'vicinity': '321 ซอยทองหล่อ แขวงคลองตัน',
      'rating': 4.0,
      'distance': 320.0,
      'open_now': false,
      'photo': '🍲',
    },
    {
      'name': 'ร้านอาหารญี่ปุ่น ซากุระ',
      'vicinity': '654 ถนนเพชรบุรี แขวงมักกะสัน',
      'rating': 4.6,
      'distance': 890.0,
      'open_now': true,
      'photo': '🍱',
    },
    {
      'name': 'ผัดผักคลีน',
      'vicinity': '987 ถนนรัชดาภิเษก แขวงดินแดง',
      'rating': 3.9,
      'distance': 520.0,
      'open_now': true,
      'photo': '🥬',
    },
  ];

  List<Map<String, dynamic>> get _filteredRestaurants {
    return _mockRestaurants.where((r) {
      if (_selectedFilter == 'เปิดอยู่' && !r['open_now']) return false;
      if (_selectedFilter == '⭐4.0+' && r['rating'] < 4.0) return false;
      if (_selectedKeyword != 'ทั้งหมด' && 
          !r['name'].toString().toLowerCase().contains(_selectedKeyword.toLowerCase())) {
        return false;
      }
      if (r['distance'] > _radiusMeters) return false;
      return true;
    }).toList()..sort((a, b) => a['distance'].compareTo(b['distance']));
  }

  String _getAICalorieHint(double remainingCal) {
    if (remainingCal > 800) {
      return 'คุณมีแคลอรี่เหลือเยอะ เลือกได้อิสระ!';
    } else if (remainingCal > 500) {
      return 'แนะนำเมนูปานกลาง หรือแบ่งปัน';
    } else if (remainingCal > 300) {
      return 'เลือกเมนูเบา เช่น สลัด หรือซุป';
    } else if (remainingCal > 0) {
      return 'แคลอรี่เหลือน้อย ควรเลือกของว่าง';
    } else {
      return 'แคลอรี่เกินแล้ว ควรหลีกเลี่ยงอาหารหนัก';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          _buildMapPlaceholder(),
          _buildTopBar(),
          _buildRestaurantList(),
          if (_selectedRestaurant != null) _buildDetailPanel(),
          _buildRadiusToggle(),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      color: _greenL,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _green.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.map, size: 64, color: _green),
                  const SizedBox(height: 16),
                  const Text(
                    '🗺️ แผนที่ร้านอาหาร',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'พบ ${_filteredRestaurants.length} ร้านใกล้คุณ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _orangeL,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'รัศมี ${_radiusMeters}m',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: _green.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'ร้านอาหารใกล้ฉัน',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: _green),
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFilterChips(),
            const SizedBox(height: 12),
            _buildKeywordScroll(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: _filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            backgroundColor: Colors.white,
            selectedColor: _greenL,
            labelStyle: TextStyle(
              color: isSelected ? _green : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected ? _green : Colors.grey.shade300,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeywordScroll() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _keywords.length,
        itemBuilder: (context, index) {
          final keyword = _keywords[index];
          final isSelected = _selectedKeyword == keyword;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(keyword),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedKeyword = keyword;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: _orange.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? _orange : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? _orange : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRestaurantList() {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: _green.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'พบ ${_filteredRestaurants.length} ร้าน',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'เหลือ ${widget.remainingCalories.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredRestaurants.length,
                  itemBuilder: (context, index) {
                    return _buildRestaurantCard(_filteredRestaurants[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRestaurant = restaurant;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: _green.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _greenL,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                restaurant['photo'],
                style: const TextStyle(fontSize: 40),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant['vicinity'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: _orange),
                      const SizedBox(width: 4),
                      Text(
                        restaurant['rating'].toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on, size: 16, color: _blue),
                      const SizedBox(width: 4),
                      Text(
                        '${(restaurant['distance'] / 1000).toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: restaurant['open_now'] ? _greenL : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          restaurant['open_now'] ? 'เปิดอยู่' : 'ปิดแล้ว',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: restaurant['open_now'] ? _green : _red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel() {
    final restaurant = _selectedRestaurant!;
    final aiHint = _getAICalorieHint(widget.remainingCalories);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: _green.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: _greenL,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        restaurant['photo'],
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant['name'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: restaurant['open_now'] ? _greenL : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            restaurant['open_now'] ? 'เปิดอยู่' : 'ปิดแล้ว',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: restaurant['open_now'] ? _green : _red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatChip(
                          Icons.star,
                          '${restaurant['rating'].toStringAsFixed(1)}',
                          _orange,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          Icons.location_on,
                          '${(restaurant['distance'] / 1000).toStringAsFixed(1)} km',
                          _blue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          Icons.local_fire_department,
                          '${widget.remainingCalories.toStringAsFixed(0)} kcal',
                          _orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _orangeL,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: _orange, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              aiHint,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      restaurant['vicinity'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('เปิด Google Maps...')),
                              );
                            },
                            icon: const Icon(Icons.directions, color: Colors.white),
                            label: const Text(
                              'นำทาง',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('เปิดเมนู...')),
                              );
                            },
                            icon: const Icon(Icons.restaurant_menu, color: _green),
                            label: const Text(
                              'ดูเมนู',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _green,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _green, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusToggle() {
    return Positioned(
      right: 16,
      bottom: MediaQuery.of(context).size.height * 0.35,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: 'radius_500',
            mini: true,
            backgroundColor: _radiusMeters == 500 ? _green : Colors.white,
            onPressed: () {
              setState(() {
                _radiusMeters = 500;
              });
            },
            child: Text(
              '500m',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _radiusMeters == 500 ? Colors.white : _green,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'radius_1000',
            mini: true,
            backgroundColor: _radiusMeters == 1000 ? _green : Colors.white,
            onPressed: () {
              setState(() {
                _radiusMeters = 1000;
              });
            },
            child: Text(
              '1km',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _radiusMeters == 1000 ? Colors.white : _green,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'radius_2000',
            mini: true,
            backgroundColor: _radiusMeters == 2000 ? _green : Colors.white,
            onPressed: () {
              setState(() {
                _radiusMeters = 2000;
              });
            },
            child: Text(
              '2km',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _radiusMeters == 2000 ? Colors.white : _green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
