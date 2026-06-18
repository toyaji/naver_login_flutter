import 'dart:io';
import 'package:args/args.dart';
import 'src/android_configurator.dart';
import 'src/ios_configurator.dart';

void main(List<String> arguments) async {
  final parser =
      ArgParser()
        ..addOption('app-name', abbr: 'n', help: 'Naver App Name')
        ..addOption('client-id', abbr: 'i', help: 'Naver Client ID')
        ..addOption('client-secret', abbr: 's', help: 'Naver Client Secret')
        ..addOption('url-scheme', abbr: 'u', help: 'iOS URL Scheme')
        ..addFlag(
          'help',
          abbr: 'h',
          negatable: false,
          help: 'Print this usage information.',
        );

  final ArgResults argResults = parser.parse(arguments);

  if (argResults['help'] == true) {
    stdout.writeln('Usage: dart run naver_login_flutter:configure [arguments]');
    stdout.writeln(parser.usage);
    return;
  }

  stdout.writeln(
    '🚀 Starting naver_login_flutter automatic configuration...\n',
  );

  String? appName = argResults['app-name'];
  String? clientId = argResults['client-id'];
  String? clientSecret = argResults['client-secret'];
  String? urlScheme = argResults['url-scheme'];

  if (appName == null) {
    stdout.write('📝 Enter your Naver App Name: ');
    appName = stdin.readLineSync()?.trim();
  }

  if (clientId == null) {
    stdout.write('🔑 Enter your Naver Client ID: ');
    clientId = stdin.readLineSync()?.trim();
  }

  if (clientSecret == null) {
    stdout.write('🔒 Enter your Naver Client Secret (will be stored safely): ');
    clientSecret = stdin.readLineSync()?.trim();
  }

  if (urlScheme == null) {
    stdout.write('🔗 Enter your iOS URL Scheme: ');
    urlScheme = stdin.readLineSync()?.trim();
  }

  if (appName == null ||
      appName.isEmpty ||
      clientId == null ||
      clientId.isEmpty ||
      clientSecret == null ||
      clientSecret.isEmpty ||
      urlScheme == null ||
      urlScheme.isEmpty) {
    stdout.writeln('\n❌ Error: All fields are required. Setup aborted.');
    exit(1);
  }

  stdout.writeln('\n⏳ Configuring Android...');
  final androidSuccess = await configureAndroid(
    appName: appName,
    clientId: clientId,
    clientSecret: clientSecret,
    askUser: askUser,
  );

  stdout.writeln('\n⏳ Configuring iOS...');
  final iosSuccess = await configureIOS(
    appName: appName,
    clientId: clientId,
    clientSecret: clientSecret,
    urlScheme: urlScheme,
    askUser: askUser,
  );

  if (androidSuccess && iosSuccess) {
    stdout.writeln('\n✅ Configuration completed successfully!');
  } else {
    stdout.writeln(
      '\n⚠️ Configuration finished with some warnings. Please check the logs above and manual setup documentation if needed.',
    );
  }
}

Future<bool> askUser(String promptMessage) async {
  while (true) {
    stdout.write('\n⚠️ $promptMessage (y/N): ');
    final response = stdin.readLineSync()?.trim().toLowerCase();
    if (response == 'y' || response == 'yes') {
      return true;
    } else if (response == 'n' ||
        response == 'no' ||
        response == null ||
        response.isEmpty) {
      return false;
    }
  }
}
