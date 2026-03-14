import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Filter locally for search
                final users = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final name = (data['displayName'] ?? '').toString().toLowerCase();
                  return email.contains(_searchQuery) || name.contains(_searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No users found', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final data = userDoc.data() as Map<String, dynamic>;
                    final uid = userDoc.id;
                    
                    return _buildUserCard(context, uid, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, String uid, Map<String, dynamic> data) {
    final email = data['email'] ?? 'No Email';
    final name = data['displayName'] ?? 'User';
    final role = data['role'] ?? 'user';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final points = (data['stats']?['total_points'] ?? 0);
    
    // Safety for points being int or double
    final double displayPoints = points is int ? points.toDouble() : (points as double? ?? 0.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: role == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: TextStyle(
              color: role == 'admin' ? Colors.red.shade800 : Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(email),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${displayPoints.toStringAsFixed(0)} pts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.fingerprint, 'UID', uid),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today, 'Joined', 
                  createdAt != null ? DateFormat.yMMMd().format(createdAt) : 'Unknown'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.shield, 'Role', role.toString().toUpperCase()),
                
                const Divider(height: 32),
                
                // Admin Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context,
                      label: 'Edit Points',
                      icon: Icons.edit,
                      color: Colors.blue,
                      onTap: () => _showEditPointsDialog(context, uid, name, displayPoints),
                    ),
                    _buildActionButton(
                      context,
                      label: 'Make Admin',
                      icon: Icons.admin_panel_settings,
                      color: Colors.orange,
                      onTap: () => _toggleAdminRole(uid, role),
                    ),
                    _buildActionButton(
                      context,
                      label: 'Delete',
                      icon: Icons.delete_forever,
                      color: Colors.red,
                      onTap: () => _confirmDeleteUser(context, uid, email),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        Expanded(child: Text(value, style: const TextStyle(fontFamily: 'monospace'))),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha((255 * 0.1).round()),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha((255 * 0.3).round())),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPointsDialog(BuildContext context, String uid, String name, double currentPoints) async {
    final controller = TextEditingController(text: currentPoints.toStringAsFixed(0));
    final messenger = ScaffoldMessenger.of(context);
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Points for $name'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total Points',
            border: OutlineInputBorder(),
            suffixText: 'pts',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final dialogNavigator = Navigator.of(dialogContext);
              final newPoints = double.tryParse(controller.text);
              if (newPoints != null) {
                await _firestore.collection('users').doc(uid).update({
                  'stats.total_points': newPoints,
                });
                
                // Also update leaderboard collection if used
                try {
                  await _firestore.collection('leaderboard').doc(uid).update({
                    'totalPoints': newPoints,
                  });
                } catch (e) {
                  // Ignore if leaderboard doc doesn't exist
                }
                
                if (!mounted) return;
                dialogNavigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Points updated to ${newPoints.toInt()}')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _toggleAdminRole(String uid, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    await _firestore.collection('users').doc(uid).update({
      'role': newRole,
    });
  }

  Future<void> _confirmDeleteUser(BuildContext context, String uid, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to delete user $email? This will remove their profile data from Firestore. (Note: Auth account deletion requires backend).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    final messenger = ScaffoldMessenger.of(context);

    if (confirm == true) {
      await _firestore.collection('users').doc(uid).delete();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('User $email data deleted')),
      );
    }
  }
}
