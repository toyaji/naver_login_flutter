// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:naver_login_flutter/naver_login_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isLoggedIn test', (WidgetTester tester) async {
    // Check if the plugin initializes correctly and isLoggedIn returns false initially.
    final bool isLoggedIn = await FlutterNaverLogin.isLoggedIn();
    expect(isLoggedIn, false);
  });

  testWidgets('setLogEnabled does not break subsequent calls', (
    WidgetTester tester,
  ) async {
    await FlutterNaverLogin.setLogEnabled(false);
    await FlutterNaverLogin.setLogEnabled(true);

    // 채널 응답이 정리되지 않으면 이후 호출이 진행 중 요청으로 막힌다.
    expect(await FlutterNaverLogin.isLoggedIn(), false);
  });
}
