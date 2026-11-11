# Cung ba kiem tra co trong CI. Moi lenh loi thi dung de sua truoc khi lam tiep.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

Push-Location -LiteralPath $projectRoot
try {
    Write-Host '1/3 - Kiem tra cach format code'
    & dart format --output=none --set-exit-if-changed lib test tool
    if ($LASTEXITCODE -ne 0) { throw 'Format chua dat. Chay: dart format lib test tool' }

    Write-Host '2/3 - Phan tich code'
    & flutter analyze --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Analyzer chua dat. Xem loi phia tren.' }

    Write-Host '3/3 - Chay test'
    & flutter test --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Co test chua dat. Xem ket qua phia tren.' }

    Write-Host 'Dat ca ba kiem tra. Build/chay thiet bi theo README khi can.'
} finally {
    Pop-Location
}
