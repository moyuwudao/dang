# 通义听悟离线转写测试脚本
# 使用 PowerShell + .NET HttpClient

$accessKeyId = $env:ALIBABA_ACCESS_KEY_ID
$accessKeySecret = $env:ALIBABA_ACCESS_KEY_SECRET
$appKey = $env:TINGWU_APP_KEY

if (-not $accessKeyId -or -not $accessKeySecret -or -not $appKey) {
    Write-Host "错误: 请设置环境变量 ALIBABA_ACCESS_KEY_ID, ALIBABA_ACCESS_KEY_SECRET, TINGWU_APP_KEY" -ForegroundColor Red
    exit 1
}
$audioFile = "C:\Users\Mayn\Downloads\backup_1779071705220\recording_1778953588269.wav"

# 读取音频文件并转为 Base64
$audioBytes = [System.IO.File]::ReadAllBytes($audioFile)
$audioBase64 = [Convert]::ToBase64String($audioBytes)
Write-Host "音频文件大小: $($audioBytes.Length) bytes"
Write-Host "Base64 长度: $($audioBase64.Length)"

# 构建请求体
$body = @{
    AppKey = $appKey
    Input = @{
        FileUrl = "data:audio/wav;base64,$audioBase64"
        SourceLanguage = "cn"
        TaskKey = "test_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }
    Parameters = @{
        Transcription = @{
            DiarizationEnabled = $true
            Diarization = @{
                SpeakerCount = 0
            }
        }
    }
} | ConvertTo-Json -Depth 10

Write-Host "请求体:"
Write-Host $body.Substring(0, [Math]::Min(500, $body.Length))...

# 发送请求
$url = "https://tingwu.cn-beijing.aliyuncs.com/openapi/tingwu/v2/tasks?type=offline"

try {
    $response = Invoke-RestMethod -Uri $url -Method PUT -Body $body -ContentType "application/json" -Headers @{
        "Authorization" = "acs $accessKeyId:$(Get-Signature -Method PUT -Path "/openapi/tingwu/v2/tasks" -Body $body)"
    }
    Write-Host "✅ 任务创建成功!"
    Write-Host $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ 请求失败: $_"
}
