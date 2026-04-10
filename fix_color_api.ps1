# PowerShell script to fix all withValues(alpha: X) to withOpacity(X)

Write-Host "🔧 Fixing Color API compatibility issues..." -ForegroundColor Yellow

# Get all Dart files in the lib directory
$dartFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"

$totalFiles = 0
$totalReplacements = 0

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Replace .withValues(alpha: X) with .withOpacity(X)
    $content = $content -replace '\.withValues\(alpha:\s*([^)]+)\)', '.withOpacity($1)'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $replacements = ([regex]::Matches($originalContent, '\.withValues\(alpha:')).Count
        $totalReplacements += $replacements
        $totalFiles++
        Write-Host "✅ Fixed $replacements instances in $($file.Name