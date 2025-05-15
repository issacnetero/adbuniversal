@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

rem ======================================================================
rem  ADB UNIVERSAL Batch Script
rem  Author: issacnetero
rem  GitHub: https://github.com/issacnetero
rem ======================================================================

rem ANSI Color Codes
set "ESC="
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "MAGENTA=%ESC%[95m"
set "CYAN=%ESC%[96m"
set "LINE=%ESC%[90m─────────────────────────────────────────────────────%RESET%"

rem ======================================================================
rem  INITIALIZATION
rem ======================================================================
rem Create temp directory if it doesn't exist
if not exist "%TEMP%\adb_universal" mkdir "%TEMP%\adb_universal"

rem Check for ADB availability
adb version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%ADB is not available in the system path.%RESET%
    echo %YELLOW%Please install Android SDK platform tools and add them to your PATH.%RESET%
    pause
    exit /b 1
)

:mainMenu
cls
echo %CYAN%======================================================================%RESET%
echo %BOLD%%CYAN%  ADB UNIVERSAL Batch Script%RESET%
echo %MAGENTA%  Author: issacnetero%RESET%
echo %MAGENTA%  GitHub: https://github.com/issacnetero%RESET%
echo %CYAN%======================================================================%RESET%
echo.
echo %LINE%
echo %YELLOW%  1%RESET%) Install APKs from URL list
echo %YELLOW%  2%RESET%) Uninstall packages
echo %YELLOW%  3%RESET%) Exit
echo %LINE%
set /p "choice=%MAGENTA%Select action [1-3]: %RESET%"

if "%choice%"=="1" goto installPrep
if "%choice%"=="2" goto uninstallPrep
if "%choice%"=="3" exit /b
echo %RED%Invalid selection, please try again%RESET%
timeout /t 2 >nul
goto mainMenu

:installPrep
set ACTION=INSTALL
goto fileSelect

:uninstallPrep
set ACTION=UNINSTALL
goto fileSelect

:fileSelect
set "SCRIPT_DIR=%~dp0"
set fileCount=0

echo %CYAN%Available .txt files:%RESET%
rem Use /A-D /B for faster directory listing (files only, no directories)
for /f "delims=" %%F in ('dir /A-D /B "%SCRIPT_DIR%*.txt" 2^>nul') do (
    set /a fileCount+=1
    set "file[!fileCount!]=%%F"
    echo %YELLOW%  [!fileCount!]%RESET% %%F
)

if %fileCount%==0 (
    echo %RED%No .txt files found in %SCRIPT_DIR%%RESET%
    echo %YELLOW%Please create a text file with URLs or package names%RESET%
    pause
    goto mainMenu
)

:selectFile
set /p "fileIdx=%MAGENTA%Select list file by number (1-%fileCount%): %RESET%"
if not defined file[%fileIdx%] (
    echo %RED%Invalid selection. Try again.%RESET%
    goto selectFile
)
set "listFile=!file[%fileIdx%]!"
echo %GREEN%Selected file: %listFile%%RESET%

rem ======================================================================
rem  DEVICE SELECTION
rem ======================================================================
set deviceCount=0
for /f "skip=1 tokens=1" %%D in ('adb devices 2^>nul') do (
    if not "%%D"=="" if not "%%D"=="device" (
        set /a deviceCount+=1
        set "deviceSerial[!deviceCount!]=%%D"
        for /f "usebackq delims=" %%M in (`adb -s %%D shell getprop ro.product.model 2^>nul`) do (
            set "deviceName[!deviceCount!]=%%M"
        )
    )
)

if %deviceCount%==0 (
    echo %RED%No devices detected. Please connect a device with USB debugging enabled.%RESET%
    echo %YELLOW%Troubleshooting tips:%RESET%
    echo %YELLOW%1. Ensure USB debugging is enabled in device developer options%RESET%
    echo %YELLOW%2. Check your USB cable connection%RESET%
    echo %YELLOW%3. Try installing/updating device drivers%RESET%
    pause
    goto mainMenu
)

echo %CYAN%Connected devices:%RESET%
for /l %%i in (1,1,%deviceCount%) do (
    echo %YELLOW%  [%%i]%RESET% !deviceSerial[%%i]! %MAGENTA%-%RESET% !deviceName[%%i]!
)

:selectDevice
set /p "devIdx=%MAGENTA%Select device by number (1-%deviceCount%): %RESET%"
if not defined deviceSerial[%devIdx%] (
    echo %RED%Invalid selection. Try again.%RESET%
    goto selectDevice
)
set "TARGET=!deviceSerial[%devIdx%]!"
echo %GREEN%Selected device: %TARGET% - !deviceName[%devIdx%]!%RESET%

if "%ACTION%"=="INSTALL" goto installAction
if "%ACTION%"=="UNINSTALL" goto uninstallAction
goto mainMenu

rem ======================================================================
rem  INSTALL ACTION
rem ======================================================================
:installAction
set pkgCount=0
for /f "usebackq delims=" %%P in ("%SCRIPT_DIR%%listFile%") do (
    set /a pkgCount+=1
    set "url=%%P"
    set "url=!url:^M=!"
    set "pkg[!pkgCount!]=!url!"
)

if %pkgCount%==0 (
    echo %RED%%listFile% is empty or not found.%RESET%
    pause
    goto mainMenu
)

echo %CYAN%APKs to install:%RESET%
for /l %%i in (1,1,%pkgCount%) do (
    echo %YELLOW%  [%%i]%RESET% !pkg[%%i]!
)

