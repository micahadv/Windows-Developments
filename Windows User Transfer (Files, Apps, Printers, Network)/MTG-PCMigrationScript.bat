
@echo off

REM May not be required. Subject to removal 
for /f "tokens=1-7 delims=:/-, " %%i in ('echo exit^|cmd /q /k"prompt $d $t"') do (
   for /f "tokens=2-4 delims=/-,() skip=1" %%a in ('echo.^|date') do (
      set dow=%%i
      set %%a=%%j
      set %%b=%%k
      set %%c=%%l
      set hh=%%m
      set min=%%n
      set ss=%%o
   )
)


echo.
echo Today is %dow% %yy%-%mm%-%dd% @ %hh%:%min%:%ss%

echo.

set timeStamp=%yy%-%mm%-%dd%

:----------------------------------------
echo.
echo Are you ready to begin the backup process? [y] or [n]
set /p web=Type option:
if "%web%"=="y" goto home
if "%web%"=="ye" goto home
if "%web%"=="yes" goto home
if "%web%"=="n" exit
if "%web%"=="no" exit
if "%web%"=="x" exit
pause


:home

SET /P identiKey=First step, what is the user account of the user you are backing up?: %=%

echo You said %identiKey%
echo Is this what you meant? [y] [n] or [x] for Exit
set /p web=Type option:
if "%web%"=="y" goto B-ROption
if "%web%"=="n" goto home
if "%web%"=="x" exit
pause



:B-ROption
echo Is this Local PC the New or Old PC? [new] [old] or [x] for Exit
set /p web=Type option:
if "%web%"=="new" goto NewPC-step1
if "%web%"=="n" goto NewPC-step1
if "%web%"=="old" goto OldPC-step1
if "%web%"=="o" goto OldPC-step1
if "%web%"=="x" exit
pause



:NewPC-step1
net share MTGTransfer=C:\Users /GRANT:%identiKey%,FULL

set host=%COMPUTERNAME%
set ip=ipconfig | find /i "IPv4"

echo This PC is ready for Restore. Please enter %host% for the target PC name on Old PC script. Please wait while the old PC completes. 
pause


echo If the Tansfer has completed on the Old PC, You can now Import Map Network Drives and Printers for you.
echo Would you like me to import those items at this time? [y] [n] or [x] for Exit
set /p web=Type option:
if "%web%"=="y" goto NewPC-step2
if "%web%"=="n" goto Finished
if "%web%"=="x" exit
pause

:NewPC-step2

REM Import Map File Drive
REG Import C:\Users\%identiKey%\MTGTransfer-Logs-Files\OldPCMapDriveShares.REG

REM Import Printers
c:\windows\system32\spool\tools\printBrm.exe -r -f C:\Users\%identiKey%\MTGTransfer-Logs-Files\OldPC-Printers.printer_export -o force


:OldPC-step1

set host=%COMPUTERNAME%
echo The computer is named %host%.

echo I will now open up that user's profile folder.
pause
explorer %SystemDrive%\users\%identiKey%

echo Make sure you have permission to view and browse the folder.
echo It's the only way this script will back up properly.
echo If you are currently logged in as that user, open documents may have errors when copying over.

echo.
echo.
SET /P backUP=What is the IP - OR - Hostname of the New MTG PC?: %=%

echo You said %backUP%
echo Is this what you meant? [y] [n] or [x] for Exit
set /p web=Type option:
if "%web%"=="y" goto OldPC-step2
if "%web%"=="n" goto OldPC-step1
if "%web%"=="x" exit
pause


:OldPC-step2
echo.
echo.
echo We are Robocopying to \\%backUP%\Users\%identiKey%
echo.

set /p web=Proceed? y [proceed] n [start over] x [exit]:
if "%web%"=="y" goto OldPC-step3
if "%web%"=="n" goto OldPC-step1
if "%web%"=="x" exit


:OldPC-step3

if not exist "\\%backUP%\MTGTransfer\%identiKey%" mkdir "\\%backUP%\MTGTransfer\%identiKey%"

