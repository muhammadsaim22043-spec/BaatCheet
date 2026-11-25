// The full app can't be pumped in a plain widget test because it needs
// Firebase, Supabase and Isar initialised, so these cover the pure logic.

import 'package:flutter_test/flutter_test.dart';

import 'package:whatsapp_clone/core/utils/date_parser.dart';
import 'package:whatsapp_clone/core/utils/string_sanitizer.dart';

void main() {
  group('StringSanitizer.normalizePakistaniPhone', () {
    test('converts every accepted format to E.164', () {
      for (final input in [
        '+923001234567',
        '923001234567',
        '03001234567',
        '3001234567',
        '0300 123-4567',
      ]) {
        expect(StringSanitizer.normalizePakistaniPhone(input), '+923001234567',
            reason: input);
      }
    });

    test('rejects invalid numbers', () {
      expect(StringSanitizer.normalizePakistaniPhone('12345'), isNull);
      expect(StringSanitizer.normalizePakistaniPhone('+14155550123'), isNull);
      expect(StringSanitizer.normalizePakistaniPhone(''), isNull);
    });
  });

  test('StringSanitizer.initial handles empty names', () {
    expect(StringSanitizer.initial('ali'), 'A');
    expect(StringSanitizer.initial('  '), '?');
  });

  test('StringSanitizer.sanitize strips tags and enforces max length', () {
    expect(StringSanitizer.sanitize('  <b>hi</b>  '), 'hi');
    expect(StringSanitizer.sanitize('abcdef', maxLength: 3), 'abc');
  });

  test('DateParser round-trips through UTC', () {
    final now = DateTime(2026, 1, 2, 3, 4, 5);
    final stored = DateParser.toFirestore(now);
    expect(stored.endsWith('Z'), isTrue);
    expect(DateParser.fromFirestore(stored), now);
  });
}
