import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedMonth = DateTime.now();

  Map<String, List<Map<String, dynamic>>> _groupedActivities = {};

  final Map<String, Map<String, dynamic>> _categoryStyles = {
    'Food': {'icon': Icons.restaurant, 'color': Colors.orange},
    'Shopping': {'icon': Icons.shopping_bag, 'color': Colors.green},
    'Transport': {'icon': Icons.directions_car, 'color': Colors.amber},
    'Bills': {'icon': Icons.receipt_long, 'color': Colors.blue},
    'Other': {'icon': Icons.category, 'color': Colors.grey},
    'Savings': {'icon': Icons.savings, 'color': Colors.pink},
    'Salary': {'icon': Icons.attach_money, 'color': Colors.green},
    'Cash': {'icon': Icons.money, 'color': Colors.orange},
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// 🔁 AUTO REFRESH WHEN SCREEN OPENS
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHistory();
  }

  /// LOAD HISTORY
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('expenses') ?? [];

    final List<Map<String, dynamic>> filtered = stored
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .where((e) {
          final d = DateTime.parse(e['date']);
          return d.year == _selectedMonth.year &&
              d.month == _selectedMonth.month;
        })
        .toList();

    filtered.sort((a, b) {
      final da = DateTime.parse(a['date']);
      final db = DateTime.parse(b['date']);
      return db.compareTo(da);
    });

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final e in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(DateTime.parse(e['date']));
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(e);
    }

    setState(() => _groupedActivities = grouped);
  }

  /// DELETE TRANSACTION
  Future<void> _deleteTransaction(Map transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> expenses = prefs.getStringList('expenses') ?? [];

    double balance = prefs.getDouble('availableBalance') ?? 0.0;

    if (transaction['type'] == 'expense') {
      balance += transaction['amount'];
    } else {
      balance -= transaction['amount'];
    }

    await prefs.setDouble('availableBalance', balance);

    for (int i = 0; i < expenses.length; i++) {
      final decoded = jsonDecode(expenses[i]);

      if (decoded['date'] == transaction['date'] &&
          decoded['amount'] == transaction['amount'] &&
          decoded['notes'] == transaction['notes']) {
        expenses.removeAt(i);
        break;
      }
    }

    await prefs.setStringList('expenses', expenses);

    _loadHistory();
  }

  /// EDIT OR DELETE OPTIONS
  void _showOptions(Map transaction) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Transaction"),
                onTap: () async {
                  Navigator.pop(context);

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditScreen(transaction: transaction, index: 0),
                    ),
                  );

                  if (result == true) {
                    _loadHistory();
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete Transaction"),
                onTap: () {
                  Navigator.pop(context);
                  _deleteTransaction(transaction);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) {
        return SizedBox(
          height: 260,
          child: ListView.builder(
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = DateTime(now.year, index + 1);

              return ListTile(
                title: Text(DateFormat('MMMM yyyy').format(month)),
                onTap: () => Navigator.pop(context, month),
              );
            },
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedMonth = picked);
      _loadHistory();
    }
  }

  String _dateHeader(String key) {
    final d = DateTime.parse(key);
    return DateFormat('MMMM d, yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calendar_today, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: _pickMonth,

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),

                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),

                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 16),
                          const SizedBox(width: 6),

                          Text(
                            DateFormat('MMMM yyyy').format(_selectedMonth),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Expanded(
                child: _groupedActivities.isEmpty
                    ? const Center(
                        child: Text(
                          'No history for this month.',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 15,
                          ),
                        ),
                      )
                    : ListView(
                        children: _groupedActivities.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Text(
                                  _dateHeader(entry.key),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),

                              Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),

                                child: Column(
                                  children: entry.value.map((e) {
                                    final style =
                                        _categoryStyles[e['category']] ??
                                        _categoryStyles['Other']!;

                                    final bool isIncome = e['type'] == 'income';

                                    return ListTile(
                                      onLongPress: () {
                                        _showOptions(e);
                                      },

                                      leading: CircleAvatar(
                                        backgroundColor: style['color'],
                                        child: Icon(
                                          style['icon'],
                                          color: Theme.of(context).cardColor,
                                          size: 20,
                                        ),
                                      ),

                                      title: Text(e['category']),
                                      subtitle: Text(e['notes'] ?? ''),

                                      trailing: Text(
                                        '${isIncome ? '+' : '-'} ₱${(e['amount'] as num).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: isIncome
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                              const SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
