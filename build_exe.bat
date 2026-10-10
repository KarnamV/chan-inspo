@echo off
rem Rebuilds build\windows\DemonRealmEscape.exe (single file, game data embedded).
rem Needs Godot 4.7 + its export templates (%APPDATA%\Godot\export_templates\4.7.stable).
set GODOT=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe
if not exist build\windows mkdir build\windows
"%GODOT%" --headless --path game --export-release "Windows Desktop" ..\build\windows\DemonRealmEscape.exe
if errorlevel 1 (echo Export failed & exit /b 1)
echo Built build\windows\DemonRealmEscape.exe
