# Script to Check APK Icon and App Name
Write-Host "=== Library One APK Icon Checker ===" -ForegroundColor Green
Write-Host ""

# Check if APK exists
if (Test-Path "Library_One_v1.0.0.apk") {
    Write-Host "✅ APK Found: Library_One_v1.0.0.apk" -ForegroundColor Green
    
    # Get APK size
    $apkSize = (Get-Item "Library_One_v1.0.0.apk").Length / 1MB
    Write-Host "📦 APK Size: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "🔍 Icon Locations in Project:" -ForegroundColor Yellow
    Write-Host "   Source Icon: assets/icon/app_icon.png"
    Write-Host "   Generated Icons:"
    Write-Host "   - android/app/src/main/res/mipmap-hdpi/launcher_icon.png (72x72)"
    Write-Host "   - android/app/src/main/res/mipmap-mdpi/launcher_icon.png (48x48)"
    Write-Host "   - android/app/src/main/res/mipmap-xhdpi/launcher_icon.png (96x96)"
    Write-Host "   - android/app/src/main/res/mipmap-xxhdpi/launcher_icon.png (144x144)"
    Write-Host "   - android/app/src/main/res/mipmap-xxxhdpi/launcher_icon.png (192x192)"
    
    Write-Host ""
    Write-Host "📱 To Check Icon on Device:" -ForegroundColor Yellow
    Write-Host "   1. Install the APK on an Android device"
    Write-Host "   2. Look for 'Library One' in the app drawer"
    Write-Host "   3. The icon should appear as a library-themed icon"
    
    Write-Host ""
    Write-Host "🛠️ Alternative Methods:" -ForegroundColor Yellow
    Write-Host "   1. Use Android Studio APK Analyzer"
    Write-Host "   2. Extract APK (rename to .zip and extract)"
    
} else {
    Write-Host "❌ APK not found: Library_One_v1.0.0.apk" -ForegroundColor Red
    Write-Host "Please build the APK first using: flutter build apk --release" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Icon Check Complete ===" -ForegroundColor Green