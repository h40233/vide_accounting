import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class AddScheduleSheet extends ConsumerStatefulWidget {
  const AddScheduleSheet({super.key});

  @override
  ConsumerState<AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends ConsumerState<AddScheduleSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customDaysController = TextEditingController();
  
  String _selectedType = 'expense';
  String? _selectedAccountId;
  
  List<dynamic> _categories = [];
  List<dynamic> _accounts = [];
  
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  
  int _intervalDays = 30; // Default Monthly
  DateTime _nextRunDate = DateTime.now().add(const Duration(days: 1));
  
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
        if (_accounts.isNotEmpty) _selectedAccountId = _accounts[0]['id'];
        _isLoading = false;
      });
    } catch (e) {
      if(mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load data.')));
      }
    }
  }

  List<dynamic> get _currentMainCategories => _categories.where((c) => c['type'] == _selectedType).toList();

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
    
    final finalCategoryId = _selectedSubCategoryId ?? _selectedMainCategoryId;

    int finalIntervalDays = _intervalDays;
    if (_intervalDays == -1) {
      final customParsed = int.tryParse(_customDaysController.text);
      if (customParsed == null || customParsed <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid number of days.')));
        return;
      }
      finalIntervalDays = customParsed;
    }

    setState(() { _isSubmitting = true; });

    final api = ref.read(apiServiceProvider);
    try {
      await api.createSchedule({
        'account_id': _selectedAccountId,
        'category_id': finalCategoryId,
        'amount': double.parse(_amountController.text),
        'type': _selectedType,
        'note': _noteController.text.isEmpty ? "Recurring payment" : _noteController.text,
        'interval_days': finalIntervalDays,
        'next_run': _nextRunDate.toIso8601String(),
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
            const Text('Add Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Frequency
            DropdownButtonFormField<int>(
              value: _intervalDays,
              decoration: InputDecoration(labelText: 'Frequency', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Daily')),
                DropdownMenuItem(value: 7, child: Text('Weekly')),
                DropdownMenuItem(value: 30, child: Text('Monthly')),
                DropdownMenuItem(value: 365, child: Text('Yearly')),
                DropdownMenuItem(value: -1, child: Text('Custom (Every X Days)')),
              ],
              onChanged: (val) => setState(() => _intervalDays = val!),
            ),
            const SizedBox(height: 16),
            
            if (_intervalDays == -1) ...[
              TextField(
                controller: _customDaysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Repeat every X days',
                  suffixText: 'days',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Start Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Next Run Date'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_nextRunDate), style: const TextStyle(color: Colors.tealAccent)),
              trailing: const Icon(Icons.date_range),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _nextRunDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() => _nextRunDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            
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
                  _selectedMainCategoryId = null;
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
            
            // Account & Category
            DropdownButtonFormField<String>(
              value: _selectedAccountId,
              decoration: InputDecoration(labelText: 'Account', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: _accounts.map((a) => DropdownMenuItem<String>(value: a['id'], child: Text(a['name']))).toList(),
              onChanged: (val) => setState(() => _selectedAccountId = val),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMainCategoryId,
                    decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: _currentMainCategories.map((c) => DropdownMenuItem<String>(value: c['id'], child: Text(c['name']))).toList(),
                    onChanged: (val) => setState(() {
                      _selectedMainCategoryId = val;
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
                labelText: 'Schedule Title / Note',
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
                : const Text('Create Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
