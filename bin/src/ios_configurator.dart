import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

Future<bool> configureIOS({
  required String appName,
  required String clientId,
  required String clientSecret,
  required String urlScheme,
  String projectDir = '.',
  Future<bool> Function(String promptMessage)? askUser,
}) async {
  bool success = true;

  // 1. Create NaverKeys.xcconfig
  final keysDir = Directory(path.join(projectDir, 'ios', 'Flutter'));
  if (!keysDir.existsSync()) {
    stdout.writeln(
      '  [WARN] ios/Flutter directory not found. Skipping iOS configuration.',
    );
    return false;
  }

  final xcconfigFile = File(
    path.join(projectDir, 'ios', 'Flutter', 'NaverKeys.xcconfig'),
  );
  xcconfigFile.writeAsStringSync('NAVER_CLIENT_SECRET = $clientSecret\n');
  stdout.writeln('  [OK] Created ios/Flutter/NaverKeys.xcconfig');

  // 2. Update .gitignore
  final gitignoreFile = File(path.join(projectDir, 'ios', '.gitignore'));
  if (gitignoreFile.existsSync()) {
    String gitignoreContent = gitignoreFile.readAsStringSync();
    if (!gitignoreContent.contains('Flutter/NaverKeys.xcconfig')) {
      gitignoreFile.writeAsStringSync(
        '$gitignoreContent\n# Secret API Keys\nFlutter/NaverKeys.xcconfig\n',
      );
      stdout.writeln('  [OK] Added NaverKeys.xcconfig to ios/.gitignore');
    }
  }

  // 3. Update Debug.xcconfig & Release.xcconfig
  for (String configName in ['Debug.xcconfig', 'Release.xcconfig']) {
    final configFile = File(
      path.join(projectDir, 'ios', 'Flutter', configName),
    );
    if (configFile.existsSync()) {
      String content = configFile.readAsStringSync();
      if (!content.contains('NaverKeys.xcconfig')) {
        content = '#include? "NaverKeys.xcconfig"\n$content';
        configFile.writeAsStringSync(content);
        stdout.writeln('  [OK] Included NaverKeys.xcconfig in $configName');
      }
    } else {
      stdout.writeln('  [WARN] ios/Flutter/$configName not found.');
      success = false;
    }
  }

  // 4. Update Info.plist safely with xml package
  final plistFile = File(path.join(projectDir, 'ios', 'Runner', 'Info.plist'));
  if (plistFile.existsSync()) {
    try {
      final document = XmlDocument.parse(plistFile.readAsStringSync());
      final dictNodes = document.findAllElements('dict');

      if (dictNodes.isEmpty) {
        stdout.writeln(
          '  [WARN] <dict> tag not found in Info.plist. Skipping manifest configuration.',
        );
        return false;
      }

      final rootDict = dictNodes.first;

      // Check if existing keys are present
      final existingKeys =
          rootDict.children.where((node) {
            if (node is XmlElement && node.name.local == 'key') {
              return [
                'NidClientID',
                'NidClientSecret',
                'NidAppName',
                'NidUrlScheme',
              ].contains(node.innerText);
            }
            return false;
          }).toList();

      if (existingKeys.isNotEmpty) {
        if (askUser != null) {
          final overwrite = await askUser(
            'Naver configuration already exists in Info.plist. Do you want to overwrite it?',
          );
          if (!overwrite) {
            stdout.writeln('  [SKIP] Left existing Info.plist intact.');
            return success;
          }
        }

        // Safely remove existing keys and their corresponding following sibling (which is usually <string>)
        for (var keyNode in existingKeys) {
          var sibling = keyNode.nextElementSibling;
          if (sibling != null && sibling.name.local == 'string') {
            sibling.parent?.children.remove(sibling);
          }
          keyNode.parent?.children.remove(keyNode);
        }
      }

      // Remove trailing whitespace nodes to ensure clean formatting at the end
      while (rootDict.children.isNotEmpty &&
          rootDict.children.last is XmlText &&
          rootDict.children.last.innerText.trim().isEmpty) {
        rootDict.children.removeLast();
      }

      // Append new keys
      rootDict.children.add(XmlText('\n\t'));
      rootDict.children.add(
        XmlElement(XmlName.qualified('key'), [], [XmlText('NidClientID')]),
      );
      rootDict.children.add(XmlText('\n\t'));
      rootDict.children.add(
        XmlElement(XmlName.qualified('string'), [], [XmlText(clientId)]),
      );

      rootDict.children.add(XmlText('\n\t'));
      rootDict.children.add(
        XmlElement(XmlName.qualified('key'), [], [XmlText('NidClientSecret')]),
      );
      rootDict.children.add(XmlText('\n\t'));
      rootDict.children.add(
        XmlElement(XmlName.qualified('string'), [], [
          XmlText('\$(NAVER_CLIENT_SECRET)'),
        ]),
      );

      rootDict.children.add(XmlText('\n\t'));
      rootDict.children.add(
        XmlElement(XmlName.qualified('key'), [], [XmlText('NidAppName')]),
      );
      rootDict.children.add(XmlText('\n\t'));
      rootDict.children.add(
        XmlElement(XmlName.qualified('string'), [], [XmlText(appName)]),
      );

      rootDict.children.add(XmlText('\n\t'));
      rootDict.children.add(
        XmlElement(XmlName.qualified('key'), [], [XmlText('NidUrlScheme')]),
      );
      rootDict.children.add(XmlText('\n\t'));
      rootDict.children.add(
        XmlElement(XmlName.qualified('string'), [], [XmlText(urlScheme)]),
      );
      rootDict.children.add(XmlText('\n'));

      // Check LSApplicationQueriesSchemes
      var queryKey =
          rootDict.children
              .whereType<XmlElement>()
              .where(
                (e) =>
                    e.name.local == 'key' &&
                    e.innerText == 'LSApplicationQueriesSchemes',
              )
              .firstOrNull;
      if (queryKey == null) {
        rootDict.children.add(XmlText('\t'));
        rootDict.children.add(
          XmlElement(XmlName.qualified('key'), [], [
            XmlText('LSApplicationQueriesSchemes'),
          ]),
        );
        rootDict.children.add(XmlText('\n\t'));
        final arrayNode = XmlElement(XmlName.qualified('array'), [], [
          XmlText('\n\t\t'),
          XmlElement(XmlName.qualified('string'), [], [
            XmlText('naversearchapp'),
          ]),
          XmlText('\n\t\t'),
          XmlElement(XmlName.qualified('string'), [], [
            XmlText('naversearchthirdlogin'),
          ]),
          XmlText('\n\t'),
        ]);
        rootDict.children.add(arrayNode);
        rootDict.children.add(XmlText('\n'));
      } else {
        var arraySibling = queryKey.nextElementSibling;
        if (arraySibling != null && arraySibling.name.local == 'array') {
          final existingStrings =
              arraySibling
                  .findAllElements('string')
                  .map((e) => e.innerText)
                  .toSet();
          if (!existingStrings.contains('naversearchapp')) {
            arraySibling.children.add(XmlText('\t\t'));
            arraySibling.children.add(
              XmlElement(XmlName.qualified('string'), [], [
                XmlText('naversearchapp'),
              ]),
            );
            arraySibling.children.add(XmlText('\n\t'));
          }
          if (!existingStrings.contains('naversearchthirdlogin')) {
            arraySibling.children.add(XmlText('\t\t'));
            arraySibling.children.add(
              XmlElement(XmlName.qualified('string'), [], [
                XmlText('naversearchthirdlogin'),
              ]),
            );
            arraySibling.children.add(XmlText('\n\t'));
          }
        }
      }

      // Register the redirect URL scheme in CFBundleURLTypes so iOS routes the
      // OAuth callback (scheme://...) back to the app. Without this the login
      // succeeds in Safari/Naver app but never returns to Flutter.
      var urlTypesKey =
          rootDict.children
              .whereType<XmlElement>()
              .where(
                (e) =>
                    e.name.local == 'key' &&
                    e.innerText == 'CFBundleURLTypes',
              )
              .firstOrNull;

      bool schemeAlreadyRegistered = false;
      if (urlTypesKey != null) {
        final urlTypesArray = urlTypesKey.nextElementSibling;
        if (urlTypesArray != null && urlTypesArray.name.local == 'array') {
          schemeAlreadyRegistered = urlTypesArray
              .findAllElements('string')
              .any((e) => e.innerText == urlScheme);

          if (!schemeAlreadyRegistered) {
            urlTypesArray.children.add(XmlText('\t\t'));
            urlTypesArray.children.add(
              XmlElement(XmlName.qualified('dict'), [], [
                XmlText('\n\t\t\t'),
                XmlElement(XmlName.qualified('key'), [], [
                  XmlText('CFBundleURLSchemes'),
                ]),
                XmlText('\n\t\t\t'),
                XmlElement(XmlName.qualified('array'), [], [
                  XmlText('\n\t\t\t\t'),
                  XmlElement(XmlName.qualified('string'), [], [
                    XmlText(urlScheme),
                  ]),
                  XmlText('\n\t\t\t'),
                ]),
                XmlText('\n\t\t'),
              ]),
            );
            urlTypesArray.children.add(XmlText('\n\t'));
          }
        }
      } else {
        rootDict.children.add(XmlText('\t'));
        rootDict.children.add(
          XmlElement(XmlName.qualified('key'), [], [
            XmlText('CFBundleURLTypes'),
          ]),
        );
        rootDict.children.add(XmlText('\n\t'));
        rootDict.children.add(
          XmlElement(XmlName.qualified('array'), [], [
            XmlText('\n\t\t'),
            XmlElement(XmlName.qualified('dict'), [], [
              XmlText('\n\t\t\t'),
              XmlElement(XmlName.qualified('key'), [], [
                XmlText('CFBundleURLSchemes'),
              ]),
              XmlText('\n\t\t\t'),
              XmlElement(XmlName.qualified('array'), [], [
                XmlText('\n\t\t\t\t'),
                XmlElement(XmlName.qualified('string'), [], [
                  XmlText(urlScheme),
                ]),
                XmlText('\n\t\t\t'),
              ]),
              XmlText('\n\t\t'),
            ]),
            XmlText('\n\t'),
          ]),
        );
        rootDict.children.add(XmlText('\n'));
      }

      plistFile.writeAsStringSync(document.toXmlString(pretty: false));
      stdout.writeln('  [OK] Updated ios/Runner/Info.plist');
    } catch (e) {
      stdout.writeln('  [ERROR] Failed to parse Info.plist safely: \$e');
      success = false;
    }
  } else {
    stdout.writeln(
      '  [WARN] ios/Runner/Info.plist not found. Skipping Info.plist configuration.',
    );
    success = false;
  }

  return success;
}
