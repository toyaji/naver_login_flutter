#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint naver_login_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'naver_login_flutter'
  s.version          = '3.0.4'
  s.summary          = 'A Flutter plugin for using the native Naver Login SDKs on Android and iOS.'
  s.description      = <<-DESC
A Flutter plugin for using the native Naver Login SDKs on Android and iOS.
Provides Swift Package Manager (SPM) integration for iOS and Gradle integration for Android.
                       DESC
  s.homepage         = 'https://github.com/toyaji/naver_login_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'toyaji' => 'toyaji83@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'naver_login_flutter/Sources/naver_login_flutter/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

  # 네이버 로그인 라이브러리
  s.dependency 'NidThirdPartyLogin', '~> 5.1.0'

  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'naver_login_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
