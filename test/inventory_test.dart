import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:garage_accounting_pro/core/theme/app_theme.dart';
import 'package:garage_accounting_pro/core/currency/currency_manager.dart';
import 'package:garage_accounting_pro/core/localization/app_locale.dart';
import 'package:garage_accounting_pro/data/models/stock_item.dart';
import 'package:garage_accounting_pro/data/repositories/garage_repository.dart';
import 'package:garage_accounting_pro/features/inventory/widgets/stock_item_card.dart';
import 'package:garage_accounting_pro/features/inventory/widgets/low_stock_banner.dart';
import 'package:garage_accounting_pro/features/inventory/widgets/dispense_stock_modal.dart';
import 'package:garage_accounting_pro/features/inventory/widgets/create_stock_item_modal.dart';
import 'package:garage_accounting_pro/features/inventory/widgets/edit_stock_item_modal.dart';
import 'package:garage_accounting_pro/features/inventory/screens/stock_inventory_screen.dart';

void main() {
  Widget createTestWidget(Widget child, {GarageRepository? repo}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => repo ?? GarageRepository()),
        ChangeNotifierProvider(create: (_) => CurrencyManager()),
        ChangeNotifierProvider(create: (_) => AppLocaleManager()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: child,
      ),
    );
  }

  group('StockItemCard Widget Tests', () {
    testWidgets('Renders IN STOCK item with enabled buttons and pricing in OMR', (tester) async {
      bool dispensed = false;
      bool added = false;

      final item = StockItem(
        id: 'item-1',
        name: 'Castrol Edge 5W-40 Synthetic (1L)',
        brand: 'Castrol',
        sku: 'CAS-5W40-01',
        quantity: 14,
        reorderThreshold: 5,
        costPrice: 8.500,
        sellingPrice: 14.000,
        unit: 'Qts',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: StockItemCard(
              item: item,
              onDispense: () => dispensed = true,
              onAddStock: () => added = true,
            ),
          ),
        ),
      );

      expect(find.text('Castrol Edge 5W-40 Synthetic (1L)'), findsOneWidget);
      expect(find.text('Castrol'), findsOneWidget);
      expect(find.text('CAS-5W40-01'), findsOneWidget);
      expect(find.text('14 Qts IN STOCK'), findsOneWidget);
      // Cost price must NOT be displayed on the card
      expect(find.text('OMR 8.500'), findsNothing);
      // Sell price must be prominently displayed
      expect(find.text('OMR 14.000'), findsOneWidget);
      expect(find.text('14 Qts'), findsOneWidget);
      expect(find.text('– Dispense'), findsOneWidget);
      expect(find.text('+ Add Stock'), findsOneWidget);

      await tester.tap(find.text('– Dispense'));
      await tester.pump();
      expect(dispensed, isTrue);

      await tester.tap(find.text('+ Add Stock'));
      await tester.pump();
      expect(added, isTrue);
    });

    testWidgets('Renders OUT OF STOCK badge and disables dispense button', (tester) async {
      bool dispensed = false;

      final item = StockItem(
        id: 'item-2',
        name: 'Bosch Ceramic Front Brake Pads',
        brand: 'Bosch',
        sku: 'BOS-BP-442',
        quantity: 0,
        reorderThreshold: 3,
        costPrice: 28.000,
        sellingPrice: 45.000,
        unit: 'Sets',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: StockItemCard(
              item: item,
              onDispense: () => dispensed = true,
              onAddStock: () {},
            ),
          ),
        ),
      );

      expect(find.text('0 Sets OUT OF STOCK'), findsOneWidget);
      expect(find.text('0 Sets'), findsOneWidget);

      // Tap dispense - should not trigger since quantity is 0
      await tester.tap(find.text('– Dispense'));
      await tester.pump();
      expect(dispensed, isFalse);
    });
  });

  group('LowStockBanner Tests', () {
    testWidgets('Renders critical alert carousel when low stock items exist', (tester) async {
      final lowItems = [
        StockItem(
          id: 'item-2',
          name: 'Bosch Ceramic Front Brake Pads',
          brand: 'Bosch',
          sku: 'BOS-BP-442',
          quantity: 0,
          reorderThreshold: 3,
          costPrice: 28.000,
          sellingPrice: 45.000,
          unit: 'Sets',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        StockItem(
          id: 'item-3',
          name: 'Denso Radiator Coolant Pre-mix',
          brand: 'Denso',
          sku: 'DEN-CL-101',
          quantity: 2,
          reorderThreshold: 5,
          costPrice: 12.000,
          sellingPrice: 22.000,
          unit: 'Gal',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            body: LowStockBanner(lowStockItems: lowItems),
          ),
        ),
      );

      expect(find.text('ACTION REQUIRED (2 ITEMS LOW / OUT OF STOCK)'), findsOneWidget);
      expect(find.text('0 Sets left (OUT OF STOCK)'), findsOneWidget);
      expect(find.text('2 Gal left (Min req: 5)'), findsOneWidget);
      expect(find.text('Reorder / Add Stock'), findsNWidgets(2));
    });

    testWidgets('Renders well-stocked banner when low stock list is empty', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const Scaffold(
            body: LowStockBanner(lowStockItems: []),
          ),
        ),
      );

      expect(find.text('All inventory items are well-stocked (0 critical alerts)'), findsOneWidget);
    });
  });

  group('StockInventoryScreen Tests', () {
    testWidgets('Renders screen headers, search input, brand filter chips, and Add Item FAB', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const StockInventoryScreen()),
      );

      expect(find.text('Parts & Inventory'), findsOneWidget);
      expect(find.text('Scan barcode or search part name, OEM #...'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      expect(find.text('Add New Item'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('Step 5: Stock Improvements & Dispense Bargaining Tests', () {
    testWidgets('CreateStockItemModal marks Cost Price as Owner Only', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CreateStockItemModal.show(context),
              child: const Text('Open Create'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Create'));
      await tester.pumpAndSettle();

      expect(find.text('Cost Price (Owner Only)'), findsOneWidget);
      expect(find.text('🔒 Hidden from cards'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('EditStockItemModal marks Cost Price as Owner Only', (tester) async {
      final item = StockItem(
        id: 'item-edit-1',
        name: 'Oil Filter 90915-YZZE1',
        brand: 'Toyota Genuine',
        sku: 'TOY-OF-90915',
        quantity: 8,
        reorderThreshold: 3,
        costPrice: 2.500,
        sellingPrice: 4.500,
        unit: 'Pcs',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EditStockItemModal.show(context, item),
              child: const Text('Open Edit'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Cost Price (Owner Only) *'), findsOneWidget);
      expect(find.text('🔒 Hidden from cards'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('DispenseStockModal renders editable price input and payment methods', (tester) async {
      final item = StockItem(
        id: 'item-disp-1',
        name: 'Brake Fluid DOT4',
        brand: 'Castrol',
        sku: 'CAS-BF-101',
        quantity: 10,
        reorderThreshold: 2,
        costPrice: 3.000,
        sellingPrice: 6.000,
        unit: 'Bottles',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DispenseStockModal.show(context, item: item),
              child: const Text('Open Dispense'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dispense'));
      await tester.pumpAndSettle();

      expect(find.text('Sell & Dispense Part'), findsOneWidget);
      expect(find.text('Final Selling Price (OMR)'), findsOneWidget);
      expect(find.text('💡 Edit if customer bargained, paid less, or got a discount'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('Bank Transfer'), findsOneWidget);
      expect(find.text('Recorded as Income in Cashbook:'), findsOneWidget);
    });

    test('dispenseStock records custom bargained price as Income and undo restores stock', () async {
      final repo = GarageRepository();
      await repo.loadAllData();

      // Create a test stock item
      final testItem = StockItem(
        id: 'item-unit-test-1',
        name: 'Castrol Edge 5W-40 Synthetic',
        brand: 'Castrol',
        sku: 'CAS-5W40-U1',
        quantity: 14,
        reorderThreshold: 5,
        costPrice: 8.500,
        sellingPrice: 14.000,
        unit: 'Qts',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createStockItem(testItem);

      final item = repo.getStockItemById(testItem.id)!;
      final initialQty = item.quantity;
      final initialIncome = repo.todayIncome;

      // Dispense 2 units with custom bargained price 11.500 OMR instead of default
      const customPrice = 11.500;
      await repo.dispenseStock(
        itemName: item.name,
        itemId: item.id,
        quantity: 2,
        targetBay: 'Bay 1',
        customPrice: customPrice,
        paymentMethod: 'Cash',
      );

      // Verify stock quantity decreased
      final updatedItem = repo.getStockItemById(item.id)!;
      expect(updatedItem.quantity, initialQty - 2);

      // Verify today's income increased by customPrice
      expect(repo.todayIncome, closeTo(initialIncome + customPrice, 0.001));

      // Verify Cashbook daily income breakdown contains stock_sale transaction
      final breakdown = repo.getDailyIncomeBreakdown(DateTime.now());
      final saleTx = breakdown.transactions.firstWhere((t) => t.type == 'stock_sale');
      expect(saleTx.amount, customPrice);
      expect(saleTx.isIncome, isTrue);
      expect(saleTx.isStockSale, isTrue);

      // Verify undo window is active
      expect(repo.lastUndoAction, isNotNull);
      expect(repo.lastUndoAction!.type, 'stock_sale');

      // Perform Undo
      await repo.undoLastAction();

      // Verify stock quantity restored
      final restoredItem = repo.getStockItemById(item.id)!;
      expect(restoredItem.quantity, initialQty);

      // Verify income reverted
      expect(repo.todayIncome, closeTo(initialIncome, 0.001));
    });
  });
}
