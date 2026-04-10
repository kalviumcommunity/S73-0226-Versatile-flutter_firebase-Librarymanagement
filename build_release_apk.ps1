# Build Release APK Script for Library One
Write-Host "Building Library One Release APK..." -ForegroundColor Green

# Build the release APK
Write-Host "Starting Flutter build..." -ForegroundColor Yellow
flutter build apk --release --verbose

# Check if build was successful
if (Test-Path "build/app/outputs/flutter-apk/app-release.apk") {
    Write-Host "Build successful! Renaming APK..." -ForegroundColor Green
    
    # Copy and rename the APK
    Copy-Item "build/app/outputs/flutter-apk/app-release.apk" "Library_One_v1.0.0.apk"
    
    Write-Host "APK created successfully: Library_One_v1.0.0.apk" -ForegroundColor Green
    Write-Host "File size: $((Get-Item 'Library_One_v1.0.0.apk').Length / 1MB) MB" -ForegroundColor Cyan
} else {
    Write-Host "Build failed or APK not found!" -ForegroundColor Red
    Write-Host "Checking for debug APK..." -ForegroundColor Yellow
    
    if (Test-Path "build/app/outputs/flutter-apk/app-debug.apk") {
        Write-Host "Debug APK found, copying as fallback..." -ForegroundColor Yellow
        Copy-Item "build/app/outputs/flutter-apk/app-debug.apk" "Library_One_Debug_v1.0.0.apk"
        Write-Host "Debug APK created: Library_One_Debug_v1.0.0.apk" -ForegroundColor Yellow
    }
}

Write-Host "Build process completed!" -ForegroundColor Green