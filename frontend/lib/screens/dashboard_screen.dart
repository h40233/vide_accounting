import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

enum ViewMode { calendar, list }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  ViewMode _viewMode = ViewMode.list;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final api = ref.watch(apiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting Premium', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: SegmentedButton<ViewMode>(
              segments: const [
                ButtonSegment(
                  value: ViewMode.list,
                  label: Text('List'),
                  icon: Icon(Icons.list_alt_rounded),
                ),
                ButtonSegment(
                  value: ViewMode.calendar,
                  label: Text('Calendar'),
                  icon: Icon(Icons.calendar_month_rounded),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (Set<ViewMode> newSelection) {
                setState(() {
                  _viewMode = newSelection.first;
                });
              },
            ),
          ),
          
          Expanded(
            child: _viewMode == ViewMode.list 
                ? _buildListView(api, user) 
                : _buildCalendarView(api, user),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildListView(ApiService api, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(context),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Recent Transactions (Top 10)', () {}),
          const SizedBox(height: 16),
          FutureBuilder(
            future: api.getTransactions(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final List txs = snapshot.data!.data;
              return Column(
                children: txs.take(10).map((tx) => _buildTransactionItem(tx)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(ApiService api, dynamic user) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: Colors.tealAccent.withOpacity(0.3), shape: BoxShape.circle),
            selectedDecoration: const BoxDecoration(color: Colors.tealAccent, shape: BoxShape.circle),
            selectedTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        ),
        const Divider(),
        Expanded(
          child: FutureBuilder(
            future: api.getTransactions(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final List txs = snapshot.data!.data;
              
              // Filter transactions by selected day
              final filteredTxs = txs.where((tx) {
                final txDate = DateTime.parse(tx['transaction_date']);
                return isSameDay(txDate, _selectedDay);
              }).toList();

              if (filteredTxs.isEmpty) {
                return Center(child: Text('No records for ${DateFormat('MMMM d, y').format(_selectedDay!)}', style: const TextStyle(color: Colors.white38)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTxs.length,
                itemBuilder: (context, i) => _buildTransactionItem(filteredTxs[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E3137), Color(0xFF1A1D23)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Net Worth', style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 12),
          const Text('\$12,580.00', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.tealAccent)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSimpleStat('Income', '+\$2,450', Colors.greenAccent),
              const SizedBox(width: 40),
              _buildSimpleStat('Expense', '-\$1,120', Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onTap, child: const Text('See All', style: TextStyle(color: Colors.tealAccent))),
      ],
    );
  }

  Widget _buildTransactionItem(Map tx) {
    final isIncome = tx['type'] == 'income';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D23),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isIncome ? Colors.greenAccent : Colors.redAccent).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: isIncome ? Colors.greenAccent : Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['note'] != "" ? tx['note'] : 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(tx['transaction_date'].toString().split('T')[0], style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isIncome ? "+" : ""}${tx['amount']}',
            style: TextStyle(
              color: isIncome ? Colors.greenAccent : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
