ShowLog:
	ld	hl, (logStartAddress)
	ld	(logReadAddress), hl
	ld	a, (logStartPage)
	ld	(logReadPage), a
	ld	hl, (logCount)
	ld	(logReadCount), hl
	call	ClearWind
	ld	(logReadCount), hl
	ld	a, l
	or	h
	jr	nz, showLogPage
	ld	hl, logNoDataMsg
	call	PutS
	call	GetKey
	jp	Restart
logNoDataMsg:
	.db	"No data.", 0
showLogPage:
;	call	HomeUp
;	ld	ixl, 16
showLogLine:
	ld	de, (logReadCount)
	ld	hl, (logCount)
	or	a
	sbc	hl, de
	call	DispHL
	ld	a, ':'
	call	PutC
	ld	a, ' '
	call	PutC
	call	ReadLogByte
	ld	b, a
	call	GetEntryInfo
	call	PutS
	ld	a, c
	or	a
	jr	z, showLogNoData
	ld	b, c
@:	call	ReadLogByte
	call	DispByte
	djnz	{-1@}
showLogNoData:
	call	NewLineClrEOL2
	ld	hl, (logReadCount)
	dec	hl
	ld	(logReadCount), hl
	ld	a, l
	or	h
	jr	z, showLogPageDone
;	dec	ixl
	ld	a, (windTop)
	ld	b, a
	ld	a, (currentRow)
	cp	b
	jr	nz, showLogLine
	jr	{@}
showLogPageDone:
	call	FinishClearWind
@:	call	GetKey
	cp	skClear
	jp	z, Restart
	cp	skEnter
	jr	nz, {-1@}
	ld	hl, (logReadCount)
	ld	a, l
	or	h
	jr	z, {-1@}
	jr	showLogPage


ReadLogByte:
; Reads a byte from the log.
; Inputs:
;  - logReadAddress
;  - logReadPage
; Output:
;  - A: Byte read
; Destroys:
;  - Flags
	push	hl
	push	bc
	ld	hl, (logReadAddress)
	.ifdef	LOG_IN_BANK_B
		in	a, (pMPgB)
	.else
		in	a, (pMPgA)
	.endif
	push	af
	ld	a, (logReadPage)
	.ifdef	LOG_IN_BANK_B
		out	(pMPgB), a
	.else
		out	(pMPgA), a
	.endif	
	ld	b, (hl)
	inc	hl
	.ifdef	LOG_IN_BANK_B
		bit	6, h
	.else
		bit	7, h
	.endif
	jr	z, {@}
	inc	a
	ld	(logReadPage), a
	ld	a, h
	sub	40h
	ld	h, a
@:	ld	(logReadAddress), hl
	pop	af
	.ifdef	LOG_IN_BANK_B
		out	(pMPgB), a
	.else
		out	(pMPgA), a
	.endif
	ld	a, b
	pop	bc
	pop	hl
	ret


GetEntryInfo:
; Inputs:
;  - B: ID number
; Outputs:
;  - HL: Pointer to string
;  - C: Entry length
; Destroys:
;  - AF
;  - B

	ld	hl, LogInfoTable
	xor	a
	cp	b
	jr	z, {2@}
@:	inc	hl
	ld	c, 0FFh
	cpir
;	inc	hl
	djnz	{-1@}
@:	ld	c, (hl)
	inc	hl
	ret
	
	





.deflong LogTableEntry(symbol, datalength, text)
	.echo	"THINGY: ", text, " "
	.db	datalength
	.db	text
	.db	0
	symbol = logIdCurrent
	.echo	logIdCurrent, "\n"
	logIdCurrent = logIdCurrent + 1
.enddeflong

.deflong LogTableUsbIntEntry(symbol, datalength, text)
	.ifdef	LOG_USB_INT
;		LogTableEntry(symbol, datalength, text)
		.db	datalength
		.db	text
		.db	0
		symbol = logIdCurrent
		logIdCurrent = logIdCurrent + 1
	.endif
.enddeflong

.deflong LogTableUsbLowEntry(symbol, datalength, text)
	.ifdef	LOG_USB_LOW
