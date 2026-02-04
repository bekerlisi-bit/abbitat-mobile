import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/accomplishment.dart';
import '../../services/accomplishment_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _accomplishmentController = TextEditingController();
  final _accomplishmentService = AccomplishmentService();
  
  List<Accomplishment> _todayAccomplishments = [];
  Map<String, int> _weeklyStats = {'count': 0, 'totalScore': 0};
  int _streak = 0;
  String _userName = '';
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        final profile = await supabase
            .from('profiles')
            .select('name')
            .eq('id', userId)
            .single();
        _userName = profile['name'] ?? 'there';
      }

      _todayAccomplishments = await _accomplishmentService.getTodaysAccomplishments();
      _weeklyStats = await _accomplishmentService.getWeeklyStats();
      _streak = await _accomplishmentService.calculateStreak();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _submitAccomplishment() async {
    final text = _accomplishmentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await _accomplishmentService.createAccomplishment(text);
      _accomplishmentController.clear();
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    setState(() => _isSubmitting = false);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF34D399);
    if (score >= 60) return const Color(0xFFFBBF24);
    if (score >= 40) return const Color(0xFFFB923C);
    return Colors.grey;
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'fitness':
        return Icons.fitness_center;
      case 'career':
        return Icons.work;
      case 'learning':
        return Icons.school;
      case 'relationships':
        return Icons.favorite;
      case 'creativity':
        return Icons.palette;
      case 'habits':
        return Icons.auto_awesome;
      case 'mental':
        return Icons.psychology;
      case 'finance':
        return Icons.account_balance_wallet;
      default:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('A', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Abbitat'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      '${_getGreeting()}, $_userName',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What did you accomplish today?',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 16),

                    // Input
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _accomplishmentController,
                              decoration: const InputDecoration(
                                hintText: 'I went to the gym, finished a project...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              onSubmitted: (_) => _submitAccomplishment(),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isSubmitting ? null : _submitAccomplishment,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Log',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats
                    Row(
                      children: [
                        _buildStatCard(
                          _todayAccomplishments.length.toString(),
                          'Today',
                          const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          _weeklyStats['count'].toString(),
                          'This Week',
                          const Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          _streak.toString(),
                          'Day Streak',
                          const Color(0xFF34D399),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Today's date
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Today's Wins
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.flag, color: Color(0xFF8B5CF6)),
                              const SizedBox(width: 8),
                              const Text(
                                "Today's Wins",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_todayAccomplishments.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Text(
                                      'No accomplishments logged yet today.',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Start by logging something above!',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...(_todayAccomplishments.map((a) => _buildAccomplishmentTile(a))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccomplishmentTile(Accomplishment a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getCategoryIcon(a.category),
            size: 20,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              a.displayText,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            a.score.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(a.score),
            ),
          ),
        ],
      ),
    );
  }
}
