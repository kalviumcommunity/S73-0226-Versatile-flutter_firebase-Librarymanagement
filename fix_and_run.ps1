# Complete Fix and Run Script for Flutter Build Issues
# This script will clean everything and rebuild from scratch

Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Flutter Build Cache Fix & Run Script" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean build artifacts
Write-Host "🧹 Step 1: Cleaning build artifacts..." -ForegroundColor Yellow
if (Test-Path "build") {
    Remove-Item -Recurse -Force build
    Write-Host "   ✓ Removed build folder" -ForegroundColor Green
}
if (Test-Path ".dart_tool") {
    Remove-Item -Recurse -Force .dart_tool
    Write-Host "   ✓ Removed .dart_tool folder" -ForegroundColor Green
}

# Step 2: Flutter clean
Write-Host ""
Write-Host "🧹 Step 2: Running flutter clean..." -ForegroundColor Yellow
flutter clean
Write-Host "   ✓ Flutter clean complete" -ForegroundColor Green

# Step 3: Get dependencies
Write-Host ""
Write-Host "📦 Step 3: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "   ✓ Dependencies installed" -ForegroundColor Green

# Step 4: Analyze for errors
Write-Host ""
Write-Host "🔍 Step 4: Analyzing code..." -ForegroundColor Yellow
flutter analyze --no-fatal-infos
Write-Host "   ✓ Analysis complete" -ForegroundColor Green

# Step 5: Run the app
Write-Host ""
Write-Host "🚀 Step 5: Running the app..." -ForegroundColor Yellow
Write-Host ""
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Starting Flutter App on Device 10BCBF1272000H7" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

flutter run -d 10BCBF1272000H7