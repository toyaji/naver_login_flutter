import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naver_login_flutter/naver_login_flutter_method_channel.dart';
import 'package:naver_login_flutter/interface/types/naver_login_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelFlutterNaverLogin platform;
  late List<MethodCall> log;

  setUp(() {
    platform = MethodChannelFlutterNaverLogin();
    log = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel, (
          MethodCall methodCall,
        ) async {
          log.add(methodCall);

          switch (methodCall.method) {
            case 'logIn':
              return {
                'status': 'loggedIn',
                'accessToken': {
                  'accessToken': 'dummy_access_token',
                  'refreshToken': 'dummy_refresh_token',
                  'expiresAt': '2030-12-31T00:00:00.000',
                  'tokenType': 'bearer',
                },
                'account': {'id': 'user123', 'name': 'Test User'},
              };
            case 'logOut':
            case 'logoutAndDeleteToken':
              return null;
            case 'getCurrentAccount':
              return {
                'account': {'id': 'user123', 'name': 'Test User'},
              };
            case 'isLoggedIn':
              return {'status': 'loggedin'};
            case 'getCurrentAccessToken':
              return {
                'accessToken': {
                  'accessToken': 'dummy_access_token',
                  'refreshToken': 'dummy_refresh_token',
                  'expiresAt': '2030-12-31T00:00:00.000',
                  'tokenType': 'bearer',
                },
              };
            case 'refreshAccessTokenWithRefreshToken':
              return {
                'accessToken': 'new_access_token',
                'refreshToken': 'new_refresh_token',
                'expiresAt': '2030-12-31T00:00:00.000',
                'tokenType': 'bearer',
              };
            default:
              return null;
          }
        });
  });

  tearDown(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel, null);
  });

  test('logIn', () async {
    final result = await platform.logIn();
    expect(log, <Matcher>[isMethodCall('logIn', arguments: null)]);
    expect(result.status, NaverLoginStatus.loggedIn);
    expect(result.accessToken?.accessToken, 'dummy_access_token');
    expect(result.account?.id, 'user123');
  });

  test('logOut', () async {
    final result = await platform.logOut();
    expect(log, <Matcher>[isMethodCall('logOut', arguments: null)]);
    expect(result.status, NaverLoginStatus.loggedOut);
  });

  test('logOutAndDeleteToken', () async {
    final result = await platform.logOutAndDeleteToken();
    expect(log, <Matcher>[
      isMethodCall('logoutAndDeleteToken', arguments: null),
    ]);
    expect(result.status, NaverLoginStatus.loggedOut);
  });

  test('getCurrentAccount', () async {
    final result = await platform.getCurrentAccount();
    expect(log, <Matcher>[isMethodCall('getCurrentAccount', arguments: null)]);
    expect(result.id, 'user123');
  });

  test('isLoggedIn', () async {
    final result = await platform.isLoggedIn();
    expect(log, <Matcher>[isMethodCall('isLoggedIn', arguments: null)]);
    expect(result, true);
  });

  test('isLoggedIn returns false when logged out', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform.methodChannel, (
          MethodCall methodCall,
        ) async {
          log.add(methodCall);
          return {'status': 'loggedout'};
        });

    final result = await platform.isLoggedIn();
    expect(log, <Matcher>[isMethodCall('isLoggedIn', arguments: null)]);
    expect(result, false);
  });

  test('setLogEnabled', () async {
    await platform.setLogEnabled(false);
    expect(log, <Matcher>[
      isMethodCall('setLogEnabled', arguments: {'enabled': false}),
    ]);
  });

  test('getCurrentAccessToken', () async {
    final result = await platform.getCurrentAccessToken();
    expect(log, <Matcher>[
      isMethodCall('getCurrentAccessToken', arguments: null),
    ]);
    expect(result.accessToken, 'dummy_access_token');
  });

  test('refreshAccessTokenWithRefreshToken', () async {
    final result = await platform.refreshAccessTokenWithRefreshToken();
    expect(log, <Matcher>[
      isMethodCall('refreshAccessTokenWithRefreshToken', arguments: null),
    ]);
    expect(result.accessToken, 'new_access_token');
  });

  group('PlatformException handling', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform.methodChannel, (
            MethodCall methodCall,
          ) async {
            throw PlatformException(code: 'ERROR', message: 'Test Error');
          });
    });

    test('logIn handles exception', () async {
      final result = await platform.logIn();
      expect(result.status, NaverLoginStatus.error);
      expect(result.errorMessage, 'Test Error');
    });

    test('logOut handles exception', () async {
      final result = await platform.logOut();
      expect(result.status, NaverLoginStatus.error);
      expect(result.errorMessage, 'Test Error');
    });

    test('logOutAndDeleteToken handles exception', () async {
      final result = await platform.logOutAndDeleteToken();
      expect(result.status, NaverLoginStatus.error);
      expect(result.errorMessage, 'Test Error');
    });

    test('getCurrentAccount handles exception', () async {
      final result = await platform.getCurrentAccount();
      expect(result.id, isNull);
    });

    test('getCurrentAccessToken handles exception', () async {
      final result = await platform.getCurrentAccessToken();
      expect(result.accessToken, isEmpty);
    });

    test('refreshAccessTokenWithRefreshToken handles exception', () async {
      final result = await platform.refreshAccessTokenWithRefreshToken();
      expect(result.accessToken, isEmpty);
    });
  });
}
