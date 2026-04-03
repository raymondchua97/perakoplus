import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:perako/screens/edit_screen.dart';

class TransactionManager extends StatefulWidget {
  const TransactionManager({super.key});

  @override
  State<TransactionManager> createState() => _TransactionManagerState();
}

class _TransactionManagerState extends State<TransactionManager> {
  List<Map<String, dynamic>> _transactions = [];

  final NumberFormat pesoFormat = NumberFormat("#,##0.00", "en_PH");

  final Map<String, Map<String, dynamic>> _categoryStyles = {
    'Food': {'icon': Icons.restaurant, 'color': Colors.orange},
    'Shopping': {'icon': Icons.shopping_bag, 'color': Colors.green},
    'Transport': {'icon': Icons.directions_car, 'color': Colors.amber},
    'Bills': {'icon': Icons.receipt_long, 'color': Colors.blue},
    'Other': {'icon': Icons.category, 'color': Colors.grey},
    'Savings': {'icon': Icons.savings, 'color': Colors.purple},
    'Salary': {'icon': Icons.attach_money, 'color': Colors.green},
    'Cash': {'icon': Icons.money, 'color': Colors.orange},
  };

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final expenseStrings = prefs.getStringList('expenses') ?? [];

    final now = DateTime.now();

    setState(() {
      _transactions = expenseStrings
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .where((e) {
            final d = DateTime.parse(e['date']);

            return d.year == now.year &&
                d.month == now.month &&
                d.day == now.day;
          })
          .toList()
          .reversed
          .toList();
    });
  }

  Future<void> _deleteTransaction(int index, Map transaction) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> expenses = prefs.getStringList('expenses') ?? [];

    double balance = prefs.getDouble('availableBalance') ?? 0.0;

    /// FIXED BALANCE LOGIC
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

    _loadTransactions();
  }

  void _showOptions(int index, Map transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
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
                          EditScreen(transaction: transaction, index: index),
                    ),
                  );

                  if (result == true) {
                    _loadTransactions();
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete Transaction"),
                onTap: () async {
                  Navigator.pop(context);

                  await _deleteTransaction(index, transaction);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Transactions")),

      body: _transactions.isEmpty
          ? const Center(child: Text("No transactions yet."))
          : ListView.builder(
              itemCount: _transactions.length,

              itemBuilder: (context, index) {
                final e = _transactions[index];

                final isIncome = e['type'] == 'income';

                final style =
                    _categoryStyles[e['category']] ?? _categoryStyles['Other']!;

                return Dismissible(
                  key: Key(e['date'].toString() + index.toString()),

                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    color: Colors.blue,
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),

                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),

                  confirmDismiss: (direction) async {
                    /// SWIPE RIGHT → EDIT
                    if (direction == DismissDirection.startToEnd) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditScreen(transaction: e, index: index),
                        ),
                      );

                      if (result == true) {
                        _loadTransactions();
                      }

                      return false;
                    }

                    /// SWIPE LEFT → DELETE
                    if (direction == DismissDirection.endToStart) {
                      await _deleteTransaction(index, e);

                      return true;
                    }

                    return false;
                  },

                  child: ListTile(
                    onLongPress: () {
                      _showOptions(index, e);
                    },

                    leading: CircleAvatar(
                      backgroundColor: style['color'],
                      child: Icon(style['icon'], color: Colors.white),
                    ),

                    title: Text(e['category']),

                    subtitle: Text(e['notes'] ?? ""),

                    trailing: Text(
                      "${isIncome ? '+' : '-'} ₱${pesoFormat.format(e['amount'])}",
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
