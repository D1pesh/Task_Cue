import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskcue_app/services/leaderboard_service.dart';
import 'package:taskcue_app/services/auth_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late LeaderboardService _leaderboardService;
  String _selectedType = 'total'; // total, weekly, monthly
  List<LeaderboardEntry> _leaderboardData = [];
  String _errorMessage = '';
  int? _userRank;

  @override
  void initState() {
    super.initState();
    _leaderboardService = LeaderboardService();
    _seedAndLoad();
  }

  Future<void> _seedAndLoad() async {
    try {
      final auth = AuthService.instance;
      if (auth.currentUser != null) {
        // Sync first, then check if we need mock data
        await _leaderboardService.syncUserStats(auth.currentUser!.uid);
      }

      // Only seed if we actually need data (e.g., if Firestore is empty)
      // For demonstration, we'll keep it but make it conditional if possible
      // In a real app, this would be an admin-only function.
      await _leaderboardService.seedMockUsers();
    } catch (e) {
      debugPrint('Seeding/Syncing failed: $e');
    }
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _errorMessage = '';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      // Auto-sync current user to leaderboard on refresh to ensure they are listed
      if (currentUser != null) {
        try {
          await _leaderboardService.syncUserStats(currentUser.uid);
          // Small delay to allow Firestore to process before we fetch the full list
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('Sync failed (likely offline): $e');
        }
      }

      final data = await _leaderboardService.fetchTopUsers(
        type: _selectedType,
        limit: 50,
        currentUserId: currentUser?.uid,
      );

      if (currentUser != null) {
        _userRank = await _leaderboardService.getUserRank(
          uid: currentUser.uid,
          type: _selectedType,
        );
      }

      setState(() {
        _leaderboardData = data;
        _errorMessage = '';
      });
    } catch (e) {
      debugPrint('Leaderboard screen error: $e');
      setState(() {
        _errorMessage = 'Offline: Showing cached data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Leaderboard',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          if (_errorMessage.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.cloud_off, color: Colors.grey, size: 20),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: StreamBuilder<List<LeaderboardEntry>>(
        stream: _leaderboardService.topUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _leaderboardData.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && _leaderboardData.isEmpty) {
            return _buildErrorWidget();
          }

          final data = snapshot.data ?? _leaderboardData;
          if (data.isEmpty) {
            return _buildErrorWidget();
          }

          return _buildLeaderboardContent(data);
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Colors.blueGrey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Leaderboard Unavailable Offline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to the internet to see how you rank against other competitors.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLeaderboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent(List<LeaderboardEntry> data) {
    // Current user rank
    final currentUser = FirebaseAuth.instance.currentUser;
    int? currentRank;
    try {
      currentRank = data.indexWhere((e) => e.uid == currentUser?.uid);
      if (currentRank != -1) {
        currentRank += 1;
      } else {
        currentRank = null;
      }
    } catch (_) {}

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(
            bottom: 110,
          ), // Space for sticky footer
          child: Column(
            children: [
              // Filter tabs
              _buildFilterTabs(),
              const SizedBox(height: 10),

              // Top 3 Podium
              if (data.length >= 3) _buildTopThreeSection(data),
              const SizedBox(height: 24),

              // Unified Leaderboard List (Rest of the users)
              _buildLeaderboardList(data),
            ],
          ),
        ),
        // Sticky Footer
        _buildStickyUserCard(data, currentRank),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Total', 'total'),
            const SizedBox(width: 8),
            _buildFilterChip('Weekly', 'weekly'),
            const SizedBox(width: 8),
            _buildFilterChip('Monthly', 'monthly'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
        _loadLeaderboard();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopThreeSection(List<LeaderboardEntry> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No leaderboard data available'));
    }

    // Get top 3
    final topThree = data.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Podium layout
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              if (topThree.length > 1)
                Expanded(
                  child: _buildPodiumStep(
                    entry: topThree[1],
                    position: 2,
                    height: 140, // Increased from 125
                  ),
                ),
              const SizedBox(width: 8),

              // 1st place (tallest)
              Expanded(
                child: _buildPodiumStep(
                  entry: topThree[0],
                  position: 1,
                  height: 175, // Increased from 155
                ),
              ),
              const SizedBox(width: 8),

              // 3rd place
              if (topThree.length > 2)
                Expanded(
                  child: _buildPodiumStep(
                    entry: topThree[2],
                    position: 3,
                    height: 115, // Increased from 95
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Display rankings below podium
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (topThree.length > 1)
                _buildRankingLabel(topThree[1], position: 2),
              _buildRankingLabel(topThree[0], position: 1),
              if (topThree.length > 2)
                _buildRankingLabel(topThree[2], position: 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStep({
    required LeaderboardEntry entry,
    required int position,
    required double height,
  }) {
    final medalColor = _getMedalColor(position);
    final medalIcon = _getMedalIcon(position);
    final ribbonText = position == 1
        ? 'CHAMPION'
        : (position == 2 ? 'CHALLENGER' : 'ELITE');

    return Column(
      children: [
        // Ribbon Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: medalColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: medalColor.withAlpha(60),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            ribbonText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8, // Reduced from 9
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8), // Reduced from 12
        // Medal badge at top
        Container(
          width: 54, // Reduced from 70
          height: 54, // Reduced from 70
          decoration: BoxDecoration(
            color: medalColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: medalColor.withAlpha(100),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              medalIcon,
              size: 32, // Reduced from 40
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Podium step
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: medalColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: medalColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$position',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: medalColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'ID: ${entry.uid.length > 6 ? entry.uid.substring(entry.uid.length - 6) : entry.uid}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.totalPoints} EXP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: medalColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingLabel(LeaderboardEntry entry, {required int position}) {
    return Column(
      children: [
        Text(
          entry.displayName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          'Lvl ${entry.currentLevel}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> data) {
    // If we show podium, we skip top 3 in the list to avoid duplication
    final showPodium = data.length >= 3;
    final displayEntries = showPodium ? data.skip(3).toList() : data;
    final topEntries = displayEntries.length > 20
        ? displayEntries.sublist(0, 20)
        : displayEntries;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'Leaderboard Standings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topEntries.length,
            itemBuilder: (context, index) {
              final entry = topEntries[index];
              final isCurrentUser = entry.isCurrentUser;
              final Color medalColor = _getMedalColor(entry.rank);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? const Color(0xFFEEF2FF)
                      : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E293B)
                            : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCurrentUser
                        ? const Color(0xFF4F46E5).withValues(alpha: 0.3)
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100),
                  ),
                  boxShadow: [
                    if (!isCurrentUser)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: entry.rank <= 3
                              ? LinearGradient(
                                  colors: [
                                    medalColor,
                                    medalColor.withValues(alpha: 0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade100,
                                    Colors.grey.shade200,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                        ),
                      ),
                      Text(
                        '${entry.rank}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: entry.rank <= 3
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(
                        entry.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isCurrentUser
                              ? const Color(0xFF4F46E5)
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF1E293B)),
                        ),
                      ),
                      if (entry.rank <= 3) ...[
                        const SizedBox(width: 6),
                        Icon(
                          _getMedalIcon(entry.rank),
                          size: 16,
                          color: medalColor,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${entry.currentLevel}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        'ID: ${entry.uid.length > 6 ? entry.uid.substring(entry.uid.length - 6) : entry.uid}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${entry.totalPoints}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: entry.rank <= 3
                              ? medalColor
                              : const Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        'EXP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStickyUserCard(List<LeaderboardEntry> data, int? userRank) {
    if (userRank == null) return const SizedBox.shrink();

    // Find current user in the data if possible for points
    final currentUserEntry = data.firstWhere(
      (e) => e.isCurrentUser,
      orElse: () => LeaderboardEntry(
        uid: '',
        displayName: 'You',
        totalPoints: 0,
        lifetimePoints: 0,
        weeklyPoints: 0,
        monthlyPoints: 0,
        currentLevel: 1,
        rank: userRank,
        isCurrentUser: true,
        updatedAt: DateTime.now(),
      ),
    );

    return Positioned(
      bottom: 100, // Adjusted for the floating nav bar
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$_userRank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Your Daily Progress',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const Spacer(),
                      Text(
                        '${currentUserEntry.totalPoints} EXP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentUserEntry.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${currentUserEntry.totalPoints}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'TOTAL EXP',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (currentUserEntry.uid.isNotEmpty)
                  Text(
                    'ID: ${currentUserEntry.uid.length > 6 ? currentUserEntry.uid.substring(currentUserEntry.uid.length - 6) : currentUserEntry.uid}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideY(
      begin: 1.0,
      end: 0,
      curve: Curves.easeOutBack,
      duration: 600.ms,
    );
  }

  Color _getMedalColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  IconData _getMedalIcon(int position) {
    switch (position) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.star_half;
      default:
        return Icons.grade;
    }
  }
}
