$paths = @(
    "HKLM:\SOFTWARE\Classes\CLSID\{860BB310-5D01-11d0-BD3B-00A0C911CE86}\Instance",
    "HKLM:\SOFTWARE\WOW6432Node\Classes\CLSID\{860BB310-5D01-11d0-BD3B-00A0C911CE86}\Instance",
    "HKCU:\Software\Classes\CLSID\{860BB310-5D01-11d0-BD3B-00A0C911CE86}\Instance",
    "HKLM:\SOFTWARE\Classes\CLSID\{A3FCE0F5-3493-419F-958A-ABA1250EC20B}\Instance",
    "HKLM:\SOFTWARE\WOW6432Node\Classes\CLSID\{A3FCE0F5-3493-419F-958A-ABA1250EC20B}\Instance",
    "HKCU:\Software\Classes\CLSID\{A3FCE0F5-3493-419F-958A-ABA1250EC20B}\Instance",
    "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceClasses\{65e8773d-8f56-11d0-a3b9-00a0c9223196}"
)

foreach ($path in $paths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Recurse | ForEach-Object {
            $prop = Get-ItemProperty -Path $_.PSPath
            if ($prop.FriendlyName -match "Twitch" -or $prop.DeviceDesc -match "Twitch" -or $_.Name -match "Twitch") {
                Write-Host "找到残留条目: $($_.PSPath)" -ForegroundColor Red
                Remove-Item -Path $_.PSPath -Recurse -Force
                Write-Host "已成功删除！" -ForegroundColor Green
            }
        }
    }
}