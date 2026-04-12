import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class AchievementCongratulationsDialog extends StatelessWidget {
  final List<Map<String, String>> achievements;
  final VoidCallback onContinue;

  const AchievementCongratulationsDialog({
    super.key,
    required this.achievements,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Main Card
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : const Color(0xFF4F46E5)).withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CONGRATULATIONS!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                    letterSpacing: 2,
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),
                
                const SizedBox(height: 8),
                
                Text(
                  'You\'ve unlocked ${achievements.length} new ${achievements.length == 1 ? 'achievement' : 'achievements'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                
                const SizedBox(height: 24),
                
                // Achievement List
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      return _buildAchievementItem(context, achievement, index);
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                    ),
                    child: const Text(
                      'AWESOME!',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
          
          // Trophy Icon / Header Art
          Positioned(
            top: -50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 60,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds, curve: Curves.easeInOut)
             .shimmer(delay: 2.seconds, duration: 2.seconds),
          ),
          
          // Confetti particles (simplified)
          ...List.generate(12, (index) {
            final random = math.Random(index);
            final angle = random.nextDouble() * 2 * math.pi;
            final distance = 100.0 + random.nextDouble() * 50.0;
            return Positioned(
              left: 200 + math.cos(angle) * distance,
              top: 50 + math.sin(angle) * distance,
              child: _buildConfettiParticle(index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(BuildContext context, Map<String, String> achievement, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['name'] ?? 'Achievement',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  achievement['description'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (600 + index * 150).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildConfettiParticle(int index) {
    final colors = [Colors.blue, Colors.green, Colors.yellow, Colors.pink, Colors.purple, Colors.orange];
    final color = colors[index % colors.length];
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: index % 2 == 0 ? BoxShape.circle : BoxShape.rectangle,
      ),
    ).animate().fadeIn(duration: 500.ms).moveY(begin: 0, end: 300, duration: 2.seconds, curve: Curves.easeOutQuad).rotate(end: 2);
  }
}
