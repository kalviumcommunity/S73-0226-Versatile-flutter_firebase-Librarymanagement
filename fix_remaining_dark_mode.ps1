# Fix Remaining Dark Mode Issues
# Fixes: Stock Management, Borrow/Return, Admin Profile Library tab

Write-Host "=== Fixing Remaining Dark Mode Issues ===" -ForegroundColor Cyan
Write-Host ""

$files = @(
    "lib/features/books/screens/stock_management_screen.dart",
    "lib/features/borrow/screens/librarian_borrow_return_screen.dart",
    "lib/features/admin/screens/admin_profile_screen.dart"
)

$replacements = @{
    # Background colors
    'backgroundColor: AppColors\.background' = 'backgroundColor: AppColors.darkBackground'
    'color: AppColors\.background(?![A-Z])' = 'color: AppColors.darkBackground'
    
    # Surface colors
    'AppColors\.surface(?!Variant)' = 'AppColors.darkSurface'
    'AppColors\.surfaceVariant' = 'AppColors.darkSurfaceVariant'
    
    # Text colors
    'color: AppColors\.textPrimary' = 'color: AppColors.darkTextPrimary'
    'AppColors\.textPrimary(?!,)' = 'AppColors.darkTextPrimary'
    'color: AppColors\.textSecondary' = 'color: AppColors.darkTextSecondary'
    'AppColors\.textSecondary(?!,)' = 'AppColors.darkTextSecondary'
    'AppColors\.textTertiary' = 'AppColors.darkTextTertiary'
    
    # Border colors
    'AppColors\.border(?!Radius)' = 'AppColors.darkBorder'
    'AppColors\.divider' = 'AppColors.darkDivider'
    
    # Primary colors
    'color: AppColors\.primary(?!Light|Dark)' = 'color: AppColors.darkPrimary'
    'AppColors\.primary(?!Light|Dark|\.)' = 'AppColors.darkPrimary'
    
    # Status colors
    'AppColors\.error(?!\.)' = 'AppColors.darkError'
    'AppColors\.success(?!\.)' = 'AppColors.darkSuccess'
    'AppColors\.warning(?!\.)' = 'AppColors.darkWarning'
    'AppColors\.info(?!\.)' = 'AppColors.darkInfo'
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
Write-Host "Run: flutter run" -ForegroundColor Yellow
