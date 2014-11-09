;Low-level USB routines

DEFAULT_TIMEOUT             EQU    0FFFFh
FRAME_COUNTER_TIMEOUT       EQU    0FFFFh*5

InitializeUSB_Peripheral:
;Initializes the USB controller in peripheral mode.
;Returns carry set if problems
	LogUsbLowEventNull(lidUsbLowInitPeriph)
	;Hold the USB controller in reset
	xor	a
	out	(pUsbSystem), a
	;Disable 48MHz crystal, power down Toshiba PHY,
	; and disable USB suspend interrupt
	ld	a, swDisable48Mhz	; Not: usbSuspendIe swEnableIpClk hwEnable48Mhz hwDisable48MhzEn hwDisable48Mhz swEnablePhyswEnableChgPumpClock
	out	(pUsbSuspendCtrl), a
	;Set D- switches to default
	ld	a, pdConM
	out	(pPuPdCtrl), a
	;Enable the various clocks we need

	call	SetupClocks
	
	;Release USB controller reset and enable protocol interrupts
	ld	a, usbCoreIntrEnable
	out	(pUsbCoreIntrEnable), a
	ld	a, usbReset_
	out	(pUsbSystem), a
	;Wait until IP clock is enabled
	ld	de, DEFAULT_TIMEOUT
@:	call	DecrementCounter
	;TODO: This needs to go to an error routine instead
	scf
	ret	z
	in	a, (pUsbSystem)
	and	~chargePumpClockEnable	;res	6, a ;don't care about charge pump setting
	cp	usbRstO | usbReset_ | ipClockGated	; 1Ah
	jr	nz, {-1@}
	;Enable all pipes for input and output
	ld	a, 0FFh
	out	(pUsbIntrTxMask), a
	xor	a
	out	(pUsbTxCsrCont), a ;not sure what this is or if it's necessary
	ld	a, 1110b ;0Eh
	out	(pUsbIntrRxMask), a
	;Set the protocol interrupt mask, fires when:
	;      Bus is suspended
	;      Bus reset occurs
	ld	a, usbIntrSuspend | usbIntrReset
	out	(pUsbIntrMask), a
	;I don't know for sure, but I think this tells the controller to drive VBus.
;	in	a, (pUsbPower)
;	or	usbPowerEnSuspend
;	out	(pUsbPower), a
	;Enable the bus suspend interrupt
	in	a, (pUsbSuspendCtrl)
	or	usbSuspendIe
	out	(pUsbSuspendCtrl), a

	or	a
	ret
	
	ld	b, FRAME_COUNTER_TIMEOUT / DEFAULT_TIMEOUT
frameCounterLoop:
	; I'm not sure why this waits so long
	ld	de, DEFAULT_TIMEOUT
@:	call	DecrementCounter
	jr	z, counterExpired
	in	a, (pUsbFrame)
	or	a
	jr	z, {-1@}
	or	a
	ret
counterExpired:
	djnz	frameCounterLoop
	;TODO: This needs to go to an error routine instead
	scf
	ret
SetupClocks:

;.ifdef	NEVER
	; Disable the charge pump for peripheral mode
	xor	a
	out	(pVbusCtrl), a
	
	xor	a
	out	(pUsbSuspendCtrl), a
	
	; Wait about 10 ms at 15 MHz
	ld	hl, 5500
@:	dec	hl		; 10 6
	ld	a, l		; 8  4
	or	h		; 8  4
	jr	nz, {-1@}	; 12 12
	
	;Enable 48MHz clock and take Toshiba PHY out of power down mode
	ld	a, swEnablePhy | swEnableIpClk	; 44h
	out	(pUsbSuspendCtrl), a
	
	in	a, (pGpioData)
	and	0F8h
	out	(pGpioData), a
	ret
;.endif

	;Set up internal charge pump
	xor	a
	out	(pVbusCtrl), a
	in	a, (pGpioData)
	and	gpioExtChgPump	;bit	3, a
	jr	z, {1@}
	;We have an external charge pump, so disable the internal one
	ld	a, vbusBypassEn
	out	(pVbusCtrl), a
