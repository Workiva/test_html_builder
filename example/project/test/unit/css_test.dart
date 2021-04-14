@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';

void main() {
  test('css is loaded', () {
    expect(document.head.querySelector('link'), isNotNull);
  });
}
