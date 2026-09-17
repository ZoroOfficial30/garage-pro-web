import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_locale.dart';
import '../home/screens/home_screen.dart';
import '../customers/screens/customers_list_screen.dart';
import '../jobs/screens/jobs_screen.dart';
import 'widgets/drawer_helper.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainScaffoldState>();
    state?.setIndex(index);
  }

  static void openJobs(BuildContext context) {
    final state = context.findAncestorStateOfType<_MainScaffoldState>();
    if (state != null) {
      state.setIndex(2);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JobsScreen()),
      );
    }
  }

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<AppLocaleManager>(context);

    final List<Widget> screens = [
      const HomeScreen(),
      const CustomersListScreen(),
      const JobsScreen(),
    ];

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: buildAppDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: isKeyboardOpen
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
              ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                );
              }
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setIndex(index),
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primaryLight,
            elevation: 0,
            height: 58,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded, color: AppColors.primary),
                label: locale.translate('home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.people_alt_outlined),
                selectedIcon: const Icon(Icons.people_alt_rounded, color: AppColors.primary),
                label: locale.translate('customers'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.car_repair_outlined),
                selectedIcon: const Icon(Icons.car_repair_rounded, color: AppColors.primary),
                label: locale.translate('jobs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
