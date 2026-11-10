# Chạy từ PowerShell để xem Flutter web trên điện thoại cùng Wi-Fi.
# Không thay đổi SDK, cấu hình toàn máy hoặc Firewall.
param(
    [ValidateRange(1024, 65535)]
    [int]$Port = 8080,
    [switch]$UseSupabase,
    [switch]$Offline
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Chưa tìm thấy Flutter trên PATH. Xem README của project.'
}

Write-Host 'Đây là bản WEB để xem bằng Safari/Chrome trên điện thoại.'
Write-Host 'Windows và điện thoại cần cùng mạng Wi-Fi/LAN.'
Write-Host "Mở http://IP_MAY_WINDOWS:$Port trên điện thoại, không dùng localhost."
Write-Host 'Dùng ipconfig để xem IPv4 của Wi-Fi/Ethernet đang kết nối.'
Write-Host 'Nhấn Ctrl+C trong cửa sổ này để dừng server.'
Write-Host ''
$flutterArgs = @('run', '-d', 'web-server', '--web-hostname', '0.0.0.0', '--web-port', "$Port", '--no-web-resources-cdn')
if ($UseSupabase -and $Offline) { throw 'Chọn -UseSupabase hoặc -Offline, không chọn cả hai.' }
if ($Offline) {
    $flutterArgs += '--dart-define=USE_SUPABASE=false'
    Write-Host 'Chế độ UI offline được chọn rõ ràng; Auth không gọi cloud.'
} elseif ($UseSupabase) {
    $configFile = Join-Path $projectRoot 'config/development.local.json'
    if (-not (Test-Path -LiteralPath $configFile)) {
        throw 'Chưa có config/development.local.json. Xem docs/supabase-setup.md.'
    }
    $config = Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json
    if ([string]$config.USE_SUPABASE -ne 'true') { throw 'File config local đang tắt Supabase.' }
    $flutterArgs += "--dart-define-from-file=$configFile"
    Write-Host 'Đã chọn cấu hình Supabase local.'
} else {
    Write-Host 'Dùng backend smart-fashion-dev mặc định. Thêm -Offline nếu chỉ xem UI.'
}

Push-Location -LiteralPath $projectRoot
try {
    & flutter @flutterArgs
    $flutterExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $flutterExitCode
