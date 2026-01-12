import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildLeaderboard(),
    );
  }

  Widget _buildLeaderboard() {
    // Sample leaderboard data
    final List<Map<String, dynamic>> leaderboard = [
      {'rank': 1, 'name': 'Alex Johnson', 'points': 2450, 'badge': '👑'},
      {'rank': 2, 'name': 'Sarah Chen', 'points': 2380, 'badge': '🥈'},
      {'rank': 3, 'name': 'Mike Williams', 'points': 2210, 'badge': '🥉'},
      {'rank': 4, 'name': 'Emily Davis', 'points': 1950, 'badge': '⭐'},
      {'rank': 5, 'name': 'You', 'points': 1820, 'badge': '🔥'},
      {'rank': 6, 'name': 'Chris Lee', 'points': 1670, 'badge': '💪'},
      {'rank': 7, 'name': 'Anna Martinez', 'points': 1540, 'badge': '🎯'},
    ];

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
                  'Compete with others and climb the ranks!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final user = leaderboard[index];
                final isCurrentUser = user['name'] == 'You';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrentUser ? Colors.blue : Colors.grey.shade200,
                      width: isCurrentUser ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
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
                        color: _getRankColor(user['rank']).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#${user['rank']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getRankColor(user['rank']),
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          user['name'],
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user['badge'],
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${user['points']} pts',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
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
