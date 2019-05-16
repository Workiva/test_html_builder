@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';

void main() {
  test('custom HTML passes', () {
    expect(querySelector('h2').text, 'CUSTOM');
  });
}