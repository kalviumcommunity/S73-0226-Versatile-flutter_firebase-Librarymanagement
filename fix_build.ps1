# Flutter Build Fix Script
# This script cleans the build cache and rebuilds the project

Write-Host "🧹 Cleaning Flutter build cache..." -ForegroundColor Yellow
flutter clean

Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "🔨 Building project..." -ForegroundColor Yellow
flutter build apk --debug

Write-Host "✅ Build fix complete! Now run: flutter run -d 10BCBF1272000H7" -ForegroundColor Green