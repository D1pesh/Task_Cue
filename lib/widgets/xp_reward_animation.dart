import 'package:flutter/material.dart';

class XPRewardAnimation extends StatefulWidget {
  final int xpEarned;
  final List<String> bonuses;
  final bool rankedUp;
  final String? newRank;
  final List<Map<String, String>>? newAchievements;

  const XPRewardAnimation({
    super.key,
    required this.xpEarned,
    required this.bonuses,
    this.rankedUp = false,
    this.newRank,
    this.newAchievements,
  });

  static Future<void> show(
    BuildContext context, {
    required int xpEarned,
    required List<String> bonuses,
    bool rankedUp = false,
    String? newRank,
    List<Map<String, String>>? newAchievements,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => XPRewardAnimation(
        xpEarned: xpEarned,
        bonuses: bonuses,
        rankedUp: rankedUp,
        newRank: newRank,
        newAchievements: newAchievements,
      ),
    );
  }

  @override
  State<XPRewardAnimation> createState() => _XPRewardAnimationState();
}

class _XPRewardAnimationState extends State<XPRewardAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto dismiss after 3 seconds if no rank up or achievements
    if (!widget.rankedUp && (widget.newAchievements?.isEmpty ?? true)) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade700,
                Colors.blue.shade700,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(128, 0, 128, 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // XP Earned
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Icon(
                      Icons.stars,
                      size: 64,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '+${widget.xpEarned} XP',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'EARNED',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // Bonuses
              if (widget.bonuses.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(color: Colors.white54),
                const SizedBox(height: 12),
                ...widget.bonuses.map((bonus) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            bonus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              // Rank Up
              if (widget.rankedUp && widget.newRank != null) ...[
                const SizedBox(height: 20),
                const Divider(color: Colors.white54),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 193, 7, 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.amber, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'RANK UP!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.newRank!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // New Achievements
              if (widget.newAchievements != null &&
                  widget.newAchievements!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(color: Colors.white54),
                const SizedBox(height: 12),
                const Text(
                  'NEW ACHIEVEMENTS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.newAchievements!.map(
                  (achievement) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.military_tech,
                            color: Colors.amber, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                achievement['description'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Close button
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
