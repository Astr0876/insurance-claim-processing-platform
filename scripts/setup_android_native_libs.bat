@echo off
REM =============================================================================
REM RunAnywhere Android Native Libraries Fix (Windows)
REM =============================================================================
REM The RunAnywhere Flutter plugin v0.16.0 has broken Android download URLs.
REM This script patches the pub cache plugin build.gradle files to gracefully
REM handle the missing downloads so the Android build doesn't crash.
REM
REM Usage: scripts\setup_android_native_libs.bat
REM =============================================================================

echo.
echo ===============================================================
echo  RunAnywhere Android Build Fix (Windows)
echo ===============================================================
echo.

REM Detect pub cache directory
set "PUB_CACHE_DIR=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev"
if not exist "%PUB_CACHE_DIR%" (
    set "PUB_CACHE_DIR=%USERPROFILE%\.pub-cache\hosted\pub.dev"
)
if not exist "%PUB_CACHE_DIR%" (
    echo ERROR: Could not find pub cache directory
    echo Run 'flutter pub get' first.
    exit /b 1
)

set PATCHED=0

REM Patch runanywhere
for /d %%D in ("%PUB_CACHE_DIR%\runanywhere-*") do (
    call :patch_plugin "%%D\android\build.gradle" "%%~nxD"
)

REM Patch runanywhere_llamacpp
for /d %%D in ("%PUB_CACHE_DIR%\runanywhere_llamacpp-*") do (
    call :patch_plugin "%%D\android\build.gradle" "%%~nxD"
)

REM Patch runanywhere_onnx
for /d %%D in ("%PUB_CACHE_DIR%\runanywhere_onnx-*") do (
    call :patch_plugin "%%D\android\build.gradle" "%%~nxD"
)

echo.
echo Done! The Android build should now succeed.
echo.
echo NOTE: runanywhere AI features (LLM, STT, TTS, VAD) require
echo Android native binaries that haven't been published yet.
echo The app will build and run, but these features won't work
echo on Android until the plugin authors fix this.
echo.
pause
exit /b 0

:patch_plugin
set "BUILD_FILE=%~1"
set "PLUGIN_NAME=%~2"

if not exist "%BUILD_FILE%" goto :eof

REM Check if already patched
findstr /C:"Download failed (Android binaries not yet published)" "%BUILD_FILE%" >nul 2>&1
if %errorlevel% equ 0 (
    echo   Already patched: %PLUGIN_NAME%
    goto :eof
)

REM Use PowerShell to do the replacement
powershell -Command "(Get-Content '%BUILD_FILE%') -replace 'ant\.get\(src: downloadUrl, dest: zipFile\)', 'try { ant.get(src: downloadUrl, dest: zipFile) } catch (Exception e) { println \"WARNING: Download failed (Android binaries not yet published): ${e.message}\"; println \"   The app will build but runanywhere native features may not work on Android.\"; return }' | Set-Content '%BUILD_FILE%'"

echo   Patched: %PLUGIN_NAME%
set /a PATCHED+=1
goto :eof
