// @dart=2.7
// ^ Do not remove until migrated to null safety. More info at https://wiki.atl.workiva.net/pages/viewpage.action?pageId=189370832
@TestOn('browser')
import 'dart:js';

import 'package:test/test.dart';

void main() {
  test('js is loaded', () {
    expect(context['custom'], isTrue);
  });
}
