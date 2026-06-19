import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

Future<bool> configureAndroid({
  required String appName,
  required String clientId,
  required String clientSecret,
  String projectDir = '.',
  Future<bool> Function(String promptMessage)? askUser,
}) async {
  bool success = true;

  // 1. Update local.properties
  final localPropFile = File(
    path.join(projectDir, 'android', 'local.properties'),
  );
  if (localPropFile.existsSync()) {
    String content = localPropFile.readAsStringSync();
    if (content.contains('naver.client_secret=')) {
      content = content.replaceAll(
        RegExp(r'naver\.client_secret=.*'),
        'naver.client_secret=$clientSecret',
      );
    } else {
      content += '\nnaver.client_secret=$clientSecret\n';
    }
    localPropFile.writeAsStringSync(content);
    stdout.writeln('  [OK] Updated android/local.properties');
  } else {
    stdout.writeln(
      '  [WARN] android/local.properties not found. Please ensure you are running this in a Flutter project root.',
    );
    success = false;
  }

  // 2. Update build.gradle or build.gradle.kts
  final buildGradle = File(
    path.join(projectDir, 'android', 'app', 'build.gradle'),
  );
  final buildGradleKts = File(
    path.join(projectDir, 'android', 'app', 'build.gradle.kts'),
  );
  File? targetGradle;

  if (buildGradle.existsSync()) {
    targetGradle = buildGradle;
  } else if (buildGradleKts.existsSync()) {
    targetGradle = buildGradleKts;
  }

  if (targetGradle != null) {
    String gradleContent = targetGradle.readAsStringSync();
    bool isKts = targetGradle.path.endsWith('.kts');

    // Check if properties loader is already there
    if (!gradleContent.contains('naver.client_secret')) {
      final propertiesSnippet =
          isKts
              ? '''
import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val naverClientSecret = localProperties.getProperty("naver.client_secret") ?: ""

'''
              : '''
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def naverClientSecret = localProperties.getProperty('naver.client_secret') ?: ""

''';

      gradleContent = propertiesSnippet + gradleContent;
    }

    // Insert resValue into defaultConfig
    if (!gradleContent.contains('resValue("string", "client_secret"')) {
      final resValueSnippet =
          isKts
              ? '\n        resValue("string", "client_secret", naverClientSecret.toString())'
              : '\n        resValue "string", "client_secret", naverClientSecret';

      gradleContent = gradleContent.replaceFirst(
        RegExp(r'defaultConfig\s*\{'),
        'defaultConfig {$resValueSnippet',
      );
    }

    targetGradle.writeAsStringSync(gradleContent);
    stdout.writeln('  [OK] Updated \${targetGradle.path}');
  } else {
    stdout.writeln(
      '  [WARN] android/app/build.gradle(.kts) not found. Skipping gradle configuration.',
    );
    success = false;
  }

  // 3. Update AndroidManifest.xml safely with xml package
  final manifestFile = File(
    path.join(
      projectDir,
      'android',
      'app',
      'src',
      'main',
      'AndroidManifest.xml',
    ),
  );
  if (manifestFile.existsSync()) {
    try {
      final document = XmlDocument.parse(manifestFile.readAsStringSync());
      final applicationNodes = document.findAllElements('application');

      if (applicationNodes.isEmpty) {
        stdout.writeln(
          '  [WARN] <application> tag not found in AndroidManifest.xml. Skipping manifest configuration.',
        );
        return false;
      }

      final application = applicationNodes.first;

      // Find existing meta-data nodes for Naver SDK anywhere in application
      final existingMetaDatas =
          application.findAllElements('meta-data').where((node) {
            final name = node.getAttribute('android:name');
            return name == 'com.naver.sdk.clientId' ||
                name == 'com.naver.sdk.clientSecret' ||
                name == 'com.naver.sdk.clientName';
          }).toList();

      if (existingMetaDatas.isNotEmpty) {
        if (askUser != null) {
          final overwrite = await askUser(
            'Naver configuration already exists in AndroidManifest.xml. Do you want to overwrite it?',
          );
          if (!overwrite) {
            stdout.writeln(
              '  [SKIP] Left existing AndroidManifest.xml intact.',
            );
            return success;
          }
        }
        // Remove existing to replace them safely
        for (var node in existingMetaDatas) {
          final parent = node.parent;
          if (parent != null) {
            final index = parent.children.indexOf(node);
            if (index > 0 &&
                parent.children[index - 1] is XmlText &&
                parent.children[index - 1].value?.trim().isEmpty == true) {
              parent.children.removeAt(index - 1);
            }
            parent.children.remove(node);
          }
        }

        // Remove existing comments to prevent duplicates
        final existingComments =
            application.descendants
                .where((n) => n is XmlComment && n.value.contains('네이버 로그인 설정'))
                .toList();
        for (var comment in existingComments) {
          final parent = comment.parent;
          if (parent != null) {
            final index = parent.children.indexOf(comment);
            if (index > 0 &&
                parent.children[index - 1] is XmlText &&
                parent.children[index - 1].value?.trim().isEmpty == true) {
              parent.children.removeAt(index - 1);
            }
            parent.children.remove(comment);
          }
        }
      }

      // Add new meta-data elements
      final newElements = [
        XmlElement(XmlName('meta-data'), [
          XmlAttribute(
            XmlName('name', 'android'),
            'com.naver.sdk.clientId',
          ),
          XmlAttribute(XmlName('value', 'android'), clientId),
        ]),
        XmlElement(XmlName('meta-data'), [
          XmlAttribute(
            XmlName('name', 'android'),
            'com.naver.sdk.clientSecret',
          ),
          XmlAttribute(
            XmlName('value', 'android'),
            '@string/client_secret',
          ),
        ]),
        XmlElement(XmlName('meta-data'), [
          XmlAttribute(
            XmlName('name', 'android'),
            'com.naver.sdk.clientName',
          ),
          XmlAttribute(XmlName('value', 'android'), appName),
        ]),
      ];

      // Format them a bit for readability
      int insertIndex = 0;
      application.children.insert(insertIndex++, XmlText('\n        '));
      application.children.insert(insertIndex++, XmlComment(' 네이버 로그인 설정 '));

      for (var element in newElements) {
        application.children.insert(insertIndex++, XmlText('\n        '));
        application.children.insert(insertIndex++, element);
      }
      application.children.insert(insertIndex++, XmlText('\n'));

      manifestFile.writeAsStringSync(document.toXmlString(pretty: false));
      stdout.writeln('  [OK] Updated android/app/src/main/AndroidManifest.xml');
    } catch (e) {
      stdout.writeln(
        '  [ERROR] Failed to parse AndroidManifest.xml safely: \$e',
      );
      success = false;
    }
  } else {
    stdout.writeln(
      '  [WARN] android/app/src/main/AndroidManifest.xml not found. Skipping manifest configuration.',
    );
    success = false;
  }

  return success;
}
