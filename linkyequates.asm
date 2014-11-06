;Safe RAM
;safeRAM              EQU    tempSwapArea
;lwrCaseFlag          EQU    safeRAM+0            ;1
;menuAddr             EQU    lwrCaseFlag+1        ;2
;numChoices           EQU    menuAddr+2           ;1
;TempNum              EQU    numChoices+1         ;2

controlBuffer               EQU    9F0Ah ;8
controlDataAddress          EQU    9F12h ;2
controlDataRemaining        EQU    controlDataAddress+2        ;2
maxPacketSizes              EQU    controlDataRemaining+2      ;16
deviceDescriptor            EQU    maxPacketSizes+16           ;2
deviceDescriptorPage        EQU    deviceDescriptor+2          ;1
configDescriptor            EQU    deviceDescriptorPage+1      ;2
configDescriptorPage        EQU    configDescriptor+2          ;1
stringDescriptor            EQU    configDescriptorPage+1      ;2
stringDescriptorPage        EQU    stringDescriptor+2          ;1
controlRequestHandler       EQU    stringDescriptorPage+1      ;2
controlDataPage             EQU    controlRequestHandler+2     ;1

USBaddress           EQU    9F52h ;1
USBFlags             EQU    9F56h ;1
noInterruptMode      EQU    0
sendingControlData   EQU    1
setAddress           EQU    2
receivingControlData EQU    3

errEPIndex           EQU 1