@:	;Power down Toshiba PHY, disable USB suspend interrupt,
	; and stop master 48MHz disable signal
	xor	a
	out	(pUsbSuspendCtrl), a
	;Wait 10ms for the hardware to deal with that
	ld	b, 1
;	call	WaitTimerBms
	;Enable 48MHz clock and take Toshiba PHY out of power down mode
	in	a, (pGpioData)
	and	gpioExtChgPump	;bit	3, a
	jr	z, {1@}
	;We have an external charge pump, don't enable the internal one
	ld	a, swEnablePhy | swEnableIpClk	; 44h
	out	(pUsbSuspendCtrl), a
@:	;But then we enable it anyway? This might be an OS bug carried over to here.
	ld	a, swEnableChgPumpClock | swEnablePhy | swEnableIpClk	; 0C4h
	out	(pUsbSuspendCtrl), a
	ret

WaitTimerBms:
;Waits B*10 milliseconds
	ld	a, tmr100Hz
	out	(pCrstlTmr3Freq), a
	xor	a
	out	(pCrstlTmr3Cfg), a
	ld	a, b
	out	(pCrstlTmr3Count), a
;@:	in	a, (4)
;	bit	7, a
;	jr	z, {-1@}
@:	in	a, (pIntId)
	and	intOnKeyDown
	jp	z, Quit
	in	a, (pCrstlTmr3Cfg)
	and	tmrLoop
	jr	z, {-1@}
	xor	a
	out	(pCrstlTmr3Cfg), a
	out	(pCrstlTmr3Freq), a
	ret


StallControlPipe:
	LogUsbLowEventNull(lidUsbLowStallControl)
	xor	a
	out	(pUsbIndex), a
	ld	a, csr0SendStall | csr0SvdRxPktRdy	; 60h
	out	(pUsbCsr0),a
	ret

FinishControlRequest:
;Yes, you need the dummy reads. Apparently.
	LogUsbLowEventNull(lidUsbLowFinishControl)
	xor	a
	out	(pUsbIndex), a
	in	a, (pUsbCsr0)
	ld	a, csr0DataEnd | csr0SvdRxPktRdy	; 48h
	out	(pUsbCsr0), a
	in	a, (pUsbCsr0)
	ret

.ifdef	NEVER
;RecycleUSB:
;Disconnects the USB connection and then re-initializes it
;Returns carry set if problems
;This routine can be replaced with an entry point...possibly 5311h (relies on interrupt)
       xor a
       out (5Bh),a
       in a,(4Dh)
       bit 5,a
       jr nz,{1@}
       xor a
       out (4Ch),a
       res 6,(iy+41h)
       jr finishPart1
@:    ld b,8
       in a,(4Dh)
       bit 6,a
       jr nz,{1@}
       ld b,0
@:    ld a,b
       out (4Ch),a
finishPart1:
       ld a,2
       out (54h),a
       ld a,(39h)
       and 0F8h
       out (39h),a
       res 0,(iy+41h)
       in a,(4Dh)
       bit 5,a
       jr nz,finishPart2
       ld de,0FFFFh
@:    dec de
       ld a,d
       or e
       scf
       ret z
       in a,(4Dh)
       bit 7,a
       jr z,{-1@}
       in a,(4Dh)
       bit 0,a
       jr z,{-1@}
       ld a,22h
       out (57h),a
       xor a
       ret
finishPart2:
       in a,(4Dh)
       bit 6,a
       jr nz,{1@}
       xor a
       out (4Ch),a
       ld a,50h
       jr outputPort57h
@:    ld a,93h
outputPort57h:
       out (57h),a
       xor a
       ret
.endif

GetControlPacket:
;Gets B bytes from control pipe to HL
;	in	a, (pUsbControlPipe)
;	ld	(hl), a
;	inc	hl
;	djnz	GetControlPacket
	LogUsbLowEventNull(lidUsbLowGetControl)
	push	bc
	ld	c, pUsbControlPipe
	inir
	pop	bc
	ret

WaitPort82:
;Wait on port 82h to acknowledge transfer
	LogUsbLowEventNull(lidUsbLowWaitPort82)
	in	a, (pUsbIntrTx)
	and	1	; Pipe 0
	jr	z, WaitPort82
	in	a, (pUsbCsr0)
	ret

