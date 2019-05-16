@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';

void main() {
  test('generated HTML passes', () {
    expect(querySelector('h2'), isNull);
  });
}