$ErrorActionPreference = "Stop"

Write-Host "=== 本地 APK 构建脚本 ===" -ForegroundColor Cyan

$projectPath = "D:\trae_projects\dang"
$flutterPath = "C:\flutter-sdk\bin\flutter"

Write-Host "`n1. 检查 Flutter 环境..." -ForegroundColor Yellow
& $flutterPath --version

Write-Host "`n2. 清理构建缓存..." -ForegroundColor Yellow
& $flutterPath clean

Write-Host "`n3. 获取依赖..." -ForegroundColor Yellow
& $flutterPath pub get

Write-Host "`n4. 构建 APK（release）..." -ForegroundColor Yellow
& $flutterPath build apk --release --no-tree-shake-icons

Write-Host "`n5. 复制构建产物..." -ForegroundColor Yellow
$sourceApk = "$projectPath\build\app\outputs\flutter-apk\app-release.apk"
$targetApk = "$projectPath\changji_app.apk"

if (Test-Path $sourceApk) {
    Copy-Item $sourceApk $targetApk -Force
    Write-Host "✅ APK 构建成功！" -ForegroundColor Green
    Write-Host "输出路径: $targetApk" -ForegroundColor Green
} else {
    Write-Host "❌ APK 构建失败！" -ForegroundColor Red
    exit 1
}