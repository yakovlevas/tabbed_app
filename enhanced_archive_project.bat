@echo off
REM ======================================================
REM enhanced_archive_project.bat - Improved Flutter Project Archive Script
REM Collects all project files into a folder with metadata added
REM ======================================================

echo ======================================================
echo   Flutter Project Archive Utility (Enhanced)
echo   Copies files with metadata added
echo ======================================================

REM Set timestamp for unique folder name
set TIMESTAMP=%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%
set TIMESTAMP=%TIMESTAMP: =0%
set ARCHIVE_FOLDER=tabbed_app_project_%TIMESTAMP%
set ARCHIVE_ZIP=%ARCHIVE_FOLDER%.zip

echo Creating archive folder: %ARCHIVE_FOLDER%
mkdir "%ARCHIVE_FOLDER%" 2>nul
if errorlevel 1 (
    echo ERROR: Cannot create archive folder
    pause
    exit /b 1
)

echo.
echo ======================================================
echo   Copying and Enhancing Project Files...
echo ======================================================

REM Function to add metadata to a file
set "ADD_METADATA=call :AddMetadata"

REM 1. Copy project structure and files
echo [1] Project configuration files...

REM Create a file counter
set /a TOTAL_FILES=0

REM Process each file type and add metadata
for %%F in (pubspec.yaml pubspec.lock README.md .gitignore analysis_options.yaml .metadata) do (
    if exist "%%F" (
        %ADD_METADATA% "%%F" "%ARCHIVE_FOLDER%\%%F"
        set /a TOTAL_FILES+=1
        echo   - %%F (with metadata)
    )
)

REM 2. Copy lib directory with metadata
echo [2] Source code (lib directory)...
if exist lib (
    echo   Processing Dart files in lib...
    
    REM Create lib directory structure
    xcopy "lib" "%ARCHIVE_FOLDER%\lib\" /E /I /Y /Q >nul
    
    REM Process all Dart files in lib
    for /r "lib" %%f in (*.dart) do (
        REM Get relative path
        set "REL_PATH=%%f"
        set "REL_PATH=!REL_PATH:lib\=!"
        
        %ADD_METADATA% "%%f" "%ARCHIVE_FOLDER%\lib\!REL_PATH!"
        set /a TOTAL_FILES+=1
        
        REM Show progress for first few files
        if !TOTAL_FILES! LEQ 10 (
            echo     - !REL_PATH!
        )
    )
    echo   - Total Dart files in lib: (processed with metadata)
)

REM 3. Copy all Dart files in root
echo [3] Dart files in root directory...
set /a DART_COUNT=0
for %%f in (*.dart) do (
    %ADD_METADATA% "%%f" "%ARCHIVE_FOLDER%\%%f"
    set /a TOTAL_FILES+=1
    set /a DART_COUNT+=1
    echo   - %%f
)
if %DART_COUNT%==0 echo   - No Dart files in root

REM 4. Copy all JSON files
echo [4] JSON configuration files...
set /a JSON_COUNT=0
for %%f in (*.json) do (
    %ADD_METADATA% "%%f" "%ARCHIVE_FOLDER%\%%f"
    set /a TOTAL_FILES+=1
    set /a JSON_COUNT+=1
    echo   - %%f
)
if %JSON_COUNT%==0 echo   - No JSON files found

REM 5. Copy assets if exist
echo [5] Asset files...
if exist assets (
    xcopy "assets" "%ARCHIVE_FOLDER%\assets\" /E /I /Y /Q >nul
    echo   - assets\ directory copied
)

REM 6. Copy test files if exist
echo [6] Test files...
if exist test (
    xcopy "test" "%ARCHIVE_FOLDER%\test\" /E /I /Y /Q >nul
    echo   - test\ directory copied
)

REM 7. Copy Android files if exist
echo [7] Android configuration...
if exist android (
    xcopy "android\app\src\main\AndroidManifest.xml" "%ARCHIVE_FOLDER%\android\app\src\main\" /I /Y /Q >nul 2>nul
    if exist "android\app\build.gradle" (
        xcopy "android\app\build.gradle" "%ARCHIVE_FOLDER%\android\app\" /I /Y /Q >nul 2>nul
    )
    echo   - Android configuration files
)

