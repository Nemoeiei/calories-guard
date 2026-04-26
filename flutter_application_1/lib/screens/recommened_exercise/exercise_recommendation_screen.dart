import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/constants/constants.dart';
import '/providers/user_data_provider.dart';

class ExerciseRecommendationScreen extends ConsumerStatefulWidget {
  const ExerciseRecommendationScreen({super.key});

  @override
  ConsumerState<ExerciseRecommendationScreen> createState() =>
      _ExerciseRecommendationScreenState();
}

class _ExerciseRecommendationScreenState
    extends ConsumerState<ExerciseRecommendationScreen>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF628141);
  static const _greenL = Color(0xFFE8EFCF);

  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  String? _errorMsg;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}/leaderboard'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data =
            (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        setState(() => _leaderboard = data);
        _animController.forward(from: 0);
      } else {
        setState(() => _errorMsg = 'โหลดข้อมูลไม่สำเร็จ (${res.statusCode})');
      }
    } catch (_) {
      setState(() => _errorMsg = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = ref.watch(userDataProvider).userId;

    return Scaffold(
      backgroundColor: _greenL,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _green))
          : _errorMsg != null
              ? _buildError()
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildContent(myUserId)),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(_errorMsg!,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _loadLeaderboard,
          icon: const Icon(Icons.refresh),
          label: const Text('ลองใหม่'),
          style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    );
  }

  Widget _buildContent(int myUserId) {
    final top3 = _leaderboard.take(3).toList();
    final rest = _leaderboard.skip(3).toList();

    return RefreshIndicator(
      color: _green,
      onRefresh: _loadLeaderboard,
      child: CustomScrollView(
        slivers: [
          // ─── App Bar ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          // ─── Podium ──────────────────────────────────────────
          if (top3.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildPodium(top3, myUserId),
            ),
          // ─── Rank 4+ list ─────────────────────────────────────
          if (rest.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(children: [
                  const Icon(Icons.format_list_numbered,
                      color: _green, size: 20),
                  const SizedBox(width: 8),
                  Text('อันดับที่ 4 ขึ้นไป',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.grey.shade700)),
                ]),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildRankTile(rest[i], i + 4, myUserId),
                childCount: rest.length,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3D5A27), Color(0xFF628141)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏆 ลีดเดอร์บอร์ด',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text('จัดอันดับตาม streak วันต่อเนื่อง',
                    style:
                        TextStyle(fontSize: 13, color: Color(0xFFCCDEA8))),
              ],
            ),
            GestureDetector(
              onTap: _loadLeaderboard,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle),
                child: const Icon(Icons.refresh,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.local_fire_department,
                color: Color(0xFFFFB347), size: 18),
            const SizedBox(width: 8),
            Text(
              'สะสมวันเข้าใช้งานต่อเนื่องเพื่อขึ้นอันดับ!',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3, int myUserId) {
    // order: 2nd (left), 1st (center), 3rd (right)
    final ordered = [
      if (top3.length > 1) top3[1] else null,
      top3[0],
      if (top3.length > 2) top3[2] else null,
    ];
    final heights = [100.0, 130.0, 80.0];
    final medals = ['🥈', '🥇', '🥉'];
    final medalColors = [
      const Color(0xFFB8C4D0),
      const Color(0xFFFFD700),
      const Color(0xFFCD7F32),
    ];
    final bgGrads = [
      [const Color(0xFFCDD9E5), const Color(0xFFB8C4D0)],
      [const Color(0xFFFFF8DC), const Color(0xFFFFE566)],
      [const Color(0xFFEDD9C3), const Color(0xFFCD7F32)],
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(children: [
        const Text('TOP 3',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _green,
                letterSpacing: 3)),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) {
            final user = ordered[i];
            if (user == null) return const SizedBox(width: 100);
            final isMe = user['user_id'] == myUserId;
            return _buildPodiumItem(
              user: user,
              medal: medals[i],
              medalColor: medalColors[i],
              podiumHeight: heights[i],
              bgGradient: bgGrads[i],
              isMe: isMe,
              rank: (i == 0 ? 2 : i == 1 ? 1 : 3),
            );
          }),
        ),
      ]),
    );
  }

  Widget _buildPodiumItem({
    required Map<String, dynamic> user,
    required String medal,
    required Color medalColor,
    required double podiumHeight,
    required List<Color> bgGradient,
    required bool isMe,
    required int rank,
  }) {
    final name = (user['username'] as String?) ?? 'ผู้ใช้';
    final streak = (user['current_streak'] as int?) ?? 0;
    final shortName = name.length > 8 ? '${name.substring(0, 7)}…' : name;

    return Column(
      children: [
        // Avatar
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: bgGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                border: Border.all(
                    color: isMe ? _green : medalColor, width: isMe ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                      color: medalColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: rank == 1
                          ? const Color(0xFF7A5500)
                          : Colors.grey.shade700),
                ),
              ),
            ),
            Positioned(
              top: -10,
              child: Text(medal, style: const TextStyle(fontSize: 20)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(shortName,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isMe ? _green : Colors.black87)),
        const SizedBox(height: 2),
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.local_fire_department,
              size: 13, color: Color(0xFFFF6B35)),
          Text('$streak วัน',
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFFF6B35),
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        // Podium block
        Container(
          width: 88,
          height: podiumHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: bgGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            boxShadow: [
              BoxShadow(
                  color: medalColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2))
            ],
          ),
          child: Center(
            child: Text('#$rank',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.9))),
          ),
        ),
      ],
    );
  }

  Widget _buildRankTile(
      Map<String, dynamic> user, int rank, int myUserId) {
    final name = (user['username'] as String?) ?? 'ผู้ใช้';
    final streak = (user['current_streak'] as int?) ?? 0;
    final totalDays = (user['total_login_days'] as int?) ?? 0;
    final isMe = user['user_id'] == myUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFEAF2DB) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMe
            ? Border.all(color: _green, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 28,
            child: Text('#$rank',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isMe ? _green : Colors.grey.shade500)),
          ),
          const SizedBox(width: 6),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe ? const Color(0xFFD4E8B0) : Colors.grey.shade100,
              border: Border.all(
                  color: isMe ? _green : Colors.grey.shade300, width: 1.5),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isMe ? _green : Colors.grey.shade600),
              ),
            ),
          ),
        ]),
        title: Text(
          name + (isMe ? ' (คุณ)' : ''),
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isMe ? _green : Colors.black87),
        ),
        subtitle: Text(
          'เข้าใช้งาน $totalDays วัน',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: streak > 0
                ? const Color(0xFFFF6B35).withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.local_fire_department,
                size: 16,
                color: streak > 0
                    ? const Color(0xFFFF6B35)
                    : Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: streak > 0
                      ? const Color(0xFFFF6B35)
                      : Colors.grey.shade400),
            ),
          ]),
        ),
      ),
    );
  }
}
