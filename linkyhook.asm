
;USB Activity Hook
;--------------------------------------------------------------------------------------------------
USBactivityHook:
	add	a,e
	push	ix
	call	_USBactivityHook
	pop	ix
	ret
_USBactivityHook:

;	push	bc
;	ld	a, 'U'
;	call	PutC
;	pop	bc
	LogUsbIntEvent8(lidUsbIntDo, c)
	;C contains the value of port 55h XOR'd with 0FFh (USB interrupt status)
	bit 0,c
	jr nz,enteredSuspend
	bit 1,c
	jp nz,dischargeTimeoutOccurred
	bit 2,c
	jp nz,lineInterruptOccurred
	bit 3,c
	jp nz,viewscreenMissedByte
	bit 4,c
	jp nz,HandleProtocolInterrupt
	;Uh...I don't know. Just get out.
	;jp exitUSBHook
	jp	Panic
enteredSuspend:

;	in	a, (pGpioData)
;	and	~gpioBacklightCtrl
;	out	(pGpioData), a
	
;	push	bc
;	ld	a, 'S'
;	call	PutC
;	pop	bc

	LogUsbIntEventNull(lidUsbIntSuspend)

	in	a, (pUsbSuspendCtrl)
	and	~usbSuspendIe
	out	(pUsbSuspendCtrl), a
	or	usbSuspendIe
	out	(pUsbSuspendCtrl), a
;	in	a, (pUsbCoreIntrStatus)
;	and	usbSuspendIntr_
;	call	z, Panic
;	call	DispByte
	ret
	;MUSBFDRC entered USB suspend mode
	;jp exitUSBHook
	call	Panic;jp	Restart
dischargeTimeoutOccurred:

;	in	a, (pGpioData)
;	and	~gpioBacklightCtrl
;	out	(pGpioData), a
	
;	push	bc
;	ld	a, 'D'
;	call	PutC
;	pop	bc


	;Toshiba PHY discharge timeout occurred
	;This is basically an OTG SRP timeout
	;TODO: Make dealing with this configurable? Or something?
	;jp exitUSBHook
	call	Panic;jp	Restart
lineInterruptOccurred:

;	in	a, (pGpioData)
;	and	~gpioBacklightCtrl
;	out	(pGpioData), a
;	or	gpioBacklightCtrl
;	out	(pGpioData), a

;	push	bc
;	ld	a, 'L'
;	call	PutC
;	pop	bc
	
	in a,(56h)
	LogUsbIntEvent8(lidUsbIntLine, a)
HandleLineInterrupt:
       bit 0,a
       jr nz,DPWentLow
       bit 1,a
       jr nz,DPWentHigh
       bit 2,a
       jr nz,DMWentLow
       bit 3,a
       jr nz,DMWentHigh
       bit 4,a
       jr nz,AcablePluggedIn
       bit 5,a
       jr nz,AcableUnplugged
       bit 6,a
       jr nz,BcablePluggedIn
       bit 7,a
       jr nz,BcableUnplugged
       ;Uh...just try to acknowledge it
       ;It shouldn't be possible to get here, but you never know
;       ld b,a
;       in a,(57h)
;       push af
;       ld a,b
;       xor 0FFh
;       out (57h),a
;       pop af
;       out (57h),a
;       jp exitUSBHook
DPWentLow:
       ;D+ went low
       ;Acknowledge interrupt
;       res 0,a
;       out (57h),a
;       jp exitUSBHook
;	ld	a, ~dipFall
;	jp	ackLineInterrupt
DPWentHigh:
       ;D+ went high
       ;Acknowledge interrupt
;       res 1,a
;       out (57h),a
;       jp exitUSBHook
;	ld	a, ~dipRise
;	jp	ackLineInterrupt
DMWentLow:
       ;D- went low
       ;Acknowledge interrupt
;       res 2,a
;       out (57h),a
;       jp exitUSBHook
;	ld	a, ~dimFall
;	jp	ackLineInterrupt
DMWentHigh:
       ;D- went high
       ;Acknowledge interrupt
