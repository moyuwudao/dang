$token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4ZWE3MzU4MC1jNmYzLTRmZTAtODFkYi1hNWUyZmViZmJlMTQiLCJwaG9uZSI6IjEzODAwMTM4MDAxIiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNzc5ODQ2MjA2LCJleHAiOjE3Nzk4NDcxMDZ9.xknUWYNUvVKkMBzYDH7qoe37N8GIq1MZN8ukoF1ah3g"
$headers = @{ "Authorization" = "Bearer $token" }

Write-Host "=== Users ==="
$r = Invoke-WebRequest -Uri "http://101.133.238.249/api/v1/admin/users" -Headers $headers -UseBasicParsing
Write-Host $r.StatusCode

Write-Host "=== Subscriptions ==="
$r = Invoke-WebRequest -Uri "http://101.133.238.249/api/v1/admin/subscriptions" -Headers $headers -UseBasicParsing
Write-Host $r.StatusCode

Write-Host "=== Plans ==="
$r = Invoke-WebRequest -Uri "http://101.133.238.249/api/v1/subscription/plans" -Headers $headers -UseBasicParsing
Write-Host $r.StatusCode

Write-Host "=== API Keys ==="
$r = Invoke-WebRequest -Uri "http://101.133.238.249/api/v1/api-key/admin/list" -Headers $headers -UseBasicParsing
Write-Host $r.StatusCode

Write-Host "=== Dashboard ==="
$r = Invoke-WebRequest -Uri "http://101.133.238.249/api/v1/admin/stats" -Headers $headers -UseBasicParsing
Write-Host $r.StatusCode

Write-Host "=== Monitor System ==="
$r = Invoke-WebRequest -Uri "http://101.133.238.249/api/v1/monitor/system" -Headers $headers -UseBasicParsing
Write-Host $r.StatusCode

Write-Host "=== Monitor Services ==="
$r = Invoke-WebRequest -Uri "http://101.133.238.249/api/v1/monitor/services" -Headers $headers -UseBasicParsing
Write-Host $r.StatusCode
