import 'package:flutter/material.dart';
import '../../cashbook/screens/cashbook_screen.dart';

export '../../cashbook/screens/cashbook_screen.dart';

/// Legacy alias for [CashbookScreen] to ensure full backward compatibility.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CashbookScreen();
  }
}