;       res 3,a
;       out (57h),a
;       jp exitUSBHook
;	ld	a, ~dimRise
;	jp	ackLineInterrupt
	call	Panic
AcablePluggedIn:
       ;Acknowledge interrupt
;       res 4,a
;       out (57h),a
       ;TODO: Do something?
;       jp exitUSBHook
	jp	Restart
AcableUnplugged:
       ;Acknowledge interrupt
;       res 5,a
;       out (57h),a
       ;TODO: Do something?
;       jp exitUSBHook
	ld	c, ~cidRise
	jp	ackLineInterrupt
BcablePluggedIn:
       ;Enable only the B unplug event
       ld a,80h
       out (57h),a
       call InitializeUSB_Peripheral
       jp exitUSBHook
BcableUnplugged:
       ;Acknowledge interrupt
;       res 7,a
	xor	a
       out (57h),a
       ;Disable all protocol interrupts
       xor a
       out (5Bh),a
       ;If VBus isn't powered, hold the controller in reset
       in a,(4Dh)
       bit 6,a
       jr nz,{1@}
       xor a
       out (4Ch),a
@:    ;Disable 48MHz crystal, power down Toshiba PHY,
       ; and disable USB suspend interrupt
       ld a,2
       out (54h),a
       ;Disable GPIO outputs on pins 0-3, which are somehow power-related
       ;The OS does it, so we do it too
       in a,(39h)
       and 0F8h
       out (39h),a
       ;Set new interrupt mask
       ;If VBus is powered, enable A and B plug-in events
       ;If VBus is NOT powered, enable:
       ;      B cable unplug
       ;      A cable plug-in
       ;      D+ line changes
       ;I think the latter half is OTG magic we might not necessarily want.
       in a,(4Dh)
       bit 6,a
       ld a,50h
       jr nz,{1@}
       ld a,93h | 40h
@:    out (57h),a
       jp exitUSBHook
ackLineInterrupt:
	in	a, (pUsbIntrEnable)
	ld	b, a
	and	c
	out	(pUsbIntrEnable), a
	ld	a, b
	out	(pUsbIntrEnable), a
	jp	exitUSBHook
viewscreenMissedByte:
       ;LCD was ready to write a byte but ViewScreen DMA
       ; was still busy writing the previous byte
       ;This means we're sending LCD bytes too fast
       ;You must set bit 2 of port 5Bh to get this event, and
       ; since we don't care, ever, I don't set it.
       ;jp exitUSBHook
       	
;	in	a, (pGpioData)
;	and	~gpioBacklightCtrl
;	out	(pGpioData), a

;	push	bc
;	ld	a, 'v'
;	call	PutC
;	pop	bc


	jp	Panic
HandleProtocolInterrupt:

;	in	a, (pGpioData)
;	and	~gpioBacklightCtrl
;	out	(pGpioData), a

;	push	bc
;	ld	a, 'P'
;	call	PutC
;	pop	bc



       ;Something happened (maybe) in the MUSBFDRC chip
       in a,(86h)
       ld b,a
       in a,(8Fh)
     	.ifdef	LOG_USB_INT
	push	af
	push	bc
	push	de
	push	hl
	ld	d, b
	ld	e, a
	ld	b, lidUsbIntProt
	call	Log16
	pop	hl
	pop	de
	pop	bc
	pop	af
	.endif

       bit 7,a
       jr nz,{1@}
       ;A cable is currently inserted
       ;TODO: Handle these
       ;      bit 6,(86h) is related to HNP
       ;      bit 7,(86h) means insufficient power
@:    in a,(8Fh)
       bit 2,a
       jr z,inPeripheralMode
       ;Host bit is set
       ;TODO: Do something here
       jp exitUSBHook
inPeripheralMode:
       bit 2,b
       jr nz,busResetOccurred
       in a,(82h)
       bit 0,a
       res 0,a
       jp nz,controlPipeEventOccurred
       or a
       jp nz,outgoingDataSuccess
       in a,(84h)
       or a
       jp nz,incomingDataReady
       jp exitUSBHook
