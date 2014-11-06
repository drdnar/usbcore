@echo off
echo Assembling . . .
echo.
brass usbtest.asm usbtest.8xp -l usbtest.html
echo .defcont +1>> build_number.asm
rem echo.
rem echo Signing. . . .
rem rabbitsign -g -o usbtest.8ck usbtest.hex
echo.
echo Build complete.
echo.