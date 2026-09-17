import 'package:flutter/material.dart';
import '../../cashbook/screens/cashbook_screen.dart';
import '../../inventory/screens/stock_inventory_screen.dart';
import '../../employees/screens/employees_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../suppliers/screens/supplier_dues_screen.dart';
import 'app_navigation_drawer.dart';

Widget buildAppDrawer(BuildContext context) {
  void navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  return AppNavigationDrawer(
    onSelectCashbook: () => navigateTo(const CashbookScreen()),
    onSelectInventory: () => navigateTo(const StockInventoryScreen()),
    onSelectSupplierDues: () => navigateTo(const SupplierDuesScreen()),
    onSelectStaff: () => navigateTo(const EmployeesScreen()),
    onSelectDashboard: () => navigateTo(const DashboardScreen()),
    onSelectSettings: () => navigateTo(const SettingsScreen()),
  );
}

Widget buildDrawerHamburgerButton(BuildContext context) {
  return Builder(
    builder: (btnCtx) => IconButton(
      icon: const Icon(Icons.menu_rounded, size: 26),
      tooltip: 'Menu',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: () => Scaffold.of(btnCtx).openDrawer(),
    ),
  );
}

Widget buildNavLeadingButton(BuildContext context) {
  if (Navigator.canPop(context)) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
      iconSize: 24,
      tooltip: 'Back',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: () => Navigator.of(context).pop(),
    );
  }
  return buildDrawerHamburgerButton(context);
}
