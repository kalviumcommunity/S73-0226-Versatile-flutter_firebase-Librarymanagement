#!/usr/bin/env pwsh

# Flutter App Restart Script
# This script stops the current Flutter app and restarts it with hot restart

Write-Host "🔄 Restarting Flutter App..." -ForegroundColor Cyan
Write-Host ""

# Kill any existing Flutter processes
Write-Host "🛑 Stopping existing Flutter processes..." -ForegroundColor Yellow
try {
    Get-Process -Name "flutter" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "✅ Flutter processes stopped" -ForegroundColor Green
} catch {
    Write-Host "ℹ️ No Flutter processes to stop" -ForegroundColor Gray
}

# Wait a moment
Start-Sleep -Seconds 2

# Start Flutter app
Write-Host "🚀 Starting Flutter app..." -ForegroundColor Cyan
Write-Host ""

# Run flutter with hot restart capability
flutter run --hot

Write-Host ""
Write-Host "✅ App restarted! The dialog fix should now work properly." -ForegroundColor Green
Write-Host ""
Write-Host "📋 Test Steps:" -ForegroundColor Yellow
Write-Host "1. Go to Librarian Reservation Scanner" -ForegroundColor White
Write-Host "2. Scan a reservation QR code" -ForegroundColor White
Write-Host "3. Click 'Issue Books'" -ForegroundColor White
Write-Host "4. Dialog should close immediately after success" -ForegroundColor White