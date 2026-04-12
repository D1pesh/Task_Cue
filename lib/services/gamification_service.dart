import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'leaderboard_service.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Rank thresholds
  static const Map<String, int> rankThresholds = {
    'Aether III': 0,
    'Aether II': 150,
    'Aether I': 300,
    'Vanguard III': 500,
    'Vanguard II': 750,
    'Vanguard I': 950,
    'Champion III': 1200,
    'Champion II': 1500,
    'Champion I': 1850,
    'Sentinel III': 2200,
    'Sentinel II': 2700,
    'Sentinel I': 3200,
    'Gladiator III': 3800,
    'Gladiator II': 4400,
    'Gladiator I': 5100,
    'Legion III': 5800,
    'Legion II': 6600,
    'Legion I': 7500,
    'Imperium': 8500,
  };

  static const List<String> rankOrder = [
    'Aether III', 'Aether II', 'Aether I',
    'Vanguard III', 'Vanguard II', 'Vanguard I',
    'Champion III', 'Champion II', 'Champion I',
    'Sentinel III', 'Sentinel II', 'Sentinel I',
    'Gladiator III', 'Gladiator II', 'Gladiator I',
    'Legion III', 'Legion II', 'Legion I',
    'Imperium',
  ];

  // Calculate XP for a completed task
  Future<Map<String, dynamic>> calculateTaskXP({
    required String difficulty,
    required String priority,
    required int durationMinutes,
    required String category,
    Map<String, dynamic>? cachedUserData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return {'xp': 0, 'bonuses': []};

    // 1. Base XP from difficulty
    int baseXP = _getBaseXP(difficulty);

    // 2. Priority multiplier
    double priorityMultiplier = _getPriorityMultiplier(priority);

    // 3. Duration bonus (capped)
    int durationBonus = _getDurationBonus(durationMinutes);

    // 4. Get user stats 
    Map<String, dynamic> userData = cachedUserData ?? {};
    if (cachedUserData == null) {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        userData = userDoc.data() ?? {};
      } catch (e) {
        try {
           final userDoc = await _firestore.collection('users').doc(user.uid).get(const GetOptions(source: Source.cache));
           userData = userDoc.data() ?? {};
        } catch (_) {}
      }
    }
    
    final stats = userData['gamification'] as Map<String, dynamic>? ?? {};

    // 5. Streak multiplier
    final currentStreak = stats['currentStreak'] ?? 0;
    double streakMultiplier = _getStreakMultiplier(currentStreak);

    // 6. Get today's category usage
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final dailyCategories = stats['dailyCategories'] as Map<String, dynamic>? ?? {};
    final todaysCategories = Set<String>.from(dailyCategories[todayKey] ?? []);
    todaysCategories.add(category);

    // 7. Balance bonus (3+ categories today)
    double balanceBonus = todaysCategories.length >= 3 ? 1.15 : 1.0;

    // 8. Focus bonus (3+ tasks in same category today)
    final dailyTasksByCategory = stats['dailyTasksByCategory'] as Map<String, dynamic>? ?? {};
    final todaysCategoryTasks = dailyTasksByCategory[todayKey] as Map<String, dynamic>? ?? {};
    final categoryCount = (todaysCategoryTasks[category] ?? 0) + 1;
    double focusBonus = categoryCount >= 3 ? 1.20 : 1.0;

    // 9. Calculate final XP
    double rawXP = (baseXP * priorityMultiplier + durationBonus) *
        streakMultiplier *
        balanceBonus *
        focusBonus;
    int finalXP = rawXP.round();

    // Track applied bonuses
    List<String> bonuses = [];
    if (streakMultiplier > 1.0) bonuses.add('Streak ×${streakMultiplier.toStringAsFixed(2)}');
    if (balanceBonus > 1.0) bonuses.add('Balance Bonus');
    if (focusBonus > 1.0) bonuses.add('Focus Bonus');
    if (durationBonus > 0) bonuses.add('+$durationBonus Duration');

    return {
      'xp': finalXP,
      'bonuses': bonuses,
      'baseXP': baseXP,
      'priorityMultiplier': priorityMultiplier,
      'durationBonus': durationBonus,
      'streakMultiplier': streakMultiplier,
      'balanceBonus': balanceBonus,
      'focusBonus': focusBonus,
      'categoryCount': categoryCount,
      'todaysCategories': todaysCategories.toList(),
    };
  }

  // Award XP and update progression
  Future<Map<String, dynamic>> awardTaskCompletion({
    required String difficulty,
    required String priority,
    required int durationMinutes,
    required String category,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final userRef = _firestore.collection('users').doc(user.uid);
    
    // MASTER READ: Fetch user data once
    Map<String, dynamic> userData = {};
    try {
      final userDoc = await userRef.get();
      userData = userDoc.data() ?? {};
    } catch (_) {
      try {
        final userDoc = await userRef.get(const GetOptions(source: Source.cache));
        userData = userDoc.data() ?? {};
      } catch (_) {}
    }

    // Update streak locally (non-blocking)
    final streakResult = _calculateNewStreak(userData);
    
    // Calculate XP using cached data
    final xpData = await calculateTaskXP(
      difficulty: difficulty,
      priority: priority,
      durationMinutes: durationMinutes,
      category: category,
      cachedUserData: userData,
    );
    
    final xpEarned = xpData['xp'] as int;
    final bonuses = xpData['bonuses'] as List<String>;
    final todaysCategories = xpData['todaysCategories'] as List<String>;
    final categoryCount = xpData['categoryCount'] as int;
    
    final stats = userData['gamification'] as Map<String, dynamic>? ?? {};

    // Get current values
    int currentMonthXP = stats['currentMonthXP'] ?? 0;
    String currentRank = stats['currentRank'] ?? 'Aether III';
    int totalTasksCompleted = (stats['totalTasksCompleted'] ?? 0) + 1;

    // Update XP
    int newMonthXP = currentMonthXP + xpEarned;

    // Check for rank up
    String newRank = _calculateRank(newMonthXP);
    bool rankedUp = rankOrder.indexOf(newRank) > rankOrder.indexOf(currentRank);

    // Update daily tracking
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    Map<String, dynamic> dailyCategories = Map<String, dynamic>.from(stats['dailyCategories'] ?? {});
    dailyCategories[todayKey] = todaysCategories;

    Map<String, dynamic> dailyTasksByCategory = Map<String, dynamic>.from(stats['dailyTasksByCategory'] ?? {});
    Map<String, dynamic> todaysCategoryTasks = Map<String, dynamic>.from(dailyTasksByCategory[todayKey] ?? {});
    todaysCategoryTasks[category] = categoryCount;
    dailyTasksByCategory[todayKey] = todaysCategoryTasks;

    // Update task counts by attributes
    Map<String, int> difficultyCount = Map<String, int>.from(stats['tasksByDifficulty'] ?? {});
    difficultyCount[difficulty] = (difficultyCount[difficulty] ?? 0) + 1;

    Map<String, int> priorityCount = Map<String, int>.from(stats['tasksByPriority'] ?? {});
    priorityCount[priority] = (priorityCount[priority] ?? 0) + 1;

    Map<String, int> categoryTaskCount = Map<String, int>.from(stats['tasksByCategory'] ?? {});
    categoryTaskCount[category] = (categoryTaskCount[category] ?? 0) + 1;

    int longTaskCount = durationMinutes >= 60 ? (stats['longTaskCount'] ?? 0) + 1 : (stats['longTaskCount'] ?? 0);

    // Check achievements
    final achievementResults = await _checkAchievements(
      totalTasks: totalTasksCompleted,
      currentStreak: streakResult['streak']!,
      newRank: newRank,
      rankedUp: rankedUp,
      longTaskCount: longTaskCount,
      priorityCount: priorityCount,
      categoryTaskCount: categoryTaskCount,
      dailyCategories: dailyCategories,
      todaysCategories: todaysCategories,
      userData: userData,
    );
    final newAchievements = achievementResults['newlyUnlocked'] as List<Map<String, String>>;

    // Update Firestore in one batch
    await userRef.set({
      'gamification': {
        'currentMonthXP': newMonthXP,
        'currentRank': newRank,
        'totalTasksCompleted': totalTasksCompleted,
        'dailyCategories': dailyCategories,
        'dailyTasksByCategory': dailyTasksByCategory,
        'tasksByDifficulty': difficultyCount,
        'tasksByPriority': priorityCount,
        'tasksByCategory': categoryTaskCount,
        'longTaskCount': longTaskCount,
        'lastTaskCompletedAt': FieldValue.serverTimestamp(),
        'currentStreak': streakResult['streak'],
        'longestStreak': streakResult['longestStreak'],
        'achievementsUnlocked': achievementResults['fullList'],
      }
    }, SetOptions(merge: true));

    // 10. Instant Sync with global Leaderboard
    try {
      final leaderboardService = LeaderboardService();
      String displayName = userData['displayName'] ?? user.displayName ?? 'User';
      
      // Calculate level based on unified XP progression
      int level = (newMonthXP / 1000).floor() + 1;

      // Force push latest stats to leaderboard collection
      // This triggers real-time listeners on the Leaderboard screen
      await leaderboardService.updateUserPoints(
        uid: user.uid,
        displayName: displayName,
        totalPoints: newMonthXP,
        currentLevel: level,
        weeklyPoints: newMonthXP,
        monthlyPoints: newMonthXP,
      );
      
      debugPrint('Instant leaderboard sync successful for ${user.uid}');
    } catch (e) {
      debugPrint('Instant leaderboard sync failed: $e');
    }

    return {
      'xpEarned': xpEarned,
      'bonuses': bonuses,
      'newMonthXP': newMonthXP,
      'newRank': newRank,
      'rankedUp': rankedUp,
      'newAchievements': newAchievements,
    };
  }

  // Check and unlock achievements
  Future<Map<String, dynamic>> _checkAchievements({
    required int totalTasks,
    required int currentStreak,
    required String newRank,
    required bool rankedUp,
    required int longTaskCount,
    required Map<String, int> priorityCount,
    required Map<String, int> categoryTaskCount,
    required Map<String, dynamic> dailyCategories,
    required List<String> todaysCategories,
    required Map<String, dynamic> userData,
  }) async {
    final stats = userData['gamification'] as Map<String, dynamic>? ?? {};
    final unlockedAchievements = Set<String>.from(stats['achievementsUnlocked'] ?? []);
    final newlyUnlocked = <Map<String, String>>[];

    // Helper to unlock achievement
    void unlock(String id, String name, String description) {
      if (!unlockedAchievements.contains(id)) {
        unlockedAchievements.add(id);
        newlyUnlocked.add({'id': id, 'name': name, 'description': description});
      }
    }

    // First Progress achievements
    if (totalTasks >= 1) unlock('first_oath', 'First Oath', 'Complete your first task');
    if (totalTasks >= 10) unlock('initiate_action', 'Initiate of Action', 'Complete 10 tasks');
    if (totalTasks >= 50) unlock('pathfinder', 'Pathfinder', 'Complete 50 tasks');
    if (totalTasks >= 100) unlock('builder_discipline', 'Builder of Discipline', 'Complete 100 tasks');
    if (totalTasks >= 250) unlock('veteran_deeds', 'Veteran of Deeds', 'Complete 250 tasks');

    // Consistency achievements
    if (currentStreak >= 3) unlock('spark_discipline', 'Spark of Discipline', '3 day streak');
    if (currentStreak >= 7) unlock('keeper_week', 'Keeper of the Week', '7 day streak');
    if (currentStreak >= 14) unlock('warden_fortnight', 'Warden of Fortnight', '14 day streak');
    if (currentStreak >= 30) unlock('guardian_cycle', 'Guardian of the Cycle', '30 day streak');
    if (currentStreak >= 90) unlock('iron_resolve', 'Iron Resolve', '90 day streak');
    if (currentStreak >= 180) unlock('unbroken_will', 'Unbroken Will', '180 day streak');
    if (currentStreak >= 365) unlock('eternal_discipline', 'Eternal Discipline', '365 day streak');

    // Focus achievements
    if (longTaskCount >= 5) unlock('student_focus', 'Student of Focus', 'Complete 5 long tasks');
    if (longTaskCount >= 20) unlock('disciple_depth', 'Disciple of Depth', 'Complete 20 long tasks');
    if (longTaskCount >= 50) unlock('iron_mind', 'Iron Mind', 'Complete 50 long tasks');
    if (longTaskCount >= 100) unlock('master_concentration', 'Master of Concentration', 'Complete 100 long tasks');

    // Priority achievements
    final highPriorityCount = priorityCount['High'] ?? 0;
    if (highPriorityCount >= 10) unlock('responder', 'Responder', 'Complete 10 high priority tasks');
    if (highPriorityCount >= 30) unlock('strategist', 'Strategist', 'Complete 30 high priority tasks');
    if (highPriorityCount >= 75) unlock('commander_urgency', 'Commander of Urgency', 'Complete 75 high priority tasks');
    if (highPriorityCount >= 150) unlock('master_critical', 'Master of Critical Paths', 'Complete 150 high priority tasks');

    // Balance achievements
    if (todaysCategories.length >= 3) unlock('seeker_balance', 'Seeker of Balance', '3 categories in one day');
    
    // Check weekly categories
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekCategories = <String>{};
    dailyCategories.forEach((key, value) {
      final parts = key.split('-');
      if (parts.length == 3) {
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        if (date.isAfter(weekAgo)) {
          weekCategories.addAll(List<String>.from(value));
        }
      }
    });
    if (weekCategories.length >= 5) unlock('walker_realms', 'Walker of Realms', '5 categories in a week');

    // Rank achievements
    if (rankedUp) {
      if (newRank.contains('Vanguard')) unlock('vanguard_ascended', 'Vanguard Ascended', 'Reach Vanguard rank');
      if (newRank.contains('Champion')) unlock('champion_forged', 'Champion Forged', 'Reach Champion rank');
      if (newRank.contains('Sentinel')) unlock('sentinel_awakened', 'Sentinel Awakened', 'Reach Sentinel rank');
      if (newRank.contains('Gladiator')) unlock('gladiator_unleashed', 'Gladiator Unleashed', 'Reach Gladiator rank');
      if (newRank.contains('Legion')) unlock('legion_commander', 'Legion Commander', 'Reach Legion rank');
      if (newRank.contains('Imperium')) unlock('imperium_crowned', 'Imperium Crowned', 'Reach Imperium rank');
    }

    return {
      'newlyUnlocked': newlyUnlocked,
      'fullList': unlockedAchievements.toList(),
    };
  }

  // Internal helper to calculate new streak without extra reads
  Map<String, int> _calculateNewStreak(Map<String, dynamic> userData) {
    final stats = userData['gamification'] as Map<String, dynamic>? ?? {};
    final lastCompletedTimestamp = stats['lastTaskCompletedAt'] as Timestamp?;
    final currentStreak = stats['currentStreak'] ?? 0;
    final longestStreak = stats['longestStreak'] ?? 0;

    if (lastCompletedTimestamp == null) {
      return {'streak': 1, 'longestStreak': 1};
    }

    final lastCompleted = lastCompletedTimestamp.toDate();
    final now = DateTime.now();
    final lastDate = DateTime(lastCompleted.year, lastCompleted.month, lastCompleted.day);
    final today = DateTime(now.year, now.month, now.day);
    final daysDiff = today.difference(lastDate).inDays;

    int newStreak = currentStreak;
    if (daysDiff == 1) {
      newStreak = currentStreak + 1;
    } else if (daysDiff > 1) {
      newStreak = 1;
    }

    return {
      'streak': newStreak,
      'longestStreak': math.max(longestStreak, newStreak),
    };
  }

  // Award streak separately if needed (legacy or manual update)
  Future<void> updateStreak() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();
    final res = _calculateNewStreak(doc.data() ?? {});
    await userRef.set({
      'gamification': {
        'currentStreak': res['streak'],
        'longestStreak': res['longestStreak'],
      }
    }, SetOptions(merge: true));
  }

  // Monthly reset
  Future<void> performMonthlyReset() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();
    final userData = userDoc.data() ?? {};
    final stats = userData['gamification'] as Map<String, dynamic>? ?? {};

    final currentRank = stats['currentRank'] ?? 'Aether';
    final prestigeRanks = Map<String, int>.from(stats['prestigeRanks'] ?? {});

    // Increment prestige for achieved rank
    if (currentRank != 'Aether III') {
      prestigeRanks[currentRank] = (prestigeRanks[currentRank] ?? 0) + 1;
    }

    // Reset monthly progression
    await userRef.set({
      'gamification': {
        'currentMonthXP': 0,
        'currentRank': 'Aether III',
        'prestigeRanks': prestigeRanks,
        'lastMonthlyReset': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  }

  // Helper methods
  int _getBaseXP(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'low':
        return 10;
      case 'medium':
        return 20;
      case 'high':
        return 35;
      default:
        return 10;
    }
  }

  double _getPriorityMultiplier(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return 1.0;
      case 'medium':
        return 1.2;
      case 'high':
        return 1.5;
      default:
        return 1.0;
    }
  }

  int _getDurationBonus(int minutes) {
    if (minutes < 30) return 0;
    if (minutes < 60) return 5;
    if (minutes < 120) return 10;
    return 15; // Capped at 15
  }

  double _getStreakMultiplier(int streak) {
    if (streak >= 365) return 1.30;
    if (streak >= 180) return 1.25;
    if (streak >= 90) return 1.20;
    if (streak >= 30) return 1.15;
    if (streak >= 14) return 1.10;
    if (streak >= 7) return 1.05;
    return 1.0;
  }

  String _calculateRank(int xp) {
    for (int i = rankOrder.length - 1; i >= 0; i--) {
      final rank = rankOrder[i];
      if (xp >= rankThresholds[rank]!) {
        return rank;
      }
    }
    return 'Aether III';
  }

  int getRankThreshold(String rank) {
    return rankThresholds[rank] ?? 0;
  }

  String getNextRank(String currentRank) {
    final index = rankOrder.indexOf(currentRank);
    if (index < 0 || index >= rankOrder.length - 1) return currentRank;
    return rankOrder[index + 1];
  }
}
