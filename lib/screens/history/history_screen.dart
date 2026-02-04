import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/accomplishment.dart';
import '../../services/accomplishment_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _accomplishmentService = AccomplishmentService();
  List<Accomplishment> _accomplishments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _accomplishments = await _accomplishmentService.getAllAccomplishments();
    setState(() => _isLoading = false);
  }

  Map<String, List<Accomplishment>> _groupByDate() {
    final grouped = <String, List<Accomplishment>>{};
    for (final a in _accomplishments) {
      grouped.putIfAbsent(a.loggedDate, () => []).add(a);
    }
    return grouped;
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (dateStr == DateFormat('yyyy-MM-dd').format(today)) {
      return 'Today';
    } else if (dateStr == DateFormat('yyyy-MM-dd').format(yesterday)) {
      return 'Yesterday';
    }
    return DateFormat('EEEE, MMM d').format(date);
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF34D399);
    if (score >= 60) return const Color(0xFFFBBF24);
    if (score >= 40) return const Color(0xFFFB923C);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Journey'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_accomplishments.length} accomplishments',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _accomplishments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          Text(
                            'No accomplishments yet',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final date = grouped.keys.toList()[index];
                        final items = grouped[date]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (index > 0) const SizedBox(height: 24),
                            Text(
                              _formatDate(date),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...items.map((a) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF18181B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF27272A),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(a.displayText),
                                      ),
                                      Text(
                                        a.score.toString(),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: _getScoreColor(a.score),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        );
                      },
                    ),
            ),
    );
  }
}
