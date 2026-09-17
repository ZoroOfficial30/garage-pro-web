import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/currency/currency_manager.dart';
import '../../../core/localization/app_locale.dart';
import '../../../data/repositories/garage_repository.dart';
import '../../../data/models/customer.dart';
import '../services/command_parser.dart';
import '../services/voice_service.dart';
import '../widgets/customer_command_suggestions.dart';
import '../widgets/expense_category_suggestions.dart';
import '../widgets/income_preset_suggestions.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/quick_action_modals.dart';
import '../widgets/action_confirmation_card.dart';
import '../widgets/chat_feed_item.dart';
import '../../navigation/widgets/drawer_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  final ValueNotifier<double> _soundLevelNotifier = ValueNotifier<double>(0.0);
  late AnimationController _pulseController;

  CommandDraft? _currentDraft;
  Customer? _selectedCustomer;
  bool _createNewCustomerSelected = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _commandController.addListener(_onCommandChanged);
  }

  @override
  void dispose() {
    _voiceService.cancelListening();
    _commandController.removeListener(_onCommandChanged);
    _commandController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _soundLevelNotifier.dispose();
    super.dispose();
  }

  void _onCommandChanged() {
    final text = _commandController.text;
    final draft = CommandParser.parseDraft(text);
    if (draft != null) {
      if (_currentDraft?.rawText != text) {
        setState(() {
          _currentDraft = draft;
        });
      }
    } else if (_currentDraft != null) {
      setState(() {
        _currentDraft = null;
        _selectedCustomer = null;
        _createNewCustomerSelected = false;
      });
    }
  }

  void _onSelectCustomer(Customer customer) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final draft = _currentDraft;
    if (draft == null) return;

    if (draft.amount != null && draft.amount! > 0) {
      if (draft.type == CommandType.due) {
        repo.addDue(
          customerId: customer.id,
          customerName: customer.name,
          amount: draft.amount!,
          description: draft.rawText,
        );
      } else {
        repo.addPayment(
          customerId: customer.id,
          customerName: customer.name,
          amount: draft.amount!,
          description: draft.rawText,
        );
      }
      _commandController.clear();
      setState(() {
        _currentDraft = null;
        _selectedCustomer = null;
        _createNewCustomerSelected = false;
      });
    } else {
      final prefix = draft.type == CommandType.due ? 'ad' : 'sp';
      final newText = '$prefix ${customer.name} ';
      _commandController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      setState(() {
        _selectedCustomer = customer;
        _createNewCustomerSelected = false;
      });
    }
  }

  void _onCreateNewCustomer(String name) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final draft = _currentDraft;
    if (draft == null) return;

    final customerName = name.trim().isEmpty ? 'New Customer' : name.trim();

    if (draft.amount != null && draft.amount! > 0) {
      if (draft.type == CommandType.due) {
        repo.addDue(
          customerName: customerName,
          amount: draft.amount!,
          createNewCustomer: true,
          description: draft.rawText,
        );
      } else {
        repo.addPayment(
          customerName: customerName,
          amount: draft.amount!,
          createNewCustomer: true,
          description: draft.rawText,
        );
      }
      _commandController.clear();
      setState(() {
        _currentDraft = null;
        _selectedCustomer = null;
        _createNewCustomerSelected = false;
      });
    } else {
      final prefix = draft.type == CommandType.due ? 'ad' : 'sp';
      final newText = '$prefix $customerName ';
      _commandController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      setState(() {
        _selectedCustomer = null;
        _createNewCustomerSelected = true;
      });
    }
  }

  void _onSelectExpenseCategory(String categoryKey, String displayLabel) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final draft = _currentDraft;
    if (draft == null) return;

    if (draft.amount != null && draft.amount! > 0) {
      repo.addExpenseRecord(
        title: '$displayLabel Expense',
        category: categoryKey,
        amount: draft.amount!,
      );
      _commandController.clear();
      setState(() {
        _currentDraft = null;
      });
    } else {
      final newText = 'ex ${displayLabel.toLowerCase()} ';
      _commandController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  void _onSelectIncomeCategory(String categoryKey, String displayLabel) {
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final draft = _currentDraft;
    if (draft == null) return;

    if (draft.amount != null && draft.amount! > 0) {
      repo.recordIncome(
        category: categoryKey,
        amount: draft.amount!,
        description: '$displayLabel Income',
      );
      _commandController.clear();
      setState(() {
        _currentDraft = null;
      });
    } else {
      final keyword = categoryKey == 'Car Wash' ? 'car wash' : (categoryKey == 'Service' ? 'service' : 'other');
      final newText = 'in $keyword ';
      _commandController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  void _handleCommandSubmit(String text) {
    if (text.trim().isEmpty) return;
    final repo = Provider.of<GarageRepository>(context, listen: false);
    final locale = Provider.of<AppLocaleManager>(context, listen: false);
    final cmd = CommandParser.parse(text);

    switch (cmd.type) {
      case CommandType.income:
        repo.recordIncome(
          category: cmd.category ?? 'Other Income',
          amount: cmd.amount ?? 20.0,
          description: cmd.description ?? 'Direct Income',
          customerName: cmd.customerOrItem ?? 'Walk-in Customer',
        );
        break;
      case CommandType.expense:
        repo.addExpenseRecord(
          title: cmd.description ?? 'Workshop Expense',
          category: cmd.category ?? 'Miscellaneous',
          amount: cmd.amount ?? 15.0,
        );
        break;
      case CommandType.due:
        final targetCust = _selectedCustomer ??
            (_createNewCustomerSelected
                ? null
                : repo.findCustomerByQuery(cmd.customerOrItem ?? ''));
        repo.addDue(
          customerId: targetCust?.id,
          customerName: targetCust?.name ?? (cmd.customerOrItem ?? 'Customer'),
          amount: cmd.amount ?? 50.0,
          createNewCustomer: _createNewCustomerSelected,
          description: cmd.rawText,
        );
        break;
      case CommandType.pay:
        final targetCust = _selectedCustomer ??
            (_createNewCustomerSelected
                ? null
                : repo.findCustomerByQuery(cmd.customerOrItem ?? ''));
        repo.addPayment(
          customerId: targetCust?.id,
          customerName: targetCust?.name ?? (cmd.customerOrItem ?? 'Customer'),
          amount: cmd.amount ?? 50.0,
          createNewCustomer: _createNewCustomerSelected,
          description: cmd.rawText,
        );
        break;
      case CommandType.stockOut:
        repo.dispenseStock(
          itemName: cmd.customerOrItem ?? 'Castrol',
          quantity: cmd.quantity ?? 1,
        );
        break;
      case CommandType.newJob:
        repo.addNewJob(
          customerName: cmd.customerOrItem ?? 'Customer',
          vehicle: 'Vehicle in Bay',
          task: cmd.description ?? 'Inspection & Repair',
        );
        break;
      case CommandType.unknown:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locale.isBangla
                  ? 'কমান্ড বুঝতে পারিনি। "in [বিবরণ] [টাকা]" বা "ex [খাত] [টাকা]" লিখুন।'
                  : 'Command not recognized. Use "in [category] [amt]", "ex [category] [amt]", "ad [name] [amt]", or "sp [name] [amt]".',
            ),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }

    _commandController.clear();
    setState(() {
      _currentDraft = null;
      _selectedCustomer = null;
      _createNewCustomerSelected = false;
    });
  }

  Future<void> _toggleVoiceInput(AppLocaleManager locale) async {
    if (_isListening) {
      await _stopVoiceInput(locale);
    } else {
      await _startVoiceInput(locale);
    }
  }

  Future<void> _startVoiceInput(AppLocaleManager locale) async {
    _soundLevelNotifier.value = 0.0;
    setState(() {
      _isListening = true;
    });

    final started = await _voiceService.startListening(
      language: locale.currentLanguage,
      onResult: (text, isFinal) {
        if (!mounted) return;
        _commandController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        if (isFinal) {
          _soundLevelNotifier.value = 0.0;
          setState(() {
            _isListening = false;
          });
        }
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        _soundLevelNotifier.value = (level.clamp(0.0, 10.0) / 10.0);
      },
    );

    if (!started && mounted) {
      _soundLevelNotifier.value = 0.0;
      setState(() {
        _isListening = false;
      });
      _showVoiceFallbackSheet(locale);
    }
  }

  Future<void> _stopVoiceInput(AppLocaleManager locale) async {
    await _voiceService.stopListening();
    if (mounted) {
      _soundLevelNotifier.value = 0.0;
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _cancelVoiceInput() async {
    await _voiceService.cancelListening();
    if (mounted) {
      _soundLevelNotifier.value = 0.0;
      setState(() {
        _isListening = false;
      });
    }
  }

  void _showVoiceFallbackSheet(AppLocaleManager locale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                locale.translate('mic_permission_needed'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                locale.translate('mic_permission_desc'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  locale.isBangla
                      ? 'দ্রুত ভয়েস কমান্ড বেছে নিন:'
                      : 'Quick Voice Presets (Tap to use):',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildVoicePresetChip(ctx, 'ad Karim 50'),
                  _buildVoicePresetChip(ctx, 'sp David 30'),
                  _buildVoicePresetChip(ctx, '+due Rahim 100'),
                  _buildVoicePresetChip(ctx, '-pay Kamal 50'),
                  _buildVoicePresetChip(ctx, 'ad করিম ৫০'),
                  _buildVoicePresetChip(ctx, 'sp ডেভিড ৩০'),
                  _buildVoicePresetChip(ctx, 'stockout 2 Castrol 5W-30'),
                  _buildVoicePresetChip(ctx, 'expense 15 Staff Tea'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(locale.translate('cancel')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoicePresetChip(BuildContext ctx, String sampleVoiceText) {
    return ActionChip(
      avatar: const Icon(Icons.mic, size: 16, color: AppColors.primary),
      label: Text(
        sampleVoiceText,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      backgroundColor: AppColors.background,
      side: const BorderSide(color: AppColors.border, width: 1.2),
      onPressed: () {
        Navigator.pop(ctx);
        setState(() {
          _commandController.text = sampleVoiceText;
          _commandController.selection =
              TextSelection.collapsed(offset: sampleVoiceText.length);
        });
      },
    );
  }

  Widget _buildActiveVoiceBanner(AppLocaleManager locale) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(
                        alpha: 0.4 + (_pulseController.value * 0.6),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        locale.translate('listening_status'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            locale.isBangla ? 'বাংলা (bn_BD)' : 'English (en_US)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: () => _stopVoiceInput(locale),
                icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    locale.isBangla ? 'সম্পন্ন' : 'Done',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                onPressed: _cancelVoiceInput,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: locale.translate('cancel'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _soundLevelNotifier]),
              builder: (context, child) {
                final soundLevel = _soundLevelNotifier.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(9, (index) {
                    final double factor = (index % 2 == 0)
                        ? _pulseController.value
                        : (1.0 - _pulseController.value);
                    final double dynamicBoost = (soundLevel * 16.0);
                    final double barHeight = 8 + (factor * 12) + dynamicBoost;
                    final isCenter = index == 4;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 5,
                      height: barHeight.clamp(6.0, 36.0),
                      decoration: BoxDecoration(
                        color: isCenter ? AppColors.danger : AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.centerLeft,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _commandController,
              builder: (context, val, child) {
                final hasText = val.text.isNotEmpty;
                return Text(
                  hasText ? val.text : locale.translate('listening_hint'),
                  style: TextStyle(
                    color: hasText
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontStyle: hasText
                        ? FontStyle.normal
                        : FontStyle.italic,
                    fontWeight: hasText
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<GarageRepository>(context);
    final currency = Provider.of<CurrencyManager>(context);
    final locale = Provider.of<AppLocaleManager>(context);
    final nowFormatted = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      drawer: buildAppDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP STATUS & BRANDING BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      buildDrawerHamburgerButton(context),
                      const SizedBox(width: 6),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (repo.workshopLogoBase64 != null)
                            ? Image.memory(
                                base64Decode(repo.workshopLogoBase64!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.build_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              )
                            : const Icon(
                                Icons.build_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repo.workshopProfile['name']?.isNotEmpty == true
                                  ? repo.workshopProfile['name']!
                                  : locale.translate('app_title'),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              nowFormatted,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Language Toggle Pill
                      InkWell(
                        onTap: () => locale.toggleLanguage(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 1.2),
                          ),
                          child: Text(
                            locale.isBangla ? 'বাংলা 🇧🇩' : 'EN 🇺🇸',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // PIN Lock icon
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Online Status Bar & Currency Indicator
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isListening ? AppColors.danger : AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _isListening ? locale.translate('listening_status') : locale.translate('online_sync'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _isListening ? AppColors.danger : AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${currency.currentInfo.symbol} (${currency.currentInfo.englishName})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. CONFIRMATION & UNDO FLOATING BANNER
            if (repo.lastUndoAction != null)
              ActionConfirmationCard(
                title: repo.lastUndoAction!.title,
                description: repo.lastUndoAction!.description,
                countdownSeconds: repo.undoCountdown,
                onUndo: () => repo.undoLastAction(),
              ),

            // 3. FIVE GIANT QUICK ACTION BUTTONS STRIP
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              color: AppColors.background,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    QuickActionButton(
                      label: locale.translate('quick_due'),
                      icon: Icons.add_circle_outline,
                      color: AppColors.danger,
                      onTap: () => QuickActionModals.showDueModal(context),
                    ),
                    const SizedBox(width: 8),
                    QuickActionButton(
                      label: locale.translate('quick_pay'),
                      icon: Icons.payments_outlined,
                      color: AppColors.success,
                      onTap: () => QuickActionModals.showPayModal(context),
                    ),
                    const SizedBox(width: 8),
                    QuickActionButton(
                      label: locale.translate('quick_stock_out'),
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      onTap: () => QuickActionModals.showStockOutModal(context),
                    ),
                    const SizedBox(width: 8),
                    QuickActionButton(
                      label: locale.translate('quick_expense'),
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.warning,
                      onTap: () => QuickActionModals.showExpenseModal(context),
                    ),
                    const SizedBox(width: 8),
                    QuickActionButton(
                      label: locale.translate('quick_new_job'),
                      icon: Icons.build_circle_outlined,
                      color: AppColors.primaryDark,
                      onTap: () => QuickActionModals.showNewJobModal(context),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // 4. SCROLLABLE CONVERSATIONAL CHAT FEED
            Expanded(
              child: repo.transactions.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 34,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              locale.isBangla
                                  ? 'কোন লেনদেন এখনও নেই'
                                  : 'No transactions yet',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              locale.isBangla
                                  ? 'শুরু করতে নিচের বক্সে লিখুন বা দ্রুত অ্যাকশন ব্যবহার করুন!'
                                  : 'Type in the box below to start, or tap the mic to speak!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildEmptyPromptChip(
                                  icon: Icons.add_circle_outline,
                                  label: locale.isBangla ? 'বাকি যোগ' : 'Add Due',
                                  onTap: () => QuickActionModals.showDueModal(context),
                                ),
                                _buildEmptyPromptChip(
                                  icon: Icons.payments_outlined,
                                  label: locale.isBangla ? 'টাকা জমা' : 'Receive Pay',
                                  onTap: () => QuickActionModals.showPayModal(context),
                                ),
                                _buildEmptyPromptChip(
                                  icon: Icons.car_repair_rounded,
                                  label: locale.isBangla ? 'কাজের কার্ড' : 'Create Job',
                                  onTap: () => QuickActionModals.showNewJobModal(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: repo.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = repo.transactions[index];
                        return ChatFeedItem(
                          record: tx,
                          formattedAmount: currency.format(tx.amount),
                          formattedRunningBalance: currency.format(tx.runningBalance),
                        );
                      },
                    ),
            ),

            // 4.5 LIVE COMMAND SUGGESTIONS (Due/Pay, Expense Categories, Income Presets)
            if (_currentDraft != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_currentDraft!.type == CommandType.due || _currentDraft!.type == CommandType.pay)
                        CustomerCommandSuggestions(
                          draft: _currentDraft!,
                          matchingCustomers: repo.searchCustomers(_currentDraft!.query),
                          currency: currency,
                          onSelectCustomer: _onSelectCustomer,
                          onCreateNewCustomer: _onCreateNewCustomer,
                          onClose: () => setState(() => _currentDraft = null),
                        ),
                      if (_currentDraft!.type == CommandType.expense)
                        ExpenseCategorySuggestions(
                          draft: _currentDraft!,
                          currency: currency,
                          onSelectCategory: _onSelectExpenseCategory,
                          onClose: () => setState(() => _currentDraft = null),
                        ),
                      if (_currentDraft!.type == CommandType.income)
                        IncomePresetSuggestions(
                          draft: _currentDraft!,
                          currency: currency,
                          onSelectCategory: _onSelectIncomeCategory,
                          onClose: () => setState(() => _currentDraft = null),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // 4.6 ACTIVE VOICE RECORDING BANNER (SMOOTH BOUNDED CROSS-FADE)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 240),
              crossFadeState: _isListening
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _buildActiveVoiceBanner(locale),
              secondChild: const SizedBox(width: double.infinity, height: 0),
              sizeCurve: Curves.easeInOutCubic,
            ),

            // 5. PRIMARY COMMAND BAR WITH INLINE MIC & SEND SUFFIX ACTIONS
            SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
                ),
              child: SizedBox(
                height: 52,
                child: TextField(
                  controller: _commandController,
                  autofocus: false,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: locale.translate('type_command_hint'),
                    hintStyle: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFFFFFF),
                    isDense: true,
                    contentPadding: const EdgeInsets.only(left: 14, right: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.6),
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _commandController,
                      builder: (context, val, _) {
                        final hasText = val.text.trim().isNotEmpty;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasText)
                              IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                                onPressed: () => _commandController.clear(),
                                tooltip: locale.translate('cancel'),
                              ),
                            // 40px Circular Inline Mic Target
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (_isListening)
                                      AnimatedBuilder(
                                        animation: Listenable.merge([_pulseController, _soundLevelNotifier]),
                                        builder: (context, _) {
                                          final soundLevel = _soundLevelNotifier.value;
                                          final extra = (_pulseController.value * 4 + soundLevel * 4).clamp(0.0, 6.0);
                                          return Container(
                                            width: 32 + extra,
                                            height: 32 + extra,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFFE11D48).withValues(alpha: 0.25),
                                            ),
                                          );
                                        },
                                      ),
                                    Material(
                                      color: _isListening
                                          ? const Color(0xFFE11D48)
                                          : const Color(0xFF0284C7).withValues(alpha: 0.1),
                                      shape: const CircleBorder(),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () => _toggleVoiceInput(locale),
                                        onLongPress: () => _showVoiceFallbackSheet(locale),
                                        child: SizedBox(
                                          width: 34,
                                          height: 34,
                                          child: Icon(
                                            _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                                            color: _isListening ? Colors.white : const Color(0xFF0284C7),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Send button: Visible when text is typed to submit commands directly
                            if (hasText)
                              Padding(
                                padding: const EdgeInsets.only(right: 6, left: 2),
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Material(
                                    color: const Color(0xFF0284C7),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () => _handleCommandSubmit(_commandController.text),
                                      child: const Center(
                                        child: Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  onSubmitted: _handleCommandSubmit,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEmptyPromptChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

