# Build APK phát triển có Auth. Không cần ghi nhớ --dart-define mỗi lần.
param([ValidateSet('debug', 'release')][string]$Mode = 'debug')

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$configFile = Join-Path $projectRoot 'config/development.local.json'
$buildArgs = @('build', 'apk', "--$Mode")
if (Test-Path -LiteralPath $configFile) {
    $config = Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json
    if ([string]$config.USE_SUPABASE -ne 'true') {
        throw 'Config local đang tắt Supabase. Bật USE_SUPABASE=true trước khi build bản dùng Auth.'
    }
    if (-not $config.SUPABASE_URL -or -not ([string]$config.SUPABASE_PUBLISHABLE_KEY).StartsWith('sb_publishable_')) {
        throw 'Config local cần URL và publishable key hợp lệ; không dùng khóa đặc quyền.'
    }
    $buildArgs += "--dart-define-from-file=$configFile"
    Write-Host 'Dùng cấu hình Supabase dev từ file local.'
} else {
    Write-Host 'Dùng cấu hình client công khai của smart-fashion-dev.'
}

Push-Location -LiteralPath $projectRoot
try {
    & flutter @buildArgs
    if ($LASTEXITCODE -ne 0) { throw 'Build APK chưa thành công. Xem lỗi phía trên.' }
    $apkPath = Join-Path $projectRoot "build/app/outputs/flutter-apk/app-$Mode.apk"
    $handoffPath = Join-Path $projectRoot "build/app/outputs/flutter-apk/smart-fashion-dev-$Mode.apk"
    Copy-Item -LiteralPath $apkPath -Destination $handoffPath -Force
    Write-Host "APK mới: $handoffPath"
    Write-Host 'Đây là bản phát triển dùng project smart-fashion-dev.'
} finally {
    Pop-Location
}
