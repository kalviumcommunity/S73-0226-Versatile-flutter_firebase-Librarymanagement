# Build Library_One APK with New Icon
Write-Host "========================================" -ForegroundColor Green
Write-Host "Building Library_One APK with New Icon" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "[1/4] Regenerating launcher icons..." -ForegroundColor Yellow
flutter pub run flutter_launcher_icons:main

Write-Host ""
Write-Host "[2/4] Cleaning previous build..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "[3/4] Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "[4/4] Building release APK..." -ForegroundColor Yellow
Write-Host "This may take 5-10 minutes, please be patient..." -ForegroundColor Cyan
flutter build apk --release

Write-Host ""
Write-Host "[Final] Creating Library_One APK..." -ForegroundColor Yellow
if (Test-Path "build\app\outputs\flutter-apk\app-release.apk") {
    Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "Library_One.apk"
    Write-Host "✅ SUCCESS: Library_One.apk created!" -ForegroundColor Green
    Get-Item "Library_One.apk" | Format-Table Name, Length, LastWriteTime
    Write-Host ""
    Write-Host "📱 Your new APK is ready: Library_One.apk" -ForegroundColor Green
    Write-Host "🎨 With your new custom icon" -ForegroundColor Green
    Write-Host "📦 App name: Library One" -ForegroundColor Green
} else {
    Write-Host "❌ Build failed - APK not found" -ForegroundColor Red
    Write-Host "Please check the build output above for errors" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build Process Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green