# PowerShell script to fix all dark mode issues

Write-Host "Fixing all dark mode issues..." -ForegroundColor Cyan

# Fix Login Screen
Write-Host "Fixing login_screen.dart..." -ForegroundColor Yellow
(Get-Content "lib/features/auth/screens/login_screen.dart") -replace 'backgroundColor: AppColors\.background', 'backgroundColor: AppColors.darkBackground' | Set-Content "lib/features/auth/screens/login_screen.dart"
(Get-Content "lib/features/auth/screens/login_screen.dart") -replace 'AppColors\.surfaceVariant', 'AppColors.darkSurfaceVariant' | Set-Content "lib/features/auth/screens/login_screen.dart"
(Get-Content "lib/features/auth/screens/login_screen.dart") -replace 'AppColors\.textSecondary', 'AppColors.darkTextSecondary' | Set-Content "lib/features/auth/screens/login_screen.dart"
(Get-Content "lib/features/auth/screens/login_screen.dart") -replace 'AppColors\.textPrimary', 'AppColors.darkTextPrimary' | Set-Content "lib/features/auth/screens/login_screen.dart"
(Get-Content "lib/features/auth/screens/login_screen.dart") -replace 'AppColors\.surface(?!Variant)', 'AppColors.darkSurface' | Set-Content "lib/features/auth/screens/login_screen.dart"
(Get-Content "lib/features/auth/screens/login_screen.dart") -replace 'AppColors\.primary(?!Light|Dark)', 'AppColors.darkPrimary' | Set-Content "lib/features/auth/screens/login_screen.dart"

# Fix Signup Screen
Write-Host "Fixing signup_screen.dart..." -ForegroundColor Yellow
(Get-Content "lib/features/auth/screens/signup_screen.dart") -replace 'backgroundColor: AppColors\.background', 'backgroundColor: AppColors.darkBackground' | Set-Content "lib/features/auth/screens/signup_screen.dart"
(Get-Content "lib/features/auth/screens/signup_screen.dart") -replace 'AppColors\.surfaceVariant', 'AppColors.darkSurfaceVariant' | Set-Content "lib/features/auth/screens/signup_screen.dart"
(Get-Content "lib/features/auth/screens/signup_screen.dart") -replace 'AppColors\.textSecondary', 'AppColors.darkTextSecondary' | Set-Content "lib/features/auth/screens/signup_screen.dart"
(Get-Content "lib/features/auth/screens/signup_screen.dart") -replace 'AppColors\.textPrimary', 'AppColors.darkTextPrimary' | Set-Content "lib/features/auth/screens/signup_screen.dart"
(Get-Content "lib/features/auth/screens/signup_screen.dart") -replace 'AppColors\.surface(?!Variant)', 'AppColors.darkSurface' | Set-Content "lib/features/auth/screens/signup_screen.dart"
(Get-Content "lib/features/auth/screens/signup_screen.dart") -replace 'AppColors\.primary(?!Light|Dark)', 'AppColors.darkPrimary' | Set-Content "lib/features/auth/screens/signup_screen.dart"

# Fix Create Library Account Screen
Write-Host "Fixing create_library_account_screen.dart..." -ForegroundColor Yellow
(Get-Content "lib/features/auth/screens/create_library_account_screen.dart") -replace 'backgroundColor: AppColors\.background', 'backgroundColor: AppColors.darkBackground' | Set-Content "lib/features/auth/screens/create_library_account_screen.dart"
(Get-Content "lib/features/auth/screens/create_library_account_screen.dart") -replace 'AppColors\.surfaceVariant', 'AppColors.darkSurfaceVariant' | Set-Content "lib/features/auth/screens/create_library_account_screen.dart"
(Get-Content "lib/features/auth/screens/create_library_account_screen.dart") -replace 'AppColors\.textSecondary', 'AppColors.darkTextSecondary' | Set-Content "lib/features/auth/screens/create_library_account_screen.dart"
(Get-Content "lib/features/auth/screens/create_library_account_screen.dart") -replace 'AppColors\.textPrimary', 'AppColors.darkTextPrimary' | Set-Content "lib/features/auth/screens/create_library_account_screen.dart"
(Get-Content "lib/features/auth/screens/create_library_account_screen.dart") -replace 'AppColors\.surface(?!Variant)', 'AppColors.darkSurface' | Set-Content "lib/features/auth/screens/create_library_account_screen.dart"
(Get-Content "lib/features/auth/screens/create_library_account_screen.dart") -replace 'AppColors\.primary(?!Light|Dark)', 'AppColors.darkPrimary' | Set-Content "lib/features/auth/screens/create_library_account_screen.dart"

