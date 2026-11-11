# Kiểm tra API thật bằng publishable key, với quyền khách chưa đăng nhập.
# Chỉ đọc dữ liệu, không thay giá/tồn kho hoặc tạo tài khoản.
param([string]$ConfigPath = (Join-Path $PSScriptRoot '../config/development.local.json'))

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw 'Chưa có config local. Làm theo docs/supabase-setup.md trước.'
}
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$projectUri = $null
if (-not [Uri]::TryCreate($config.SUPABASE_URL, [UriKind]::Absolute, [ref]$projectUri) -or
    $projectUri.Scheme -ne 'https' -or $projectUri.UserInfo -ne '' -or
    $projectUri.Query -ne '' -or $projectUri.Fragment -ne '') {
    throw 'Cần URL project Supabase HTTPS hợp lệ.'
}
$publishableKey = [string]$config.SUPABASE_PUBLISHABLE_KEY
if (-not $publishableKey.StartsWith('sb_publishable_')) {
    throw 'Script này cần publishable key mới (sb_publishable_...), không dùng secret/service-role.'
}
$baseUrl = $config.SUPABASE_URL.TrimEnd('/')
$query = '/rest/v1/products?select=code,name,price_vnd,product_variants(sku,size,color,stock)&code=in.(SF01,SF02)&order=code.asc'
try {
    $responseData = Invoke-RestMethod -Method Get -Uri ($baseUrl + $query) `
        -Headers @{ apikey = $publishableKey } -TimeoutSec 30
    $products = @($responseData)
} catch {
    # Không in request headers/key khi báo lỗi.
    $errorType = $_.Exception.GetType().Name
    $statusCode = $_.Exception.Response.StatusCode
    throw "API chưa đọc được ($errorType; HTTP $statusCode). Kiểm tra mạng, project, URL/key và quyền SELECT/RLS."
}
if ($products.Count -ne 2 -or $products[0].code -ne 'SF01' -or $products[1].code -ne 'SF02') {
    throw 'API đã trả lời nhưng thiếu SF01/SF02. Kiểm tra dữ liệu mẫu và trạng thái hiển thị.'
}
$total = ($products | Measure-Object -Property price_vnd -Sum).Sum
if ($total -ne 448000 -or @($products[0].product_variants).Count -ne 4 -or
    @($products[1].product_variants).Count -ne 1) {
    throw 'API đã trả lời nhưng giá/biến thể khác fixture demo. Xem thay đổi catalog trước khi kết luận lỗi.'
}
$products | Select-Object code, name, price_vnd | Format-Table -AutoSize
Write-Host 'PASS: API cloud đọc được hai sản phẩm, năm biến thể; tổng giá 448.000 VNĐ.'
Write-Host 'Đây là kiểm tra quyền khách. Đăng nhập/Auth và UI Flutter cần kiểm tra ở bước tiếp theo.'