;SetupOutPipe:
;Sets up outgoing pipe
;Inputs:      A is max packet size / 8
;       out (90h),a
;       ld a,48h
;       out (91h),a
;       xor a
;       out (92h),a
;       ret

;SetupInPipe:
;Sets up incoming pipe
;Inputs:      A is max packet size / 8
;       out (93h),a
;       ld a,90h
;       out (94h),a
;       xor a
;       out (95h),a
;       ret

SendInterruptData:
;Sends B bytes at HL to interrupt pipe C
; This flushes all existing data in the pipe before sending.
; I guess you'll want a routine that polls for the current data being sent
; successfully to avoid missing packets.
; If you're in host mode and using a pipe besides pipe 0 as a control pipe,
; you'll need to change the logic that figures out what value is the flush
; command.
;Returns carry if problems
;       push hl
;       ld hl,USBflag
;       bit driverConfigured,(hl)
;       pop hl
;       scf
;       ret z
	LogUsbLowEvent8(lidUsbLowTx, c)

	in	a, (pUsbTxCsr)
	LogUsbLowEvent8(lidUsbLowTxStatus, a)

	push	ix
	ld	ix, 0
	add	ix, sp
	push	bc	; IX - 2
;	in	a, (8Eh)
;	ld	(ix - 1), a
;	set	indicOnly, (iy + indicFlags)	; I don't know
	ld	a, (ix - 2)
	out	(pUsbIndex), a
	add	a, pUsbPipe
	ld	c, a
	ld	de, 0FFh
@:	call	DecrementCounter
	scf
	jr	z, sendInterruptDataDone
	in	a, (pUsbTxCsr)
	and	txCsrTxPktRdy	; Not the same as csr0TxPktRdy, so this doesn't work for the control pipe
	jr	nz, {-1@}
	ld	a, c
	cp	pUsbControlPipe
	jr	nz, sendInterruptDataNotControlPipe
	ld	a, csr0ContFlushFifo	; Flush pipe
	out	(pUsbCsr0Cont), a
	jr	{@}
sendInterruptDataNotControlPipe:
	ld	a, txCsrFifoFlushFifo	; Flush pipe
	out	(pUsbTxCsr), a
@:;	xor	a	; TODO: This 0 write might not be necessary
;	out	(91h), a
;@:	ld	a, (hl)
;	out	(c), a
;	inc	hl
;	djnz	{-1@}

	in	a, (pUsbTxCsr)
	LogUsbLowEvent8(lidUsbLowTxStatus, a)
	

	ld	b, (ix - 1)
	otir
	ld	a, txCsrTxPktRdy	; Not the same as csr0TxPktRdy, so this doesn't work for the control pipe
	out	(pUsbTxCsr), a
	
	in	a, (pUsbTxCsr)
	LogUsbLowEvent8(lidUsbLowTxStatus, a)
	
	xor	a
sendInterruptDataDone:
;	res	indicOnly, (iy + indicFlags)
;	ld	a, (ix - 1)
;	out	(8Eh), a
	pop	ix
	pop	ix
	ret
DecrementCounter:
	dec	de
	ld	a, d
	or	e
	ret
scfRet:
	scf
	ret




;====== ========================================================================

.ifdef	NEVER
SendBulkData:
;Sends DE bytes at HL to bulk pipe 01
;Duplicates OS functionality
       ld c,01h
SendBulkDataC:
       set 0,(iy+41h)
       res 5,(iy+41h)
       ld a,0
       ld (9C7Dh),a
       ld (9C81h),de
       ld (9C7Eh),hl
       in a,(8Fh)
       bit 2,a
       jr z,{1@}
;       ret
@:    ld a,c
       out (8Eh),a
       ld a,20h
       or c
       out (98h),a
       xor a
       in a,(98h)
       ld a,8
       out (90h),a
       xor a
       in a,(90h)
       ld a,0FFh
       out (87h),a
       xor a
       out (92h),a
       in a,(87h)
       ld a,0A1h
       out (8Bh),a
       in a,(8Bh)
;       in a,(86h)
       jr startSendData
