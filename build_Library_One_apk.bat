@echo off
echo ========================================
echo Building Library_One APK with New Icon
echo ========================================
echo.

echo [1/4] Regenerating launcher icons...
flutter pub run flutter_launcher_icons:main

echo.
echo [2/4] Cleaning previous build...
flutter clean

echo.
echo [3/4] Getting dependencies...
flutter pub get

echo.
echo [4/4] Building release APK...
echo This may take 5-10 minutes, please be patient...
flutter build apk --release --verbose

echo.
echo [Final] Creating Library_One APK...
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy "build\app\outputs\flutter-apk\app-release.apk" "Library_One.apk"
    echo ✅ SUCCESS: Library_One.apk created!
    dir "Library_One.apk"
    echo.
    echo 📱 Your new APK is ready: Library_One.apk
    echo 🎨 With your new custom icon
    echo 📦 App name: Library One
) else (
    echo ❌ Build failed - APK not found
    echo Please check the build output above for errors
)

echo.
echo ========================================
echo Build Process Complete!
echo ========================================
pause