;		LogTableEntry(symbol, datalength, text)
		.db	datalength
		.db	text
		.db	0
		symbol = logIdCurrent
		logIdCurrent = logIdCurrent + 1
	.endif
.enddeflong

.deflong LogTableUsbPhyEntry(symbol, datalength, text)
	.ifdef	LOG_USB_PHY
;		LogTableEntry(symbol, datalength, text)
		.db	datalength
		.db	text
		.db	0
		symbol = logIdCurrent
		logIdCurrent = logIdCurrent + 1
	.endif
.enddeflong

.deflong LogTableUsbProtEntry(symbol, datalength, text)
	.ifdef	LOG_USB_PROT
;		LogTableEntry(symbol, datalength, text)
		.db	datalength
		.db	text
		.db	0
		symbol = logIdCurrent
		logIdCurrent = logIdCurrent + 1
	.endif
.enddeflong


logIdCurrent	.equ	0
LogInfoTable:
log_table_start:
	LogTableEntry(lidUsbStart, 0, "USB start")
	LogTableEntry(lidUsbStop, 0, "USB stop")
	LogTableEntry(lidTest, 1, "test")
	
;	LogTableUsbIntEntry(lidUsbIntSuspend, 0, "INT suspend")
;	LogTableUsbIntEntry(lidUsbInt
	
	
;.ifdef	NEVER
	LogTableUsbIntEntry(lidUsbIntDo, 1, "INT ")
	LogTableUsbIntEntry(lidUsbIntSuspend, 0, "INT suspend")
	LogTableUsbIntEntry(lidUsbIntLine, 1, "INT line ")
	LogTableUsbIntEntry(lidUsbIntProt, 2, "INT prot ")	; high byte is port 86, low is port 8F
	LogTableUsbIntEntry(lidUsbIntBusReset, 0, "INT bus reset")
	LogTableUsbIntEntry(lidUsbIntControlPipe, 1, "INT control pipe ")
	LogTableUsbIntEntry(lidUsbIntStall, 0, "INT control STALL")
	LogTableUsbIntEntry(lidUsbIntNakThingy, 0, "INT control NAK thingy")
	LogTableUsbIntEntry(lidUsbIntSetAddress, 1, "INT set address ")
	LogTableUsbIntEntry(lidUsbIntControlStart, 8, "INT RX CTRL ")
	LogTableUsbIntEntry(lidUsbIntDoControlStall, 0, "INT CTRL do STALL")
	LogTableUsbIntEntry(lidUsbIntSetConf, 1, "INT CTRL set configuration ")
	LogTableUsbIntEntry(lidUsbIntSetAddr, 1, "INT CTRL set addr ")
	LogTableUsbIntEntry(lidUsbIntDevToHost, 1, "INT CTRL dev to host ")
	LogTableUsbIntEntry(lidUsbIntControlReponse, 0, "INT CTRL response start")
	LogTableUsbIntEntry(lidUsbIntControlOutCont, 2, "INT CTRL response cont ")
	LogTableUsbIntEntry(lidUsbIntOutSuccess, 0, "INT outgoing success")
	LogTableUsbIntEntry(lidUsbIntInReady, 0, "INT incoming ready")
	LogTableUsbLowEntry(lidUsbLowInitPeriph, 0, "LOW init peripheral")
	LogTableUsbLowEntry(lidUsbLowStallControl, 0, "LOW CTRL STALL")
	LogTableUsbLowEntry(lidUsbLowFinishControl, 0, "LOW CTRL finish")
	LogTableUsbLowEntry(lidUsbLowGetControl, 0, "LOW get CTRL")
	LogTableUsbLowEntry(lidUsbLowWaitPort82, 0, "LOW wait on port 82h")
	LogTableUsbLowEntry(lidUsbLowTx, 1, "LOW TX packet pipe ")
	LogTableUsbLowEntry(lidUsbLowTxStatus, 1, "LOW TX packet status ")
	LogTableUsbPhyEntry(lidUsbPhyDisable, 0, "PHY disable")
	LogTableUsbPhyEntry(lidUsbPhyDriverInit, 0, "PHY driver init")
	LogTableUsbProtEntry(lidUsbProtKbdCtrlReqClass, 1, "HID class-specific CTRL ")
	LogTableUsbProtEntry(lidUsbProtKbdGetReport, 0, "HID get report")
;.endif
log_table_end:









LoggingTest:
	call	ClearWind
	ld	hl, (logStartAddress)
	call	DispHL
	call	NewLine
logtestloop:
	ld	hl, (logCount)
	call	DispHL
	ld	a, ':'
	call	PutC
	ld	hl, (logAddress)
	call	DispHL
	ld	a, ' '
	call	PutC
	call	GetKey
	cp	sk1
	jr	z, log1
	cp	sk2
	jr	z, log2
	cp	sk3
	jr	z, log3
	cp	skClear
	jp	Restart
log1:
	ld	b, lidUsbStart
	call	LogNull
	jr	logtestloop
log2:
	ld	b, lidUsbStop
	call	LogNull
	jr	logtestloop
log3:
	ld	b, lidTest
	ld	a, r
	ld	e, a
	call	Log8
	jr	logtestloop




ResetLog:
; Inputs:
;  - None
; Outputs:
;  - Log reset
; Destroys:
;  - Everything?
	ld	hl, (logStartAddress)
	ld	(logAddress), hl
	ld	a, (logStartPage)
	ld	(logPage), a
	ld	hl, 0
	ld	(logCount), hl
	ret


LogNull:
; Inputs:
;  - B: Log Event ID
; Destroys:
;  - AF
;  - HL
	in	a, (pMPgA)
	push	af
	ld	a, (logPage)
	out	(pMPgA), a
	ld	hl, (logAddress)
	bit	7, h
	jr	nz, {@}
	ld	(hl), b
	inc	hl
	ld	(logAddress), hl
	ld	hl, (logCount)
	inc	hl
	ld	(logCount), hl
@:	pop	af
	out	(pMPgA), a
	ret


LogByte:
; Inputs:
;  - B: Byte
; Destroys:
;  - AF
;  - HL
	in	a, (pMPgA)
	push	af
	ld	a, (logPage)
	out	(pMPgA), a
	ld	hl, (logAddress)
	bit	7, h
	jr	nz, {@}
	ld	(hl), b
	inc	hl
	ld	(logAddress), hl
@:	pop	af
	out	(pMPgA), a
	ret


Log8:
; Inputs:
;  - B: Log Event ID
;  - E: Code
; Destroys:
;  - AF
;  - HL
	in	a, (pMPgA)
	push	af
	ld	a, (logPage)
	out	(pMPgA), a
	ld	hl, (logAddress)
	bit	7, h
	jr	nz, {@}
	ld	(hl), b
	inc	hl
	ld	(hl), e
	inc	hl
	ld	(logAddress), hl
	ld	hl, (logCount)
	inc	hl
	ld	(logCount), hl
@:	pop	af
	out	(pMPgA), a
	ret


Log16:
; Inputs:
;  - B: Log Event ID
;  - DE: Code
; Destroys:
;  - AF
;  - HL
	in	a, (pMPgA)
	push	af
	ld	a, (logPage)
	out	(pMPgA), a
	ld	hl, (logAddress)
	bit	7, h
	jr	nz, {@}
	ld	(hl), b
	inc	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(logAddress), hl
	ld	hl, (logCount)
	inc	hl
	ld	(logCount), hl
@:	pop	af
	out	(pMPgA), a
	ret


LogTime:
; 45h = LSB
; Destroys:
;  - AF
;  - BC
;  - HL
	in	a, (pMPgA)
	push	af
	ld	a, (logPage)
	out	(pMPgA), a
	ld	hl, (logAddress)
	bit	7, h
	jr	nz, {@}
	ld	bc, (genFastTimer)
	ld	(hl), c
	inc	hl
	ld	(hl), b
	inc	hl
	ld	a, (interruptCounter)
	ld	(hl), a
	ld	(logAddress), hl
@:	pop	af
	out	(pMPgA), a
	ret
