
.deflong LogTableEntry(symbol, datalength, text)
	.echo	"THINGY: ", text, " "
	.db	datalength
	.db	text
	.db	0
	symbol .equ logIdCurrent
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

.deflong LogTableUsbQueueEntry(symbol, datalength, text)
	.ifdef	LOG_USB_QUEUE
;		LogTableEntry(symbol, datalength, text)
		.db	datalength
		.db	text
		.db	0
		symbol = logIdCurrent
		logIdCurrent = logIdCurrent + 1
	.endif
.enddeflong


.echo	"\n{"
.echo	lidUsbStart, ", "
.echo	lidUsbStop, ", "
.echo	lidTest, ", "
.echo	lidTest2, "}\n"


logIdCurrent	.equ	0
LogInfoTable:
log_table_start:
	LogTableEntry(lidUsbStart, 0, "USB start")
	LogTableEntry(lidUsbStop, 0, "USB stop")
	LogTableEntry(lidTest, 1, "test: ")
	LogTableEntry(lidTest2, 2, "test2: ")
	
.echo	"\n{"
.echo	lidUsbStart, ", "
.echo	lidUsbStop, ", "
.echo	lidTest, ", "
.echo	lidTest2, "}\n"
	
;	LogTableUsbIntEntry(lidUsbIntSuspend, 0, "INT suspend")
;	LogTableUsbIntEntry(lidUsbInt
	
	LogTableUsbIntEntry(lidUsbIntDo, 1, "INT ")
	LogTableUsbIntEntry(lidUsbIntSuspend, 0, "INT suspend")
	LogTableUsbIntEntry(lidUsbIntVScreen, 0, "INT ViewScreen")
	LogTableUsbIntEntry(lidUsbIntVBusTimeout, 0, "INT v-bus timeout")
	LogTableUsbIntEntry(lidUsbIntLine, 1, "INT LINE ")
	LogTableUsbIntEntry(lidUsbIntLineBDisconnect, 0, "INT LINE B disconnect")
	LogTableUsbIntEntry(lidUsbIntLineBConnect, 0, "INT LINE B connect")
	LogTableUsbIntEntry(lidUsbIntLineAConnect, 0, "INT LINE A connect")
	LogTableUsbIntEntry(lidUsbIntLineADisconnect, 0, "INT LINE A disconnect")
	LogTableUsbIntEntry(lidUsbIntProt, 1, "INT PROT ")
	LogTableUsbIntEntry(lidUsbIntTxComplete, 1, "INT TX complete")
	LogTableUsbIntEntry(lidUsbIntRxComplete, 1, "INT RX complete")
	LogTableUsbQueueEntry(lidUsbQueueProcessEvents, 0, "INT QUEUE start")
	LogTableUsbQueueEntry(lidUsbQueueProcessEvent, 2, "INT DEQUEUE call back: ")
	LogTableUsbQueueEntry(lidUsbQueueProcessEventsDone, 0, "INT DEQUEUE stop")
	
.ifdef	NEVER
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
.endif
log_table_end:





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
	
	

LogItem:
	; RET ADDR	; ix + 13, 12
	push	iy	; ix + 11, 10
	push	ix	; ix + 9, 8
	push	hl	; ix + 7, 6
	push	de	; ix + 5, 4
	push	bc	; ix + 3, 2
	push	af	; ix + 1, 0
	ld	ix, 0
	add	ix, sp
	ld	l, (ix + 12)
	ld	h, (ix + 13)
	ld	b, (hl)
	inc	hl
	ld	c, (hl)
	inc	hl
	ld	(ix + 12), l
	ld	(ix + 13), h
	call	LogByte
	ld	a, c
	or	a
	jr	z, {@}
	res	7, c
	ld	b, 0
	add	ix, bc
	ld	b, (ix)
	push	af
	call	LogByte
	pop	af
	and	80h
	jr	z, {@}
	inc	ix
	ld	b, (ix)
	call	LogByte
@:	ld	hl, (logCount)
	inc	hl
	ld	(logCount), hl
	pop	af
	pop	bc
	pop	de
	pop	hl
	pop	ix
	pop	iy
	ret






dumpLog:
	ld	ix, (logStartAddress)
	ld	c, 24
	in	a, (pMPgA)
	push	af
	ld	a, (logPage)
	out	(pMPgA), a
	call	ShowHexDump
	pop	af
	out	(pMPgA), a
	call	GetKey
	jp	Restart


.ifdef	NEVER
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
	cp	sk4
	jr	z, log4
	cp	skClear
	jp	Restart
log1:
	ld	b, lidUsbStart
	call	LogNull
	jr	logtestloop
log2:
.echo	"\n\n<", lidUsbStop, ">\n\n"
	ld	b, lidUsbStop
	call	LogNull
	jr	logtestloop
log3:
	ld	b, lidTest
	ld	a, r
	ld	e, a
	call	Log8
	jr	logtestloop
log4:
	LogEvent(lidUsbStop, logNoReg)
	ld	a, 11h
	LogEvent(lidTest, logRegA)
	ld	b, 22h
	LogEvent(lidTest, logRegB)
	ld	c, 33h
	LogEvent(lidTest, logRegC)
	ld	d, 44h
	LogEvent(lidTest, logRegD)
	ld	e, 55h
	LogEvent(lidTest, logRegE)
	ld	h, 66h
	LogEvent(lidTest, logRegH)
	ld	l, 77h
	LogEvent(lidTest, logRegL)
	ld	ixh, 88h
	LogEvent(lidTest, logRegIXH)
	ld	ixl, 99h
	LogEvent(lidTest, logRegIXL)
	ld	bc, 0102h
	LogEvent(lidTest2, logRegBC)
	ld	de, 0304h
	LogEvent(lidTest2, logRegDE)
	ld	hl, 0506h
	LogEvent(lidTest2, logRegHL)
	ld	ix, 0708h
	LogEvent(lidTest2, logRegIX)
	jp	logtestloop
.endif

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
