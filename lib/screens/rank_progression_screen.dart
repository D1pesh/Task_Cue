import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gamification_service.dart';

class RankProgressionScreen extends StatelessWidget {
  final String currentRank;
  final int currentXP;

  const RankProgressionScreen({
    super.key,
    required this.currentRank,
    required this.currentXP,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    
    final ranks = GamificationService.rankOrder;
    final currentRankIndex = ranks.indexOf(currentRank);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Rank Journey', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Vertical Line
          Positioned(
            left: 48,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.withValues(alpha: 0.1),
                    const Color(0xFF4F46E5).withValues(alpha: 0.3),
                    const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 40),
            itemCount: ranks.length,
            itemBuilder: (context, index) {
              final rank = ranks[index];
              final isAchieved = index <= currentRankIndex;
              final isCurrent = index == currentRankIndex;
              final threshold = GamificationService.rankThresholds[rank] ?? 0;
              final baseRank = rank.split(' ')[0];
              
              return _buildRankMilestone(
                context, 
                rank: rank, 
                baseRank: baseRank,
                threshold: threshold,
                isAchieved: isAchieved,
                isCurrent: isCurrent,
                index: index,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankMilestone(
    BuildContext context, {
    required String rank,
    required String baseRank,
    required int threshold,
    required bool isAchieved,
    required bool isCurrent,
    required int index,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankColor = _getRankColor(baseRank);
    final tier = rank.split(' ').length > 1 ? rank.split(' ').last : '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circle Indicator with Overlays
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 65, // Increased from 60
                height: 65, // Increased from 60
                decoration: BoxDecoration(
                  color: isAchieved 
                    ? rankColor 
                    : (isDark ? rankColor.withValues(alpha: 0.15) : rankColor.withValues(alpha: 0.1)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAchieved 
                        ? Colors.white.withValues(alpha: 0.5) 
                        : rankColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    if (isAchieved)
                      BoxShadow(
                        color: rankColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isAchieved ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ) : null,
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: isAchieved ? 1.0 : 0.65, // Increased from 0.4
                      child: Image.asset(
                        _getRankImagePath(baseRank),
                        width: 52,
                        height: 52,
                        fit: BoxFit.contain,
                        errorBuilder: (context, e, s) => Icon(
                          Icons.shield_rounded, 
                          color: isAchieved ? Colors.white : rankColor.withValues(alpha: 0.5),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Roman Numeral Badge (I, II, III)
              if (tier.isNotEmpty)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAchieved ? const Color(0xFF1E293B) : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      tier,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

              // Locked Icon
              if (!isAchieved)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          
          // Rank Info Card
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isCurrent ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getRankThemeGradients(baseRank).map((c) => c.withValues(alpha: 0.15)).toList(),
                ) : null,
                color: isCurrent 
                    ? null 
                    : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCurrent 
                      ? rankColor.withValues(alpha: 0.5) 
                      : (isAchieved ? rankColor.withValues(alpha: 0.2) : Colors.transparent),
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Header
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: _getRankThemeGradients(baseRank),
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              rank.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isAchieved 
                                    ? (isDark ? Colors.white : Colors.black87) 
                                    : Colors.grey,
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: rankColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'CURRENT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Requires $threshold XP',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAchieved ? (isDark ? Colors.white70 : Colors.black54) : Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isCurrent && index < GamificationService.rankOrder.length - 1) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Next Milestone: ${GamificationService.rankThresholds[GamificationService.rankOrder[index + 1]]! - currentXP} XP to go',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: rankColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
    );
  }

  List<Color> _getRankThemeGradients(String rank) {
    switch (rank) {
      case 'Aether': return [const Color(0xFF1E293B), const Color(0xFF334155)];
      case 'Vanguard': return [const Color(0xFF2563EB), const Color(0xFF3B82F6)];
      case 'Champion': return [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)];
      case 'Sentinel': return [const Color(0xFF4F46E5), const Color(0xFF6366F1)];
      case 'Gladiator': return [const Color(0xFFEA580C), const Color(0xFFF97316)];
      case 'Legion': return [const Color(0xFFDC2626), const Color(0xFFEF4444)];
      case 'Imperium': return [const Color(0xFFD97706), const Color(0xFFF59E0B)];
      default: return [const Color(0xFF64748B), const Color(0xFF94A3B8)];
    }
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Aether': return const Color(0xFF64748B);
      case 'Vanguard': return const Color(0xFF3B82F6);
      case 'Champion': return const Color(0xFF8B5CF6);
      case 'Sentinel': return const Color(0xFF6366F1);
      case 'Gladiator': return const Color(0xFFF97316);
      case 'Legion': return const Color(0xFFEF4444);
      case 'Imperium': return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  String _getRankImagePath(String rank) {
    switch (rank) {
      case 'Aether': return 'assets/images/Aether1.png';
      case 'Vanguard': return 'assets/images/Vanguard2.png';
      case 'Champion': return 'assets/images/Champion2.png';
      case 'Sentinel': return 'assets/images/Sentinel2.png';
      case 'Gladiator': return 'assets/images/Gladious21.png';
      case 'Legion': return 'assets/images/Legion2.png';
      case 'Imperium': return 'assets/images/Imperium2.png';
      default: return 'assets/images/Aether1.png';
    }
  }
}
