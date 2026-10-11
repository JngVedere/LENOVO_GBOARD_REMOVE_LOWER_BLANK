@echo off
rem Lenovo Gboard Blank Patcher - command line.
rem usage: patch                         - list modules
rem        patch <module> <action>       - actions are listed in modules\<module>.sh
rem needs: adb in PATH, USB debugging on. No root.
rem prebuilt\patch_<module>_<action>.apk (RRO overlay made by build.ps1) is pushed along if it exists.
setlocal
if "%~1"=="" (for %%f in ("%~dp0modules\*.sh") do @echo %%~nf) & exit /b
if not exist "%~dp0modules\%~1.sh" echo no module: %~1 & exit /b 1
if exist "%~dp0prebuilt\patch_%~1_%~2.apk" adb push -q "%~dp0prebuilt\patch_%~1_%~2.apk" /data/local/tmp/patch_%~1_%~2.apk >nul || exit /b 1
adb push -q "%~dp0overlay.sh" /data/local/tmp/patch_overlay.sh >nul || exit /b 1
adb push -q "%~dp0modules\%~1.sh" /data/local/tmp/patch_%~1.sh >nul || exit /b 1
adb shell sh /data/local/tmp/patch_%~1.sh %2
