import 'dart:convert';
import 'package:perako/manager/transaction_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/scheduler.dart';
import 'add_expense_screen.dart';
import 'add_balance_screen.dart';
import 'package:perako/widget/notification_sheet.dart';
import 'package:perako/manager/notification_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _balance = 0.0;
  String _username = 'User';
  bool _hideBalance = false;
  bool _hasUnreadNotifications = false;
  List<Map<String, dynamic>> _expenses = [];

  final ImagePicker _picker = ImagePicker();

  final NumberFormat pesoFormat = NumberFormat("#,##0.00", "en_PH");

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
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocalData();
    });
  }

  @override
  void initState() {
    super.initState();

    _loadLocalData();
    _loadNotificationState(); // 👈 ADD THIS LINE

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _reloadWhenReturn();
    });
  }

  void _reloadWhenReturn() {
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      await _loadLocalData();
      setState(() {});

      return true;
    });
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final expenseStrings = prefs.getStringList('expenses') ?? [];
    final now = DateTime.now();

    setState(() {
      _balance = prefs.getDouble('availableBalance') ?? 0.0;

      final isGuest = prefs.getBool('isGuest') ?? false;

      if (isGuest) {
        _username = "Guest";
      } else {
        _username = prefs.getString('username') ?? 'User';
      }

      _expenses = expenseStrings
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

  /// notification
  Future<void> _loadNotificationState() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _hasUnreadNotifications =
          prefs.getBool('hasUnreadNotifications') ?? false;
    });
  }

  /// 📷 SCAN RECEIPT + OCR
  Future<void> _scanReceipt(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    /// 🔵 SHOW LOADING
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    final inputImage = InputImage.fromFilePath(image.path);

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    String scannedText = recognizedText.text;

    textRecognizer.close();

    /// 🔵 CLOSE LOADING
    if (mounted) Navigator.pop(context);

    print("==== RECEIPT TEXT ====");
    print(scannedText);

    _extractAmount(scannedText);
  }

  /// 💰 EXTRACT AMOUNT FROM RECEIPT
  Future<void> _extractAmount(String text) async {
    final RegExp amountRegex = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2}))');

    final match = amountRegex.firstMatch(text);

    if (match != null) {
      final amountString = match.group(0)!;

      final cleanedAmount = amountString.replaceAll(',', '');

      final double amount = double.parse(cleanedAmount);

      final result = await Navigator.push(
        context,
        _slidePage(AddExpenseScreen(detectedAmount: amount)),
      );

      if (result == true) {
        _loadLocalData();
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not detect amount")));
    }

    return;
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _scanReceipt(ImageSource.camera);
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _scanReceipt(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Route _slidePage(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
            );

        return SlideTransition(position: slideAnimation, child: child);
      },
    );
  }

  Widget _featureChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF2563EB)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 10),

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/app_icon_foreground.png', width: 42),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hello,",
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            "$_username!",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 2),
                      ],
                    ),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await NotificationManager.clearUnread();

                            setState(() {
                              _hasUnreadNotifications = false;
                            });

                            NotificationSheet.show(context);
                          },
                          child: const Icon(Icons.notifications_none),
                        ),

                        if (_hasUnreadNotifications)
                          const Positioned(
                            right: 0,
                            top: 0,
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// BALANCE CARD
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 2),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hideBalance
                          ? "₱ ••••••"
                          : "₱${pesoFormat.format(_balance)}",
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Text(
                          "Available Balance",
                          style: TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(width: 6),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _hideBalance = !_hideBalance;
                            });
                          },
                          child: Icon(
                            _hideBalance
                                ? Icons.visibility_off_outlined
                                : Icons.remove_red_eye_outlined,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// BUTTONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          _slidePage(const AddExpenseScreen()),
                        );

                        if (result == true) _loadLocalData();
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),

                      child: const Text(
                        "Add Expense",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          _slidePage(const AddBalanceScreen()),
                        );

                        if (result == true) _loadLocalData();
                      },

                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),

                      child: const Text(
                        "Add Balance",
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// SCAN RECEIPT
              GestureDetector(
                onTap: _showScanOptions,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F7DF3), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(width: 20),
                      Icon(Icons.camera_alt, color: Colors.white),
                      SizedBox(width: 25),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Scan Receipt",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Auto-detect amount & date",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  _featureChip(Icons.flash_on, "Fast"),
                  const SizedBox(width: 3),
                  _featureChip(Icons.verified, "Accurate"),
                  const SizedBox(width: 3),
                  _featureChip(Icons.auto_awesome, "Smart"),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Activity",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  TextButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionManager(),
                        ),
                      );

                      if (result == true) {
                        _loadLocalData();
                        // reload balance + activity
                      }
                    },

                    child: const Text(
                      "View All",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Expanded(
                child: _expenses.isEmpty
                    ? const Center(
                        child: Text(
                          "No recent activity today.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) {
                          final e = _expenses[index];
                          final isIncome = e['type'] == 'income';

                          final style =
                              _categoryStyles[e['category']] ??
                              _categoryStyles['Other']!;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: style['color'],
                              child: Icon(style['icon'], color: Colors.white),
                            ),
                            title: Text(e['category']),
                            subtitle: Text(e['notes'] ?? ''),
                            trailing: Text(
                              "${isIncome ? '+' : '-'} ₱${pesoFormat.format(e['amount'])}",
                              style: TextStyle(
                                color: isIncome ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
