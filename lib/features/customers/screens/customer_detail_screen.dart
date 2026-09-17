import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/utils/image_picker_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/transaction_record.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../home/widgets/action_confirmation_card.dart';
import '../../home/widgets/quick_action_modals.dart';
import '../../../shared/utils/communication_helper.dart';
import '../../../shared/widgets/statement_modal_helper.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  String _selectedTxFilter = 'all'; // 'all', 'due', 'payment'

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'CU';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _showEditCustomerModal(BuildContext context, Customer customer) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);

    final nameCtrl = TextEditingController(text: customer.name);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final vehicleCtrl = TextEditingController(text: customer.vehicleModel);
    final plateCtrl = TextEditingController(text: customer.plateNumber);
    final notesCtrl = TextEditingController(text: customer.notes);
    bool isVip = customer.isVip;
    String? avatarBase64 = customer.avatarBase64;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_note_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          locale.isBangla
                              ? 'কাস্টমার প্রোফাইল সম্পাদন'
                              : 'Edit Customer Profile',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Avatar Picker
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final result = await ImagePickerHelper.showPhotoSourceDialog(
                                context: context,
                                hasExistingPhoto: avatarBase64 != null && avatarBase64!.isNotEmpty,
                              );
                              if (result != null) {
                                setModalState(() {
                                  avatarBase64 = result.isEmpty ? null : result;
                                });
                              }
                            },
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryLight,
                                border: Border.all(color: AppColors.primary, width: 2),
                              ),
                              child: ClipOval(
                                child: avatarBase64 != null && avatarBase64!.isNotEmpty
                                    ? Image.memory(
                                        base64Decode(avatarBase64!),
                                        fit: BoxFit.cover,
                                        width: 76,
                                        height: 76,
                                      )
                                    : Center(
                                        child: Text(
                                          _getInitials(nameCtrl.text),
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                final result = await ImagePickerHelper.showPhotoSourceDialog(
                                  context: context,
                                  hasExistingPhoto: avatarBase64 != null && avatarBase64!.isNotEmpty,
                                );
                                if (result != null) {
                                  setModalState(() {
                                    avatarBase64 = result.isEmpty ? null : result;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: locale.translate('customer_name'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: vehicleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle Model',
                              prefixIcon: Icon(Icons.directions_car_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: plateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Plate Number',
                              prefixIcon: Icon(Icons.pin_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Workshop Notes / Vehicle History',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: isVip,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setModalState(() => isVip = val ?? false);
                          },
                        ),
                        const Text(
                          'Mark as VIP Customer',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final updatedName = nameCtrl.text.trim();
                        if (updatedName.isEmpty) return;

                        final updatedCustomer = customer.copyWith(
                          name: updatedName,
                          phone: phoneCtrl.text.trim(),
                          vehicleModel: vehicleCtrl.text.trim(),
                          plateNumber: plateCtrl.text.trim(),
                          notes: notesCtrl.text.trim(),
                          isVip: isVip,
                          avatarBase64: avatarBase64,
                          updatedAt: DateTime.now(),
                        );

                        repo.updateCustomer(updatedCustomer);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Profile updated successfully',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: AppColors.primaryDark,
                          ),
                        );
                      },
                      child: Text(
                        locale.isBangla
                            ? 'পরিবর্তন সংরক্ষণ করুন'
                            : 'Save Changes',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStatementModal(
      BuildContext context, Customer customer, List<TransactionRecord> transactions) {
    final currency = Provider.of<CurrencyManager>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final profile = repo.workshopProfile;
    final workshopName = profile['name']?.isNotEmpty == true ? profile['name']! : 'Apex Auto Workshop';
    final workshopPhone = profile['phone'] ?? '';
    final workshopAddress = profile['address'] ?? '';
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final textStatement = StringBuffer();
    textStatement.writeln('========================================');
    textStatement.writeln('       ${workshopName.toUpperCase()}');
    if (workshopAddress.isNotEmpty) textStatement.writeln('  $workshopAddress');
    if (workshopPhone.isNotEmpty) textStatement.writeln('  Tel: $workshopPhone');
    textStatement.writeln('========================================');
    textStatement.writeln('  CUSTOMER ACCOUNT STATEMENT');
    textStatement.writeln('  Date: $nowStr');
    textStatement.writeln('----------------------------------------');
    textStatement.writeln('CUSTOMER DETAILS:');
    textStatement.writeln(' • Name: ${customer.name}');
    if (customer.phone.isNotEmpty) textStatement.writeln(' • Phone: ${customer.phone}');
    textStatement.writeln(' • Vehicle: ${customer.vehicleModel} [${customer.plateNumber}]');
    textStatement.writeln('----------------------------------------');
    textStatement.writeln('ACCOUNT BALANCE:');
    textStatement.writeln(' • Total Billed:    ${currency.format(customer.totalBilled)}');
    textStatement.writeln(' • Total Paid:      ${currency.format(customer.totalPaid)}');
    textStatement.writeln(' • OUTSTANDING DUE: ${currency.format(customer.totalDue)}');
    textStatement.writeln('----------------------------------------');
    if (transactions.isNotEmpty) {
      textStatement.writeln('TRANSACTION HISTORY (${transactions.length} entries):');
      for (final tx in transactions) {
        final dateStr = DateFormat('dd MMM yyyy').format(tx.date);
        final tag = tx.isDue ? 'DEBIT' : (tx.isPayment ? 'CREDIT' : tx.type.toUpperCase());
        final sign = tx.isDue ? '+' : '-';
        textStatement.writeln(' - $dateStr: ${tx.description} [$sign${currency.format(tx.amount)}] ($tag)');
      }
    } else {
      textStatement.writeln('No transactions recorded.');
    }
    textStatement.writeln('========================================');
    textStatement.writeln('Thank you for choosing $workshopName!');

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer & Vehicle Info Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      customer.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                    ),
                  ),
                  if (customer.isVip)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('VIP', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900, fontSize: 10)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${customer.phone.isNotEmpty ? customer.phone : "No phone"} • ${customer.vehicleModel} [${customer.plateNumber}]',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Financial Summary Bento Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: customer.totalDue > 0 ? AppColors.dangerLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: customer.totalDue > 0 ? AppColors.danger.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.isBangla ? 'বকেয়া পাওনা' : 'OUTSTANDING DUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: customer.totalDue > 0 ? AppColors.danger : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(customer.totalDue),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: customer.totalDue > 0 ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.isBangla ? 'মোট বিল' : 'TOTAL BILLED',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(customer.totalBilled),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.isBangla ? 'মোট জমা' : 'TOTAL PAID',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(customer.totalPaid),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Transactions List
        Text(
          locale.isBangla ? 'লেনদেনের বিস্তারিত বিবরণী' : 'Ledger Entries (${transactions.length})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                locale.isBangla ? 'কোন লেনদেন পাওয়া যায়নি' : 'No transactions recorded',
                style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, i) => const Divider(height: 12, color: AppColors.border),
            itemBuilder: (context, idx) {
              final tx = transactions[idx];
              final isDebit = tx.isDue || tx.type == 'invoice';
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.description,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(tx.date),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDebit ? AppColors.dangerLight : AppColors.successLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isDebit ? 'DEBIT' : 'CREDIT',
                      style: TextStyle(color: isDebit ? AppColors.danger : AppColors.success, fontWeight: FontWeight.w900, fontSize: 9),
                    ),
                  ),
                  Text(
                    '${isDebit ? '+' : '-'}${currency.format(tx.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isDebit ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );

    StatementModalHelper.show(
      context: context,
      title: locale.isBangla ? 'কাস্টমার হিসাব বিবরণী' : 'Customer Statement',
      subtitle: customer.name,
      content: content,
      textStatement: textStatement.toString(),
      customerPhone: customer.phone,
      whatsAppMessage: textStatement.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final currency = Provider.of<CurrencyManager>(context);
    final locale = Provider.of<AppLocaleManager>(context);

    final customer = repo.getCustomerById(widget.customerId);

    if (customer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Customer Not Found'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_rounded,
                  size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text('Customer does not exist or has been removed.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final allTransactions =
        repo.getTransactionsForCustomer(customer.id, customer.name);

    final filteredTransactions = allTransactions.where((t) {
      if (_selectedTxFilter == 'due') {
        return t.isDue || t.type == 'invoice';
      } else if (_selectedTxFilter == 'payment') {
        return t.isPayment;
      }
      return true;
    }).toList();

    final lastVisitStr = allTransactions.isNotEmpty
        ? DateFormat('MMM d, yyyy').format(allTransactions.first.date)
        : DateFormat('MMM d, yyyy').format(customer.updatedAt);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          locale.isBangla ? 'কাস্টমার প্রোফাইল' : 'Customer Profile',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => _showEditCustomerModal(context, customer),
          ),
          if (repo.isOwner)
            IconButton(
              tooltip: 'Delete Customer',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              onPressed: () => _showDeleteCustomerDialog(context, repo, customer, currency, locale),
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Profile Summary Card (Bento Style)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar (Interactive tap to change photo)
                        GestureDetector(
                          onTap: () async {
                            final result = await ImagePickerHelper.showPhotoSourceDialog(
                              context: context,
                              hasExistingPhoto: customer.avatarBase64 != null && customer.avatarBase64!.isNotEmpty,
                            );
                            if (result != null) {
                              final updated = customer.copyWith(
                                avatarBase64: result.isEmpty ? null : result,
                                updatedAt: DateTime.now(),
                              );
                              await repo.updateCustomer(updated);
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: customer.totalDue > 0
                                      ? AppColors.dangerLight
                                      : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: customer.totalDue > 0
                                        ? AppColors.danger.withValues(alpha: 0.3)
                                        : AppColors.primary.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: customer.avatarBase64 != null && customer.avatarBase64!.isNotEmpty
                                      ? Image.memory(
                                          base64Decode(customer.avatarBase64!),
                                          fit: BoxFit.cover,
                                          width: 56,
                                          height: 56,
                                        )
                                      : Center(
                                          child: Text(
                                            _getInitials(customer.name),
                                            style: TextStyle(
                                              color: customer.totalDue > 0
                                                  ? AppColors.danger
                                                  : AppColors.primary,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      customer.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  if (customer.isVip) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE4E6),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: AppColors.danger
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: const Text(
                                        'VIP',
                                        style: TextStyle(
                                          color: AppColors.danger,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Phone
                              Row(
                                children: [
                                  const Icon(Icons.phone_rounded,
                                      size: 15, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    customer.phone.isNotEmpty
                                        ? customer.phone
                                        : 'No phone registered',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Vehicle & Plate
                              Row(
                                children: [
                                  const Icon(Icons.directions_car_rounded,
                                      size: 15, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    customer.vehicleModel.isNotEmpty
                                        ? customer.vehicleModel
                                        : 'Vehicle Not Set',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (customer.plateNumber.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: AppColors.border, width: 0.8),
                                      ),
                                      child: Text(
                                        customer.plateNumber,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (customer.notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  customer.notes,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Action vertical stack
                        Column(
                          children: [
                            IconButton(
                              tooltip: 'Call',
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.call_rounded,
                                    color: AppColors.primary, size: 18),
                              ),
                              onPressed: () {
                                CommunicationHelper.makePhoneCall(context, customer.phone);
                              },
                            ),
                            IconButton(
                              tooltip: 'WhatsApp',
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDCFCE7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_rounded,
                                    color: Color(0xFF16A34A), size: 18),
                              ),
                              onPressed: () {
                                final formattedDue = currency.format(customer.totalDue);
                                final msg = repo.formatWhatsAppDueMessage(
                                  amount: customer.totalDue,
                                  formattedAmount: formattedDue,
                                );
                                CommunicationHelper.sendWhatsAppMessage(
                                  context,
                                  rawPhone: customer.phone,
                                  message: msg,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Outstanding Due Hero Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: customer.totalDue > 0
                            ? [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ]
                            : [
                                const Color(0xFF0F766E),
                                const Color(0xFF047857),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (customer.totalDue > 0
                                  ? AppColors.primary
                                  : AppColors.success)
                              .withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              locale.isBangla
                                  ? 'বর্তমান বকেয়া বাকি'
                                  : 'CURRENT OUTSTANDING DUE',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                customer.totalDue > 0 ? 'PENDING' : 'SETTLED',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currency.format(customer.totalDue),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.only(top: 14),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_long_rounded,
                                      size: 15,
                                      color: Colors.white.withValues(alpha: 0.8)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Lifetime Billed: ${currency.format(customer.totalBilled)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.payments_rounded,
                                      size: 15,
                                      color: Colors.white.withValues(alpha: 0.8)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Paid: ${currency.format(customer.totalPaid)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event_outlined,
                                      size: 15,
                                      color: Colors.white.withValues(alpha: 0.8)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Last Visit: $lastVisitStr',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Primary Action Buttons Group (Ergonomic 54px min height)
                  Row(
                    children: [
                      // Settle Payment
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              QuickActionModals.showPayModal(
                                context,
                                initialCustomerName: customer.name,
                                customerId: customer.id,
                                initialAmount: customer.totalDue > 0
                                    ? customer.totalDue
                                    : 50.0,
                              );
                            },
                            icon: const Icon(Icons.account_balance_wallet_outlined,
                                size: 18),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                locale.isBangla
                                    ? 'পেমেন্ট জমা'
                                    : 'Settle Payment',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Add Due / Bill
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              side: const BorderSide(
                                  color: AppColors.border, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              QuickActionModals.showDueModal(
                                context,
                                initialCustomerName: customer.name,
                                customerId: customer.id,
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded,
                                size: 18, color: AppColors.danger),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                locale.isBangla ? '+ বাকি যোগ' : 'Add Due / Bill',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Share Statement
                      SizedBox(
                        height: 52,
                        width: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            padding: EdgeInsets.zero,
                            side: const BorderSide(
                                color: AppColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _showStatementModal(
                              context, customer, allTransactions),
                          child: const Icon(Icons.share_outlined,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
                    ],
                  ),
                  if (customer.totalDue > 0) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final formattedDue = currency.format(customer.totalDue);
                          final msg = repo.formatWhatsAppDueMessage(
                            amount: customer.totalDue,
                            formattedAmount: formattedDue,
                          );
                          CommunicationHelper.sendWhatsAppMessage(
                            context,
                            rawPhone: customer.phone,
                            message: msg,
                          );
                        },
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            locale.translate('send_whatsapp'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // 4. Transaction History Ledger
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${locale.isBangla ? "লেনদেনের ইতিহাস" : "Transaction History"} (${filteredTransactions.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      // Filter Segment Pills
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Row(
                          children: [
                            _buildFilterPill('all', 'All'),
                            _buildFilterPill('due', 'Dues'),
                            _buildFilterPill('payment', 'Payments'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Transaction List Items
                  if (filteredTransactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.history_rounded,
                                size: 48,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              locale.isBangla
                                  ? 'কোন লেনদেন পাওয়া যায়নি'
                                  : 'No transactions recorded yet',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
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
                      itemCount: filteredTransactions.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = filteredTransactions[index];
                        final isDebit = tx.isDue || tx.type == 'invoice';
                        final isCredit = tx.isPayment;
                        final formattedDate =
                            DateFormat('dd MMM yyyy, hh:mm a').format(tx.date);

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Left accent strip
                                  Container(
                                    width: 5,
                                    color: isDebit
                                        ? AppColors.danger
                                        : (isCredit
                                            ? AppColors.success
                                            : AppColors.primary),
                                  ),
                                  // Content
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                formattedDate,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              // Type Tag
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isDebit
                                                      ? AppColors.dangerLight
                                                      : (isCredit
                                                          ? AppColors.successLight
                                                          : AppColors
                                                              .primaryLight),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isDebit
                                                      ? 'DEBIT'
                                                      : (isCredit
                                                          ? 'CREDIT'
                                                          : 'STOCK'),
                                                  style: TextStyle(
                                                    color: isDebit
                                                        ? AppColors.danger
                                                        : (isCredit
                                                            ? AppColors.success
                                                            : AppColors
                                                                .primary),
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  tx.description,
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    fontSize: 14,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isDebit
                                                    ? '+${currency.format(tx.amount)}'
                                                    : '-${currency.format(tx.amount)}',
                                                style: TextStyle(
                                                  color: isDebit
                                                      ? AppColors.danger
                                                      : AppColors.success,
                                                  fontWeight:
                                                      FontWeight.w900,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.only(
                                                top: 6),
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                    color: AppColors.border,
                                                    width: 0.7),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Method: ${tx.paymentMethod.toUpperCase()}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: AppColors
                                                        .textSecondary,
                                                  ),
                                                ),
                                                Text(
                                                  'Running Due: ${currency.format(tx.runningBalance)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
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
    );
  }

  Widget _buildFilterPill(String value, String label) {
    final isSelected = _selectedTxFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTxFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showDeleteCustomerDialog(
    BuildContext context,
    GarageRepository repo,
    Customer customer,
    CurrencyManager currency,
    AppLocaleManager locale,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                locale.isBangla ? 'কাস্টমার ডিলিট করবেন?' : 'Delete Customer?',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.isBangla
                  ? 'আপনি কি নিশ্চিত যে "${customer.name}" প্রোফাইলটি ডিলিট করতে চান?'
                  : 'Are you sure you want to delete "${customer.name}"?',
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (customer.totalDue > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locale.isBangla
                            ? 'সতর্কতা: এই কাস্টমারের ${currency.format(customer.totalDue)} বকেয়া রয়েছে। ডিলিট করলে সকল লেনদেনের হিসাব মুছে যাবে।'
                            : 'Warning: This customer has an outstanding balance of ${currency.format(customer.totalDue)}. Deleting will remove all associated records.',
                        style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              locale.isBangla
                  ? 'ডিলিট করার পর ৫ সেকেন্ডের মধ্যে আনডু করার সুযোগ পাবেন।'
                  : 'You can undo this deletion within 5 seconds after confirming.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              locale.isBangla ? 'বাতিল' : 'Cancel',
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await repo.deleteCustomer(customer.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text(
              locale.isBangla ? 'ডিলিট করুন' : 'Delete Customer',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
