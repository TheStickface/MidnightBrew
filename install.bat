@echo off
cd /d "%~dp0"
set "WOW_PATH=D:\World of Warcraft\_retail_\Interface\AddOns\MidnightBrew"

echo Syncing MidnightBrew...
if not exist "%WOW_PATH%" mkdir "%WOW_PATH%"

xcopy /Y "Init.lua" "%WOW_PATH%\"
xcopy /Y "Core.lua" "%WOW_PATH%\"
xcopy /Y "UI.lua" "%WOW_PATH%\"
xcopy /Y "Debug.lua" "%WOW_PATH%\"
xcopy /Y "Modules.lua" "%WOW_PATH%\"
xcopy /Y "Config.lua" "%WOW_PATH%\"
xcopy /Y "Tests.lua" "%WOW_PATH%\"
xcopy /Y "MidnightBrew.toc" "%WOW_PATH%\"

echo.
echo [DONE] 8 Files copied to your D: drive.
echo Type /reload in-game.
pause