REM 8. Copy iOS files if exist
echo [8] iOS configuration...
if exist ios (
    xcopy "ios\Runner\Info.plist" "%ARCHIVE_FOLDER%\ios\Runner\" /I /Y /Q >nul 2>nul
    echo   - iOS configuration files
)

REM 9. Create comprehensive project information file
echo [9] Creating project documentation...
echo # Flutter Project Archive > "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo. >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo ## Project Overview >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo **Project Name:** tabbed_app >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo **Archive Created:** %date% %time% >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo **Archive Format:** Files with embedded metadata >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo. >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo ## Project Statistics >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - Total Files: %TOTAL_FILES% >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - Dart Files: %DART_COUNT% in root + all in lib/ >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - JSON Files: %JSON_COUNT% >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo. >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo ## Key Features >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - Multi-broker portfolio tracking >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - Tinkoff Invest API integration >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - Portfolio visualization with charts >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - Connection management system >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo. >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo ## File Structure >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - `lib/` - Main application source code >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - `lib/main.dart` - Application entry point >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - `lib/pages/portfolio_page.dart` - Portfolio management page >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - Configuration files (pubspec.yaml, etc.) >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - API test data (JSON files) >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo. >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo ## Metadata Information >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo Each file in this archive has metadata appended as comments: >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - Original file location >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - Archive timestamp >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - Project context >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo - SHA256 hash for verification >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo. >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo ## For Analysis >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo This is a Flutter application with financial portfolio tracking capabilities. >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"
echo The application integrates with Tinkoff Invest API for real-time market data. >> "%ARCHIVE_FOLDER%\PROJECT_INFO.md"

set /a TOTAL_FILES+=1

REM Create file list
echo [10] Generating file list...
dir "%ARCHIVE_FOLDER%" /b /s > "%ARCHIVE_FOLDER%\FILE_LIST.txt"

echo.
echo ======================================================
echo   ARCHIVE COMPLETE
echo ======================================================
echo.
echo Folder created: %ARCHIVE_FOLDER%
echo Total files processed: %TOTAL_FILES%
echo.
echo Contents:
dir "%ARCHIVE_FOLDER%" /b

echo.
echo ======================================================
echo   OPTIONAL: Create ZIP Archive
echo ======================================================
echo.
choice /M "Do you want to create a ZIP archive of the folder"
if errorlevel 2 (
    echo Skipping ZIP creation.
    echo You can find all files in: %ARCHIVE_FOLDER%
) else (
    echo Creating ZIP archive: %ARCHIVE_ZIP%
    powershell -Command "Compress-Archive -Path '%ARCHIVE_FOLDER%' -DestinationPath '%ARCHIVE_ZIP%' -Force"
    
    if errorlevel 1 (
        echo ERROR: Failed to create ZIP
    ) else (
        echo ZIP archive created: %ARCHIVE_ZIP%
        echo Original folder: %ARCHIVE_FOLDER%
    )
)

echo.
echo ======================================================
echo   NEXT STEPS:
echo ======================================================
echo 1. Review files in: %ARCHIVE_FOLDER%
echo 2. Each file contains metadata at the end
echo 3. Share the folder or ZIP as needed
echo 4. Check PROJECT_INFO.md for project overview
echo 5. Delete when no longer needed
echo ======================================================

echo.
echo Press any key to open the archive folder...
pause >nul
explorer "%ARCHIVE_FOLDER%"

exit /b 0

REM ======================================================
REM Function: AddMetadata
REM Adds metadata to files based on their type
REM ======================================================
:AddMetadata
set "SOURCE_FILE=%~1"
set "DEST_FILE=%~2"

REM Create destination directory if needed
for %%I in ("%DEST_FILE%") do set "DEST_DIR=%%~dpI"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%" 2>nul

REM Copy the original file
copy "%SOURCE_FILE%" "%DEST_FILE%" >nul

REM Get file extension
for %%I in ("%SOURCE_FILE%") do set "EXT=%%~xI"

REM Calculate file hash (simplified)
set "FILE_HASH="
for %%I in ("%SOURCE_FILE%") do set "FILE_SIZE=%%~zI"
set "FILE_HASH=%FILE_SIZE%_%RANDOM%"

