@TestOn('browser')
import 'dart:js';

import 'package:test/test.dart';

void main() {
  test('js is loaded', () {
    expect(context['custom'], isTrue);
  });
}