sendDataLoop:
       xor a
       out (5Bh),a
       set 0,(iy+41h)
       ld b,40h
       ld a,c
       add a,0A0h
       ld c,a
@:    call wasteTime
;       bit useExtraRAMPages,(iy+periph8xFlags)
       jr z,useRAM1
;       call getAfromHL_ExtraRAMPage
       jr continueSendLoop1
useRAM1:
       ld a,(hl)
continueSendLoop1:
       out (c),a
       inc hl
       dec de
       djnz {-1@}
       ld a,c
       sub 0A0h
       ld c,a
       out (8Eh),a
       ld a,1
       out (91h),a
;       call DebugStart                          ;*** TESTING
waitLoop1:
       res 0,(iy+43h)
       bit 0,(iy+43h)
       jr z,{1@}
       in a,(91h)
       and 0D9h
       or 8
       out (91h),a
       scf
       ret
@:    call isSendError
       jr nz,scfRet
       push bc
       in a,(82h)
@:    srl a
       dec c
       jr nz,{-1@}
       and 1
       pop bc
       jr z,waitLoop1
;       call DebugStop                           ;*** TESTING
       in a,(91h)
       bit 5,a
       jp nz,scfRet
       ld a,c
       out (8Eh),a
       ld a,8
       out (91h),a
startSendData:
       ld a,d
       or a
       jr nz,sendDataLoop
       ld a,e
       cp 40h
       jr nc,sendDataLoop
       push af
       xor a
       out (5Bh),a
       set 0,(iy+41h)
       pop af
       or a
       jr z,skipWrite
       ld b,a
       ld a,c
       add a,0A0h
       ld c,a
@:    call wasteTime
;       bit useExtraRAMPages,(iy+periph8xFlags)
       jr z,useRAM2
;       call getAfromHL_ExtraRAMPage
       jr continueSendLoop2
useRAM2:
       ld a,(hl)
continueSendLoop2:
       out (c),a
       inc hl
       djnz {-1@}
       ld a,c
       sub 0A0h
       ld c,a
skipWrite:
       ld a,c
       out (8Eh),a
       ld a,1
       out (91h),a
;       call DebugStart                          ;*** TESTING
waitLoop2:
       res 0,(iy+43h)
       bit 0,(iy+43h)
       jr z,{1@}
       in a,(91h)
       and 0D9h
       or 8
       out (91h),a
       scf
       ret
@:    call isSendError
       jp nz,scfRet
       push bc
       in a,(82h)
@:    srl a
       dec c
       jr nz,{-1@}
       and 1
       pop bc
       jr z,waitLoop2
;       call DebugStop                           ;*** TESTING
       in a,(91h)
       bit 5,a
       jp nz,scfRet
       ld a,c
       out (8Eh),a
       ld a,8
       out (91h),a
       ld a,1
       out (5Bh),a
       res 0,(iy+41h)
;       ei
       ret
isSendError:
       in a,(86h)
       bit 5,a
       ret nz
       bit 7,a
       ret
wasteTime:
       nop
       inc hl
       dec hl
       push af
       push af
       pop af
       pop af
       inc hl
       dec hl
       nop
       call scfRet
       ccf
       call scfRet
       ccf
       ret

ReceiveLargeData:
;Receives BC bytes to HL on bulk pipe 02
;Duplicates OS functionality
       ld d,2
ReceiveLargeDataD:
       res 2,(iy+40h)
       res 5,(iy+43h)
       push bc
       push af
       ld (iMathPtr5),hl
       push de
receiveLargeLoop:
;       set 2,(iy+12h)
       res 3,(iy+8)
       push bc
       push hl
       ld hl,40h
       or a
       sbc hl,bc
       pop hl
       ld b,c
       jr nc,{1@}
       ld b,40h
@:    pop hl
       pop af
       push af
       push hl
       ld d,a
       ld hl,(iMathPtr5)
       call ReceiveDataD
       ld (iMathPtr5),hl
       pop hl
;       call initCrystalTimer
       or a
       ld b,0
       sbc hl,bc
       jr z,{1@}
       ld b,h
       ld c,l
       jr receiveLargeLoop
