@echo off
echo ========================================
echo Library One - Update Icon and Build APK
echo ========================================
echo.

echo [1/5] Checking for new icon...
if exist "assets\icon\app_icon.png" (
    echo ✅ Icon found: assets\icon\app_icon.png
) else (
    echo ❌ Please place your new icon at: assets\icon\app_icon.png
    echo    Requirements: PNG format, 512x512 pixels recommended
    pause
    exit /b 1
)

echo.
echo [2/5] Regenerating launcher icons...
flutter pub run flutter_launcher_icons:main

echo.
echo [3/5] Cleaning previous build...
flutter clean

echo.
echo [4/5] Getting dependencies...
flutter pub get

echo.
echo [5/5] Building new APK with updated icon...
echo This may take 5-10 minutes...
flutter build apk --release

echo.
echo [Final] Creating renamed APK...
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy "build\app\outputs\flutter-apk\app-release.apk" "Library_One_v1.1.0_NewIcon.apk"
    echo ✅ New APK created: Library_One_v1.1.0_NewIcon.apk
    dir "Library_One_v1.1.0_NewIcon.apk"
) else (
    echo ❌ Build failed - check output above
)

echo.
echo ========================================
echo Icon Update and Build Complete!
echo ========================================
pause