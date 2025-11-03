@echo off
setlocal

if "%~1"=="" (
    echo [error] need input dir
    echo.
    echo  %~n0 [input dir] [output dir] [file list]
    echo  %~n0 "C:\my_project\shaders" "C:\my_project\spirv"
    goto :eof
)

if "%~2"=="" (
    echo [error] need output dir
    echo.
    echo  %~n0 [input dir] [output dir] [file list]
    echo  %~n0 "C:\my_project\shaders" "C:\my_project\spirv"
    goto :eof
)

if "%~3"=="" (
    echo [error] need file list txt
    echo.
    echo  %~n0 [input dir] [output dir] [file list]
    echo  %~n0 "C:\my_project\shaders" "C:\my_project\spirv"
    goto :eof
)

set "INPUT_DIR=%~1"
set "OUTPUT_DIR=%~2"
set "File_List=%~3"

where glslc >nul 2>nul
if %errorlevel% neq 0 (
    goto :eof
)

if not exist "%INPUT_DIR%" (
    echo [error] input dir "%INPUT_DIR%" missing
    goto :eof
)

if not exist "%OUTPUT_DIR%" (
    echo [info] output dir "%OUTPUT_DIR%" creating
    mkdir "%OUTPUT_DIR%"
)

set "SHADER_COUNT=0"
for /f "usebackq delims=" %%i in ("%File_List%") do (

    for %%f in ("%INPUT_DIR%\%%i") do (
        if exist "%%f" (
            C:\D\code\zig\game\zig-out\bin\samplerJsonPrase.exe "%%f" "%OUTPUT_DIR%\%%~nf.sampler"
            
            set /a SHADER_COUNT+=1
        )
    )
)

echo.
echo done: %SHADER_COUNT% shader files

endlocal

