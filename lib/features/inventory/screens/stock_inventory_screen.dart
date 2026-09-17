import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/stock_item.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../../shared/widgets/statement_modal_helper.dart';
import '../../home/widgets/action_confirmation_card.dart';
import '../widgets/add_stock_modal.dart';
import '../widgets/create_stock_item_modal.dart';
import '../widgets/edit_stock_item_modal.dart';
import '../widgets/dispense_stock_modal.dart';
import '../widgets/low_stock_banner.dart';
import '../widgets/stock_item_card.dart';
import '../../navigation/widgets/drawer_helper.dart';

class StockInventoryScreen extends StatefulWidget {
  const StockInventoryScreen({super.key});

  @override
  State<StockInventoryScreen> createState() => _StockInventoryScreenState();
}

class _StockInventoryScreenState extends State<StockInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedBrand = 'All';

  void _confirmDeleteStockItem(BuildContext context, dynamic item) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                locale.isBangla ? 'পার্টসটি মুছে ফেলবেন?' : 'Delete Stock Item?',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${item.name}" (${item.brand}, SKU: ${item.sku})? This cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.isBangla ? 'বাতিল' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await repo.deleteStockItem(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted item: ${item.name}'),
                    backgroundColor: AppColors.primaryDark,
                  ),
                );
              }
            },
            child: Text(locale.isBangla ? 'মুছে ফেলুন' : 'Delete'),
          ),
        ],
      ),
    );
  }

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

  void _showBarcodeSimulation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              'Barcode & OEM Scanner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan part package barcode or OEM sticker to pull instant inventory quantity.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _searchController.text = 'CAS-5W40-01';
                });
              },
              child: const Text('Simulate Scan (Castrol CAS-5W40-01)'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    final allStock = repo.stockItems;
    final lowStockItems =
        allStock.where((s) => s.isLowStock || s.isOutOfStock).toList();

    // Collect distinct brand list
    final standardBrands = [
      'All',
      'Castrol',
      'Mobil',
      'Bosch',
      'Denso',
      'Toyota OEM',
      'NGK',
      'Others',
    ];

    // Filter by Brand & Search query
    final filteredStock = allStock.where((item) {
      // 1. Brand filter
      if (_selectedBrand != 'All') {
        if (_selectedBrand == 'Others') {
          final known = ['castrol', 'mobil', 'bosch', 'denso', 'toyota oem', 'ngk'];
          if (known.contains(item.brand.toLowerCase())) return false;
        } else {
          if (item.brand.toLowerCase() != _selectedBrand.toLowerCase()) {
            return false;
          }
        }
      }

      // 2. Search query filter
      if (_searchQuery.isNotEmpty) {
        final matchName = item.name.toLowerCase().contains(_searchQuery);
        final matchBrand = item.brand.toLowerCase().contains(_searchQuery);
        final matchSku = item.sku.toLowerCase().contains(_searchQuery);
        if (!matchName && !matchBrand && !matchSku) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                iconSize: 24,
                tooltip: 'Back',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => Navigator.of(context).pop(),
              )
            : buildDrawerHamburgerButton(context),
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.isBangla ? 'পার্টস ও স্টক ইনভেন্টরি' : 'Parts & Inventory',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 19,
                color: AppColors.primary,
              ),
            ),
            Text(
              '${allStock.length} SKUs in Stock • ${lowStockItems.length} Low Stock Alert',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: locale.isBangla ? 'স্টক ও সতর্কবার্তা রিপোর্ট প্রিন্ট' : 'Print Stock & Alert Report',
            icon: const Icon(Icons.print_rounded, color: AppColors.textPrimary),
            onPressed: () => _showStockReportModal(context, repo, allStock, lowStockItems, locale),
          ),
          IconButton(
            tooltip: 'Add New Item',
            icon: const Icon(Icons.add_box_outlined, color: AppColors.primary),
            onPressed: () => CreateStockItemModal.show(context),
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
                // 1. Search Bar (54px)
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
                          ? 'বারকোড স্ক্যান বা পার্টস, OEM # খুঁজুন...'
                          : 'Scan barcode or search part name, OEM #...',
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
                            tooltip: 'Scan Barcode or QR',
                            icon: const Icon(Icons.qr_code_scanner_rounded,
                                color: AppColors.primary),
                            onPressed: () => _showBarcodeSimulation(context),
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Low Stock Alert Carousel
                LowStockBanner(lowStockItems: lowStockItems),
                const SizedBox(height: 16),

                // 3. Brand Filter Pills
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: standardBrands.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final brand = standardBrands[index];
                      final isSelected = _selectedBrand == brand;

                      // Calculate count for brand
                      final int count;
                      if (brand == 'All') {
                        count = allStock.length;
                      } else if (brand == 'Others') {
                        final known = ['castrol', 'mobil', 'bosch', 'denso', 'toyota oem', 'ngk'];
                        count = allStock
                            .where((s) => !known.contains(s.brand.toLowerCase()))
                            .length;
                      } else {
                        count = allStock
                            .where((s) =>
                                s.brand.toLowerCase() == brand.toLowerCase())
                            .length;
                      }

                      return GestureDetector(
                        onTap: () => setState(() => _selectedBrand = brand),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            '$brand ($count)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Stock Items Grid/List
                if (filteredStock.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 56,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            locale.isBangla
                                ? 'কোন পার্টস পাওয়া যায়নি'
                                : 'No matching parts found',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No inventory items match "$_searchQuery". Check SKU or part name.'
                                : 'No items found for brand "$_selectedBrand".',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_searchQuery.isNotEmpty || _selectedBrand != 'All')
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedBrand = 'All';
                                });
                              },
                              child: const Text('Clear All Filters'),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () => CreateStockItemModal.show(context),
                              icon: const Icon(Icons.add_box_rounded),
                              label: const Text('Add First Inventory Part'),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredStock.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredStock[index];
                      return StockItemCard(
                        item: item,
                        onDispense: () {
                          DispenseStockModal.show(context, item: item);
                        },
                        onAddStock: () {
                          AddStockModal.show(context, item: item);
                        },
                        onEdit: () {
                          EditStockItemModal.show(context, item);
                        },
                        onDelete: () {
                          _confirmDeleteStockItem(context, item);
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
        onPressed: () => CreateStockItemModal.show(context),
        icon: const Icon(Icons.add_box_rounded),
        label: Text(
          locale.isBangla ? 'নতুন পার্ট' : 'Add New Item',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  void _showStockReportModal(
    BuildContext context,
    GarageRepository repo,
    List<StockItem> allStock,
    List<StockItem> lowStockItems,
    AppLocaleManager locale,
  ) {
    final currency = Provider.of<CurrencyManager>(context, listen: false);
    final profile = repo.workshopProfile;
    final workshopName = repo.getWorkshopName();
    final address = profile['address'] ?? '';
    final phone = profile['phone'] ?? '';
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    double totalStockValuation = 0;
    for (final item in allStock) {
      totalStockValuation += (item.quantity * item.sellingPrice);
    }

    final sb = StringBuffer();
    sb.writeln('========================================');
    sb.writeln(workshopName.toUpperCase());
    if (address.isNotEmpty) sb.writeln(address);
    if (phone.isNotEmpty) sb.writeln('Phone: $phone');
    sb.writeln('========================================');
    sb.writeln('STOCK INVENTORY & LOW STOCK REPORT');
    sb.writeln('Generated: $nowStr');
    sb.writeln('Total Items / SKUs: ${allStock.length}');
    sb.writeln('Low Stock Alerts:   ${lowStockItems.length}');
    sb.writeln('Est. Sell Value:    ${currency.format(totalStockValuation)}');
    sb.writeln('----------------------------------------');

    if (lowStockItems.isNotEmpty) {
      sb.writeln('*** LOW STOCK / REORDER ALERTS ***');
      for (final item in lowStockItems) {
        sb.writeln('• ${item.name} (${item.brand})');
        sb.writeln('  Qty Left: ${item.quantity} ${item.unit} (Min: ${item.reorderThreshold}) - REORDER NEEDED');
      }
      sb.writeln('----------------------------------------');
    }

    sb.writeln('ALL INVENTORY ITEMS:');
    for (int i = 0; i < allStock.length; i++) {
      final item = allStock[i];
      sb.writeln('${i + 1}. ${item.name} | ${item.brand}');
      sb.writeln('   SKU: ${item.sku} | Qty: ${item.quantity} ${item.unit}');
      sb.writeln('   Sell Price: ${currency.format(item.sellingPrice)}');
    }
    sb.writeln('========================================');
    sb.writeln('End of Stock Report');

    final plainText = sb.toString();

    StatementModalHelper.show(
      context: context,
      title: locale.isBangla ? 'স্টক ও সতর্কবার্তা রিপোর্ট' : 'Stock Inventory & Alert Report',
      subtitle: '${allStock.length} SKUs • ${lowStockItems.length} Low Stock',
      textStatement: plainText,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isBangla ? 'মোট আইটেম' : 'Total Items',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${allStock.length} SKUs',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: lowStockItems.isNotEmpty
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: lowStockItems.isNotEmpty
                          ? AppColors.warning.withValues(alpha: 0.3)
                          : AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isBangla ? 'কম স্টক সতর্কতা' : 'Low Stock Alert',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lowStockItems.length} items',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: lowStockItems.isNotEmpty ? AppColors.warning : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale.isBangla ? 'আনুমানিক স্টক মূল্য (বিক্রয়)' : 'Est. Stock Sell Value',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                Text(
                  currency.format(totalStockValuation),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            locale.isBangla ? 'ইনভেন্টরি আইটেম তালিকা' : 'Inventory Items Breakdown',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          ...allStock.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (item.isLowStock || item.isOutOfStock)
                      ? AppColors.warning.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${item.brand} • SKU: ${item.sku}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.quantity} ${item.unit}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: (item.isLowStock || item.isOutOfStock) ? AppColors.danger : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        currency.format(item.sellingPrice),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
