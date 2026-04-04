import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications & Settings')),
      body: FutureBuilder(
        key: _refreshKey,
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
      ),
    );
  }
}
