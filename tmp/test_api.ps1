$body = @{phone='13800138001'; password='ChangJi@2026#Admin!'} | ConvertTo-Json
$res = Invoke-WebRequest -Uri 'http://101.133.238.249/api/v1/auth/login' -Method POST -ContentType 'application/json' -Body $body -UseBasicParsing
$data = $res.Content | ConvertFrom-Json
$token = $data.data.accessToken
Write-Host "Login OK"

Write-Host "=== 测试1: healthy-models API ==="
$hm = Invoke-WebRequest -Uri 'http://101.133.238.249/api/v1/api-key/admin/healthy-models' -Headers @{'Authorization'="Bearer $token"} -UseBasicParsing
Write-Host "HealthyModels: $($hm.StatusCode)"
$hmData = $hm.Content | ConvertFrom-Json
Write-Host "Count: $($hmData.data.Count)"

Write-Host "=== 测试2: Plans ==="
$plans = Invoke-WebRequest -Uri 'http://101.133.238.249/api/v1/subscription/plans' -Headers @{'Authorization'="Bearer $token"} -UseBasicParsing
Write-Host "Plans: $($plans.StatusCode)"
$plansData = $plans.Content | ConvertFrom-Json
Write-Host "Count: $($plansData.data.Count)"
if ($plansData.data.Count -gt 0) {
    Write-Host "First plan allowedModels: $($plansData.data[0].allowedModels)"
}

Write-Host "=== 测试3: 保存套餐 ==="
$planBody = @{
    name='测试套餐'
    description='测试'
    priceCents=100
    durationDays=30
    quotaType='minutes'
    quotaValue=100
    isActive=$true
} | ConvertTo-Json
$save = Invoke-WebRequest -Uri 'http://101.133.238.249/api/v1/admin/plans' -Method POST -Headers @{'Authorization'="Bearer $token"} -ContentType 'application/json' -Body $planBody -UseBasicParsing
Write-Host "SavePlan: $($save.StatusCode)"
Write-Host "Response: $($save.Content)"
