# Final Dark Mode Fix Script
# This script fixes all color references to use dark mode colors

Write-Host "=== Starting Comprehensive Dark Mode Fix ===" -ForegroundColor Cyan
Write-Host ""

$files = @(
    "lib/features/auth/screens/login_screen.dart",
    "lib/features/auth/screens/signup_screen.dart",
    "lib/features/auth/screens/create_library_account_screen.dart",
    "lib/features/auth/screens/forgot_password_screen.dart",
    "lib/features/auth/screens/set_password_screen.dart",
    "lib/features/auth/screens/access_code_prompt_screen.dart",
    "lib/features/borrow/screens/reader_transactions_screen.dart",
    "lib/features/admin/screens/admin_profile_screen.dart"
)

$replacements = @{
    'backgroundColor: AppColors\.background' = 'backgroundColor: AppColors.darkBackground'
    'color: AppColors\.background(?![,\)])' = 'color: AppColors.darkBackground'
    'AppColors\.surface(?!Variant)' = 'AppColors.darkSurface'
    'AppColors\.surfaceVariant' = 'AppColors.darkSurfaceVariant'
    'AppColors\.textPrimary(?!,)' = 'AppColors.darkTextPrimary'
    'AppColors\.textSecondary(?!,)' = 'AppColors.darkTextSecondary'
    'AppColors\.textTertiary' = 'AppColors.darkTextTertiary'
    'AppColors\.border(?!,)' = 'AppColors.darkBorder'
    'color: AppColors\.primary(?!Light|Dark)' = 'color: AppColors.darkPrimary'
    'AppColors\.primary(?!Light|Dark|\.)' = 'AppColors.darkPrimary'
    'AppColors\.error(?!\.)' = 'AppColors.darkError'
    'AppColors\.success(?!\.)' = 'AppColors.darkSuccess'
}

$fixedCount = 0
$errorCount = 0

foreach ($file in $files) {
    if (Test-Path $file) {
        try {
            Write-Host "Processing: $file" -ForegroundColor Yellow
            $content = Get-Content $file -Raw -Encoding UTF8
            
            $originalContent = $content
            foreach ($pattern in $replacements.Keys) {
                $replacement = $replacements[$pattern]
                $content = $content -replace $pattern, $replacement
            }
            
            if ($content -ne $originalContent) {
                $content | Set-Content $file -NoNewline -Encoding UTF8
                Write-Host "  Fixed" -ForegroundColor Green
                $fixedCount++
            } else {
                Write-Host "  No changes needed" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "  Error: $_" -ForegroundColor Red
            $errorCount++
        }
    } else {
        Write-Host "  File not found" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Files fixed: $fixedCount" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "Errors: $errorCount" -ForegroundColor Red
} else {
    Write-Host "Errors: $errorCount" -ForegroundColor Green
}
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: flutter clean"
Write-Host "2. Run: flutter pub get"
Write-Host "3. Run: flutter run"
