[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "源仓库路径/URL")]
    [string]$SourceRepo,

    [Parameter(Mandatory = $true, Position = 1, HelpMessage = "临时导出目录")]
    [string]$TempExportDir,

    [Parameter(Mandatory = $true, Position = 2, HelpMessage = "目标中心仓库路径/URL")]
    [string]$CenterRepo
)

# 遇到错误时停止执行
$ErrorActionPreference = "Stop"

# 如果 path.txt 在执行脚本的当前目录下，先锁定其绝对路径，避免进入临时目录后找不到
$PathFile = "path.txt"
if (Test-Path "path.txt") {
    $PathFile = (Resolve-Path "path.txt").Path
}

Write-Host "==> [1/5] 克隆仓库: $SourceRepo -> $TempExportDir"
git clone $SourceRepo $TempExportDir
if ($LASTEXITCODE -ne 0) { throw "git clone 失败！" }

# 进入临时目录（使用 try-finally 确保脚本无论成功或异常都能退回原目录，避免目录占用无法删除）
Push-Location $TempExportDir
try {
    Write-Host "==> [2/5] 检出 main 分支"
    git checkout export2
    if ($LASTEXITCODE -ne 0) { throw "git checkout 失败！" }

    Write-Host "==> [3/5] 执行 filter-repo"
    git filter-repo --paths-from-file $PathFile --force
    if ($LASTEXITCODE -ne 0) { throw "git filter-repo 失败！" }
    
    Write-Host "==> [4/6] 执行 filter-repo"
    git filter-repo --path monsoon/fileSystem/fileNameID.zig --invert-paths --force
    if ($LASTEXITCODE -ne 0) { throw "git filter-repo 失败！" }

    Write-Host "==> [5/6] 添加远程仓库 center: $CenterRepo"
    git remote add center $CenterRepo
    if ($LASTEXITCODE -ne 0) { throw "git remote add 失败！" }

    Write-Host "==> [6/6] 强制推送至 center"
    git push center export2:init --force
    if ($LASTEXITCODE -ne 0) { throw "git push 失败！" }
}
finally {
    # 离开临时目录
    Pop-Location
}

# 清理临时目录
Write-Host "==> 清理临时目录: $TempExportDir"
if (Test-Path $TempExportDir) {
    Remove-Item -Path $TempExportDir -Recurse -Force
}

Write-Host "==> 执行完毕！" -ForegroundColor Green
