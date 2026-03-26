@echo off
setlocal
cd /d %~dp0file_transfer_rs
echo Building Rust library in release mode...
"%USERPROFILE%\.cargo\bin\cargo" build --release
if %ERRORLEVEL% neq 0 (
    echo Rust build failed!
    exit /b %ERRORLEVEL%
)
endlocal
