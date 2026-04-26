@echo off
:: Ensure we are running from the folder where the script is located
cd /d "%~dp0"

:: THE CORRECTED PATH
set "WOW_PATH=D:\World of Warcraft\_retail_\Interface\AddOns\MidnightBrew"

echo Syncing MidnightBrew from %cd%
echo Targeting %WOW_PATH%

if not exist "%WOW_PATH%" mkdir "%WOW_PATH%"

:: Copy individual files
xcopy /Y "Core.lua" "%WOW_PATH%\"
xcopy /Y "UI.lua" "%WOW_PATH%\"
xcopy /Y "Debug.lua" "%WOW_PATH%\"
xcopy /Y "Config.lua" "%WOW_PATH%\"
xcopy /Y "Tests.lua" "%WOW_PATH%\"
xcopy /Y "MidnightBrew.toc" "%WOW_PATH%\"

echo.
echo [DONE] 6 Files copied to your D: drive.
echo Type /reload in-game to see the changes.
pause
