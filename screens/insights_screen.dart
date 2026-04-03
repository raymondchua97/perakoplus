import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  DateTime _selectedMonth = DateTime.now();
  Map<String, double> _categoryTotals = {};
  double _totalExpenses = 0.0;

  final Map<String, Color> _categoryColors = {
    'Food': Colors.orange,
    'Shopping': Colors.green,
    'Transport': Colors.amber,
    'Bills': Colors.blue,
    'Other': Colors.grey,
  };

  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant,
    'Shopping': Icons.shopping_bag,
    'Transport': Icons.directions_car,
    'Bills': Icons.receipt_long,
    'Other': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expenseStrings = prefs.getStringList('expenses') ?? [];

    final Map<String, double> totals = {};
    double sum = 0.0;

    for (final e in expenseStrings) {
      final data = jsonDecode(e);

      if (data['type'] != 'expense') continue;

      final date = DateTime.parse(data['date']);
      if (date.year == _selectedMonth.year &&
          date.month == _selectedMonth.month) {
        final category = data['category'];
        final amount = (data['amount'] as num).toDouble();
        totals[category] = (totals[category] ?? 0) + amount;
        sum += amount;
      }
    }

    setState(() {
      _categoryTotals = totals;
      _totalExpenses = sum;
    });
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
                title: Text(
                  DateFormat('MMMM yyyy').format(month),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(context, month),
              );
            },
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedMonth = picked);
      _loadExpenses();
    }
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
              // --- INSIDE build() ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.bar_chart, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Insights',
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
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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

              if (_categoryTotals.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No expense data for this month.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(220, 220),
                              painter: _PieChartPainter(
                                _categoryTotals,
                                _categoryColors,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Total Expenses',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  '₱${_totalExpenses.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      Expanded(
                        child: ListView(
                          children: _categoryTotals.entries.map((entry) {
                            final color =
                                _categoryColors[entry.key] ?? Colors.grey;
                            final icon =
                                _categoryIcons[entry.key] ?? Icons.category;

                            final percent = _totalExpenses == 0
                                ? 0
                                : (entry.value / _totalExpenses) * 100;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: color,
                                    child: Icon(
                                      icon,
                                      color: Theme.of(context).cardColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₱${entry.value.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${percent.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Map<String, Color> colors;

  _PieChartPainter(this.data, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    double startAngle = -90 * 3.1415926535 / 180;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26;

    for (final entry in data.entries) {
      final sweepAngle = (entry.value / total) * 2 * 3.1415926535;
      paint.color = colors[entry.key] ?? Colors.grey;

      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