busResetOccurred:
       LogUsbIntEventNull(lidUsbIntBusReset)
       ;Enable control pipe for input/output
       in a,(87h)
       or 1
       out (87h),a
       ;Reset stuff
       ld hl,USBFlags
       res sendingControlData,(hl)
       res setAddress,(hl)
       jp exitUSBHook
controlPipeEventOccurred:
       xor a
       out (8Eh),a
       in a,(91h)
       LogUsbIntEvent8(lidUsbIntControlPipe, a)
       bit 2,a
       jr z,{1@}
       ;The control pipe STALLed, so reset the condition and bail out
       and 0FBh
       out (91h),a
       LogUsbIntEventNull(lidUsbIntStall)
       ld hl,USBFlags
       res sendingControlData,(hl)
       jp exitUSBHook
@:    bit 4,a
       jr z,{1@}
       ;The control pipe has NAK'd, so...we set bit 7, whatever that does
       LogUsbIntEventNull(lidUsbIntNakThingy)
       set 7,a
       out (91h),a
@:    ;Now is as good a time as any to continue sending/receiving control data, if we need to
       ld hl,USBFlags
       bit receivingControlData,(hl)
       jp nz,continueControlInput
       bit sendingControlData,(hl)
       jp nz,continueControlOutput
       bit 0,a
       jp nz,{1@}
       ;Apparently, now is when we should actually change the function address, if we need to.
       ld hl,USBFlags
       bit setAddress,(hl)
       jp z,exitUSBHook
       ld a,(USBaddress)
       LogUsbIntEvent8(lidUsbIntSetAddress, a)
       out (80h),a
       jp exitUSBHook
@:    ;We have a control request starting, so receive the 8 bytes to our buffer
       LogUsbIntEventNull(lidUsbIntControlStart)
       ld hl,controlBuffer
       ld b,8
@:    in a,(0A0h)
       ld (hl),a
	.ifdef	LOG_USB_INT
		LogEventByte(a)
	.endif
       inc hl
       djnz {-1@}
       ;Handle the incoming control request
       ld hl,(controlRequestHandler)
       call jpHL
       jp nc,exitUSBHook
       ld a,(controlBuffer)
       bit 7,a
       jp nz,deviceToHostRequestReceived
       ;Host to device request received
       ld a,(controlBuffer+1)
       cp 05h
       jp z,setAddressReceived
       cp 09h
       jr z,setConfigurationReceived
stallControlPipeExitHook:
	LogUsbIntEventNull(lidUsbIntDoControlStall)
       call StallControlPipe
       jp exitUSBHook
setConfigurationReceived:
       ld a,(controlBuffer+2)
       ;A is configuration value
       ;TODO: Do we care?
	LogUsbIntEvent8(lidUsbIntSetConf, a)
       jp finishControlRequestExitHook
setAddressReceived:
       ld a,(controlBuffer+2)
       	LogUsbIntEvent8(lidUsbIntSetAddr, a)
       ld (USBaddress),a
       ld hl,USBFlags
       set setAddress,(hl)
finishControlRequestExitHook:
       call FinishControlRequest
       jp exitUSBHook
deviceToHostRequestReceived:
       ld a,(controlBuffer+1)
       LogUsbIntEvent8(lidUsbIntDevToHost, a)
       cp 06h
       jr z,getDescriptorReceived
       jp stallControlPipeExitHook
getDescriptorReceived:
       ld a,(controlBuffer+3)
       cp 01h
       jr z,getDeviceDescriptorReceived
       cp 02h
       jr z,getConfigDescriptorReceived
       cp 03h
       jr z,getStringDescriptorReceived
       jp stallControlPipeExitHook
getStringDescriptorReceived:
       ld hl,(stringDescriptor)
       ld bc,(stringDescriptorPage-1)
       call GetDescriptorByte
       or a
       jp z,stallControlPipeExitHook
       ld d,a
       call IncBHL
       ld a,(controlBuffer+2)
       ld c,a