@:    pop de
       pop bc
       pop bc
       ret

ReceiveData:
;Receives B bytes to HL on bulk pipe 02, max size 40h
;Duplicates OS functionality
       ld d,2
ReceiveDataD:
       ld a,b
       or a
       ret z
       ld a,40h
       cp b
       ret c
       jr nz,{1@}
       nop
@:    ld a,b
       ld (9C80h),a
;       ld a,(bytesRemaining)
       or a
       jr z,{1@}
       cp b
       jr nc,{1@}
       ld b,a
       ld (9C80h),a
@:    in a,(8Fh)
       bit 2,a
       jr z,{1@}
       ret
@:    ld a,d
       out (8Eh),a
       in a,(94h)
       bit 6,a
       jr z,{1@}
       and 0DFh
       out (94h),a
       pop af
       scf
       ret
@:    ;ld a,(bytesRemaining)
       or a
       jr nz,{1@}
       in a,(96h)
@:    push af
       ld c,0
receiveLoop:
       ld a,d
       add a,0A0h
       push bc
       ld c,a
       in a,(c)
       pop bc
;       bit 2,(iy+40h)
;       jr nz,receiveToZone1
;receiveToZone1:
;       bit useExtraRAMPages,(iy+periph8xFlags)
       jr z,{1@}
;       call putAtoHL_ExtraRAMPage
       jr continueReceiveLoop
@:    ld (hl),a
continueReceiveLoop:
       inc hl
       inc c
       djnz receiveLoop
       ld a,d
       out (8Eh),a
       pop af
       sub c
;       ld (bytesRemaining),a
       ret nz
       xor a
;       ld (bytesRemaining),a
       in a,(94h)
       and 0FEh
       out (94h),a
       res 5,(iy+41h)
;       ld a,0A1h
       ld a,21h
       out (8Bh),a
       ld a,1
;       out (5Bh),a
       res 0,(iy+41h)
;       ei
       ret

initCrystalTimer:
;Sets up/Resets crystal timer that OS uses for USB stuff
;       di
       xor a
       out (33h),a
       ld a,43h
       out (33h),a
       ld a,3
       out (34h),a
       ld a,(90A8h)
       ld (90AAh),a
       ld a,(90A9h)
       ld (90ABh),a
       or a
       ld a,0FFh
       jr nz,{1@}
       ld a,(90A8h)
@:    out (35h),a
       res 0,(iy+43h)
;       ei
       ret

;initUSBStuff:
;Initializes memory and ports that OS uses for USB stuff
;Duplicates OS functionality
       set 1,(iy+43h)
       res 0,(iy+42h)
       ld hl,8449h
       ld (hl),74h
       res 0,(iy+42h)
       ld de,0FAh
       ld (90A0h),de
       ld (9094h),de
       ld a,14h
       ld (90A8h),a
       xor a
       ld (90A9h),a
       ld a,0
       ld (90A5h),a
       ret

;sendUSBData_BCbytesFromHL:
;Sends BC bytes from HL out bulk pipe 01
;Duplicates OS functionality
       push hl
       push af
       push de
       push bc
       push bc
       pop de
       call SendBulkData
;       res useExtraRAMPages,(iy+periph8xFlags)
       jr c,sendFailed
       xor a
       jr zeroToDEret
sendFailed:
       ld de,0FFFFh
       or 1
       jr saveDEret
zeroToDEret:
       ld de,0
saveDEret:
       ld (90A6h),de
       pop bc
       pop de
       pop hl
       ld a,h
       pop hl
       ret

;receiveAndWriteUSBData:
;Receives BC bytes to HL from bulk pipe 02
;Duplicates OS functionality
       set 2,(iy+40h)
       jr {1@}
receiveAndWriteUSBData_resFlag:
       res 2,(iy+40h)
@:    res 5,(iy+43h)
receiveAndWriteUSBData_sub:
       push bc
       push af
       ld (iMathPtr5),hl
       bit 7,h
       jr nz,receiveUSBDataAndWriteLoop
       xor a
       ld (pagedCount),a