echo.
set /p "choices=%MAGENTA%Enter numbers to install (e.g. 1 3 5) or 'all': %RESET%"

rem Validate URL format before proceeding
if /i "%choices%"=="all" (
    for /l %%i in (1,1,%pkgCount%) do (
        set "url=!pkg[%%i]!"
        if not "!url:http=!"=="!url!" (
            echo %BLUE%Downloading APK from: !pkg[%%i]!%RESET%
            set "tempFile=%TEMP%\adb_universal\apk_%%i.apk"
            
            rem Download with proper error handling
            powershell -Command "try { Invoke-WebRequest -Uri '!pkg[%%i]!' -OutFile '!tempFile!' -UseBasicParsing } catch { exit 1 }" 2>nul
            if %ERRORLEVEL% neq 0 (
                echo %RED%Failed to download: !pkg[%%i]!%RESET%
                echo %YELLOW%Check URL formatting and internet connection%RESET%
                continue
            )
            
            if exist "!tempFile!" (
                echo %CYAN%Installing !tempFile!...%RESET%
                adb -s %TARGET% install -r "!tempFile!" 2>nul
                if %ERRORLEVEL% neq 0 (
                    echo %RED%Failed to install !tempFile!%RESET%
                ) else (
                    echo %GREEN%Successfully installed !pkg[%%i]!%RESET%
                )
                del /Q "!tempFile!" >nul 2>&1
            ) else (
                echo %RED%Failed to download: !pkg[%%i]!%RESET%
            )
        ) else (
            echo %RED%Invalid URL format: !pkg[%%i]!%RESET%
            echo %YELLOW%URLs must start with http:// or https://%RESET%
        )
    )
) else (
    for %%c in (%choices%) do (
        if %%c geq 1 if %%c leq %pkgCount% (
            set "url=!pkg[%%c]!"
            if not "!url:http=!"=="!url!" (
                echo %BLUE%Downloading APK from: !pkg[%%c]!%RESET%
                set "tempFile=%TEMP%\adb_universal\apk_%%c.apk"
                
                rem Download with proper error handling
                powershell -Command "try { Invoke-WebRequest -Uri '!pkg[%%c]!' -OutFile '!tempFile!' -UseBasicParsing } catch { exit 1 }" 2>nul
                if %ERRORLEVEL% neq 0 (
                    echo %RED%Failed to download: !pkg[%%c]!%RESET%
                    echo %YELLOW%Check URL formatting and internet connection%RESET%
                    continue
                )
                
                if exist "!tempFile!" (
                    echo %CYAN%Installing !tempFile!...%RESET%
                    adb -s %TARGET% install -r "!tempFile!" 2>nul
                    if %ERRORLEVEL% neq 0 (
                        echo %RED%Failed to install !tempFile!%RESET%
                    ) else (
                        echo %GREEN%Successfully installed !pkg[%%c]!%RESET%
                    )
                    del /Q "!tempFile!" >nul 2>&1
                ) else (
                    echo %RED%Failed to download: !pkg[%%c]!%RESET%
                )
            ) else (
                echo %RED%Invalid URL format: !pkg[%%c]!%RESET%
                echo %YELLOW%URLs must start with http:// or https://%RESET%
            )
        ) else echo %RED%Invalid number: %%c%RESET%
    )
)
goto complete

rem ======================================================================
rem  UNINSTALL ACTION
rem ======================================================================
:uninstallAction
set pkgCount=0
for /f "usebackq delims=" %%P in ("%SCRIPT_DIR%%listFile%") do (
    set /a pkgCount+=1
    set "line=%%P"
    set "line=!line:^M=!"
    set "pkg[!pkgCount!]=!line!"
)

if %pkgCount%==0 (
    echo %RED%%listFile% is empty or not found.%RESET%
    pause
    goto mainMenu
)

echo %CYAN%Packages to uninstall:%RESET%
for /l %%i in (1,1,%pkgCount%) do (
    echo %YELLOW%  [%%i]%RESET% !pkg[%%i]!
)

echo.
set /p "choices=%MAGENTA%Enter numbers to uninstall (e.g. 1 3 5) or 'all': %RESET%"

if /i "%choices%"=="all" (
    for /l %%i in (1,1,%pkgCount%) do (
        echo %MAGENTA%Uninstalling !pkg[%%i]!...%RESET%
        adb -s %TARGET% shell pm uninstall --user 0 "!pkg[%%i]!" 2>nul
        if %ERRORLEVEL% neq 0 (
            echo %RED%Failed to uninstall: !pkg[%%i]!%RESET%
        ) else (
            echo %GREEN%Successfully uninstalled: !pkg[%%i]!%RESET%
        )
    )
) else (
    for %%c in (%choices%) do (
        if %%c geq 1 if %%c leq %pkgCount% (
            echo %MAGENTA%Uninstalling !pkg[%%c]!...%RESET%
            adb -s %TARGET% shell pm uninstall --user 0 "!pkg[%%c]!" 2>nul
            if %ERRORLEVEL% neq 0 (
                echo %RED%Failed to uninstall: !pkg[%%c]!%RESET%
            ) else (
                echo %GREEN%Successfully uninstalled: !pkg[%%c]!%RESET%
            )
        ) else echo %RED%Invalid number: %%c%RESET%
    )
)

rem ======================================================================
rem  COMPLETION
rem ======================================================================
:complete
echo.
echo %GREEN%Operation complete.%RESET%
pause
goto mainMenu
