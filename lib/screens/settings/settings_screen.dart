import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        final response = await supabase
            .from('user_settings')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null) {
          _notificationsEnabled = response['notifications_enabled'] ?? true;
          _reminderEnabled = response['reminder_enabled'] ?? false;
          if (response['reminder_time'] != null) {
            final parts = (response['reminder_time'] as String).split(':');
            _reminderTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('user_settings').upsert({
        'user_id': userId,
        'notifications_enabled': _notificationsEnabled,
        'reminder_enabled': _reminderEnabled,
        'reminder_time':
            '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
        'updated_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      context.go('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Notifications section
                const Text(
                  'NOTIFICATIONS',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Push Notifications'),
                        subtitle: Text(
                          'Get notified about your progress',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() => _notificationsEnabled = value);
                          _saveSettings();
                        },
                        activeTrackColor: const Color(0xFF8B5CF6),
                      ),
                      const Divider(color: Color(0xFF27272A), height: 1),
                      SwitchListTile(
                        title: const Text('Daily Reminder'),
                        subtitle: Text(
                          'Remind me to log accomplishments',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                        value: _reminderEnabled,
                        onChanged: (value) {
                          setState(() => _reminderEnabled = value);
                          _saveSettings();
                        },
                        activeTrackColor: const Color(0xFF8B5CF6),
                      ),
                      if (_reminderEnabled) ...[
                        const Divider(color: Color(0xFF27272A), height: 1),
                        ListTile(
                          title: const Text('Reminder Time'),
                          subtitle: Text(
                            _reminderTime.format(context),
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _reminderTime,
                            );
                            if (time != null) {
                              setState(() => _reminderTime = time);
                              _saveSettings();
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account section
                const Text(
                  'ACCOUNT',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Edit Profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/profile'),
                      ),
                      const Divider(color: Color(0xFF27272A), height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: _signOut,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // About section
                const Text(
                  'ABOUT',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: const Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.info),
                        title: Text('Version'),
                        trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
