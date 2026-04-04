import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _selectedType = 'expense';
  String? _selectedAccountId;
  
  // Categorization
  List<dynamic> _categories = [];
  List<dynamic> _accounts = [];
  
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final api = ref.read(apiServiceProvider);
    try {
      final accRes = await api.getAccounts();
      final catRes = await api.getCategories();
      setState(() {
        _accounts = accRes.data;
        _categories = catRes.data;
        
        if (_accounts.isNotEmpty) {
          _selectedAccountId = _accounts[0]['id'];
        }
        
        _isLoading = false;
      });
    } catch (e) {
      if(mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load data.')));
      }
    }
  }

  List<dynamic> get _currentMainCategories {
    return _categories.where((c) => c['type'] == _selectedType).toList();
  }

  List<dynamic> get _currentSubCategories {
    if (_selectedMainCategoryId == null) return [];
    final mainCat = _categories.firstWhere((c) => c['id'] == _selectedMainCategoryId, orElse: () => null);
    if (mainCat == null) return [];
    return mainCat['sub'] ?? [];
  }

  void _submit() async {
    if (_amountController.text.isEmpty || _selectedAccountId == null || _selectedMainCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields.')));
      return;
    }
    
    // Determine the final category: Use sub-category if selected, else main category
    final finalCategoryId = _selectedSubCategoryId ?? _selectedMainCategoryId;

    setState(() { _isSubmitting = true; });

    final api = ref.read(apiServiceProvider);
    try {
      await api.createTransaction({
        'account_id': _selectedAccountId,
        'category_id': finalCategoryId,
        'amount': double.parse(_amountController.text),
        'type': _selectedType,
        'note': _noteController.text,
      });
      
      if(mounted) {
        Navigator.pop(context, true); // true indicates success
      }
    } catch (e) {
      setState(() { _isSubmitting = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: Colors.tealAccent)));
    }

    return Container(
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D23),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Type
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedType = set.first;
                  _selectedMainCategoryId = null; // reset class
                  _selectedSubCategoryId = null;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Amount
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            // Account
            DropdownButtonFormField<String>(
              value: _selectedAccountId,
              decoration: InputDecoration(labelText: 'Account', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: _accounts.map((a) => DropdownMenuItem<String>(value: a['id'], child: Text(a['name']))).toList(),
              onChanged: (val) => setState(() => _selectedAccountId = val),
            ),
            const SizedBox(height: 16),
            
            // Main Category
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMainCategoryId,
                    decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: _currentMainCategories.map((c) => DropdownMenuItem<String>(value: c['id'], child: Text(c['name']))).toList(),
                    onChanged: (val) => setState(() {
                      _selectedMainCategoryId = val;
                      // Auto select first sub category if available, or reset
                      final subs = _currentSubCategories;
                      if (subs.isNotEmpty) {
                        _selectedSubCategoryId = subs[0]['id'];
                      } else {
                        _selectedSubCategoryId = null;
                      }
                    }),
                  ),
                ),
                if (_currentSubCategories.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currentSubCategories.any((s) => s['id'] == _selectedSubCategoryId) ? _selectedSubCategoryId : null,
                      decoration: InputDecoration(labelText: 'Sub Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _currentSubCategories.map((c) => DropdownMenuItem<String>(value: c['id'], child: Text(c['name']))).toList(),
                      onChanged: (val) => setState(() => _selectedSubCategoryId = val),
                    ),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 16),
            
            // Note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            
            // Submit Button
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
                : const Text('Save Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
