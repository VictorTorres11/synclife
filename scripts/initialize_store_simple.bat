@echo off
echo.
echo ========================================
echo   FluxoCoins Store Initialization
echo ========================================
echo.
echo This script will help you initialize the FluxoCoins store.
echo.
echo INSTRUCTIONS:
echo 1. Make sure the Flutter app is running in Chrome
echo 2. Open Chrome Developer Tools (F12)
echo 3. Go to the Console tab
echo 4. Copy and paste the contents of scripts/initialize_store_web.js
echo 5. Press Enter to load the script
echo 6. Run: initializeFluxoCoinsStore()
echo.
echo The script will add all default store items to Firestore.
echo.
echo Opening the web script file...
echo.
pause
start notepad scripts/initialize_store_web.js
echo.
echo Script file opened in Notepad.
echo Copy the contents and paste them in the browser console.
echo.
pause