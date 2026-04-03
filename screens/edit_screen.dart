import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditScreen extends StatefulWidget {
  final Map transaction;
  final int index;

  const EditScreen({super.key, required this.transaction, required this.index});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _category = "Food";

  final List<String> _categories = [
    "Food",
    "Shopping",
    "Transport",
    "Bills",
    "Other",
    "Savings",
    "Salary",
    "Cash",
  ];

  @override
  void initState() {
    super.initState();

    _amountController.text = widget.transaction['amount'].toString();
    _notesController.text = widget.transaction['notes'] ?? "";

    if (_categories.contains(widget.transaction['category'])) {
      _category = widget.transaction['category'];
    } else {
      _category = "Food";
    }
  }

  /// SAVE EDIT
  Future<void> _saveEdit() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> expenses = prefs.getStringList('expenses') ?? [];

    double balance = prefs.getDouble('availableBalance') ?? 0.0;

    final double newAmount = double.parse(_amountController.text);
    final double oldAmount = widget.transaction['amount'];

    /// FIX BALANCE LOGIC
    if (widget.transaction['type'] == 'expense') {
      balance = balance + oldAmount - newAmount;
    } else {
      balance = balance - oldAmount + newAmount;
    }

    await prefs.setDouble('availableBalance', balance);

    final updatedExpense = {
      "amount": newAmount,
      "category": _category,
      "notes": _notesController.text,
      "date": widget.transaction['date'],
      "type": widget.transaction['type'],
    };

    for (int i = 0; i < expenses.length; i++) {
      final decoded = jsonDecode(expenses[i]);

      if (decoded['date'] == widget.transaction['date'] &&
          decoded['amount'] == widget.transaction['amount']) {
        expenses[i] = jsonEncode(updatedExpense);
        break;
      }
    }

    await prefs.setStringList('expenses', expenses);

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
          "Edit",
          style: TextStyle(color: theme.textTheme.bodyLarge!.color),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: _card(theme),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    dropdownColor: theme.cardColor,
                    items: _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _category = value;
                        });
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
                      onPressed: _saveEdit,
                      child: const Text("Save Changes"),
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
