@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';

void main() {
  test('custom ID', () {
    expect(document.body.id, 'custom');
  });
}
