@echo off
echo ========================================
echo Building Library One Release APK
echo ========================================
echo.

echo [1/4] Cleaning previous builds...
flutter clean

echo.
echo [2/4] Getting dependencies...
flutter pub get

echo.
echo [3/4] Building release APK...
echo This may take 10-15 minutes, please be patient...
flutter build apk --release --verbose

echo.
echo [4/4] Checking build result...
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo ✅ Build successful!
    copy "build\app\outputs\flutter-apk\app-release.apk" "Library_One_v1.0.0.apk"
    echo ✅ APK created: Library_One_v1.0.0.apk
    dir "Library_One_v1.0.0.apk"
) else (
    echo ❌ Build failed or APK not found
    echo Check the build output above for errors
)

echo.
echo ========================================
echo Build process completed!
echo ========================================
pause