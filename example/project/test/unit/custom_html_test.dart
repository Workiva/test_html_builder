// @dart=2.7
// ^ Do not remove until migrated to null safety. More info at https://wiki.atl.workiva.net/pages/viewpage.action?pageId=189370832
@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';

void main() {
  test('custom ID', () {
    expect(document.body.id, 'custom');
  });
}
