import 'package:flutter/material.dart';
import '../services/gamification_service.dart';
import '../screens/rank_progression_screen.dart';

class RankCardWidget extends StatelessWidget {
  final String currentRank;
  final int currentXP;
  final int totalTasksCompleted;
  final int currentStreak;

  const RankCardWidget({
    super.key,
    required this.currentRank,
    required this.currentXP,
    required this.totalTasksCompleted,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final gamificationService = GamificationService();
    final nextRank = gamificationService.getNextRank(currentRank);
    final currentThreshold = gamificationService.getRankThreshold(currentRank);
    final nextThreshold = gamificationService.getRankThreshold(nextRank);

    final isMaxRank = currentRank == nextRank;
    final xpProgress = isMaxRank
        ? 1.0
        : (currentXP - currentThreshold) / (nextThreshold - currentThreshold);
    final xpProgressPercent = (xpProgress * 100).clamp(0, 100).toInt();

    final baseRank = currentRank.split(' ')[0];
    final tier = currentRank.split(' ').length > 1
        ? currentRank.split(' ')[1]
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RankProgressionScreen(
              currentRank: currentRank,
              currentXP: currentXP,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _getRankColor(baseRank).withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Background Gradient with League Theme
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getRankThemeGradients(baseRank),
                    ),
                  ),
                ),
              ),
              // Subtle Pattern/Overlay for texture
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.network(
                    'https://www.transparenttextures.com/patterns/carbon-fibre.png',
                    repeat: ImageRepeat.repeat,
                    fit: BoxFit.none,
                    errorBuilder: (context, e, s) => const SizedBox.shrink(),
                  ),
                ),
              ),
              // Glass Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4), // Outer rim
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(
                              2,
                            ), // Zoomed in effect (reduced from 12)
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.3),
                                  Colors.white.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: Image.asset(
                              _getRankImagePath(baseRank),
                              width: 52, // Increased size (from 42)
                              height: 52,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.shield_rounded,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentRank.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'TIER STATUS: ${tier.isEmpty ? "ELITE" : tier}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt,
                                color: Colors.white,
                                size: 14,
                              ),
                              Text(
                                '$currentXP',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // XP Progress
                    if (!isMaxRank) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'NEXT: ${nextRank.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '$xpProgressPercent%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(seconds: 1),
                            height: 8,
                            width:
                                (MediaQuery.of(context).size.width - 88) *
                                xpProgress,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${nextThreshold - currentXP} XP REMAINING',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            icon: Icons.task_alt_rounded,
                            label: 'COMPLETED',
                            value: totalTasksCompleted.toString(),
                          ),
                          Container(
                            width: 1,
                            height: 25,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          _buildStatColumn(
                            icon: Icons.local_fire_department_rounded,
                            label: 'STREAK',
                            value: '$currentStreak d',
                          ),
                          Container(
                            width: 1,
                            height: 25,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          _buildStatColumn(
                            icon: Icons.auto_awesome_rounded,
                            label: 'LVL',
                            value: (currentXP ~/ 1000 + 1).toString(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  List<Color> _getRankThemeGradients(String rank) {
    switch (rank) {
      case 'Aether':
        return [const Color(0xFF1E293B), const Color(0xFF334155)];
      case 'Vanguard':
        return [const Color(0xFF2563EB), const Color(0xFF3B82F6)];
      case 'Champion':
        return [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)];
      case 'Sentinel':
        return [const Color(0xFF4F46E5), const Color(0xFF6366F1)];
      case 'Gladiator':
        return [const Color(0xFFEA580C), const Color(0xFFF97316)];
      case 'Legion':
        return [const Color(0xFFDC2626), const Color(0xFFEF4444)];
      case 'Imperium':
        return [const Color(0xFFD97706), const Color(0xFFF59E0B)];
      default:
        return [const Color(0xFF64748B), const Color(0xFF94A3B8)];
    }
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Aether':
        return const Color(0xFF64748B); // Slate
      case 'Vanguard':
        return const Color(0xFF3B82F6); // Blue
      case 'Champion':
        return const Color(0xFF8B5CF6); // Violet
      case 'Sentinel':
        return const Color(0xFF6366F1); // Indigo
      case 'Gladiator':
        return const Color(0xFFF97316); // Orange
      case 'Legion':
        return const Color(0xFFEF4444); // Red
      case 'Imperium':
        return const Color(0xFFF59E0B); // Amber
      default:
        return Colors.grey;
    }
  }

  String _getRankImagePath(String rank) {
    switch (rank) {
      case 'Aether':
        return 'assets/images/Aether1.png';
      case 'Vanguard':
        return 'assets/images/Vanguard2.png';
      case 'Champion':
        return 'assets/images/Champion2.png';
      case 'Sentinel':
        return 'assets/images/Sentinel2.png';
      case 'Gladiator':
        return 'assets/images/Gladious21.png';
      case 'Legion':
        return 'assets/images/Legion2.png';
      case 'Imperium':
        return 'assets/images/Imperium2.png';
      default:
        return 'assets/images/Aether1.png';
    }
  }
}
