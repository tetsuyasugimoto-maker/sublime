@echo off
setlocal
rem ===== 設定 =====
set "DIST=dist"
set "BASE=/sublime"
rem ===============

rem .ps1 を実行（PowerShellはWindows標準でOK）
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0postbuild-prefix-base.ps1" -Dist "%DIST%" -Base "%BASE%"

if errorlevel 1 (
  echo [postbuild] 置換処理でエラーが発生しました
  exit /b 1
)

echo [postbuild] 完了
endlocal