# Fix Profile Screen
Write-Host "Fixing profile_screen.dart..." -ForegroundColor Yellow
(Get-Content "lib/features/profile/screens/profile_screen.dart") -replace 'backgroundColor: AppColors\.background', 'backgroundColor: AppColors.darkBackground' | Set-Content "lib/features/profile/screens/profile_screen.dart"
(Get-Content "lib/features/profile/screens/profile_screen.dart") -replace 'AppColors\.surfaceVariant', 'AppColors.darkSurfaceVariant' | Set-Content "lib/features/profile/screens/profile_screen.dart"
(Get-Content "lib/features/profile/screens/profile_screen.dart") -replace 'AppColors\.textSecondary', 'AppColors.darkTextSecondary' | Set-Content "lib/features/profile/screens/profile_screen.dart"
(Get-Content "lib/features/profile/screens/profile_screen.dart") -replace 'AppColors\.textPrimary', 'AppColors.darkTextPrimary' | Set-Content "lib/features/profile/screens/profile_screen.dart"
(Get-Content "lib/features/profile/screens/profile_screen.dart") -replace 'AppColors\.surface(?!Variant)', 'AppColors.darkSurface' | Set-Content "lib/features/profile/screens/profile_screen.dart"
(Get-Content "lib/features/profile/screens/profile_screen.dart") -replace 'AppColors\.border', 'AppColors.darkBorder' | Set-Content "lib/features/profile/screens/profile_screen.dart"
(Get-Content "lib/features/profile/screens/profile_screen.dart") -replace 'AppColors\.primary(?!Light|Dark)', 'AppColors.darkPrimary' | Set-Content "lib/features/profile/screens/profile_screen.dart"
(Get-Content "lib/features/profile/screens/profile_screen.dart") -replace 'AppColors\.error', 'AppColors.darkError' | Set-Content "lib/features/profile/screens/profile_screen.dart"

# Fix Reader Transactions Screen
Write-Host "Fixing reader_transactions_screen.dart..." -ForegroundColor Yellow
(Get-Content "lib/features/borrow/screens/reader_transactions_screen.dart") -replace 'backgroundColor: AppColors\.background', 'backgroundColor: AppColors.darkBackground' | Set-Content "lib/features/borrow/screens/reader_transactions_screen.dart"
(Get-Content "lib/features/borrow/screens/reader_transactions_screen.dart") -replace 'AppColors\.surfaceVariant', 'AppColors.darkSurfaceVariant' | Set-Content "lib/features/borrow/screens/reader_transactions_screen.dart"
(Get-Content "lib/features/borrow/screens/reader_transactions_screen.dart") -replace 'AppColors\.textSecondary', 'AppColors.darkTextSecondary' | Set-Content "lib/features/borrow/screens/reader_transactions_screen.dart"
(Get-Content "lib/features/borrow/screens/reader_transactions_screen.dart") -replace 'AppColors\.textPrimary', 'AppColors.darkTextPrimary' | Set-Content "lib/features/borrow/screens/reader_transactions_screen.dart"
(Get-Content "lib/features/borrow/screens/reader_transactions_screen.dart") -replace 'AppColors\.surface(?!Variant)', 'AppColors.darkSurface' | Set-Content "lib/features/borrow/screens/reader_transactions_screen.dart"
(Get-Content "lib/features/borrow/screens/reader_transactions_screen.dart") -replace 'AppColors\.primary(?!Light|Dark)', 'AppColors.darkPrimary' | Set-Content "lib/features/borrow/screens/reader_transactions_screen.dart"

Write-Host "All dark mode fixes applied!" -ForegroundColor Green
Write-Host "Run 'flutter run' to test the changes." -ForegroundColor Cyan