@:    call GetDescriptorByte
       cp c
       jr z,{1@}
       call IncBHL
       call GetDescriptorByte
       push de
       ld d,0
       ld e,a
       call BHLPlusDE
       pop de
       dec d
       jr nz,{-1@}
       jp stallControlPipeExitHook
@:    call IncBHL
       call GetDescriptorByte
       ld d,0
       ld e,a
       jr StartControlResponse
getConfigDescriptorReceived:
       ld hl,(configDescriptor)
       ld bc,(configDescriptorPage-1)
       call IncBHL
       call IncBHL
       call GetDescriptorByte
       call IncBHL
       ld e,a
       call GetDescriptorByte
       ld d,a
       ld hl,(configDescriptor)
       ld bc,(configDescriptorPage-1)
       jr StartControlResponse
getDeviceDescriptorReceived:
       ld bc,(deviceDescriptorPage-1)
       ld hl,(deviceDescriptor)
       call GetDescriptorByte
       ld d,0
       ld e,a

StartControlResponse:
; Inputs:
;  - DE: Lenth of data
;  - A: Page
;  - HL: Address
	LogUsbIntEventNull(lidUsbIntControlReponse)
       ld a,d
       or e
       jp z,scrOutputDone
       ;Start this control request response
       ld a,b
       ld (controlDataPage),a
       ld (controlDataAddress),hl
       ld hl,USBFlags
       set sendingControlData,(hl)
       ld hl,(controlBuffer+6)
       or a
       push hl
       sbc hl,de
       pop hl
       jr nc,{1@}
       ld d,h
       ld e,l
@:    ld (controlDataRemaining),de
       xor a
       out (8Eh),a
       ld a,40h
       out (91h),a
continueControlOutput:
       ld de,(controlDataRemaining)
	.ifdef	LOG_USB_INT
	push	af
	push	bc
	push	de
	push	hl
	ld	b, lidUsbIntControlOutCont
	call	Log16
	pop	hl
	pop	de
	pop	bc
	pop	af
	.endif
       ld a,d
       or e
       jp z,scrDone
       ld hl,(maxPacketSizes)
       ld h,0
       or a
       push hl
       sbc hl,de
       pop hl
       jr nc,{1@}
       ld d,h
       ld e,l
@:    ld hl,(controlDataRemaining)
       or a
       sbc hl,de
       ld (controlDataRemaining),hl
       ld hl,(controlDataAddress)
       ;Temporarily swap in correct page
;       bit 7,h
;       jr z,ocoInFlash
       ;We're pointing to 8000h bank; swap in correct RAM page
;       ld a,(controlDataPage)
;       set 7,a
;       out (7),a
ocoInRAMLoop:
       ld a,(hl)
       out (0A0h),a
       inc hl
;       bit 6,h
;       jr z,{1@}
;       res 6,h
;       ld a,(controlDataPage)
;       inc a
;       ld (controlDataPage),a
;       set 7,a
;       out (7),a
@:    dec de
       ld a,d
       or e
       jr nz,ocoInRAMLoop
       jr ocoContinue
;ocoInFlash:
;       ld a,(controlDataPage)
;       call OutputPageBank3
;       set 7,h
;       res 6,h
;ocoInFlashLoop:
;       ld a,(hl)
;       out (0A0h),a
;       inc hl
;       bit 6,h
;       jr z,{1@}
;       ld a,(controlDataPage)
;       inc a
;       ld (controlDataPage),a
;       call OutputPageBank3
;       res 6,h
;@:    dec de
;       ld a,d
;       or e
;       jr nz,ocoInFlashLoop
;       res 7,h
;       set 6,h
ocoContinue:
;       ld a,81h
;       out (7),a
       ld (controlDataAddress),hl
       ld hl,(controlDataRemaining)
       ld a,h
       or l
       jr z,scrOutputDone
       xor a
       out (8Eh),a
       ld a,2
       out (91h),a
       jp exitUSBHook
