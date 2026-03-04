import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Achievements & Badges'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Earned'),
            Tab(icon: Icon(Icons.lock_outline), text: 'Locked'),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _auth.currentUser != null
            ? _firestore
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .snapshots()
            : null,
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData =
              userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final userPoints = (userData['stats']?['total_points'] ?? 0)
              .toDouble();
          final tasksCompleted = (userData['stats']?['tasks_completed'] ?? 0);
          final currentStreak = (userData['stats']?['current_streak'] ?? 0);
          final currentLevel = ((userPoints / 100).floor() + 1);

          final allBadges = _generateAllBadges();
          final earnedBadges = allBadges
              .where(
                (badge) => _isBadgeEarned(
                  badge,
                  tasksCompleted,
                  currentStreak,
                  userPoints,
                  currentLevel,
                ),
              )
              .toList();
          final lockedBadges = allBadges
              .where(
                (badge) => !_isBadgeEarned(
                  badge,
                  tasksCompleted,
                  currentStreak,
                  userPoints,
                  currentLevel,
                ),
              )
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBadgeGrid(
                earnedBadges,
                true,
                tasksCompleted,
                currentStreak,
                userPoints,
                currentLevel,
              ),
              _buildBadgeGrid(
                lockedBadges,
                false,
                tasksCompleted,
                currentStreak,
                userPoints,
                currentLevel,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadgeGrid(
    List<BadgeData> badges,
    bool earned,
    int tasksCompleted,
    int currentStreak,
    double userPoints,
    int currentLevel,
  ) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              earned ? Icons.emoji_events : Icons.lock_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              earned ? 'No badges earned yet' : 'All badges unlocked!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!earned) const SizedBox(height: 8),
            if (!earned)
              Text(
                'Complete tasks to unlock achievements',
                style: TextStyle(color: Colors.grey.shade500),
              ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeCard(
          badge,
          earned,
          tasksCompleted,
          currentStreak,
          userPoints,
          currentLevel,
        );
      },
    );
  }

  Widget _buildBadgeCard(
    BadgeData badge,
    bool earned,
    int tasksCompleted,
    int currentStreak,
    double userPoints,
    int currentLevel,
  ) {
    final progress = _getBadgeProgress(
      badge,
      tasksCompleted,
      currentStreak,
      userPoints,
      currentLevel,
    );
    final progressPercent = (progress * 100).clamp(0, 100).toInt();

    return GestureDetector(
      onTap: () => _showBadgeDetails(context, badge, earned, progress),
      child: Card(
        elevation: earned ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: earned
              ? BorderSide(color: badge.color, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: earned
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      badge.color.withOpacity(0.1),
                      badge.color.withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: earned
                          ? badge.color.withOpacity(0.2)
                          : Colors.grey.shade200,
                      boxShadow: earned
                          ? [
                              BoxShadow(
                                color: badge.color.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        badge.icon,
                        size: 40,
                        color: earned ? badge.color : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  if (!earned && progress > 0)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$progressPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: earned ? Colors.black87 : Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(badge.difficulty).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge.difficulty.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getDifficultyColor(badge.difficulty),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars, size: 14, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '+${badge.points}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
              if (!earned && progress > 0) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(
    BuildContext context,
    BadgeData badge,
    bool earned,
    double progress,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: earned
                    ? badge.color.withOpacity(0.2)
                    : Colors.grey.shade200,
                boxShadow: earned
                    ? [
                        BoxShadow(
                          color: badge.color.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                badge.icon,
                size: 50,
                color: earned ? badge.color : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadgeDetailChip(
                  Icons.stars,
                  '+${badge.points} pts',
                  Colors.amber,
                ),
                const SizedBox(width: 12),
                _buildBadgeDetailChip(
                  Icons.shield,
                  badge.difficulty.toUpperCase(),
                  _getDifficultyColor(badge.difficulty),
                ),
              ],
            ),
            if (!earned) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Progress: ${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                badge.requirement,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'UNLOCKED',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeDetailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  bool _isBadgeEarned(
    BadgeData badge,
    int tasks,
    int streak,
    double points,
    int level,
  ) {
    switch (badge.id) {
      case 'first_task':
        return tasks >= 1;
      case 'task_10':
        return tasks >= 10;
      case 'task_50':
        return tasks >= 50;
      case 'task_100':
        return tasks >= 100;
      case 'task_500':
        return tasks >= 500;
      case 'streak_3':
        return streak >= 3;
      case 'streak_7':
        return streak >= 7;
      case 'streak_30':
        return streak >= 30;
      case 'streak_100':
        return streak >= 100;
      case 'points_100':
        return points >= 100;
      case 'points_1000':
        return points >= 1000;
      case 'points_5000':
        return points >= 5000;
      case 'points_10000':
        return points >= 10000;
      case 'level_5':
        return level >= 5;
      case 'level_10':
        return level >= 10;
      case 'level_25':
        return level >= 25;
      case 'level_50':
        return level >= 50;
      default:
        return false;
    }
  }

  double _getBadgeProgress(
    BadgeData badge,
    int tasks,
    int streak,
    double points,
    int level,
  ) {
    switch (badge.id) {
      case 'first_task':
        return (tasks / 1).clamp(0, 1);
      case 'task_10':
        return (tasks / 10).clamp(0, 1);
      case 'task_50':
        return (tasks / 50).clamp(0, 1);
      case 'task_100':
        return (tasks / 100).clamp(0, 1);
      case 'task_500':
        return (tasks / 500).clamp(0, 1);
      case 'streak_3':
        return (streak / 3).clamp(0, 1);
      case 'streak_7':
        return (streak / 7).clamp(0, 1);
      case 'streak_30':
        return (streak / 30).clamp(0, 1);
      case 'streak_100':
        return (streak / 100).clamp(0, 1);
      case 'points_100':
        return (points / 100).clamp(0, 1);
      case 'points_1000':
        return (points / 1000).clamp(0, 1);
      case 'points_5000':
        return (points / 5000).clamp(0, 1);
      case 'points_10000':
        return (points / 10000).clamp(0, 1);
      case 'level_5':
        return (level / 5).clamp(0, 1);
      case 'level_10':
        return (level / 10).clamp(0, 1);
      case 'level_25':
        return (level / 25).clamp(0, 1);
      case 'level_50':
        return (level / 50).clamp(0, 1);
      default:
        return 0;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'epic':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  List<BadgeData> _generateAllBadges() {
    return [
      // Task milestones
      BadgeData(
        id: 'first_task',
        name: 'Getting Started',
        description: 'Complete your first task',
        icon: Icons.flag,
        color: Colors.green,
        difficulty: 'easy',
        points: 25,
        requirement: 'Complete 1 task',
      ),
      BadgeData(
        id: 'task_10',
        name: 'Productive',
        description: 'Complete 10 tasks',
        icon: Icons.trending_up,
        color: Colors.blue,
        difficulty: 'easy',
        points: 50,
        requirement: 'Complete 10 tasks',
      ),
      BadgeData(
        id: 'task_50',
        name: 'Task Master',
        description: 'Complete 50 tasks',
        icon: Icons.workspace_premium,
        color: Colors.indigo,
        difficulty: 'medium',
        points: 100,
        requirement: 'Complete 50 tasks',
      ),
      BadgeData(
        id: 'task_100',
        name: 'Century Club',
        description: 'Complete 100 tasks',
        icon: Icons.military_tech,
        color: Colors.deepPurple,
        difficulty: 'hard',
        points: 200,
        requirement: 'Complete 100 tasks',
      ),
      BadgeData(
        id: 'task_500',
        name: 'Legend',
        description: 'Complete 500 tasks',
        icon: Icons.emoji_events,
        color: Colors.amber.shade800,
        difficulty: 'epic',
        points: 500,
        requirement: 'Complete 500 tasks',
      ),

      // Streak milestones
      BadgeData(
        id: 'streak_3',
        name: 'On a Roll',
        description: '3-day streak',
        icon: Icons.whatshot,
        color: Colors.orange,
        difficulty: 'easy',
        points: 30,
        requirement: 'Maintain a 3-day streak',
      ),
      BadgeData(
        id: 'streak_7',
        name: 'Week Warrior',
        description: '7-day streak',
        icon: Icons.local_fire_department,
        color: Colors.deepOrange,
        difficulty: 'medium',
        points: 75,
        requirement: 'Maintain a 7-day streak',
      ),
      BadgeData(
        id: 'streak_30',
        name: 'Unstoppable',
        description: '30-day streak',
        icon: Icons.local_fire_department,
        color: Colors.red,
        difficulty: 'hard',
        points: 200,
        requirement: 'Maintain a 30-day streak',
      ),
      BadgeData(
        id: 'streak_100',
        name: 'Eternal Flame',
        description: '100-day streak',
        icon: Icons.local_fire_department,
        color: Colors.purple.shade800,
        difficulty: 'epic',
        points: 500,
        requirement: 'Maintain a 100-day streak',
      ),

      // Points milestones
      BadgeData(
        id: 'points_100',
        name: 'Point Starter',
        description: 'Earn 100 points',
        icon: Icons.stars,
        color: Colors.amber,
        difficulty: 'easy',
        points: 25,
        requirement: 'Earn 100 total points',
      ),
      BadgeData(
        id: 'points_1000',
        name: 'Point Collector',
        description: 'Earn 1,000 points',
        icon: Icons.star,
        color: Colors.amber.shade700,
        difficulty: 'medium',
        points: 100,
        requirement: 'Earn 1,000 total points',
      ),
      BadgeData(
        id: 'points_5000',
        name: 'Point Master',
        description: 'Earn 5,000 points',
        icon: Icons.grade,
        color: Colors.amber.shade900,
        difficulty: 'hard',
        points: 250,
        requirement: 'Earn 5,000 total points',
      ),
      BadgeData(
        id: 'points_10000',
        name: 'Point Legend',
        description: 'Earn 10,000 points',
        icon: Icons.auto_awesome,
        color: Colors.yellow.shade900,
        difficulty: 'epic',
        points: 500,
        requirement: 'Earn 10,000 total points',
      ),

      // Level milestones
      BadgeData(
        id: 'level_5',
        name: 'Rising Star',
        description: 'Reach level 5',
        icon: Icons.arrow_upward,
        color: Colors.cyan,
        difficulty: 'easy',
        points: 50,
        requirement: 'Reach level 5',
      ),
      BadgeData(
        id: 'level_10',
        name: 'Expert',
        description: 'Reach level 10',
        icon: Icons.verified,
        color: Colors.teal,
        difficulty: 'medium',
        points: 100,
        requirement: 'Reach level 10',
      ),
      BadgeData(
        id: 'level_25',
        name: 'Elite',
        description: 'Reach level 25',
        icon: Icons.diamond,
        color: Colors.blue.shade900,
        difficulty: 'hard',
        points: 250,
        requirement: 'Reach level 25',
      ),
      BadgeData(
        id: 'level_50',
        name: 'Grandmaster',
        description: 'Reach level 50',
        icon: Icons.castle,
        color: Colors.deepPurple.shade900,
        difficulty: 'epic',
        points: 500,
        requirement: 'Reach level 50',
      ),
    ];
  }
}

class BadgeData {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String difficulty;
  final int points;
  final String requirement;

  BadgeData({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.difficulty,
    required this.points,
    required this.requirement,
  });
}