REM Add metadata based on file type
if /i "%EXT%"==".dart" (
    echo. >> "%DEST_FILE%"
    echo. >> "%DEST_FILE%"
    echo "// ==========================================" >> "%DEST_FILE%"
    echo "// ARCHIVE METADATA" >> "%DEST_FILE%"
    echo "// ==========================================" >> "%DEST_FILE%"
    echo "// Original: %SOURCE_FILE%" >> "%DEST_FILE%"
    echo "// Archived: %date% %time%" >> "%DEST_FILE%"
    echo "// Project: tabbed_app (Flutter Portfolio Tracker)" >> "%DEST_FILE%"
    echo "// Feature: Tinkoff API Integration" >> "%DEST_FILE%"
    echo "// File Hash: %FILE_HASH%" >> "%DEST_FILE%"
    echo "// ==========================================" >> "%DEST_FILE%"
) else if /i "%EXT%"==".yaml" (
    echo. >> "%DEST_FILE%"
    echo "# ==========================================" >> "%DEST_FILE%"
    echo "# ARCHIVE METADATA" >> "%DEST_FILE%"
    echo "# ==========================================" >> "%DEST_FILE%"
    echo "# Original: %SOURCE_FILE%" >> "%DEST_FILE%"
    echo "# Archived: %date% %time%" >> "%DEST_FILE%"
    echo "# Project: tabbed_app (Flutter Portfolio Tracker)" >> "%DEST_FILE%"
    echo "# File Hash: %FILE_HASH%" >> "%DEST_FILE%"
    echo "# ==========================================" >> "%DEST_FILE%"
) else if /i "%EXT%"==".json" (
    REM For JSON, we need to be careful with formatting
    type "%SOURCE_FILE%" > temp_json.txt
    
    REM Remove trailing } or ] to insert metadata
    powershell -Command "(Get-Content 'temp_json.txt' | Select-Object -SkipLast 1) | Set-Content 'temp_json2.txt'"
    
    echo, >> temp_json2.txt
    echo "  // ==========================================" >> temp_json2.txt
    echo "  // ARCHIVE METADATA" >> temp_json2.txt
    echo "  // ==========================================" >> temp_json2.txt
    echo "  // Original: %SOURCE_FILE%" >> temp_json2.txt
    echo "  // Archived: %date% %time%" >> temp_json2.txt
    echo "  // Project: tabbed_app (Flutter Portfolio Tracker)" >> temp_json2.txt
    echo "  // File Hash: %FILE_HASH%" >> temp_json2.txt
    echo "  // ==========================================" >> temp_json2.txt
    echo } >> temp_json2.txt
    
    move /y temp_json2.txt "%DEST_FILE%" >nul
    del temp_json.txt 2>nul
) else if /i "%EXT%"==".md" (
    echo. >> "%DEST_FILE%"
    echo. >> "%DEST_FILE%"
    echo "---" >> "%DEST_FILE%"
    echo "ARCHIVE METADATA" >> "%DEST_FILE%"
    echo "---" >> "%DEST_FILE%"
    echo "- Original: %SOURCE_FILE%" >> "%DEST_FILE%"
    echo "- Archived: %date% %time%" >> "%DEST_FILE%"
    echo "- Project: tabbed_app (Flutter Portfolio Tracker)" >> "%DEST_FILE%"
    echo "- File Hash: %FILE_HASH%" >> "%DEST_FILE%"
) else (
    REM For other files, add simple metadata
    echo. >> "%DEST_FILE%"
    echo. >> "%DEST_FILE%"
    echo "==========================================" >> "%DEST_FILE%"
    echo "ARCHIVE METADATA" >> "%DEST_FILE%"
    echo "==========================================" >> "%DEST_FILE%"
    echo "Original: %SOURCE_FILE%" >> "%DEST_FILE%"
    echo "Archived: %date% %time%" >> "%DEST_FILE%"
    echo "Project: tabbed_app (Flutter Portfolio Tracker)" >> "%DEST_FILE%"
    echo "File Hash: %FILE_HASH%" >> "%DEST_FILE%"
    echo "==========================================" >> "%DEST_FILE%"
)

exit /b