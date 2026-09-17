enum CommandType { due, pay, income, expense, stockOut, newJob, unknown }

class CommandDraft {
  final CommandType type; // due, pay, income, expense
  final String query; // customer name, or category keywords
  final double? amount;
  final String rawText;
  final String? category; // resolved category if applicable

  CommandDraft({
    required this.type,
    required this.query,
    this.amount,
    required this.rawText,
    this.category,
  });
}

class ParsedCommand {
  final CommandType type;
  final String? customerOrItem;
  final double? amount;
  final int? quantity;
  final String? description;
  final String? category;
  final String rawText;

  ParsedCommand({
    required this.type,
    this.customerOrItem,
    this.amount,
    this.quantity,
    this.description,
    this.category,
    required this.rawText,
  });
}

class CommandParser {
  static String normalizeNumerals(String input) {
    const banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(banglaDigits[i], '$i');
      result = result.replaceAll(arabicDigits[i], '$i');
    }
    return result;
  }

  static bool isPhoneNumber(String token) {
    final t = token.trim();
    if (t.isEmpty) return false;

    // Support masked phones like 017XXXXXXXX
    if (RegExp(r'^01[0-9xX]{5,}$').hasMatch(t)) return true;
    if (RegExp(r'^\+?[0-9xX\-()]{7,}$').hasMatch(t)) return true;

    // Digits only
    final digitsOnly = t.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length >= 7 &&
        (t.startsWith('01') || t.startsWith('+') || !t.contains('.'))) {
      return true;
    }
    return false;
  }

  /// Extracts query (customer name or phone) and numeric amount from token list
  static (String query, double? amount) parseCustomerTokens(List<String> tokens) {
    if (tokens.isEmpty) return ('', null);

    String? phoneToken;
    String? amountToken;
    final List<String> nameTokens = [];

    for (final token in tokens) {
      if (phoneToken == null && isPhoneNumber(token)) {
        phoneToken = token;
      } else {
        final parsed = double.tryParse(token.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (amountToken == null && parsed != null && parsed > 0 && !token.toUpperCase().contains('X')) {
          amountToken = token;
        } else {
          nameTokens.add(token);
        }
      }
    }

    final double? amount = amountToken != null
        ? double.tryParse(amountToken.replaceAll(RegExp(r'[^0-9.]'), ''))
        : null;

    final String query = phoneToken ?? nameTokens.join(' ').trim();
    return (query, amount);
  }

  /// Resolves income category from query words
  static String resolveIncomeCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('wash') ||
        lower.contains('car') ||
        lower.contains('ওয়াশ') ||
        lower.contains('ওয়াশ') ||
        lower.contains('ধোয়া')) {
      return 'Car Wash';
    }
    if (lower.contains('service') ||
        lower.contains('repair') ||
        lower.contains('oil') ||
        lower.contains('tire') ||
        lower.contains('ac') ||
        lower.contains('সার্ভিস') ||
        lower.contains('মেরামত')) {
      return 'Service';
    }
    return 'Other Income';
  }

  /// Resolves expense category from query words
  static String resolveExpenseCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('food') ||
        lower.contains('foo') ||
        lower.contains('tea') ||
        lower.contains('lunch') ||
        lower.contains('snack') ||
        lower.contains('meal') ||
        lower.contains('dinner') ||
        lower.contains('খাবার') ||
        lower.contains('চা') ||
        lower.contains('লাঞ্চ')) {
      return 'Staff Food & Tea';
    }
    if (lower.contains('tool') ||
        lower.contains('gear') ||
        lower.contains('wrench') ||
        lower.contains('socket') ||
        lower.contains('spanner') ||
        lower.contains('যন্ত্রপাতি')) {
      return 'Tools & Gear';
    }
    if (lower.contains('rent') ||
        lower.contains('ভাড়া') ||
        lower.contains('ভাড়া') ||
        lower.contains('দোকান ভাড়া')) {
      return 'Workshop Rent';
    }
    if (lower.contains('salary') ||
        lower.contains('wage') ||
        lower.contains('staff') ||
        lower.contains('employee') ||
        lower.contains('বেতন')) {
      return 'Staff Salary';
    }
    if (lower.contains('utilit') ||
        lower.contains('electric') ||
        lower.contains('power') ||
        lower.contains('water') ||
        lower.contains('bill') ||
        lower.contains('বিদ্যুৎ') ||
        lower.contains('বিল')) {
      return 'Rent & Utilities';
    }
    if (lower.contains('consum') ||
        lower.contains('parts') ||
        lower.contains('spare') ||
        lower.contains('oil') ||
        lower.contains('coolant') ||
        lower.contains('soap') ||
        lower.contains('rag') ||
        lower.contains('shop') ||
        lower.contains('মালামাল')) {
      return 'Shop Consumables';
    }
    return 'Miscellaneous';
  }

  /// Parses draft input as the user is actively typing to trigger live suggestions
  static CommandDraft? parseDraft(String input) {
    final normalized = normalizeNumerals(input.trim());
    if (normalized.isEmpty) return null;

    final lower = normalized.toLowerCase();
    CommandType? type;
    String remainder = '';

    // 1. Income commands: in, +in, income, or Bangla আয়/আয়
    if (lower.startsWith('in ') ||
        lower == 'in' ||
        lower.startsWith('+in') ||
        lower.startsWith('income ') ||
        lower == 'income' ||
        lower.startsWith('আয়') ||
        lower.startsWith('আয়')) {
      type = CommandType.income;
      if (lower.startsWith('+in')) {
        remainder = normalized.substring(3).trim();
      } else if (lower.startsWith('income ') || lower == 'income') {
        remainder = normalized.length > 6 ? normalized.substring(6).trim() : '';
      } else if (lower.startsWith('in ') || lower == 'in') {
        remainder = normalized.length > 2 ? normalized.substring(2).trim() : '';
      } else if (lower.startsWith('আয়') || lower.startsWith('আয়')) {
        remainder = normalized.substring(2).trim();
      }

      final tokens = remainder.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      double? amount;
      final List<String> queryWords = [];
      for (final t in tokens) {
        final parsed = double.tryParse(t.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (amount == null && parsed != null && parsed > 0) {
          amount = parsed;
        } else {
          queryWords.add(t);
        }
      }

      final query = queryWords.join(' ').trim();
      final category = resolveIncomeCategory(query);

      return CommandDraft(
        type: type,
        query: query,
        amount: amount,
        category: category,
        rawText: input,
      );
    }

    // 2. Expense / Outflow commands: ex, out, -out, exp, expense, or Bangla খরচ
    // Note: 'stockout' or 'stock out' is reserved for inventory stockOut
    if (!lower.startsWith('stockout') &&
        !lower.startsWith('stock out') &&
        !lower.contains('মাল আউট') &&
        (lower.startsWith('ex ') ||
            lower == 'ex' ||
            lower.startsWith('out ') ||
            lower == 'out' ||
            lower.startsWith('-out') ||
            lower.startsWith('exp ') ||
            lower == 'exp' ||
            lower.startsWith('expense ') ||
            lower == 'expense' ||
            lower.startsWith('খরচ') ||
            lower.contains('খরচ'))) {
      type = CommandType.expense;
      if (lower.startsWith('-out')) {
        remainder = normalized.substring(4).trim();
      } else if (lower.startsWith('out ') || lower == 'out') {
        remainder = normalized.length > 3 ? normalized.substring(3).trim() : '';
      } else if (lower.startsWith('expense ') || lower == 'expense') {
        remainder = normalized.length > 7 ? normalized.substring(7).trim() : '';
      } else if (lower.startsWith('exp ') || lower == 'exp') {
        remainder = normalized.length > 3 ? normalized.substring(3).trim() : '';
      } else if (lower.startsWith('ex ') || lower == 'ex') {
        remainder = normalized.length > 2 ? normalized.substring(2).trim() : '';
      } else if (lower.contains('খরচ')) {
        remainder = normalized.replaceAll('খরচ', ' ').trim();
      }

      final tokens = remainder.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      double? amount;
      final List<String> queryWords = [];
      for (final t in tokens) {
        final parsed = double.tryParse(t.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (amount == null && parsed != null && parsed > 0) {
          amount = parsed;
        } else {
          queryWords.add(t);
        }
      }

      final query = queryWords.join(' ').trim();
      final category = resolveExpenseCategory(query);

      return CommandDraft(
        type: type,
        query: query,
        amount: amount,
        category: category,
        rawText: input,
      );
    }

    // 3. Due commands: +due, ad, due, or Bangla বাকি
    if (lower.startsWith('+due') ||
        lower.startsWith('ad ') ||
        lower == 'ad' ||
        lower.startsWith('due ') ||
        lower == 'due' ||
        lower.contains('বাকি')) {
      type = CommandType.due;
      if (lower.startsWith('+due')) {
        remainder = normalized.substring(4).trim();
      } else if (lower.startsWith('ad ') || lower == 'ad') {
        remainder = normalized.length > 2 ? normalized.substring(2).trim() : '';
      } else if (lower.startsWith('due ') || lower == 'due') {
        remainder = normalized.length > 3 ? normalized.substring(3).trim() : '';
      } else if (lower.contains('বাকি')) {
        remainder = normalized.replaceAll('বাকি', ' ').trim();
      }

      final tokens = remainder.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      final (query, amount) = parseCustomerTokens(tokens);

      return CommandDraft(
        type: type,
        query: query,
        amount: amount,
        rawText: input,
      );
    }

    // 4. Pay commands: -pay, sp, pay, or Bangla জমা
    if (lower.startsWith('-pay') ||
        lower.startsWith('sp ') ||
        lower == 'sp' ||
        lower.startsWith('pay ') ||
        lower == 'pay' ||
        lower.contains('জমা')) {
      type = CommandType.pay;
      if (lower.startsWith('-pay')) {
        remainder = normalized.substring(4).trim();
      } else if (lower.startsWith('sp ') || lower == 'sp') {
        remainder = normalized.length > 2 ? normalized.substring(2).trim() : '';
      } else if (lower.startsWith('pay ') || lower == 'pay') {
        remainder = normalized.length > 3 ? normalized.substring(3).trim() : '';
      } else if (lower.contains('জমা')) {
        remainder = normalized.replaceAll('জমা', ' ').trim();
      }

      final tokens = remainder.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      final (query, amount) = parseCustomerTokens(tokens);

      return CommandDraft(
        type: type,
        query: query,
        amount: amount,
        rawText: input,
      );
    }

    return null;
  }

  static ParsedCommand parse(String input) {
    final normalized = normalizeNumerals(input.trim());
    final text = normalized;
    if (text.isEmpty) {
      return ParsedCommand(type: CommandType.unknown, rawText: input);
    }

    final lower = text.toLowerCase();

    // 1. Stock Out (strictly stockout, stock out, or মাল আউট)
    if (lower.startsWith('stockout') ||
        lower.startsWith('stock out') ||
        lower.contains('মাল আউট')) {
      final parts = text.split(RegExp(r'\s+'));
      int qty = 1;
      String itemName = 'Castrol 5W-40';

      for (final p in parts) {
        final parsedInt = int.tryParse(p);
        if (parsedInt != null) {
          qty = parsedInt;
        } else if (!['stockout', 'stock', 'out', 'আউট', 'মাল'].contains(p.toLowerCase())) {
          itemName = p;
        }
      }

      return ParsedCommand(
        type: CommandType.stockOut,
        customerOrItem: itemName,
        quantity: qty,
        description: 'Stock Out: $qty $itemName',
        rawText: text,
      );
    }

    // 2. Income Command ("in", "+in", "income", "আয়", "আয়")
    if (lower.startsWith('in ') ||
        lower == 'in' ||
        lower.startsWith('+in') ||
        lower.startsWith('income ') ||
        lower == 'income' ||
        lower.startsWith('আয়') ||
        lower.startsWith('আয়')) {
      final draft = parseDraft(text);
      final category = draft?.category ?? 'Other Income';
      final amount = (draft?.amount != null && draft!.amount! > 0)
          ? draft.amount!
          : 20.0;

      String desc;
      if (category == 'Car Wash') {
        desc = draft?.query.isNotEmpty == true
            ? '${draft!.query.toUpperCase()} Income'
            : 'Car Wash Income';
      } else if (category == 'Service') {
        desc = draft?.query.isNotEmpty == true
            ? '${draft!.query} Service Income'
            : 'Service Income';
      } else {
        desc = draft?.query.isNotEmpty == true
            ? draft!.query
            : 'Other Income';
      }

      return ParsedCommand(
        type: CommandType.income,
        category: category,
        amount: amount,
        description: desc,
        customerOrItem: 'Walk-in Customer',
        rawText: text,
      );
    }

    // 3. Expense / Outflow Command ("ex", "out", "-out", "expense", "exp", "খরচ")
    if (lower.startsWith('ex ') ||
        lower == 'ex' ||
        lower.startsWith('out ') ||
        lower == 'out' ||
        lower.startsWith('-out') ||
        lower.startsWith('expense') ||
        lower.startsWith('exp ') ||
        lower == 'exp' ||
        lower.contains('খরচ')) {
      final draft = parseDraft(text);
      final category = draft?.category ?? 'Miscellaneous';
      final amount = (draft?.amount != null && draft!.amount! > 0)
          ? draft.amount!
          : 15.0;

      final desc = draft?.query.isNotEmpty == true
          ? '${draft!.query} ($category)'
          : '$category Expense';

      return ParsedCommand(
        type: CommandType.expense,
        category: category,
        amount: amount,
        description: desc,
        rawText: text,
      );
    }

    // 4. New Job
    if (lower.startsWith('job') ||
        lower.startsWith('new job') ||
        lower.contains('কাজ') ||
        lower.contains('নতুন কাজ')) {
      final parts = text.split(RegExp(r'\s+'));
      String vehicle = 'Corolla';
      for (final p in parts) {
        if (!['job', 'new', 'কাজ', 'নতুন'].contains(p.toLowerCase())) {
          vehicle = p;
          break;
        }
      }
      return ParsedCommand(
        type: CommandType.newJob,
        customerOrItem: 'Walk-in Client',
        description: 'Repair Job for $vehicle',
        rawText: text,
      );
    }

    // 5. Due or Payment Command (via parseDraft)
    final draft = parseDraft(text);
    if (draft != null && (draft.type == CommandType.due || draft.type == CommandType.pay)) {
      final defaultAmount = draft.type == CommandType.pay ? 50.0 : 50.0;
      final finalAmount = (draft.amount != null && draft.amount! > 0)
          ? draft.amount!
          : defaultAmount;
      final customer = draft.query.isNotEmpty ? draft.query : 'Customer';

      return ParsedCommand(
        type: draft.type,
        customerOrItem: customer,
        amount: finalAmount,
        description: draft.type == CommandType.pay
            ? 'Payment collected from $customer'
            : 'Due balance recorded for $customer',
        rawText: text,
      );
    }

    // 6. Fallback: Search for numbers and customer names ONLY if NOT starting with command prefixes
    if (!lower.startsWith('in') &&
        !lower.startsWith('ex') &&
        !lower.startsWith('out') &&
        !lower.startsWith('exp')) {
      final numberMatch = RegExp(r'[0-9]+(\.[0-9]+)?').firstMatch(text);
      if (numberMatch != null) {
        final amt = double.tryParse(numberMatch.group(0)!) ?? 20.0;
        final cleanedName = text.replaceAll(numberMatch.group(0)!, '').trim();
        if (cleanedName.isNotEmpty) {
          return ParsedCommand(
            type: CommandType.due,
            customerOrItem: cleanedName,
            amount: amt,
            description: 'Due recorded for $cleanedName',
            rawText: text,
          );
        }
      }
    }

    return ParsedCommand(
      type: CommandType.unknown,
      description: text,
      rawText: text,
    );
  }
}
