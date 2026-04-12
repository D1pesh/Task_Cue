import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/leaderboard_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.leaderboard),
              text: 'Leaderboard',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final service = LeaderboardService();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Top users by total points',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LeaderboardEntry>>(
              stream: service.topUsersStream(limit: 50),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return const Center(child: Text('No leaderboard data yet'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final rank = index + 1;
                    final isCurrentUser = currentUid == entry.uid;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isCurrentUser ? Colors.blue.withAlpha((255 * 0.1).toInt()) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentUser ? Colors.blue : Colors.grey.shade200,
                          width: isCurrentUser ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha((255 * 0.1).toInt()),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getRankColor(rank).withAlpha((255 * 0.2).toInt()),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getRankColor(rank),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          entry.displayName,
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha((255 * 0.1).toInt()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${entry.totalPoints.toStringAsFixed(0)} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade600;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  

  
}

