import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  int _currentStep = 0;
  List<String> _selectedGoals = [];
  List<String> _selectedChallenges = [];
  String? _selectedLifestyle;
  double _dailyFreeTimeHours = 4;
  bool _isLoading = false;

  final _goals = [
    ('fitness', 'Fitness & Health', Icons.fitness_center),
    ('career', 'Career Growth', Icons.work),
    ('learning', 'Learning & Skills', Icons.school),
    ('relationships', 'Relationships', Icons.favorite),
    ('creativity', 'Creative Projects', Icons.palette),
    ('habits', 'Building Habits', Icons.auto_awesome),
    ('mental', 'Mental Wellness', Icons.psychology),
    ('finance', 'Financial Goals', Icons.account_balance_wallet),
  ];

  final _challenges = [
    ('consistency', 'Staying consistent'),
    ('motivation', 'Finding motivation'),
    ('time', 'Managing time'),
    ('overwhelm', 'Feeling overwhelmed'),
    ('perfectionism', 'Perfectionism'),
    ('accountability', 'Holding myself accountable'),
  ];

  final _lifestyles = [
    ('busy', 'Very busy schedule', 'Work takes most of my day'),
    ('balanced', 'Fairly balanced', 'Good mix of work and free time'),
    ('flexible', 'Flexible/variable', 'My schedule changes often'),
    ('structured', 'Highly structured', 'I plan most of my time'),
  ];

  final _freeTimeOptions = [1.0, 2.0, 3.0, 4.0, 6.0, 8.0];

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _selectedGoals.isNotEmpty;
      case 2:
        return _selectedChallenges.isNotEmpty;
      case 3:
        return _selectedLifestyle != null;
      case 4:
        return true;
      default:
        return false;
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // Update profile
      await supabase.from('profiles').update({
        'name': _nameController.text.trim(),
        'daily_free_time_hours': _dailyFreeTimeHours,
        'onboarding_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Save context
      final contextEntries = [
        ..._selectedGoals.map((goal) => {
          'user_id': userId,
          'context_type': 'onboarding',
          'category': 'goals',
          'key': goal,
          'value': {'selected': true},
        }),
        ..._selectedChallenges.map((challenge) => {
          'user_id': userId,
          'context_type': 'onboarding',
          'category': 'challenges',
          'key': challenge,
          'value': {'selected': true},
        }),
        {
          'user_id': userId,
          'context_type': 'onboarding',
          'category': 'lifestyle',
          'key': 'type',
          'value': {'type': _selectedLifestyle},
        },
        {
          'user_id': userId,
          'context_type': 'onboarding',
          'category': 'availability',
          'key': 'dailyFreeTimeHours',
          'value': {'hours': _dailyFreeTimeHours},
        },
      ];

      await supabase.from('user_context').insert(contextEntries);

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / 5,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Step ${_currentStep + 1} of 5',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStepContent(),
              ),
            ),
            
            // Navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 56),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _canProceed
                            ? const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFF8B5CF6)],
                              )
                            : null,
                        color: _canProceed ? null : Colors.grey[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: _canProceed
                            ? (_currentStep == 4
                                ? _completeOnboarding
                                : () => setState(() => _currentStep++))
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(_currentStep == 4 ? 'Get Started' : 'Continue'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildGoalsStep();
      case 2:
        return _buildChallengesStep();
      case 3:
        return _buildLifestyleStep();
      case 4:
        return _buildFreeTimeStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What should we call you?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Your name helps us personalize your experience.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Your name',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildGoalsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are you working towards?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Select all that apply.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _goals.map((goal) {
            final isSelected = _selectedGoals.contains(goal.$1);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedGoals.remove(goal.$1);
                } else {
                  _selectedGoals.add(goal.$1);
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B5CF6).withOpacity(0.2)
                      : const Color(0xFF18181B),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF27272A),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(goal.$3, size: 20),
                    const SizedBox(width: 8),
                    Text(goal.$2),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChallengesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What challenges do you face?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Be honest — this helps us score your accomplishments fairly.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        ..._challenges.map((challenge) {
          final isSelected = _selectedChallenges.contains(challenge.$1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedChallenges.remove(challenge.$1);
                } else {
                  _selectedChallenges.add(challenge.$1);
                }
              }),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B5CF6).withOpacity(0.2)
                      : const Color(0xFF18181B),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF27272A),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(challenge.$2),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLifestyleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How would you describe your lifestyle?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us understand your context.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        ..._lifestyles.map((lifestyle) {
          final isSelected = _selectedLifestyle == lifestyle.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedLifestyle = lifestyle.$1),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B5CF6).withOpacity(0.2)
                      : const Color(0xFF18181B),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF27272A),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lifestyle.$2,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lifestyle.$3,
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFreeTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How much free time do you have daily?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us validate your accomplishments and keep scoring fair.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        ..._freeTimeOptions.map((hours) {
          final isSelected = _dailyFreeTimeHours == hours;
          final label = hours == 8.0 ? '8+ hours' : '~${hours.toInt()} hour${hours > 1 ? 's' : ''}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _dailyFreeTimeHours = hours),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B5CF6).withOpacity(0.2)
                      : const Color(0xFF18181B),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF27272A),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[500],
                    ),
                    const SizedBox(width: 12),
                    Text(label),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This helps us detect unrealistic entries and keep the leaderboard fair.',
                  style: TextStyle(color: Colors.amber[200], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
