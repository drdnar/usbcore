@echo off
echo Assembling . . .
echo.
brass usbhid.asm usbhid.8xp -l usbhid.html
echo .defcont +1>> build_number.asm
rem echo.
rem echo Signing. . . .
rem rabbitsign -g -o usbhid.8ck usbhid.hex
echo.
echo Build complete.
echo.