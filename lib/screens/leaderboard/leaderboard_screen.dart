import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _globalLeaders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      
      // Get weekly scores
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final weekAgoStr = weekAgo.toIso8601String().split('T')[0];

      final response = await supabase
          .from('accomplishments')
          .select('user_id, score, profiles!inner(name, avatar_url)')
          .gte('logged_date', weekAgoStr);

      // Aggregate scores by user
      final userScores = <String, Map<String, dynamic>>{};
      for (final item in response as List) {
        final userId = item['user_id'] as String;
        final score = item['score'] as int;
        final profile = item['profiles'] as Map<String, dynamic>;

        if (!userScores.containsKey(userId)) {
          userScores[userId] = {
            'userId': userId,
            'name': profile['name'] ?? 'Anonymous',
            'avatarUrl': profile['avatar_url'],
            'totalScore': 0,
            'count': 0,
          };
        }
        userScores[userId]!['totalScore'] += score;
        userScores[userId]!['count'] += 1;
      }

      _globalLeaders = userScores.values.toList()
        ..sort((a, b) => (b['totalScore'] as int).compareTo(a['totalScore'] as int));
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5CF6),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[500],
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'My Groups'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGlobalLeaderboard(),
                _buildGroupsTab(),
              ],
            ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    if (_globalLeaders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No leaderboard data yet',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _globalLeaders.length,
        itemBuilder: (context, index) {
          final leader = _globalLeaders[index];
          final isTop3 = index < 3;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTop3 ? const Color(0xFF8B5CF6) : const Color(0xFF27272A),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isTop3 ? const Color(0xFFF59E0B) : Colors.grey[500],
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF27272A),
                  backgroundImage: leader['avatarUrl'] != null
                      ? NetworkImage(leader['avatarUrl'])
                      : null,
                  child: leader['avatarUrl'] == null
                      ? Text(
                          (leader['name'] as String).substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leader['name'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${leader['count']} accomplishments',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      leader['totalScore'].toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    Text(
                      'pts',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            "You're not in any groups yet",
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Show join group dialog
            },
            icon: const Icon(Icons.add),
            label: const Text('Join or Create a Group'),
          ),
        ],
      ),
    );
  }
}
