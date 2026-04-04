import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class AddAccountSheet extends ConsumerStatefulWidget {
  const AddAccountSheet({super.key});

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {
  final _nameController = TextEditingController();
  String _selectedType = 'liquid';
  bool _isSubmitting = false;

  void _submit() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an account name.')));
      return;
    }

    setState(() { _isSubmitting = true; });

    final api = ref.read(apiServiceProvider);
    try {
      await api.createAccount({
        'name': _nameController.text,
        'type': _selectedType,
      });
      
      if(mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() { _isSubmitting = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D23),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('New Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Account Name (e.g. Bank of America)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(labelText: 'Account Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: const [
              DropdownMenuItem(value: 'liquid', child: Text('Liquid (Cash/Bank)')),
              DropdownMenuItem(value: 'savings', child: Text('Savings')),
              DropdownMenuItem(value: 'credit', child: Text('Credit Card')),
            ],
            onChanged: (val) => setState(() => _selectedType = val!),
          ),
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }
}
