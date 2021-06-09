// @dart=2.7
// ^ Do not remove until migrated to null safety. More info at https://wiki.atl.workiva.net/pages/viewpage.action?pageId=189370832
@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';

void main() {
  test('css is loaded', () {
    expect(document.head.querySelector('link'), isNotNull);
  });
}
