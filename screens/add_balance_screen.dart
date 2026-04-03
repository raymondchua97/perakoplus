import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perako/manager/notification_manager.dart';

class AddBalanceScreen extends StatefulWidget {
  const AddBalanceScreen({super.key});

  @override
  State<AddBalanceScreen> createState() => _AddBalanceScreenState();
}

class _AddBalanceScreenState extends State<AddBalanceScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedSource = 'Savings';
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _sources = [
    {'label': 'Savings', 'icon': Icons.savings, 'color': Colors.pink},
    {'label': 'Salary', 'icon': Icons.work, 'color': Colors.green},
    {'label': 'Cash', 'icon': Icons.payments, 'color': Colors.amber},
  ];

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

  Future<void> _saveBalance() async {
    final text = _amountController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter amount')));
      return;
    }

    final amount = double.tryParse(text);

    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    double balance = prefs.getDouble('availableBalance') ?? 0.0;
    balance += amount;

    await prefs.setDouble('availableBalance', balance);

    await NotificationManager.addNotification(
      "Balance Added",
      "₱$amount added to your balance",
    );

    final income = {
      'amount': amount,
      'category': _selectedSource,
      'notes': _notesController.text.trim(),
      'date': _selectedDate.toIso8601String(),
      'type': 'income',
    };

    final records = prefs.getStringList('expenses') ?? [];
    records.add(jsonEncode(income));

    await prefs.setStringList('expenses', records);

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
          'Add Balance',
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
              _label('Amount', theme),

              _inputField(
                controller: _amountController,
                hint: '0.00',
                prefix: '₱',
                theme: theme,
              ),

              const SizedBox(height: 20),

              /// SOURCE
              _label('Source', theme),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: _card(theme),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSource,
                    isExpanded: true,
                    items: _sources.map((src) {
                      return DropdownMenuItem<String>(
                        value: src['label'],
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: src['color'],
                              child: Icon(
                                src['icon'],
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(src['label']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSource = value);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// NOTES
              _label('Notes', theme),

              _inputField(
                controller: _notesController,
                hint: 'Add a note...',
                theme: theme,
              ),

              const SizedBox(height: 20),

              /// DATE
              _label('Date', theme),

              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _card(theme),
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
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveBalance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Add Balance',
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