if not exist "\\%backUP%\MTGTransfer\%identiKey%\MTGTransfer-Logs-Files" mkdir "\\%backUP%\MTGTransfer\%identiKey%\MTGTransfer-Logs-Files"


echo At any time, if you want to stop this backup process, hit Ctrl-C.
echo Backing up your main profile
Robocopy.exe "%SystemDrive%\users\%identiKey%" "\\%backUP%\MTGTransfer\%identiKey%" /E /XJ /XO /XA:SH /S /Z /R:1 /W:1 /MT:32 /V /XD "%SystemDrive%\Users\%identiKey%\Google Drive" /XD "%SystemDrive%\users\%identiKey%\AppData" /XD "%SystemDrive%\Users\%identiKey%\OneDrive" /XD "%SystemDrive%\Users\%identiKey%\OneDrive" /XD "%SystemDrive%\Users\%identiKey%\Dropbox" /XD "%SystemDrive%\Users\%identiKey%\SpiderOak" /XD "%SystemDrive%\Users\%identiKey%\Box" /LOG+:"\\%backUP%\MTGTransfer\MTGTransfer-Logs-Files\%timeStamp%_BackupLog.txt"

echo At any time, if you want to stop this backup process, hit Ctrl-C.
echo Backing up your main profile (one last time around to refresh the log file and catch any other changes)
Robocopy.exe "%SystemDrive%\users\%identiKey%" "\\%backUP%\MTGTransfer\%identiKey%" /E /XJ /XO /XA:SH /XD "%SystemDrive%\users\%identiKey%\AppData" /XD "%SystemDrive%\Users\%identiKey%\Google Drive" /XD "%SystemDrive%\Users\identiKey%\OneDrive" /XD "%SystemDrive%\Users\%identiKey%\Google Drive" /XD "%SystemDrive%\Users\%identiKey%\ODBA" /XD "%SystemDrive%\Users\%identiKey%\OneDrive" /XD "%SystemDrive%\Users\%identiKey%\Dropbox" /S /Z /R:1 /W:1 /MT:32 /V  /LOG+:"\\%backUP%\MTGTransfer\MTGTransfer-Logs-Files\%timeStamp%_BackupLog.txt"




echo Would you like to export Printers, Map Drives, Apps List, and PC Specs? (You prob should) [y] [n] or [x] for Exit
set /p web=Type option:
if "%web%"=="y" goto OldPC-step4
if "%web%"=="n" goto Finished
if "%web%"=="x" exit

:OldPC-step4
REM Installed Apps List
wmic /output:"\\%backUP%\MTGTransfer\%identiKey%\MTGTransfer-Logs-Files\OldPC-InstalledApps.txt" product get name,version
echo File saved to \\%backUP%\MTGTransfer\%identiKey%\MTGTransfer-Logs-Files\ - OldPC-InstalledApps.txt

REM Map Drive reg file
reg export "HKEY_CURRENT_USER\Network" "\\%backUP%\MTGTransfer\%identiKey%\MTGTransfer-Logs-Files\OldPCMapDriveShares.REG"
echo Completed Map Drive Export to \\%backUP%\MTGTransfer\%identiKey%\MTGTransfer-Logs-Files\ - OldPCMapDriveShares.REG

REM Printer File 
C:\windows\system32\spool\tools\printBrm.exe -b -f C:\OldPC-Printers.printer_export -o force
move C:\OldPC-Printers.printer_export \\%backUP%\MTGTransfer\%identiKey%\MTGTransfer-Logs-Files\
echo Printer file exported to \\%backUP%\MTGTransfer\%identiKey%\MTGTransfer-Logs-Files\ - OldPC-Printers.printer_export

REM System Information File
systeminfo.exe > "\\%backUP%\MTGTransfer\%identiKey%\MTGTransfer-Logs-Files\OldPC-Specs.txt"
echo Old PC specs file exported to \\%backUP%- OldPC-Specs.txt


:Finished
echo Aaaand we're done!

pause
