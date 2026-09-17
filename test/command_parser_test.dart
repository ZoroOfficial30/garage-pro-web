import 'package:flutter_test/flutter_test.dart';
import 'package:garage_accounting_pro/features/home/services/command_parser.dart';

void main() {
  group('CommandParser Tests', () {
    test('parses English +due command', () {
      final cmd = CommandParser.parse('+due 50 Karim');
      expect(cmd.type, CommandType.due);
      expect(cmd.amount, 50.0);
      expect(cmd.customerOrItem?.toLowerCase(), 'karim');
    });

    test('parses English -pay command', () {
      final cmd = CommandParser.parse('-pay 200 David');
      expect(cmd.type, CommandType.pay);
      expect(cmd.amount, 200.0);
      expect(cmd.customerOrItem?.toLowerCase(), 'david');
    });

    test('parses stock out command', () {
      final cmd = CommandParser.parse('stockout 2 Castrol');
      expect(cmd.type, CommandType.stockOut);
      expect(cmd.quantity, 2);
      expect(cmd.customerOrItem?.toLowerCase(), 'castrol');
    });

    test('parses expense command', () {
      final cmd = CommandParser.parse('expense 15 lunch');
      expect(cmd.type, CommandType.expense);
      expect(cmd.amount, 15.0);
    });

    test('parses Bangla due command', () {
      final cmd = CommandParser.parse('করিম বাকি ৫০');
      expect(cmd.type, CommandType.due);
      expect(cmd.amount, 50.0);
    });

    test('parses Bangla payment command', () {
      final cmd = CommandParser.parse('ডেভিড জমা ২০০');
      expect(cmd.type, CommandType.pay);
      expect(cmd.amount, 200.0);
    });
    test('parses short command ad Karim 50', () {
      final cmd = CommandParser.parse('ad Karim 50');
      expect(cmd.type, CommandType.due);
      expect(cmd.amount, 50.0);
      expect(cmd.customerOrItem, 'Karim');
    });

    test('parses short command sp Karim 30', () {
      final cmd = CommandParser.parse('sp Karim 30');
      expect(cmd.type, CommandType.pay);
      expect(cmd.amount, 30.0);
      expect(cmd.customerOrItem, 'Karim');
    });

    test('parses +due with name before amount (+due Karim 50)', () {
      final cmd = CommandParser.parse('+due Karim 50');
      expect(cmd.type, CommandType.due);
      expect(cmd.amount, 50.0);
      expect(cmd.customerOrItem, 'Karim');
    });

    test('parses -pay with name before amount (-pay Karim 30)', () {
      final cmd = CommandParser.parse('-pay Karim 30');
      expect(cmd.type, CommandType.pay);
      expect(cmd.amount, 30.0);
      expect(cmd.customerOrItem, 'Karim');
    });

    test('parses ad with masked / formatted phone number (ad 017XXXXXXXX 100)', () {
      final cmd = CommandParser.parse('ad 017XXXXXXXX 100');
      expect(cmd.type, CommandType.due);
      expect(cmd.amount, 100.0);
      expect(cmd.customerOrItem, '017XXXXXXXX');
    });

    test('parses sp with masked / formatted phone number (sp 017XXXXXXXX 50)', () {
      final cmd = CommandParser.parse('sp 017XXXXXXXX 50');
      expect(cmd.type, CommandType.pay);
      expect(cmd.amount, 50.0);
      expect(cmd.customerOrItem, '017XXXXXXXX');
    });

    test('parses amount before customer name (ad 50 Karim & sp 30 Karim)', () {
      final cmd1 = CommandParser.parse('ad 50 Karim');
      expect(cmd1.type, CommandType.due);
      expect(cmd1.amount, 50.0);
      expect(cmd1.customerOrItem, 'Karim');

      final cmd2 = CommandParser.parse('sp 30 Karim');
      expect(cmd2.type, CommandType.pay);
      expect(cmd2.amount, 30.0);
      expect(cmd2.customerOrItem, 'Karim');
    });

    test('parses "in car wash 20" to Income category Car Wash and NEVER to Due', () {
      final cmd = CommandParser.parse('in car wash 20');
      expect(cmd.type, CommandType.income);
      expect(cmd.category, 'Car Wash');
      expect(cmd.amount, 20.0);
      expect(cmd.type, isNot(CommandType.due));
    });

    test('parses "in other 15" to Income category Other Income and NEVER to Due', () {
      final cmd = CommandParser.parse('in other 15');
      expect(cmd.type, CommandType.income);
      expect(cmd.category, 'Other Income');
      expect(cmd.amount, 15.0);
      expect(cmd.type, isNot(CommandType.due));
    });

    test('parses "in service 30" to Income category Service and NEVER to Due', () {
      final cmd = CommandParser.parse('in service 30');
      expect(cmd.type, CommandType.income);
      expect(cmd.category, 'Service');
      expect(cmd.amount, 30.0);
      expect(cmd.type, isNot(CommandType.due));
    });

    test('parses short code "ex food 50" to Expense category Food and NEVER to Due', () {
      final cmd = CommandParser.parse('ex food 50');
      expect(cmd.type, CommandType.expense);
      expect(cmd.category, 'Staff Food & Tea');
      expect(cmd.amount, 50.0);
      expect(cmd.type, isNot(CommandType.due));
    });

    test('parses short code "out tools 30" to Expense category Tools and NEVER to Due', () {
      final cmd = CommandParser.parse('out tools 30');
      expect(cmd.type, CommandType.expense);
      expect(cmd.category, 'Tools & Gear');
      expect(cmd.amount, 30.0);
      expect(cmd.type, isNot(CommandType.due));
    });

    test('parses "ex rent 200" to Expense category Rent', () {
      final cmd = CommandParser.parse('ex rent 200');
      expect(cmd.type, CommandType.expense);
      expect(cmd.category, 'Workshop Rent');
      expect(cmd.amount, 200.0);
      expect(cmd.type, isNot(CommandType.due));
    });

    group('CommandDraft Parser Tests', () {
      test('parses draft with keyword only', () {
        final draft1 = CommandParser.parseDraft('ad ');
        expect(draft1, isNotNull);
        expect(draft1!.type, CommandType.due);
        expect(draft1.query, '');
        expect(draft1.amount, isNull);

        final draft2 = CommandParser.parseDraft('sp');
        expect(draft2, isNotNull);
        expect(draft2!.type, CommandType.pay);

        final draftIn = CommandParser.parseDraft('in');
        expect(draftIn, isNotNull);
        expect(draftIn!.type, CommandType.income);

        final draftEx = CommandParser.parseDraft('ex');
        expect(draftEx, isNotNull);
        expect(draftEx!.type, CommandType.expense);

        final draftOut = CommandParser.parseDraft('out');
        expect(draftOut, isNotNull);
        expect(draftOut!.type, CommandType.expense);
      });

      test('parses draft with keyword and partial query', () {
        final draft = CommandParser.parseDraft('ad Ka');
        expect(draft, isNotNull);
        expect(draft!.type, CommandType.due);
        expect(draft.query, 'Ka');
        expect(draft.amount, isNull);

        final draftEx = CommandParser.parseDraft('ex foo');
        expect(draftEx, isNotNull);
        expect(draftEx!.type, CommandType.expense);
        expect(draftEx.category, 'Staff Food & Tea');
      });

      test('parses draft with keyword, query, and amount', () {
        final draft = CommandParser.parseDraft('ad Karim 50');
        expect(draft, isNotNull);
        expect(draft!.type, CommandType.due);
        expect(draft.query, 'Karim');
        expect(draft.amount, 50.0);

        final draftIn = CommandParser.parseDraft('in car wash 20');
        expect(draftIn, isNotNull);
        expect(draftIn!.type, CommandType.income);
        expect(draftIn.category, 'Car Wash');
        expect(draftIn.amount, 20.0);

        final draftOut = CommandParser.parseDraft('out tools 35');
        expect(draftOut, isNotNull);
        expect(draftOut!.type, CommandType.expense);
        expect(draftOut.category, 'Tools & Gear');
        expect(draftOut.amount, 35.0);
      });

      test('parses draft with phone number', () {
        final draft = CommandParser.parseDraft('sp 01712345678 35');
        expect(draft, isNotNull);
        expect(draft!.type, CommandType.pay);
        expect(draft.query, '01712345678');
        expect(draft.amount, 35.0);
      });

      test('returns null for non-command draft', () {
        expect(CommandParser.parseDraft('stockout 5'), isNull);
        expect(CommandParser.parseDraft('hello world'), isNull);
        expect(CommandParser.parseDraft(''), isNull);
      });
    });
  });
}
