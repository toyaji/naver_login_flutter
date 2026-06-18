import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import '../bin/src/android_configurator.dart';
import '../bin/src/ios_configurator.dart';

void main() {
  group('Configurator Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('naver_login_test');

      // Setup fake Android structure
      final androidAppSrcMain = Directory(
        path.join(tempDir.path, 'android', 'app', 'src', 'main'),
      )..createSync(recursive: true);
      File(
        path.join(
          androidAppSrcMain.parent.parent.parent.path,
          'local.properties',
        ),
      ).writeAsStringSync('sdk.dir=fake\n');
      File(
        path.join(androidAppSrcMain.parent.parent.path, 'build.gradle.kts'),
      ).writeAsStringSync('''
plugins {
    id("com.android.application")
}
android {
    defaultConfig {
        applicationId = "com.example.test"
    }
}
''');
      File(
        path.join(androidAppSrcMain.path, 'AndroidManifest.xml'),
      ).writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="test_app"
        android:icon="@mipmap/ic_launcher">
    </application>
</manifest>
''');

      // Setup fake iOS structure
      final iosFlutter = Directory(path.join(tempDir.path, 'ios', 'Flutter'))
        ..createSync(recursive: true);
      final iosRunner = Directory(path.join(tempDir.path, 'ios', 'Runner'))
        ..createSync(recursive: true);

      File(
        path.join(iosFlutter.path, 'Debug.xcconfig'),
      ).writeAsStringSync('#include "Generated.xcconfig"\n');
      File(
        path.join(iosFlutter.path, 'Release.xcconfig'),
      ).writeAsStringSync('#include "Generated.xcconfig"\n');
      File(
        path.join(iosFlutter.parent.path, '.gitignore'),
      ).writeAsStringSync('build/\n');

      File(path.join(iosRunner.path, 'Info.plist')).writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>test_app</string>
</dict>
</plist>
''');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Android Configurator handles clean injection properly', () async {
      final success = await configureAndroid(
        appName: 'TestApp',
        clientId: 'test_client_id',
        clientSecret: 'test_client_secret',
        projectDir: tempDir.path,
      );

      expect(success, isTrue);
      final manifest =
          File(
            path.join(
              tempDir.path,
              'android',
              'app',
              'src',
              'main',
              'AndroidManifest.xml',
            ),
          ).readAsStringSync();
      expect(manifest, contains('android:value="test_client_id"'));
      expect(manifest, contains('android:value="@string/client_secret"'));
    });

    test('Android Configurator respects user skipping overwrite', () async {
      // Inject dummy first
      final manifestFile = File(
        path.join(
          tempDir.path,
          'android',
          'app',
          'src',
          'main',
          'AndroidManifest.xml',
        ),
      );
      manifestFile.writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <meta-data android:name="com.naver.sdk.clientId" android:value="OLD_ID" />
    </application>
</manifest>
''');

      final success = await configureAndroid(
        appName: 'TestApp',
        clientId: 'NEW_ID',
        clientSecret: 'NEW_SECRET',
        projectDir: tempDir.path,
        askUser: (msg) async => false, // User declines
      );

      expect(success, isTrue);
      final manifest = manifestFile.readAsStringSync();
      expect(manifest, contains('OLD_ID')); // Unchanged
      expect(manifest, isNot(contains('NEW_ID')));
    });

    test('iOS Configurator respects user skipping overwrite', () async {
      final plistFile = File(
        path.join(tempDir.path, 'ios', 'Runner', 'Info.plist'),
      );
      plistFile.writeAsStringSync('''
<plist version="1.0">
<dict>
	<key>NidClientID</key>
	<string>OLD_ID</string>
</dict>
</plist>
''');

      final success = await configureIOS(
        appName: 'TestApp',
        clientId: 'NEW_ID',
        clientSecret: 'test_client_secret',
        urlScheme: 'testscheme',
        projectDir: tempDir.path,
        askUser: (msg) async => false, // User declines
      );

      expect(success, isTrue);
      final plist = plistFile.readAsStringSync();
      expect(plist, contains('OLD_ID')); // Unchanged
      expect(plist, isNot(contains('NEW_ID')));
    });

    test('iOS Configurator gracefully handles weirdly formatted XML', () async {
      final plistFile = File(
        path.join(tempDir.path, 'ios', 'Runner', 'Info.plist'),
      );
      plistFile.writeAsStringSync('''
<plist version="1.0">
  <dict>
  <key>CFBundleName</key>
  <string>test_app</string>
  <!-- Weirdly placed comment -->
  </dict>
</plist>
''');

      final success = await configureIOS(
        appName: 'TestApp',
        clientId: 'test_id',
        clientSecret: 'test_client_secret',
        urlScheme: 'testscheme',
        projectDir: tempDir.path,
      );

      expect(success, isTrue);
      final plist = plistFile.readAsStringSync();
      expect(plist, contains('<string>test_id</string>'));
      expect(plist, contains('<!-- Weirdly placed comment -->')); // Preserved
    });
  });
}
