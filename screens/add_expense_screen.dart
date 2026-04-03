import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perako/manager/notification_manager.dart';

class AddExpenseScreen extends StatefulWidget {
  final double? detectedAmount;

  const AddExpenseScreen({super.key, this.detectedAmount});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Food', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'label': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.green},
    {'label': 'Transport', 'icon': Icons.directions_car, 'color': Colors.amber},
    {'label': 'Bills', 'icon': Icons.receipt_long, 'color': Colors.blue},
    {'label': 'Other', 'icon': Icons.category, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();

    if (widget.detectedAmount != null) {
      _amountController.text = widget.detectedAmount!.toStringAsFixed(2);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _saveExpense() async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter amount')));
      return;
    }

    final amount = double.tryParse(amountText);

    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    double balance = prefs.getDouble('availableBalance') ?? 0.0;

    if (amount > balance) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not enough balance')));
      return;
    }

    balance -= amount;
    await prefs.setDouble('availableBalance', balance);

    if (balance < 100) {
      await NotificationManager.addNotification(
        "Low Balance Warning",
        "Your balance is now ₱$balance",
      );
    }

    final expense = {
      'amount': amount,
      'category': _selectedCategory,
      'notes': _notesController.text.trim(),
      'date': _selectedDate.toIso8601String(),
      'type': 'expense',
    };

    final List<String> expenses = prefs.getStringList('expenses') ?? [];

    expenses.add(jsonEncode(expense));

    await prefs.setStringList('expenses', expenses);

    await NotificationManager.addNotification(
      "Expense Added",
      "You spent ₱$amount on $_selectedCategory",
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
        title: Text(
          'Add Expense',
          style: TextStyle(
            color: theme.textTheme.bodyLarge!.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// AMOUNT
              _label("Amount", theme),

              _inputField(
                controller: _amountController,
                hint: "0.00",
                prefix: "₱",
                theme: theme,
              ),

              const SizedBox(height: 20),

              /// CATEGORY
              _label("Category", theme),

              Container(
                decoration: _card(theme),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['label'],
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: cat['color'],
                              child: Icon(
                                cat['icon'],
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(cat['label']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// NOTES
              _label("Notes", theme),

              _inputField(
                controller: _notesController,
                hint: "Add a note...",
                theme: theme,
              ),

              const SizedBox(height: 20),

              /// DATE
              _label("Date", theme),

              InkWell(
                onTap: _pickDate,
                child: Container(
                  decoration: _card(theme),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// BUTTONS
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveExpense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Add Expense',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔧 HELPERS

  Widget _label(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodyLarge!.color,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    required ThemeData theme,
  }) {
    return Container(
      decoration: _card(theme),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          prefixText: prefix,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  BoxDecoration _card(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
    );
  }
}
