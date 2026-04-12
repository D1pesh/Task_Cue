import 'package:flutter/material.dart';

class PrestigeDisplayWidget extends StatelessWidget {
  final Map<String, int> prestigeRanks;

  const PrestigeDisplayWidget({
    super.key,
    required this.prestigeRanks,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by rank order (highest to lowest)
    final sortedEntries = prestigeRanks.entries.toList()
      ..sort((a, b) {
        final rankOrder = [
          'Imperium',
          'Legion',
          'Gladiator',
          'Sentinel',
          'Champion',
          'Vanguard',
          'Aether',
        ];
        return rankOrder.indexOf(a.key).compareTo(rankOrder.indexOf(b.key));
      });

    // Filter out ranks with 0 prestiges
    final displayEntries =
        sortedEntries.where((entry) => entry.value > 0).toList();

    if (displayEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No Prestige Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete months to earn prestige',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade50,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.military_tech,
                  color: Colors.amber.shade800,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRESTIGE RANKS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Lifetime achievements',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.amber),
          const SizedBox(height: 12),
          ...displayEntries.map((entry) => _buildPrestigeItem(
                rank: entry.key,
                count: entry.value,
              )),
        ],
      ),
    );
  }

  Widget _buildPrestigeItem({
    required String rank,
    required int count,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getRankColor(rank).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _getRankColor(rank).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getRankColor(rank).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getRankIcon(rank),
              color: _getRankColor(rank),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rank.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getRankColor(rank),
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getRankColor(rank),
                  _getRankColor(rank).withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.close, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Aether':
        return Colors.blueGrey;
      case 'Vanguard':
        return Colors.blue;
      case 'Champion':
        return Colors.purple;
      case 'Sentinel':
        return Colors.indigo;
      case 'Gladiator':
        return Colors.deepOrange;
      case 'Legion':
        return Colors.red.shade800;
      case 'Imperium':
        return Colors.amber.shade800;
      default:
        return Colors.grey;
    }
  }

  IconData _getRankIcon(String rank) {
    switch (rank) {
      case 'Aether':
        return Icons.abc;
      case 'Vanguard':
        return Icons.shield;
      case 'Champion':
        return Icons.military_tech;
      case 'Sentinel':
        return Icons.security;
      case 'Gladiator':
        return Icons.sports_martial_arts;
      case 'Legion':
        return Icons.groups;
      case 'Imperium':
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }
}
