# Cùng ba kiểm tra có trong CI. Mỗi lệnh lỗi thì dừng để sửa trước khi làm tiếp.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

Push-Location -LiteralPath $projectRoot
try {
    Write-Host '1/3 · Kiểm tra cách format code'
    & dart format --output=none --set-exit-if-changed lib test tool
    if ($LASTEXITCODE -ne 0) { throw 'Format chưa đạt. Chạy: dart format lib test tool' }

    Write-Host '2/3 · Phân tích code'
    & flutter analyze --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Analyzer chưa đạt. Xem lỗi phía trên.' }

    Write-Host '3/3 · Chạy test'
    & flutter test --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Có test chưa đạt. Xem kết quả phía trên.' }

    Write-Host 'Đạt cả ba kiểm tra. Build/chạy thiết bị theo README khi cần.'
} finally {
    Pop-Location
}