scrOutputDone:
       xor a
       out (8Eh),a
       ld a,0Ah
       out (91h),a
       ;Apparently we either don't get a confirmation for the above,
       ; or we don't care, so go ahead and reset our flag.
       ld hl,USBFlags
       res sendingControlData,(hl)
       jp exitUSBHook
scrDone:
       ld hl,USBFlags
       res sendingControlData,(hl)
       jp exitUSBHook
StartControlInput:
       ld a,d
       or e
       jp z,finishControlRequestExitHook
       ;Start receiving the data for this control request
       ld a,b
       ld (controlDataPage),a
       ld (controlDataAddress),hl
       ld (controlDataRemaining),de
       ld hl,USBFlags
       set receivingControlData,(hl)
       res sendingControlData,(hl)
       xor a
       out (8Eh),a
       ld a,40h
       out (91h),a
       jp exitUSBHook
continueControlInput:
       ld de,(controlDataRemaining)
       ld a,d
       or e
       jr z,sciDone
       ld hl,(maxPacketSizes)
       ld h,0
       or a
       push hl
       sbc hl,de
       pop hl
       jr nc,{1@}
       ld d,h
       ld e,l
@:    ld hl,(controlDataRemaining)
       or a
       sbc hl,de
       ld (controlDataRemaining),hl
       ld hl,(controlDataAddress)
       ;Temporarily swap in correct page
;       ld a,(controlDataPage)
;       set 7,a
;       out (7),a
ociInRAMLoop:
       in a,(0A0h)
       ld (hl),a
       inc hl
;       bit 6,h
;       jr z,{1@}
;       res 6,h
;       ld a,(controlDataPage)
;       inc a
;       ld (controlDataPage),a
;       set 7,a
;       out (7),a
@:    dec de
       ld a,d
       or e
       jr nz,ociInRAMLoop
;       ld a,81h
;       out (7),a
       ld (controlDataAddress),hl
       ld hl,(controlDataRemaining)
       ld a,h
       or l
       jp z,finishControlRequestExitHook
       xor a
       out (8Eh),a
       ld a,40h
       out (91h),a
       jp exitUSBHook
sciDone:
       ld hl,USBFlags
       res receivingControlData,(hl)
       jp exitUSBHook
outgoingDataSuccess:
	LogUsbIntEventNull(lidUsbIntOutSuccess)
       ;TODO: Deal with this
       jr exitUSBHook
incomingDataReady:
	LogUsbIntEventNull(lidUsbIntInReady)
       ;TODO: Deal with this
       jr exitUSBHook
exitUSBHook:
	ld b,0
	ret
jpHL:  jp (hl)
;OutputPageBank3:
;       bit 7,a
;       res 7,a
;       out (7),a
;       ld a,0
;       jr z,{1@}
;       inc a
;@:    out (0Fh),a
;       ret
GetDescriptorByte:
       push bc
;       bit 7,h
;       jr z,gdbInFlash
;       ld a,b
;       set 7,a
;       out (7),a
       ld b,(hl)
;       ld a,81h
;       out (7),a
       ld a,b
       pop bc
       ret
;gdbInFlash:
;       set 7,h
;       res 6,h
;       ld a,b
;       call OutputPageBank3
;       ld b,(hl)
;       ld a,81h
;       out (7),a
;       res 7,h
;       set 6,h
;       ld a,b
;       pop bc
;       ret
IncBHL:
;       bit 7,h
;       jr z,{1@}
       inc hl
;       bit 6,h
;       ret z
;       res 6,h
;       inc b
       ret
;@:    inc hl
;       bit 7,h
;       ret z
;       res 7,h
;       set 6,h
;       inc b
;       ret
BHLPlusDE:
;       bit 7,h
;       jr z,{1@}
       add hl,de
;       bit 6,h
;       ret z
;       res 6,h
;       inc b
       ret
;@:    add hl,de
;       bit 7,h
;       ret z
;       res 7,h
;       set 6,h
;       inc b
;       ret

