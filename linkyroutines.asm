;Linky entry points

DisableUSB:
;Disables USB communication.
;Inputs:      None
;Outputs:     None
	;Hold the USB controller in reset and disable interrupts
	LogUsbPhyEventNull(lidUsbPhyDisable)
	xor	a
	out	(pUsbCoreIntrEnable), a
	out	(pUsbSystem), a
	ret


DriverInit:
;Initializes Linky driver.
;Inputs:      B is flags byte:
;             Bit 0: set for "no interrupt" mode.
;Outputs:     Returns carry set if problems
;             A is return data (all zeroes)
	LogUsbPhyEventNull(lidUsbPhyDriverInit)
	push	bc
	call	DisableUSB
	;Install the USB activity hook
;	B_CALL(_GetCurrentPageSub)
;       ld hl,USBactivityHook
;       B_CALL(_EnableUSBHook)
	;Set everything up
	pop	bc
	ld	a, b
	and	1
	ld	(USBFlags), a
	ret


EnableUSB:
;Enables USB communication.
;Inputs:      None
;Outputs:     None
	LogEventNull(lidUsbStart)
	;Hold the USB controller in reset
	xor	a
	out	(pUsbSystem), a
	;Enable protocol interrupts
	ld	a, usbCoreIntrEnable	; But not vscreenIntrEnable
	out	(pUsbCoreIntrEnable), a
	ld	a, 0FFh
	out	(pUsbIntrTxMask), a
	xor	a
	out	(pUsbTxCsrCont), a
	;
	ld	a, vbusRise | vbusFall; | cidRise | cidFall
	out	(pUsbIntrEnable), a
	; TODO: What?
	in	a, (pUsbIntrTxMask)
	ld	a, 0Eh
	out 	(pUsbIntrRxMask), a
	ld	a, 0FFh
	out	(pUsbIntrMask), a
	;Release the controller reset
	call	WaitForControllerReset
	ld	a, usbReset_
	out	(pUsbSystem), a
	xor	a
	ret


SetupPeripheralMode:
;Sets up peripheral mode.
;Inputs:      IX: descriptor table:
;                    DW deviceDescriptorAddress
;                    DB deviceDescriptorPage
;                    DW configDescriptorAddress
;                    DB configDescriptorPage
;                    DW stringDescriptorsTableAddress
;                    DB stringDescriptorsTablePage
;             A: bMaxPacketSize0
;             HL: control request event handler
	ld	(controlRequestHandler), hl
	push	ix
	pop	hl
	ld 	de, deviceDescriptor
	ld	bc, 3*3
	ldir
	ld	(maxPacketSizes),a
	;TODO: Set max packet sizes for each endpoint based on endpoint descriptors
	ret

DriverKill:
;Kills Linky driver.
;Inputs:      None
;Outputs:     Returns carry set if problems
	LogEventNull(lidUsbStop)
	;Disable interrupts, then our hook
	xor	a
	out	(pUsbCoreIntrEnable), a
	res	0, (iy+3Ah)
	;Reset the USB controller
	xor	a
	out	(pUsbSystem), a
	;Re-enable interrupts
	ld	a, usbCoreIntrEnable
	out	(pUsbCoreIntrEnable), a
	;Release controller reset
	call	WaitForControllerReset
	ld	a, usbReset_
	out	(pUsbSystem), a
	xor	a
	ret
ResetController:
	xor	a
	out	(pUsbSystem), a
WaitForControllerReset:
	in	a, (pUsbSystem)
	bit	usbRstOB, a
	jr	z, WaitForControllerReset
	ret

