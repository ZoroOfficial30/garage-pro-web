import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/localization/app_locale.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isAvailable = false;
  List<stt.LocaleName> _locales = [];

  bool get isInitialized => _isInitialized;
  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;
  List<stt.LocaleName> get locales => _locales;

  /// Initializes the speech recognition engine and checks permissions
  Future<bool> initialize({
    Function(String status)? onStatus,
    Function(dynamic error)? onError,
  }) async {
    if (_isInitialized && _isAvailable) return true;
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          onStatus?.call(status);
        },
        onError: (errorNotification) {
          debugPrint('Speech error: ${errorNotification.errorMsg}');
          onError?.call(errorNotification);
        },
        debugLogging: false,
      );
      if (_isAvailable) {
        try {
          _locales = await _speech.locales();
        } catch (_) {}
      }
      _isInitialized = true;
      return _isAvailable;
    } catch (e) {
      debugPrint('VoiceService initialization failed: $e');
      _isAvailable = false;
      _isInitialized = true;
      return false;
    }
  }

  /// Finds the best matching locale for the given AppLanguage with regional dialect priority
  String getLocaleForLanguage(AppLanguage language) {
    final List<String> preferredCandidates;
    final String fallback;

    switch (language) {
      case AppLanguage.bn:
        preferredCandidates = ['bn_BD', 'bn_IN', 'bn'];
        fallback = 'bn_BD';
        break;
      case AppLanguage.ar:
        preferredCandidates = ['ar_SA', 'ar_AE', 'ar_EG', 'ar_OM', 'ar'];
        fallback = 'ar_SA';
        break;
      case AppLanguage.hi:
        preferredCandidates = ['hi_IN', 'hi'];
        fallback = 'hi_IN';
        break;
      case AppLanguage.ur:
        preferredCandidates = ['ur_PK', 'ur_IN', 'ur'];
        fallback = 'ur_PK';
        break;
      case AppLanguage.en:
        preferredCandidates = ['en_US', 'en_GB', 'en_AU', 'en_CA', 'en_IN', 'en'];
        fallback = 'en_US';
        break;
    }

    if (_locales.isNotEmpty) {
      // 1. Try exact match from preferred candidates in priority order
      for (final candidate in preferredCandidates) {
        for (final loc in _locales) {
          final id = loc.localeId.replaceAll('-', '_').toLowerCase();
          if (id == candidate.toLowerCase()) {
            return loc.localeId;
          }
        }
      }

      // 2. Try prefix match (e.g. starts with 'bn')
      final prefix = preferredCandidates.last.toLowerCase();
      for (final loc in _locales) {
        if (loc.localeId.toLowerCase().startsWith(prefix)) {
          return loc.localeId;
        }
      }
    }

    return fallback;
  }

  /// Normalizes spoken text before passing to the command parser:
  /// - Strips trailing punctuation (. , ? ! ; । |)
  /// - Normalizes spoken numbers in English and Bengali to numeric digits
  /// - Normalizes common command spoken synonyms (e.g. "add due" -> "ad", "বাকি" -> "ad")
  static String normalizeVoiceInput(String raw) {
    if (raw.trim().isEmpty) return '';

    // 1. Strip trailing & leading whitespace and trailing punctuation
    String text = raw.trim().replaceAll(RegExp(r'[\s.,?!;:|।]+$'), '');

    // 2. Normalize spoken command synonyms
    final lower = text.toLowerCase();
    if (lower.startsWith('add due ')) {
      text = 'ad ${text.substring(8).trim()}';
    } else if (lower.startsWith('settle payment ')) {
      text = 'sp ${text.substring(15).trim()}';
    } else if (text.startsWith('বাকি ')) {
      text = 'ad ${text.substring(5).trim()}';
    } else if (text.startsWith('জমা ')) {
      text = 'sp ${text.substring(4).trim()}';
    }

    // 3. Multi-word compound number phrases (replace larger phrases first)
    const Map<String, String> compoundPhrases = {
      'ten thousand': '10000',
      'five thousand': '5000',
      'two thousand': '2000',
      'one thousand': '1000',
      'five hundred': '500',
      'four hundred': '400',
      'three hundred': '300',
      'two hundred': '200',
      'one hundred': '100',
      'twenty five': '25',
      'twenty one': '21',
      'thirty five': '35',
      'forty five': '45',
      'fifty five': '55',
      'দশ হাজার': '10000',
      'পাঁচ হাজার': '5000',
      'দুই হাজার': '2000',
      'এক হাজার': '1000',
      'পাঁচশো': '500',
      'চারশো': '400',
      'তিনশো': '300',
      'দুইশো': '200',
      'দুশো': '200',
      'একশো': '100',
      'একশত': '100',
    };

    for (final entry in compoundPhrases.entries) {
      final pattern = RegExp('(^|\\s)${RegExp.escape(entry.key)}(?=\\s|\$)', caseSensitive: false);
      text = text.replaceAllMapped(pattern, (m) => '${m[1]}${entry.value}');
    }

    // 4. Single-word spoken numbers in English & Bengali
    const Map<String, String> singleWordNumbers = {
      'zero': '0',
      'one': '1',
      'two': '2',
      'three': '3',
      'four': '4',
      'five': '5',
      'six': '6',
      'seven': '7',
      'eight': '8',
      'nine': '9',
      'ten': '10',
      'eleven': '11',
      'twelve': '12',
      'thirteen': '13',
      'fourteen': '14',
      'fifteen': '15',
      'sixteen': '16',
      'seventeen': '17',
      'eighteen': '18',
      'nineteen': '19',
      'twenty': '20',
      'thirty': '30',
      'forty': '40',
      'fifty': '50',
      'sixty': '60',
      'seventy': '70',
      'eighty': '80',
      'ninety': '90',
      'hundred': '100',
      'thousand': '1000',
      // Bengali numbers
      'শূন্য': '0',
      'এক': '1',
      'দুই': '2',
      'তিন': '3',
      'চার': '4',
      'পাঁচ': '5',
      'ছয়': '6',
      'ছয়': '6',
      'সাত': '7',
      'আট': '8',
      'নয়': '9',
      'নয়': '9',
      'দশ': '10',
      'এগারো': '11',
      'বারো': '12',
      'তেরো': '13',
      'চৌদ্দ': '14',
      'পনেরো': '15',
      'ষোলো': '16',
      'সতেরো': '17',
      'আঠারো': '18',
      'উনিশ': '19',
      'বিশ': '20',
      'কুড়ি': '20',
      'কুড়ি': '20',
      'ত্রিশ': '30',
      'তিরিশ': '30',
      'চল্লিশ': '40',
      'পঞ্চাশ': '50',
      'ষাট': '60',
      'সত্তর': '70',
      'আশি': '80',
      'নব্বই': '90',
      'একশো': '100',
      'একশত': '100',
      'দুইশো': '200',
      'দুশো': '200',
      'তিনশো': '300',
      'চারশো': '400',
      'পাঁচশো': '500',
      'শত': '100',
      'শো': '100',
      'হাজার': '1000',
    };

    final tokens = text.split(RegExp(r'\s+'));
    final normalizedTokens = <String>[];

    for (final rawToken in tokens) {
      final cleanToken = rawToken.replaceAll(RegExp(r'[\s.,?!;:|।]+$'), '');
      if (cleanToken.isEmpty) continue;

      final lowerToken = cleanToken.toLowerCase();
      if (singleWordNumbers.containsKey(lowerToken)) {
        normalizedTokens.add(singleWordNumbers[lowerToken]!);
      } else if (singleWordNumbers.containsKey(cleanToken)) {
        normalizedTokens.add(singleWordNumbers[cleanToken]!);
      } else {
        normalizedTokens.add(cleanToken);
      }
    }

    return normalizedTokens.join(' ').trim();
  }

  /// Starts listening to microphone and transcribing speech in real-time
  Future<bool> startListening({
    required Function(String text, bool isFinal) onResult,
    required AppLanguage language,
    Function(double level)? onSoundLevelChange,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    if (!_isAvailable) return false;

    final targetLocale = getLocaleForLanguage(language);

    try {
      await _speech.listen(
        onResult: (result) {
          final normalized = normalizeVoiceInput(result.recognizedWords);
          onResult(normalized, result.finalResult);
        },
        onSoundLevelChange: onSoundLevelChange,
        listenOptions: stt.SpeechListenOptions(
          localeId: targetLocale,
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('startListening failed: $e');
      return false;
    }
  }

  /// Stops listening and commits final speech
  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}
  }

  /// Cancels active speech recognition session
  Future<void> cancelListening() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (_) {}
  }
}
