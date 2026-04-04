import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/add_schedule_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Key _refreshKey = UniqueKey();

  void _markRead(String id) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.markNotificationRead(id);
      setState(() { _refreshKey = UniqueKey(); });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _deleteSchedule(String id) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.deleteSchedule(id);
      setState(() { _refreshKey = UniqueKey(); });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddSchedule() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddScheduleSheet(),
    );
    if (result == true) {
      setState(() { _refreshKey = UniqueKey(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiServiceProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Automation & Notifications', style: TextStyle(fontSize: 18)),
          bottom: const TabBar(
            indicatorColor: Colors.tealAccent,
            labelColor: Colors.tealAccent,
            tabs: [
              Tab(text: 'Schedules', icon: Icon(Icons.autorenew_rounded)),
              Tab(text: 'Notifications', icon: Icon(Icons.notifications_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- Schedules Tab ---
            _buildSchedulesTab(api),
            
            // --- Notifications Tab ---
            _buildNotificationsTab(api),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesTab(ApiService api) {
    return Scaffold(
      body: FutureBuilder(
        key: ValueKey('sch_${_refreshKey.hashCode}'),
        future: api.getSchedules(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final List schedules = snapshot.data!.data;
          
          if (schedules.isEmpty) {
            return const Center(child: Text('No active schedules.', style: TextStyle(color: Colors.white54)));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final s = schedules[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: const Color(0xFF1A1D23),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.event_repeat_rounded, color: Colors.tealAccent, size: 32),
                  title: Text(s['note'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Amount: \$${s['amount']} (${s['type']})'),
                      Text('Next Run: ${s['next_run'].toString().split('T')[0]}'),
                      Text('Every ${s['interval_days']} days', style: const TextStyle(color: Colors.tealAccent)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () => _deleteSchedule(s['id']),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSchedule,
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotificationsTab(ApiService api) {
    return FutureBuilder(
      key: ValueKey('notif_${_refreshKey.hashCode}'),
      future: api.getNotifications(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final List notifications = snapshot.data!.data;
        
        if (notifications.isEmpty) {
          return const Center(child: Text('No new notifications.', style: TextStyle(color: Colors.white54)));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final n = notifications[index];
            final isRead = n['is_read'] == true;
            return ListTile(
              leading: Icon(
                n['type'] == 'warning' ? Icons.warning_rounded : Icons.info_rounded,
                color: n['type'] == 'warning' ? Colors.redAccent : Colors.tealAccent,
              ),
              title: Text(n['title'], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
              subtitle: Text(n['message']),
              trailing: isRead 
                ? null 
                : IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () => _markRead(n['id']),
                  ),
            );
          },
        );
      },
    );
  }
}

