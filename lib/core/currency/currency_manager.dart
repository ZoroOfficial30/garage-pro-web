import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

enum CurrencyCode { omr, usd, bdt, inr, aed, eur, gbp }

class CurrencyInfo {
  final CurrencyCode code;
  final String symbol;
  final String englishName;
  final String arabicSymbol;
  final int decimalPlaces;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.englishName,
    required this.arabicSymbol,
    this.decimalPlaces = 2,
  });
}

class CurrencyManager extends ChangeNotifier {
  static const Map<CurrencyCode, CurrencyInfo> currencies = {
    CurrencyCode.omr: CurrencyInfo(
      code: CurrencyCode.omr,
      symbol: 'OMR',
      englishName: 'Omani Rial',
      arabicSymbol: 'ر.ع.',
      decimalPlaces: 3,
    ),
    CurrencyCode.usd: CurrencyInfo(
      code: CurrencyCode.usd,
      symbol: r'$',
      englishName: 'US Dollar',
      arabicSymbol: r'$',
      decimalPlaces: 2,
    ),
    CurrencyCode.bdt: CurrencyInfo(
      code: CurrencyCode.bdt,
      symbol: '৳',
      englishName: 'Bangladeshi Taka',
      arabicSymbol: '৳',
      decimalPlaces: 2,
    ),
    CurrencyCode.inr: CurrencyInfo(
      code: CurrencyCode.inr,
      symbol: '₹',
      englishName: 'Indian Rupee',
      arabicSymbol: '₹',
      decimalPlaces: 2,
    ),
    CurrencyCode.aed: CurrencyInfo(
      code: CurrencyCode.aed,
      symbol: 'AED',
      englishName: 'UAE Dirham',
      arabicSymbol: 'د.إ',
      decimalPlaces: 2,
    ),
    CurrencyCode.eur: CurrencyInfo(
      code: CurrencyCode.eur,
      symbol: '€',
      englishName: 'Euro',
      arabicSymbol: '€',
      decimalPlaces: 2,
    ),
    CurrencyCode.gbp: CurrencyInfo(
      code: CurrencyCode.gbp,
      symbol: '£',
      englishName: 'British Pound',
      arabicSymbol: '£',
      decimalPlaces: 2,
    ),
  };

  CurrencyCode _currentCurrency = CurrencyCode.omr;

  CurrencyCode get currentCurrency => _currentCurrency;
  CurrencyInfo get currentInfo => currencies[_currentCurrency]!;
  String get symbol => currentInfo.symbol;

  void setCurrency(CurrencyCode code) {
    if (_currentCurrency != code) {
      _currentCurrency = code;
      notifyListeners();
    }
  }

  String format(double amount, {bool useArabicSymbol = false}) {
    final info = currentInfo;
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: info.decimalPlaces,
    );
    final formattedNumber = formatter.format(amount).trim();

    if (info.code == CurrencyCode.omr) {
      return useArabicSymbol
          ? '$formattedNumber ${info.arabicSymbol}'
          : '${info.symbol} $formattedNumber';
    } else if (info.code == CurrencyCode.usd ||
        info.code == CurrencyCode.bdt ||
        info.code == CurrencyCode.inr ||
        info.code == CurrencyCode.gbp ||
        info.code == CurrencyCode.eur) {
      return '${info.symbol}$formattedNumber';
    } else {
      return '${info.symbol} $formattedNumber';
    }
  }
}
