@echo off
cd /d "%~dp0"
set "WOW_PATH=D:\World of Warcraft\_retail_\Interface\AddOns\MidnightBrew"

echo Syncing MidnightBrew (Engine 2.0)...
if not exist "%WOW_PATH%" mkdir "%WOW_PATH%"

xcopy /Y "*.lua" "%WOW_PATH%\"
xcopy /Y "*.toc" "%WOW_PATH%\"

echo.
echo [DONE] All files synchronized to D: drive.
echo Type /reload in-game.
pause
