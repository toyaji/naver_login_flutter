# Manual Configuration Setup

If you prefer to configure your native projects manually instead of using the CLI (`dart run naver_login_flutter:configure`), you must follow our secure secret management approach. **Do not hardcode your client secret directly into public configuration files.**

## Android Manual Setup

1. Create or open `android/local.properties` and add your secret:
```properties
naver.client_secret=[YOUR_CLIENT_SECRET]
```

2. In `android/app/build.gradle` (or `build.gradle.kts`), load this property and inject it into Android resources:
```gradle
// For build.gradle.kts:
import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
val naverClientSecret = localProperties.getProperty("naver.client_secret") ?: ""

android {
    buildFeatures {
        resValues = true // required on AGP 9+, where resValue is off by default
    }
    defaultConfig {
        resValue("string", "client_secret", naverClientSecret.toString())
    }
}
```

3. Update `android/app/src/main/AndroidManifest.xml` with the public keys and the injected secret reference:
```xml
<application>
    <meta-data
        android:name="com.naver.sdk.clientId"
        android:value="[YOUR_CLIENT_ID]" />
    <meta-data
        android:name="com.naver.sdk.clientSecret"
        android:value="@string/client_secret" />
    <meta-data
        android:name="com.naver.sdk.clientName"
        android:value="[YOUR_CLIENT_NAME]" />
</application>
```

## iOS Manual Setup

1. Create a file `ios/Flutter/NaverKeys.xcconfig` and add:
```xcconfig
NAVER_CLIENT_SECRET = [YOUR_CLIENT_SECRET]
```

2. Add `Flutter/NaverKeys.xcconfig` to your `ios/.gitignore` to prevent leaking your secret.

3. Include it in both `ios/Flutter/Debug.xcconfig` and `Release.xcconfig`:
```xcconfig
#include? "NaverKeys.xcconfig"
```

4. Add the following keys to your `ios/Runner/Info.plist`:
```xml
<key>NidClientID</key>
<string>[YOUR_CLIENT_ID]</string>
<key>NidClientSecret</key>
<string>$(NAVER_CLIENT_SECRET)</string>
<key>NidAppName</key>
<string>[YOUR_CLIENT_NAME]</string>
<key>NidUrlScheme</key>
<string>[YOUR_URL_SCHEME]</string>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>naversearchapp</string>
    <string>naversearchthirdlogin</string>
</array>
```

## Next Steps
Once your manual setup is complete, don't forget to [Update your AppDelegate](../README.md#4-update-your-appdelegate-ios-only).
