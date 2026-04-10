# Google Maps Setup Instructions

## Required: Google Maps API Key

To use the map-based location picker and ensure proper maps integration, you need to set up a Google Maps API key.

### Step 1: Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
   - Places API (optional, for better address suggestions)

4. Create credentials (API Key)
5. Restrict the API key to your app (recommended for security)

### Step 2: Configure Android

Add your API key to `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:label="library_management_app"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
    
    <!-- Add this meta-data tag -->
    <meta-data android:name="com.google.android.geo.API_KEY"
               android:value="YOUR_API_KEY_HERE"/>
    
    <activity
        android:name=".MainActivity"
        ...>
    </activity>
</application>
```

### Step 3: Configure iOS

Add your API key to `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Step 4: Update iOS Info.plist

Add location permissions to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show nearby libraries and help you navigate to them.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to show nearby libraries and help you navigate to them.</string>
```

### Step 5: Update Android Permissions

Add location permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

## Alternative: Use Without Google Maps

If you don't want to set up Google Maps API key, the app will still work with:
- Text-based address input with geocoding
- Distance-based sorting (using device GPS)
- Maps integration (opening native maps apps)

Only the map-based location picker will be unavailable without the API key.

## Testing

After setup:
1. Run `flutter clean && flutter pub get`
2. Test on physical device (location services don't work well in emulator)
3. Grant location permissions when prompted
4. Test address input with map picker
5. Test "Locate Library" button in library details

## Free Usage Limits

Google Maps provides generous free tiers:
- Maps SDK: 28,000 map loads per month
- Geocoding API: 40,000 requests per month
- Places API: 17,000 requests per month

This should be sufficient for most library management apps.