receiveUSBDataAndWriteLoop:
       bit 5,(iy+41h)
       jr nz,doTheRealReceiveAndWrite
       bit 0,(iy+43h)
       jr nz,returnProblemsBCis3
       bit 5,(iy+43h)
       jr z,doNotCheckForKeyLinkActivity
       res 2,(iy+12h)
       set 3,(iy+8)
;       B_CALL HandleLinkActivity
       ld a,(apdTimer)
       cp 1
       jr z,returnProblemsBCis3
doNotCheckForKeyLinkActivity:
       bit 5,(iy+41h)
       jr nz,doTheRealReceiveAndWrite
       push hl
       push bc
       ld hl,error_handler2
       call APP_PUSH_ERRORH
;       call checkForErrBreak
       call APP_POP_ERRORH
tryRecoveringFromError:
       pop bc
       pop hl
       jr receiveUSBDataAndWriteLoop
doTheRealReceiveAndWrite:
;       set 2,(iy+12h)
       res 3,(iy+8)
       bit 7,h
       jr nz,receiveToRAMInstead
receiveToRAMInstead:
       push bc
       push hl
       ld hl,40h
       or a
       sbc hl,bc
       pop hl
       ld b,c
       jr nc,notTooBig
       ld b,40h
notTooBig:
       call ReceiveData
       ex de,hl
       pop hl
       jr c,returnProblems_2
       call initCrystalTimer
       or a
       ld b,0
       sbc hl,bc
       jr z,routineDone
       ld b,h
       ld c,l
       ex de,hl
       jr receiveUSBDataAndWriteLoop
error_handler2:
       set 4,(iy+43h)
       bit 5,(iy+43h)
       jr z,tryRecoveringFromError
       call initCrystalTimer
       ld de,0CCCDh
       ld bc,0FFFEh
       pop hl
       pop hl
       jr problemsReturnNZ
returnProblems:
       pop bc
returnProblems_2:
       ld bc,0FFFFh
       jr problemsReturnNZ
returnProblemsBCis3:
       ld bc,3
problemsReturnNZ:
       or 1
       jr saveBCret
routineDone:
       ld bc,0
saveBCret:
       ld (90A6h),bc
       pop bc
       ld a,b
       pop bc
;       res useExtraRAMPages,(iy+periph8xFlags)
       ret

receiveAndWriteUSBData_fromInt:
       set 2,(iy+40h)
       push bc
       push af
       ld (iMathPtr5),hl
       xor a
       ld (9834h),a
       jr receive_data_ready
receiveAndWriteUSBData_noInt:
       set 2,(iy+40h)
@:    push bc
       push af
       ld (iMathPtr5),hl
       xor a
       ld (9834h),a
receive_noint_loop:
       call doTimerStuff
       bit 0,(iy+43h)
       jr nz,P2scfRet
       bit 5,(iy+41h)
       jr nz,receive_data_ready
       in a,(84h)
       bit 2,a
       jr z,{1@}
       set 5,(iy+41h)
       xor a
;       ld (bytesRemaining),a
       jr receive_data_ready
@:    in a,(86h)
       bit 5,a
       jr nz,P2scfRet
       jr receive_noint_loop
receive_data_ready:
       call initCrystalTimer
       push bc
       push hl
       ld hl,40h
       or a
       sbc hl,bc
       pop hl
       ld b,c
       jr nc,{1@}
       ld b,40h
@:    call ReceiveData
       ex de,hl
       pop hl
       jr c,P2scfRet
       or a
       ld b,0
       sbc hl,bc
       jr z,{1@}
       ld b,h
       ld c,l
       ex de,hl
       jr receive_noint_loop
@:    pop bc
       ld a,b
       pop bc
       ret
P2scfRet:
       pop af
       pop bc
       scf
       ret
doTimerStuff:
       in a,(4)
       and 40h
       ret z
       ld a,1
       out (34h),a
       ld a,(90ABh)
       or a
       jr nz,{1@}
       out (33h),a
       set 0,(iy+43h)
       ret
@:    dec a
       ld (90ABh),a
       or a
       jr z,{1@}
       ret
@:    xor a
       out (33h),a
       ld a,43h
       out (33h),a
       xor a
       out (34h),a
       ld a,(90AAh)
       out (35h),a
       ret
.endif
