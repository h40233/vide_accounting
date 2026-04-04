import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  final _groupNameController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  Key _refreshKey = UniqueKey();

  void _createGroup() async {
    if (_groupNameController.text.isEmpty) return;
    
    final api = ref.read(apiServiceProvider);
    try {
      await api.createGroup({'name': _groupNameController.text});
      _groupNameController.clear();
      setState(() { _refreshKey = UniqueKey(); });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _inviteMember(String groupId) async {
    if (_inviteEmailController.text.isEmpty) return;
    
    final api = ref.read(apiServiceProvider);
    try {
      await api.inviteToGroup(groupId, _inviteEmailController.text);
      _inviteEmailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation sent!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family Groups')),
      body: FutureBuilder(
        key: _refreshKey,
        future: api.getMyGroups(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final List groups = snapshot.data!.data;
          
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Create Group Section
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _groupNameController,
                      decoration: InputDecoration(
                        labelText: 'New Group Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _createGroup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.add),
                  )
                ],
              ),
              const SizedBox(height: 32),
              
              // Groups List
              if (groups.isEmpty)
                const Center(child: Text('You are not in any groups.', style: TextStyle(color: Colors.white54))),
                
              for (var group in groups)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Members: ${group['members']?.length ?? 0}', style: const TextStyle(color: Colors.white54)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _inviteEmailController,
                                decoration: InputDecoration(
                                  labelText: 'Invite by Email',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _inviteMember(group['id']),
                              child: const Text('Invite', style: TextStyle(color: Colors.tealAccent)),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                )
            ],
          );
        },
      ),
    );
  }
}
