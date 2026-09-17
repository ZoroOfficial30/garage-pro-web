import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../home/widgets/action_confirmation_card.dart';
import '../../home/widgets/quick_action_modals.dart';
import '../widgets/add_customer_modal.dart';
import '../widgets/customer_card.dart';
import 'customer_detail_screen.dart';
import '../../../shared/utils/communication_helper.dart';
import '../../navigation/widgets/drawer_helper.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all'; // 'all', 'has_due', 'cleared'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBulkReminderDialog(BuildContext context, int debtorsCount, double totalDue) {
    final currency = Provider.of<CurrencyManager>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sms_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              locale.isBangla ? 'বকেয়া রিমাইন্ডার SMS' : 'Bulk SMS Reminders',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.isBangla
                  ? '$debtorsCount জন গ্রাহককে বকেয়া পরিশোধের তাগাদা এসএমএস পাঠানো হবে। সর্বমোট বকেয়া: ${currency.format(totalDue)}।'
                  : 'Send automated payment reminder SMS to all $debtorsCount customers with outstanding balances totaling ${currency.format(totalDue)}?',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Template:\n"Dear Customer, your Apex Auto Workshop balance is pending. Please visit us or pay via bank transfer. Thank you!"',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.isBangla ? 'বাতিল' : 'Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Bulk reminders dispatched to $debtorsCount customer accounts!',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(locale.isBangla ? 'SMS পাঠান' : 'Send All SMS'),
          ),
        ],
      ),
    );
  }

  void _showScannerSimulation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'License Plate & QR Scanner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Point camera at vehicle registration plate or customer invoice QR code to instantly pull account records.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _searchController.text = 'GA 23-8910';
                });
              },
              child: const Text('Simulate Scan (Dhaka Metro GA 23-8910)'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final currency = Provider.of<CurrencyManager>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    final allCustomers = repo.customers;
    final totalDues = repo.totalOutstandingDues;
    final debtorsCount = allCustomers.where((c) => c.totalDue > 0).length;
    final clearedCount = allCustomers.where((c) => c.totalDue <= 0).length;

    // Filter customers
    final filteredCustomers = allCustomers.where((c) {
      // 1. Filter tabs
      if (_filter == 'has_due' && c.totalDue <= 0) return false;
      if (_filter == 'cleared' && c.totalDue > 0) return false;

      // 2. Search query
      if (_searchQuery.isNotEmpty) {
        final matchName = c.name.toLowerCase().contains(_searchQuery);
        final matchPhone = c.phone.toLowerCase().contains(_searchQuery);
        final matchVehicle = c.vehicleModel.toLowerCase().contains(_searchQuery);
        final matchPlate = c.plateNumber.toLowerCase().contains(_searchQuery);
        if (!matchName && !matchPhone && !matchVehicle && !matchPlate) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        leading: buildDrawerHamburgerButton(context),
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          locale.isBangla ? 'গ্রাহক ও বকেয়া হিসাব' : 'Customers & Dues',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Customer',
            icon: const Icon(Icons.person_add_alt_1_rounded,
                color: AppColors.primary),
            onPressed: () => AddCustomerModal.show(context),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => repo.loadAllData(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // 1. Dues Summary Hero Card (Matching Stitch DS)
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isBangla
                            ? 'সর্বমোট বকেয়া পাওনা'
                            : 'TOTAL OUTSTANDING DUES',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currency.format(totalDues),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.9)),
                          const SizedBox(width: 6),
                          Text(
                            locale.isBangla
                                ? '$debtorsCount টি বাকি একাউন্ট অপেক্ষমাণ'
                                : '$debtorsCount Pending Customer Accounts',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _showBulkReminderDialog(
                              context, debtorsCount, totalDues),
                          icon: const Icon(Icons.chat_outlined, size: 18),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              locale.isBangla
                                  ? 'গ্রাহকদের এসএমএস তাগাদা পাঠান'
                                  : 'Send Bulk Reminder SMS',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Search & Scan Bar
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: locale.isBangla
                          ? 'কাস্টমার, ফোন, প্লেট নম্বর খুঁজুন...'
                          : 'Search customer name, phone, plate #...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textSecondary),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => _searchController.clear(),
                            ),
                          IconButton(
                            tooltip: 'Scan License Plate or QR',
                            icon: const Icon(Icons.qr_code_scanner_rounded,
                                color: AppColors.primary),
                            onPressed: () => _showScannerSimulation(context),
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Filter Segmented Control
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildSegmentTab(
                        'all',
                        locale.isBangla
                            ? 'সব (${allCustomers.length})'
                            : 'All (${allCustomers.length})',
                      ),
                      _buildSegmentTab(
                        'has_due',
                        locale.isBangla
                            ? 'বকেয়া ($debtorsCount)'
                            : 'Has Due ($debtorsCount)',
                      ),
                      _buildSegmentTab(
                        'cleared',
                        locale.isBangla
                            ? 'পরিশোধ ($clearedCount)'
                            : 'Cleared ($clearedCount)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Customer Cards List
                if (filteredCustomers.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _searchQuery.isNotEmpty
                                  ? AppColors.background
                                  : AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _searchQuery.isNotEmpty
                                    ? AppColors.border
                                    : AppColors.primary.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.people_alt_rounded,
                              size: 32,
                              color: _searchQuery.isNotEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? (locale.isBangla
                                    ? 'কোন গ্রাহক খুঁজে পাওয়া যায়নি'
                                    : 'No matching customers found')
                                : (locale.isBangla
                                    ? 'কোন কাস্টমার এখনও যোগ করা হয়নি'
                                    : 'No Customers Yet'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? (locale.isBangla
                                    ? 'নাম, ফোন বা প্লেট নম্বর পরিবর্তন করে আবার চেষ্টা করুন।'
                                    : 'Try searching by a different name, phone, or vehicle plate.')
                                : (locale.isBangla
                                    ? 'বাকি ও গাড়ির সার্ভিসের হিসাব রাখতে প্রথম কাস্টমার যোগ করুন।'
                                    : 'Add your first workshop customer to start tracking dues and service history.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_searchQuery.isNotEmpty)
                            OutlinedButton(
                              onPressed: () => _searchController.clear(),
                              child: Text(locale.isBangla ? 'ফিল্টার মুছুন' : 'Clear Search Filter'),
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => AddCustomerModal.show(context),
                              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                              label: Text(
                                locale.isBangla ? 'প্রথম কাস্টমার যোগ করুন' : 'Add First Customer',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredCustomers.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return CustomerCard(
                        customer: customer,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailScreen(
                                customerId: customer.id,
                              ),
                            ),
                          );
                        },
                        onCollectPay: () {
                          if (customer.totalDue > 0) {
                            QuickActionModals.showPayModal(
                              context,
                              initialCustomerName: customer.name,
                              customerId: customer.id,
                              initialAmount: customer.totalDue,
                            );
                          } else {
                            QuickActionModals.showDueModal(
                              context,
                              initialCustomerName: customer.name,
                              customerId: customer.id,
                            );
                          }
                        },
                        onCall: () {
                          CommunicationHelper.makePhoneCall(context, customer.phone);
                        },
                      );
                    },
                  ),
              ],
            ),
          ),

          // Action Undo confirmation floating banner
          if (repo.lastUndoAction != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ActionConfirmationCard(
                title: repo.lastUndoAction!.title,
                description: repo.lastUndoAction!.description,
                countdownSeconds: repo.undoCountdown,
                onUndo: () => repo.undoLastAction(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => AddCustomerModal.show(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          locale.isBangla ? 'নতুন কাস্টমার' : 'Add Customer',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildSegmentTab(String value, String label) {
    final isSelected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
