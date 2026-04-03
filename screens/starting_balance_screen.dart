import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_tabs_screen.dart';

class StartingBalanceScreen extends StatefulWidget {
  const StartingBalanceScreen({super.key});

  @override
  State<StartingBalanceScreen> createState() => _StartingBalanceScreenState();
}

class _StartingBalanceScreenState extends State<StartingBalanceScreen> {
  final TextEditingController _balanceController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveBalance() async {
    if (_isLoading) return;

    final text = _balanceController.text.trim();

    if (text.isEmpty) {
      _showMessage('Please enter a balance');
      return;
    }

    final balance = double.tryParse(text);
    if (balance == null) {
      _showMessage('Invalid amount');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('startingBalance', balance);
      await prefs.setDouble('availableBalance', balance);
      await prefs.setBool('hasStartingBalance', true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainTabsScreen(
            onThemeChanged: (bool value) {}, // ✅ TEMP FIX
          ),
        ),
      );
    } catch (e) {
      _showMessage('Failed to save balance');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Starting Balance',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Enter your current available balance',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: '₱ 0.00',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBalance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
