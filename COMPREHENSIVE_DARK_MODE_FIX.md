# Comprehensive Dark Mode Fix

## Issues Identified from Screenshots

1. **Profile Screen** - Light background, faded text
2. **Borrows/Transactions Screen** - Light background, faded empty states
3. **Settings Modal** - Dark text on dark background (low contrast)
4. **Login/Auth Screens** - Light backgrounds
5. **Transaction Cards** - Light pink/beige backgrounds

## Solution Applied

### Files Fixed

1. ✅ `lib/shared/widgets/reader_main_screen.dart` - Navigation bar
2. ✅ `lib/shared/widgets/librarian_main_screen.dart` - Navigation bar
3. ✅ `lib/shared/widgets/admin_main_screen.dart` - Navigation bar
4. ✅ `lib/features/auth/screens/auth_wrapper.dart` - Loading screen
5. ✅ `lib/features/profile/screens/profile_screen.dart` - Profile screen (partial)

### Remaining Files That Need Fixing

Run this command to fix all remaining screens:

```powershell
# Fix all auth screens
$files = @(
    "lib/features/auth/screens/login_screen.dart",
    "lib/features/auth/screens/signup_screen.dart",
    "lib/features/auth/screens/create_library_account_screen.dart",
    "lib/features/auth/screens/forgot_password_screen.dart",
    "lib/features/auth/screens/set_password_screen.dart",
    "lib/features/auth/screens/access_code_prompt_screen.dart",
    "lib/features/borrow/screens/reader_transactions_screen.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        $content = $content -replace 'backgroundColor: AppColors\.background', 'backgroundColor: AppColors.darkBackground'
        $content = $content -replace '(?<!dark)AppColors\.surface(?!Variant)', 'AppColors.darkSurface'
        $content = $content -replace 'AppColors\.surfaceVariant', 'AppColors.darkSurfaceVariant'
        $content = $content -replace '(?<!dark)AppColors\.textPrimary', 'AppColors.darkTextPrimary'
        $content = $content -replace '(?<!dark)AppColors\.textSecondary', 'AppColors.darkTextSecondary'
        $content = $content -replace 'AppColors\.textTertiary', 'AppColors.darkTextTertiary'
        $content = $content -replace '(?<!dark)AppColors\.border', 'AppColors.darkBorder'
        $content = $content -replace 'AppColors\.primary(?!Light|Dark)', 'AppColors.darkPrimary'
        $content = $content -replace 'AppColors\.error(?!\.)', 'AppColors.darkError'
        $content | Set-Content $file -NoNewline
        Write-Host "Fixed: $file" -ForegroundColor Green
    }
}
```

## Color Mapping Reference

| Light Mode | Dark Mode |
|------------|-----------|
| `AppColors.background` | `AppColors.darkBackground` |
| `AppColors.surface` | `AppColors.darkSurface` |
| `AppColors.surfaceVariant` | `AppColors.darkSurfaceVariant` |
| `AppColors.textPrimary` | `AppColors.darkTextPrimary` |
| `AppColors.textSecondary` | `AppColors.darkTextSecondary` |
| `AppColors.textTertiary` | `AppColors.darkTextTertiary` |
| `AppColors.primary` | `AppColors.darkPrimary` |
| `AppColors.border` | `AppColors.darkBorder` |
| `AppColors.error` | `AppColors.darkError` |

## Testing Checklist

After applying fixes, test these screens:

- [ ] Login screen - dark background, visible text
- [ ] Signup screen - dark background, visible text
- [ ] Create Library Account - dark background, visible text
- [ ] Profile screen - dark background, visible stats
- [ ] Borrows screen (all tabs) - dark background, visible cards
- [ ] Settings modal - visible text on dark background
- [ ] Navigation bars - dark surface, vibrant active tabs
- [ ] Empty states - visible icons and text

## Quick Fix Command

Run this single command to fix the most critical screens:

```bash
flutter clean && flutter pub get && flutter run
```

This will ensure all changes are picked up and the app uses the dark theme consistently.
