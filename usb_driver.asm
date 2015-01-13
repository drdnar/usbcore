.define	USB_CORE_DRIVER
.module Usb
; Global data:
;  - Flags
;     - Device started (has address)
;     - USB suspended
;     - A cable connected error
;     - Set address pending
;     - Master error
;  - Enabled pipes map
;     - This is simply implied by various factors, namely the number of pipes
;       with interrupts enabled, and also by the number of pipes you create
;       variables for.
;  - There's a count for the number of enabled pipes, though it requires them
;    to be consecutive.
;  - Set address temp
;  - Descriptors tables ptr
;  - Global event call back
;     - Device start
;     - Device stop (B cable disconnect)
;     - Bus suspend
;     - Bus resume
;  - TX pipes variables array
;  - RX pipes variables array
;
; Pipe array:
;  - Flags
;     - Automatic buffering flag/buffer data ready to send flag
;        - If set for TX pipe, driver will automatically break send data up
;          into packets as needed, and send packets until buffer is empty
;           - Must call send packet function to start TX
;        - If set for RX pipe, driver will automatically combine received
;          packets.  Depending on flag, may call call back after every packet.
;     - TX/RX active flag
;        - If autobuffer, set after buffer is full/empty
;        - If not, set after every packet TX/RX complete
;  - Packet TX/TX callback
;     - If automatic buffering enabled, called after buffer is empty/full
;     - If no automatic buffering, called after TX/RX completes
;  - Buffer ptr
;  - Buffer size
;  - Buffer read ptr
;  - Buffer write ptr
;

; So this is how your peripheral-mode driver will work:
;  - Call the initialize routine to place the driver into peripheral mode
;     - This routine will set up interrupts, enable controller, set up descriptor vectors
;  - When a B-style cable is connected,
;     - The driver will call the device start callback after address is set
;     - The driver will emit descriptors as needed
;     - When the host has configured the calculator, usbPeripheralConfigured will be set
;  - You can start sending data once you get a request for it.
;  - Event call backs are called as part of ISR, but they're deferred until the
;    interrupt has been acknowledged, and interrupts are re-enabled before your
;    call back is called, so interrupts will continue processing normally.
;    AF, BC, DE, HL, and IX are save and restored; the shadow registers and IY
;    are not.
;    The driver guarantees it will call call backs in order, and that if another
;    USB interrupt occurs, any call back will not be called until the current
;    one is finished processing.  About 10 events can be queued at a time, after
;    which the driver will probably crash, or at least lose events.

; USB events

;===============================================================================
;====== USB Event Queueing Subsystem ===========================================
;===============================================================================
; Some USB events may take a while to process.  Additionally, some USB ports can
; indicate multiple events, but reading one ACKS all.  So it is useful to queue
; USB events to prevent events from being lost.
;
; Re-entrancy & mutual exclusion:
;  - The writers of the queue are mutually exclusive because they are only
;    only called during the ISR while interrupts are disabled.
;  - The reader is mutually exclusive because of the interrupt recuse flag,
;    which also ensures that each call back completes before the next starts.

;------ QueueUsbByteA ----------------------------------------------------------
_QueueUsbByteA:
; Queues a byte into the USB event queue.
; Input:
;  - A: Byte to enqueue
; Outputs:
;  - Byte queued
; Destroys:
;  - HL
;  - BC
	ld	hl, (usbEvQWritePtr)
.ifdef	DEBUG
	ld	bc, (usbEvQReadPtr)
	cphlbc
	call	z, Panic
.endif
	ld	(hl), a
	inc	hl
	ld	bc, usbEvQueueEnd
	cphlbc
	jr	c, {@}
	ld	hl, usbEvQueue
@:	ld	(usbEvQWritePtr), hl
	ret


;------ QueueUsbByte -----------------------------------------------------------
_QueueUsbByte:
; Queues a byte into the USB event queue.
; Input:
;  - E: Byte to enqueue
; Outputs:
;  - Byte queued
; Destroys:
;  - HL
;  - BC
	ld	hl, (usbEvQWritePtr)
.ifdef	DEBUG
	ld	bc, (usbEvQReadPtr)
	cphlbc
	call	z, Panic
.endif
	ld	(hl), e
	inc	hl
	ld	bc, usbEvQueueEnd
	cphlbc
	jr	c, {@}
	ld	hl, usbEvQueue
@:	ld	(usbEvQWritePtr), hl
	ret


;------ QueueUsbWord -----------------------------------------------------------
_QueueUsbWord:
; Queues a word into the USB event queue.
; Input:
;  - DE: Word to enqueue
; Outputs:
;  - Word queued
; Destroys:
;  - HL
;  - BC
	ld	hl, (usbEvQWritePtr)
.ifdef	DEBUG
	ld	bc, (usbEvQReadPtr)
	cphlbc
	call	z, Panic
	inc	hl
	cphlbc
	call	z, Panic
.endif
	ld	(hl), e
	inc	hl
	ld	bc, usbEvQueueEnd
	cphlbc
	jr	c, {@}
	ld	hl, usbEvQueue
@:	ld	(hl), d
	cphlbc
	jr	c, {@}
	ld	hl, usbEvQueue
@:	ld	(usbEvQWritePtr), hl
	ret


;------ DequeueUsbByteA --------------------------------------------------------
_DequeueUsbByteA:
; Dequeues a byte from the USB event queue.
; Inputs:
;  - None
; Outputs:
;  - A: Byte dequeued
;  - Z if no data
; Destroys:
;  - HL
;  - DE
	ld	hl, (usbEvQReadPtr)
	ld	de, (usbEvQWritePtr)
	cphlde
	ret	z
	ld	a, (hl)
	inc	hl
	ld	de, usbEvQueueEnd
	cphlde
	jr	c, {@}
	ld	hl, usbEvQueue
@:	ld	(usbEvQReadPtr), hl
	inc	h	; Force NZ.  Don't place the queue in the top 256 bytes of address space.
	ret


;------ DequeueUsbByte ---------------------------------------------------------
_DequeueUsbByte:
; Dequeues a byte from the USB event queue.
; Inputs:
;  - None
; Outputs:
;  - E: Byte dequeued
;  - Z if no data
; Destroys:
;  - HL
;  - BC
	ld	hl, (usbEvQReadPtr)
	ld	bc, (usbEvQWritePtr)
	cphlbc
	ret	z
	ld	e, (hl)
	inc	hl
	ld	bc, usbEvQueueEnd
	cphlbc
	jr	c, {@}
	ld	hl, usbEvQueue
@:	ld	(usbEvQReadPtr), hl
	inc	h	; Force NZ.  Don't place the queue in the top 256 bytes of address space.
	ret


;------ DequeueUsbWord ---------------------------------------------------------
_DequeueUsbWord:
; Dequeues a word from the USB event queue.
; Inputs:
;  - None
; Outputs:
;  - DE: Word dequeued
;  - Z if no data
; Destroys:
;  - HL
;  - BC
	ld	hl, (usbEvQReadPtr)
	ld	bc, (usbEvQWritePtr)
	cphlbc
	ret	z
	ld	e, (hl)
	inc	hl
	ld	bc, usbEvQueueEnd
	cphlbc
	jr	c, {@}
	ld	hl, usbEvQueue
@:	ld	d, (hl)
	cphlbc
	jr	c, {@}
	ld	hl, usbEvQueue
@:	ld	(usbEvQReadPtr), hl
	inc	h	; Force NZ.  Don't place the queue in the top 256 bytes of address space.
	ret


;------ QueueUsbEventWord ------------------------------------------------------
_QueueUsbEventWord:
; Queues a USB event, and then goes on to processing pending events.
; Inputs:
;  - DE: Event processing call back address
;  - HL: Argument word
	push	hl
	call	_QueueUsbWord
	pop	de
	jr	_QueueUsbEventNull


;------ QueueUsbEventByte ------------------------------------------------------
_QueueUsbEventByte:
; Queues a USB event, and then goes on to processing pending events.
; Inputs:
;  - DE: Event processing call back address
;  - A: Argument byte
	call	_QueueUsbWord
	call	_QueueUsbByteA
	jr	_ProcessUsbEvents


;------ QueueUsbEventNull ------------------------------------------------------
_QueueUsbEventNull:
; Queues a USB event, and then goes on to processing pending events.
; Input:
;  - DE: Event processing call back address
	call	_QueueUsbWord


;------ ProcessUsbEvents -------------------------------------------------------
_ProcessUsbEvents:
	LogUsbQueueEvent(lidUsbQueueProcessEvents, logNoReg)
	ld	hl, usbIntRecurseFlag
	dec	(hl)
	jr	z, {@}
	inc	(hl)
	jp	_ExitUsbInterrupt
@:	di
	call	_DequeueUsbWord
	jr	z, {@}
	LogUsbQueueEvent(lidUsbQueueProcessEvent, logRegDE)
	ei
	ex	de, hl
	call	CallHL
	jr	{-1@}
@:	ld	hl, usbIntRecurseFlag
	inc	(hl)
.ifdef	DEBUG
	ld	a, (hl)
	cp	1
	call	nz, Panic
.endif
	LogUsbQueueEvent(lidUsbQueueProcessEventsDone, logNoReg)
	pop	ix
	pop	de
	pop	bc
	pop	hl
	pop	af
	ei
	ret


_processUsbEventGlobalEvent:
	call	_DequeueUsbWord
;	UnitTestPrint("[Global event: ")
;	UnitTestPrintDE()
;	UnitTestPrintChar(']')
	ld	a, d
	ld	ix, usbGlobalEventCb
	call	InvokeCallBack
	ret


_processUsbEventBConnect:
;	UnitTestPrint("[B connect]")
	call	InitializePeripheralMode
	call	c, Panic
	ret


_processUsbEventUsbProtocol:
;	UnitTestPrint("[Prot: ")
	call	_DequeueUsbByteA
	UnitTestPrintA()
	UnitTestPrintChar(']')
	rra
	call	c, _pueSuspend
	rra
	call	c, _pueResume
	rra
	call	c, _pueReset
	rra
	call	c, _pueSof
.ifdef	DEBUG
	rra
	call	c, Panic
	rra
	call	c, Panic
	rra
	call	c, Panic
	rra
	call	c, Panic
.endif
	ret

_pueSuspend:
;	UnitTestPrint("[Prot susp]")
	push	af
	ld	de, usbEvSuspend * 256
	ld	a, d
	ld	ix, (usbGlobalEventCb)
	call	InvokeCallBack
	pop	af
	ret

_pueResume:
;	UnitTestPrint("[Prot resm]")
	push	af
	ld	de, usbEvResume * 256
	ld	a, d
	ld	ix, (usbGlobalEventCb)
	call	InvokeCallBack
	pop	af
	ret

_pueReset:
;	UnitTestPrint("[Prot reset]")
	; Reset pipes
	call	ResetPipes
	; Enable control pipe
	in	a, (pUsbIntrTxMask)
	or	1
	out	(pUsbIntrTxMask), a
	; TODO: Reset some other stuff?
	ret

_pueSof:
	; TODO: Probably make a callback hook and fire it.
;	UnitTestPrint("[Prot sof]")
	ret


_processUsbEventTxComplete:
;	UnitTestPrint("[TX comp: ")
	in	a, (pUsbIndex)
	push	af
	call	_DequeueUsbByteA
	UnitTestPrintA()
	UnitTestPrintChar(']')
	; In theory, more than one pipe TX complete event bit could be set.
	; This could happen if interrupts are inhibited for a long time.
	; So we check every bit, instead of stopping at the first.
	ld	c, 0
	ld	hl, (usbTxPipe0VarsPtr)
@:	or	a
	jr	z, {@}
	rra
	call	c, _pueTxCompleteProcess
	inc	c
	ld	de, usbPipeVarsSize
	add	hl, de
	jr	{-1@}
@:	pop	af
	out	(pUsbIndex), a
;	UnitTestPrint("[TX done]")
	ret
_pueTxCompleteProcess:
	push	af
	push	hl
	; Check for autobuffering
	ld	a, usbPipeFlagAutoBuffer | usbPipeFlagActiveXmit
	and	(hl)
	cp	usbPipeFlagAutoBuffer | usbPipeFlagActiveXmit
	ld	a, dataProcCbTxPacket
	jr	nz, _pueTxCompleteDoCbEndXmit
	; Check to see if all data have been sent
	bit	usbPipeFlagBufferEmptyB, (hl)
	jr	z, _pueTxCompleteContinueTx
	ex	de, hl
	ld	ixl, e	; Faster than push hl \ pop ix (4 + 8 + 8 = 20 vs. 11 + 14 = 25)
	ld	ixh, d
	ld	e, (ix + usbPipeBufferWritePtr)
	ld	d, (ix + usbPipeBufferWritePtr + 1)
	ld	l, (ix + usbPipeBufferReadPtr)
	ld	h, (ix + usbPipeBufferReadPtr + 1)
	cphlde
	ld	e, ixl
	ld	d, ixh
	ex	de, hl
	ld	a, dataProcCbTxComplete
	; Yes, end of TX
	jr	c, _pueTxCompleteDoCbEndXmit
_pueTxCompleteCheckForceCb:
	ld	a, dataProcCbTxPacket
	; No, not end of TX, but no more data to send
	bit	usbPipeFlagCbEveryXmitB, (hl)
	jr	nz, _pueTxCompleteDoCb
	jr	_pueTxCompleteEnd
_pueTxCompleteDoCbEndXmit:
	; Reset Xmit flag
;	UnitTestPrint("[TX end XMIT]")
	res	usbPipeFlagActiveXmitB, (hl)
_pueTxCompleteDoCb:
	; Do call back
;	UnitTestPrint("[TX CB go]")
	push	hl
	pop	ix
	inc	ix
	inc	ix
	inc	ix
	or	c
	call	InvokeCallBack
_pueTxCompleteEnd:
;	UnitTestPrint("[TX end]")
	pop	hl
	pop	af
	ret
_pueTxCompleteContinueTx:
;	UnitTestPrint("[TX cont TX]")
	push	af
	push	hl
	call	_pueTxCompleteCheckForceCb
	res	usbPipeFlagActiveXmitB, (hl)	; If call back resets XMIT flag, then discontinue send
	jr	z, _pueTxCompleteEnd
	ld	a, c
	call	_continueTxSendThing
	call	nc, Panic	; Pipe should be ready because it's done sending.
	jr	_pueTxCompleteEnd


_processUsbEventRxComplete:
;	UnitTestPrint("[RX comp: ")
	in	a, (pUsbIndex)
	push	af
	call	_DequeueUsbByteA
	UnitTestPrintA()
	UnitTestPrintChar(']')
	ld	c, 0
	ld	hl, (usbRxPipe0VarsPtr)
@:	or	a
	jr	z, {@}
	rra
	call	c, _pueRxCompleteProcess
	inc	c
	ld	de, usbPipeVarsSize
	add	hl, de
	jr	{-1@}
@:	pop	af
	out	(pUsbIndex), a
;	UnitTestPrint("[RX comp done]")
	ret
_pueRxCompleteProcess:
	push	af
	push	hl
	ld	a, c
	or	a
	jr	nz, {@}
	; It's the control pipe, so attempt default processing
	inc	hl
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	hl, _controlPipeRequestProcessingTable
	jp	ProcessPacket
_pueRxCompleteCheckCallbackType:
	pop	hl
	push	hl
@:	bit	usbPipeFlagCbIsTableB, (hl)
	inc	hl
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	jr	z, {@}
	inc	hl
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ex	de, hl
	; ProcessPacket is normally a JUMP not a CALL.
	; But the table must terminate in executable code, which we want to
	; return via RET, so we're in effect CALLing the callback ProcessPacket
	; terminates with.
	call	ProcessPacket
	jr	_pueRxCRet
@:	dec	hl
	ld	e, l
	ld	d, h
	dec	de
	dec	de
	
	; TODO: Call back ptr in IX now, so change this
	
	call	InvokeCallBack
_pueRxCRet:
	pop	hl
	pop	af
	ret





;===============================================================================
;====== USB Interrupts Subsystem ===============================================
;===============================================================================

HandleUsbInterrupt:
; Handles USB activity
; A = pUsbCoreIntrStatus
;	in	a, (pUsbCoreIntrStatus)
	LogUsbIntEvent(lidUsbIntDo, logRegA)
	rla	; This ordering puts the USB core interrupt first
	rla
	rla
	rla
	jp	nc, _handleUsbProtocolIntr
	rla
	jr	nc, _handleVscreenIntr
	rla
	jr	nc, _handleLineIntr
	rla
	jr	nc, _handleVbusTimeoutIntr
;	rla
;	call	c, Panic
;	; MUSBFDRC entered USB suspend mode
;	; TODO: Issue a suspend event?
;	LogUsbIntEventNull(lidUsbIntSuspend)
;	in	a, (pUsbSuspendCtrl)
;	and	~usbSuspendIe
;	out	(pUsbSuspendCtrl), a
;	or	usbSuspendIe
;	out	(pUsbSuspendCtrl), a
	call	Panic
_ExitUsbInterrupt:
	pop	ix
	pop	de
	pop	bc
	pop	hl
	pop	af
	ei
	ret


_handleVscreenIntr:
	; Never use this.
	LogUsbIntEvent(lidUsbIntVScreen, logNoReg)
	jp	Panic

_handleVbusTimeoutIntr:
	; Toshiba PHY discharge timeout occurred
	; This is basically an OTG SRP timeout
	; TODO: Make dealing with this configurable? Or something?
	LogUsbIntEvent(lidUsbIntVBusTimeout, logNoReg)
	jp	Panic

_handleLineIntr:
	in	a, (pUsbIntrStatus)
	LogUsbIntEvent(lidUsbIntLine, logNoReg)
	rrca
	call	c, Panic
	rrca
	call	c, Panic
	rrca
	call	c, Panic
	rrca
	call	c, Panic
	rrca
	jr	c, _aCableConnect
	rrca
	jr	c, _aCableDisconnect
	rrca
	jr	c, _bCableConnect
	rrca
	call	nc, Panic
	; B cable disconnect
	LogUsbIntEvent(lidUsbIntLineBDisconnect, logRegC)
	ld	a, vbusFall
	call	_clearUsbLineEvent
	; TODO: Should this actually disable USB? Or just wait until reconnect?
	xor	a
	out	(pUsbCoreIntrEnable), a	; Disable interrupts
	out	(pUsbSystem), a	; Reset USB
	ld	a, swDisable48Mhz
	out	(pUsbSuspendCtrl), a	; Disable 48 MHz crystal, PHY, interrupts, and charge pump
	in	a, (pGpioDirection)	; Futz with GPIO direction.  Does this sometimes get changed?
	and	0F8h
	out	(pGpioDirection), a
	ld	de, _processUsbEventGlobalEvent
	ld	hl, usbEvDeviceStop * 256
	jp	_QueueUsbEventWord
_bCableConnect:
	LogUsbIntEvent(lidUsbIntLineBConnect, logRegC)
	ld	a, vbusRise
	call	_clearUsbLineEvent
	ld	de, _processUsbEventBConnect
	jp	_QueueUsbEventNull
_aCableConnect:
	LogUsbIntEvent(lidUsbIntLineAConnect, logRegC)
	ld	a, cidFall
	call	_clearUsbLineEvent
	ld	hl, (usbEvErrMasterErr * 256) | usbErrACable
	ld	de, _processUsbEventGlobalEvent
	jp	_QueueUsbEventWord
_aCableDisconnect:
	LogUsbIntEvent(lidUsbIntLineADisconnect, logRegC)
	ld	a, cidRise
	call	_clearUsbLineEvent
	jp	_ExitUsbInterrupt
_clearUsbLineEvent:
	ld	b, a
	cpl
	ld	c, a
	in	a, (pUsbIntrEnable)
	and	c
	out	(pUsbIntrEnable), a
	or	b
	out	(pUsbIntrEnable), a
	ret


_handleUsbProtocolIntr:
	; For a dual-role host/peripheral driver, here we should check
	; pUsbDevCtl for whether we're in host or peripheral mode.
	in	a, (pUsbIntrId)
	or	a
	jr	z, {@}
	LogUsbIntEvent(lidUsbIntProt, logRegA)
	ld	de, _processUsbEventUsbProtocol
	jp	_QueueUsbEventByte
@:	; Check for TX complete
	in	a, (pUsbIntrTx)
	or	a
	jr	z, _usbProtIntCheckRx
	LogUsbIntEvent(lidUsbIntTxComplete, logRegA)
	; Handle set-address as a special case.
	ld	de, _processUsbEventTxComplete
	bit	0, a
	jp	z, _QueueUsbEventByte
	ld	hl, usbFlags
	bit	usbFlagSetAddressB, (hl)
	jp	z, _QueueUsbEventByte
	call	_QueueUsbWord
	call	_QueueUsbByteA
	ld	a, (usbTemp)
	out	(pUsbFAddr), a
	ld	hl, usbFlags
	res	usbFlagSetAddressB, (hl)
	ld	de, _processUsbEventGlobalEvent
	ld	hl, usbEvDeviceStart * 256
	jp	_QueueUsbEventWord
_usbProtIntCheckRx:
	; Check for RX complete
	in	a, (pUsbIntrRx)
	or	a
	jr	z, {@}
	LogUsbIntEvent(lidUsbIntRxComplete, logRegA)
	ld	de, _processUsbEventRxComplete
	jp	_QueueUsbEventByte
	; It shouldn't be possible to get here.
@:	call	Panic


;===============================================================================
;====== USB Protocol Subsystem =================================================
;===============================================================================


;------ StartRx ----------------------------------------------------------------
StartRx:
; Inputs:
;  - A: Pipe number
;  - BC: Number of bytes to receive
;  - HL: Ptr to data buffer
;  - E: Page of data buffer.  Should be RAM or else you won't get what you want.
; Output:
;  - Sets RX as being started
;  - usbPipeFlagActiveXmitB set if buffer is not empty.  You can call this with
;    the buffer empty, and nothing will happen.
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL
;  - IX
	push	af
	call	FlushRxFifo
	pop	af
	push	af
	ex	de, hl	; This won't work if E = RAM page, because HL is destroyed
	call	GetRxPipePtr
	push	hl
	pop	ix
	ex	de, hl
	pop	af
	res	usbPipeFlagBufferFullB, (ix + usbPipeFlags)
	set	usbPipeFlagBufferEmptyB, (ix + usbPipeFlags)
	set	usbPipeFlagActiveXmitB, (ix + usbPipeFlags)
	ld	(ix + usbPipeBufferReadPtr), l
	ld	(ix + usbPipeBufferReadPtr + 1), h
;	ld	(ix + uspPipeBufferReadPtrPg), e
	ld	(ix + usbPipeBufferDataSize), c
	ld	(ix + usbPipeBufferDataSize + 1), b
	ld	(ix + usbPipeBufferWritePtr), l
	ld	(ix + usbPipeBufferWritePtr + 1), h
;	ld	(ix + uspPipeBufferWritePtrPg), e
	set	usbPipeFlagActiveXmitB, (ix + usbPipeFlags)
	jr	_continueRxReceiveThing


;------ ContinueRx -------------------------------------------------------------
ContinueRx:
; Continues RX.
; Inputs:
;  - A: Pipe number
; Outputs:
;  - NC if cannot RX due to no data
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL
;  - IX
	push	af
	call	GetRxPipePtr
	pop	af
	bit	usbPipeFlagBufferFullB, (hl)
	ret	nz
_continueRxReceiveThing:
	out	(pUsbIndex), a
	in	a, (pUsbRxCount)
	or	a
	ret	z
	ld	e, a
	ld	d, 0
	in	a, (pUsbIndex)
	or	a
	jr	nz, {@}
.ifndef	UNIT_TESTS
	in	a, (pUsbCsr0)
	and	csr0RxPktRdy
	ret	nz	; ???
.endif
	jr	{2@}
@:	
.ifndef	UNIT_TESTS
	in	a, (pUsbRxCsr)
	and	rxCsrRxPktRdy
	ret	nz	; ???
.endif
@:	push	hl
	pop	ix
	call	GetBufferWriteByteCount
	cphlde
	jr	nc, {@}
	; Not enough space
	set	usbPipeFlagBufferFullB, (ix + usbPipeFlags)
	ld	bc, usbPipeDataProcCb
	add	ix, bc
	in	a, (pUsbIndex)
	or	dataProcCbRxBufOverflow
	call	InvokeCallBack
	jr	_continueRxReceiveRet
@:	ld	l, (ix + usbPipeBufferWritePtr)
	ld	h, (ix + usbPipeBufferWritePtr + 1)
	in	a, (pUsbIndex)
	add	a, pUsbPipe
	ld	c, a
	in	a, (pUsbRxCount)
	ld	b, a
	ld	e, a
	inir
	ld	(ix + usbPipeBufferWritePtr), l
	ld	(ix + usbPipeBufferWritePtr + 1), h
	ex	de, hl
	ld	l, (ix + usbPipeBufferPtr)
	ld	h, (ix + usbPipeBufferPtr + 1)
	ld	c, (ix + usbPipeBufferDataSize)
	ld	b, (ix + usbPipeBufferDataSize + 1)
	add	hl, bc
	ex	de, hl
	cphlde
	jr	c, _continueRxNotEnoughDataToReceive
	set	usbPipeFlagBufferFullB, (ix + usbPipeFlags)
_continueRxNotEnoughDataToReceive:
	scf	; Done, return C
	ret	nz
	set	usbPipeFlagBufferEmptyB, (ix + usbPipeFlags)
_continueRxReceiveRet:
	scf
	ret


;------ StartTx ----------------------------------------------------------------
StartTx:
; Starts sending data.  This will automatically break up the data into max-size
; packets.  This will send an empty packet if BC = 0.  If any data are pending
; in the hardware FIFO, it will be flushed without being sent.
; NO WRAPPING IS PERFORMED FOR PAGE BOUNDRY
; Inputs:
;  - A: Pipe number
;  - BC: Number of bytes to send
;  - HL: Ptr to data to send.
;  - E: Page of data to send.
; Output:
;  - Tx started
;  - usbPipeFlagActiveXmitB set
;  - Buffer pointers configured
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL
;  - IX
;  - pUsbIndex
	ld	b, a
	call	FlushTxFifo
	ld	a, b
	ex	de, hl
	call	GetTxPipePtr
	push	hl
	pop	ix
	ex	de, hl
	ld	a, b
	set	usbPipeFlagBufferFullB, (ix + usbPipeFlags)
	res	usbPipeFlagBufferEmptyB, (ix + usbPipeFlags)	; Force sending zero-byte packet if BC = 0
	ld	(ix + usbPipeBufferReadPtr), l
	ld	(ix + usbPipeBufferReadPtr + 1), h
;	ld	(ix + uspPipeBufferReadPtrPg), e
	ld	(ix + usbPipeBufferDataSize), c
	ld	(ix + usbPipeBufferDataSize + 1), b
	add	hl, bc
	ld	(ix + usbPipeBufferWritePtr), l
	ld	(ix + usbPipeBufferWritePtr + 1), h
;	ld	(ix + uspPipeBufferWritePtrPg), e
	jr	_continueTxSendThing


;------ ContinueTx -------------------------------------------------------------
ContinueTx:
; Continues a TX pipe's send.
; Input:
;  - A: Pipe number
; Output:
;  - Send continued if possible
;    May not continue if:
;     - Not enough bytes in buffer for max-size packet AND WritePtr < end of buf
;     - Hardware FIFO not empty
;  - NC if couldn't send due to pipe not being ready
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL
;  - IX
.ifdef	UNIT_TESTS
	push	af
	ld	a, 'x'
	call	PutC
	pop	af
.endif
	; Get pointer to vars
	push	af
	call	GetTxPipePtr
	pop	af
	push	hl
	pop	ix
	; If buffer is empty, can't send any data
	or	a
	bit	usbPipeFlagBufferEmptyB, (ix + usbPipeFlags)
	ret	nz
_continueTxSendThing:
	set	usbPipeFlagActiveXmitB, (ix + usbPipeFlags)
	out	(pUsbIndex), a
.ifdef	UNIT_TESTS
	push	af
	ld	a, 'X'
	call	PutC
	pop	af
.endif
	; Is pipe ready to send more data?
	ld	b, txCsrTxPktRdy
	or	a
	jr	nz, {@}
	ld	b, csr0TxPktRdy
@:	
.ifndef	UNIT_TESTS
	in	a, (pUsbTxCsr)
	and	b
	ret	nz	; Error, return NC
.endif
	; Figure out if there is enough data for a full packet
	call	GetBufferReadByteCount
.ifdef	UNIT_TESTS
	call	DispHL
.endif
	ld	a, h
	or	a
	jr	z, {@}
	ld	l, 255
@:	ld	a, (ix + usbPipeConfig)
	and	usbPipeMaxPacketMask
	add	a, a
	add	a, a
	add	a, a
.ifdef	UNIT_TESTS
	push	af
	ld	a, ','
	call	PutC
	pop	af
	call	DispByte
.endif
	ld	d, csr0TxPktRdy
	cp	l
	jr	z, {@}
	jr	c, _continueTxEnoughData
	; Not enough data for a full packet. Should we send a partial packet?
	ld	a, (ix + usbPipeBufferDataSize + 1)
	or	a
	call	nz, Panic
	ld	a, (ix + usbPipeBufferDataSize)
	cp	l
	jr	z, {@}
	call	c, Panic
	or	a
	ret
@:	ld	d, csr0TxPktRdy | csr0DataEnd
_continueTxEnoughData:
	; If you reset usbPipeFlagBufferEmptyB but set DataSize to 0 and have
	; no data in the buffer, you can force sending a null packet.
	or	a
	jr	z, _continueTxSendEmpty
	ld	b, a
	ld	e, a
	ld	d, 0
	ld	l, (ix + usbPipeBufferDataSize)
	ld	h, (ix + usbPipeBufferDataSize + 1)
	or	a
	sbc	hl, de
	call	c, Panic
	ld	(ix + usbPipeBufferDataSize), l
	ld	(ix + usbPipeBufferDataSize + 1), h
.ifdef	UNIT_TESTS
	ld	a, 'd'
	call	PutC
	ld	a, b
	call	DispByte
	ld	a, ':'
	call	PutC
.endif
	ld	l, (ix + usbPipeBufferReadPtr)
	ld	h, (ix + usbPipeBufferReadPtr + 1)
	in	a, (pUsbIndex)
	add	a, pUsbPipe
	ld	c, a
.ifndef	UNIT_TESTS
	otir
.else
@:	ld	a, (hl)
	inc	hl
	call	DispByte
	dec	b
	jr	nz, {-1@}
.endif
_continueTxSendEmpty:
.ifdef	UNIT_TESTS
	ld	a, 'z'
	call	PutC
.endif
	in	a, (pUsbIndex)
	or	a
	jr	nz, {@}
	ld	a, d
;	out	(pUsbCsr0), a	; same port as pUsbTxCsr
	jr	{2@}
@:	ld	a, txCsrTxPktRdy
@:	out	(pUsbTxCsr), a
.ifdef	UNIT_TESTS
	ld	a, 'Z'
	call	PutC
.endif
	ld	(ix + usbPipeBufferReadPtr), l
	ld	(ix + usbPipeBufferReadPtr + 1), h
	ld	c, (ix + usbPipeBufferWritePtr)
	ld	b, (ix + usbPipeBufferWritePtr + 1)
	cphlbc
	scf
	ret	nz
	set	usbPipeFlagBufferEmptyB, (ix + usbPipeFlags)
	ret


;------ FlushRxBuffer ----------------------------------------------------------
FlushRxBuffer:
; Flushes a RX pipe's buffer.  Does not flush the hardware FIFO.
; Input:
;  - A: Pipe number
; Output:
;  - Buffer flushed
;  - usbPipeFlagBufferEmpty set
;  - usbPipeFlagBufferFull & usbPipeFlagActiveXmit reset
;  - usbPipeFlagCircEnd reset if circular buffer
;  - usbPipeBufferDataSize set to zero if not circular buffer
; Destroys:
;  - AF
	push	hl
	push	ix
	call	GetRxPipePtr
	push	hl
	pop	ix
	call	FlushBuffer
	pop	ix
	pop	hl
	ret


;------ FlushTxBuffer ----------------------------------------------------------
FlushTxBuffer:
; Flushes a TX pipe's buffer.  Does not flush the hardware FIFO.
; Input:
;  - A: Pipe number
; Output:
;  - Buffer flushed
;  - usbPipeFlagBufferEmpty set
;  - usbPipeFlagBufferFull & usbPipeFlagActiveXmit reset
;  - usbPipeFlagCircEnd reset if circular buffer
;  - usbPipeBufferDataSize set to zero if not circular buffer
; Destroys:
;  - AF
	push	hl
	push	ix
	call	GetTxPipePtr
	push	hl
	pop	ix
	call	FlushBuffer
	pop	ix
	pop	hl
	ret


;------ FlushBuffer ------------------------------------------------------------
FlushBuffer:
; Flushes a pipe's buffer.  Does not flush the hardware FIFO.
; Input:
;  - IX: Pointer to buffer's vars
; Output:
;  - Buffer flushed
;  - usbPipeFlagBufferEmpty set
;  - usbPipeFlagBufferFull & usbPipeFlagActiveXmit reset
;  - usbPipeBufferDataSize set to zero
; Destroys:
;  - AF
	ld	a, (ix + usbPipeBufferPtr)
	ld	(ix + usbPipeBufferReadPtr), a
	ld	(ix + usbPipeBufferWritePtr), a
	ld	a, (ix + usbPipeBufferPtr + 1)
	ld	(ix + usbPipeBufferReadPtr + 1), a
	ld	(ix + usbPipeBufferWritePtr + 1), a
	ld	a, (ix + usbPipeBufferPtr + 2)
	ld	(ix + usbPipeBufferReadPtr + 2), a
	ld	(ix + usbPipeBufferWritePtr + 2), a
	ld	a, (ix + usbPipeFlags)
	and	~(usbPipeFlagBufferFull | usbPipeFlagActiveXmit)
	or	usbPipeFlagBufferEmpty
	ld	(ix + usbPipeFlags), a
	xor	a
	ld	(ix + usbPipeBufferDataSize), a
	ld	(ix + usbPipeBufferDataSize + 1), a
	ret


;------ WriteTxBufferByte ------------------------------------------------------
WriteTxBufferByte:
; Writes a byte to a TX pipe's buffer
; Input:
;  - A: Pipe number
;  - B: Byte
; Output:
;  - Write ptr incremented
;  - usbPipeFlagBufferFull set if buffer is now full
;  - usbPipeFlagBufferEmpty reset
;  - Z if you have written to the last free byte in the buffer
; Destroys:
;  - Flags
	push	bc
	push	de
	push	hl
	push	ix
	call	GetTxPipePtr
	push	hl
	pop	ix
	ld	a, b
	call	WriteBufferByte
	pop	ix
	pop	hl
	pop	de
	pop	bc
	ret


;------ WriteBufferByte --------------------------------------------------------
WriteBufferByte:
; Writes a byte to a buffer.
; Input:
;  - IX: Pointer to buffer's vars
;  - A: Byte to write
; Outputs:
;  - Write ptr incremented
;  - usbPipeFlagBufferFull set if buffer is now full
;  - usbPipeFlagBufferEmpty reset
;  - Z if you have written to the last free byte in the buffer
;  - HL: Number of free bytes remaining in buffer
; Destroys:
;  - Flags
;  - BC
;  - DE
;  - HL
	res	usbPipeFlagBufferEmptyB, (ix + usbPipeFlags)
	ld	l, (ix + usbPipeBufferWritePtr)
	ld	h, (ix + usbPipeBufferWritePtr + 1)
	ld	(hl), a
	inc	hl
	ld	(ix + usbPipeBufferWritePtr), l
	ld	(ix + usbPipeBufferWritePtr + 1), h
	ld	e, (ix + usbPipeBufferPtr)
	ld	d, (ix + usbPipeBufferPtr + 1)
	or	a
	sbc	hl, de
	ld	e, (ix + usbPipeBufferDataSize)
	ld	d, (ix + usbPipeBufferDataSize + 1)
	ex	de, hl
	sbc	hl, de
	ret	nz
	set	usbPipeFlagBufferFullB, (ix + usbPipeFlags)
	ret


;------ GetBufferWriteByteCount ------------------------------------------------
GetBufferWriteByteCount:
; Returns the number of bytes free to write to in a buffer.
; Input:
;  - IX: Pointer to buffer's vars
; Output:
;  - HL: Bytes free
;  - C flag set if no more bytes free
; Destroys:
;  - BC
	bit	usbPipeFlagBufferFullB, (ix + usbPipeFlags)
	jr	z, {@}
	ld	hl, 0
	scf
	ret
@:	ld	l, (ix + usbPipeBufferPtr)
	ld	h, (ix + usbPipeBufferPtr + 1)
	ld	c, (ix + usbPipeBufferDataSize)
	ld	b, (ix + usbPipeBufferDataSize + 1)
	add	hl, bc
	ld	c, (ix + usbPipeBufferWritePtr)
	ld	b, (ix + usbPipeBufferWritePtr + 1)
	or	a
	sbc	hl, bc
	ret


;------ ReadRxBufferByte -------------------------------------------------------
ReadRxBufferByte:
; Reads a byte from an RX pipe's buffer.  WARNING: This does not check to make
; sure the buffer is not empty, so calling this will cause the buffer to enter
; an inconsistent state.
; Input:
;  - A: Pipe number
; Output:
;  - A: Byte
;  - Read ptr incremented
;  - usbPipeFlagBufferEmpty set if empty
;  - Z set if you have read the last byte
; Destroys:
;  - Flags
	push	bc
	push	de
	push	hl
	push	ix
	call	GetRxPipePtr
	push	hl
	pop	ix
	call	ReadBufferByte
	pop	ix
	pop	hl
	pop	de
	pop	bc
	ret


;------ ReadBufferByte ---------------------------------------------------------
ReadBufferByte:
; Reads a byte from a buffer.
; Input:
;  - IX: Pointer to buffer's vars
; Outputs:
;  - A: Byte read
;  - Read ptr incremented
;  - usbPipeFlagBufferEmpty set if empty
;  - Z if you have read the last byte actually in the buffer
; Destroys:
;  - Flags
;  - DE
;  - HL
	ld	l, (ix + usbPipeBufferReadPtr)
	ld	h, (ix + usbPipeBufferReadPtr + 1)
	ld	a, (hl)
	inc	hl
	ld	(ix + usbPipeBufferReadPtr), l
	ld	(ix + usbPipeBufferReadPtr + 1), h
	ld	e, (ix + usbPipeBufferWritePtr)
	ld	d, (ix + usbPipeBufferWritePtr + 1)
	cphlde
	ret	nz
	set	usbPipeFlagBufferEmptyB, (ix + usbPipeFlags)
	ret


;------ GetBufferReadByteCount -------------------------------------------------
GetBufferReadByteCount:
; Returns the number of bytes left to read in a buffer.
; This value reflects the number of bytes actually present, not the number of
; bytes implied by DataSize.
; Input:
;  - IX: Pointer to buffer's vars
; Output:
;  - HL: Bytes left to read
;  - C flag set if no more bytes to read
; Destroys:
;  - DE
	bit	usbPipeFlagBufferEmptyB, (ix + usbPipeFlags)
	jr	z, {@}
	ld	hl, 0
	scf
	ret
@:	ld	e, (ix + usbPipeBufferReadPtr)
	ld	d, (ix + usbPipeBufferReadPtr + 1)
	ld	l, (ix + usbPipeBufferWritePtr)
	ld	h, (ix + usbPipeBufferWritePtr + 1)
	or	a
	sbc	hl, de
	ret
	

;------ GetTxPipePtr -----------------------------------------------------------
GetTxPipePtr:
; Gets a pointer to a TX pipe's vars
; Inputs:
;  - A: Pipe number
; Output:
;  - HL: Ptr
; Destroys:
;  - AF
	add	a, a
	add	a, a
	ld	l, a
	add	a, a
	add	a, l
	ld	hl, (usbTxPipe0VarsPtr)
	add	a, l
	ld	l, a
	ret	nc
	inc	h
	ret


;------ GetRxPipePtr -----------------------------------------------------------
GetRxPipePtr:
; Gets a pointer to a RX pipe's vars
; Inputs:
;  - A: Pipe number
; Output:
;  - HL: Ptr
; Destroys:
;  - AF
	add	a, a
	add	a, a
	ld	l, a
	add	a, a
	add	a, l
	ld	hl, (usbRxPipe0VarsPtr)
	add	a, l
	ld	l, a
	ret	nc
	inc	h
	ret
	

;------ GetRxPacketSize --------------------------------------------------------
GetRxPacketSize:
; Gets the size of the packet sitting in the hardware FIFO.
; Inputs:
;  - A: FIFO number
; Output:
;  - A: Packet size
; Destroys:
;  - pUsbIndex
	LogUsbLowEvent(lidUsbLowGetRxPacketSize, logRegA)
	out	(pUsbIndex), a
.ifndef	UNIT_TESTS
	in	a, (pUsbRxCount)
.endif
	LogUsbLowEvent(lidUsbLowGetRxPacketSizeResult, logRegA)
	ret


;------ ReadyControlPipeForRx --------------------------------------------------
ReadyControlPipeForRx:
; Call this before when you expect to get data for a control request.
; Inputs:
;  - None
; Outputs:
;  - Ready to RX control request
; Destroys:
;  - AF
;  - pUsbIndex
	LogUsbLowEvent(lidUsbLowReadyControlForRx, logNoReg)
	xor	a
	out	(pUsbIndex), a
.ifndef	UNIT_TESTS
	ld	a, csr0SvdRxPktRdy
	out	(pUsbCsr0), a
.endif
	ret


;------ ReadPacket -------------------------------------------------------------
ReadPacket:
; Reads all possible bytes from packet FIFO into RAM buffer
; This does not support large packets whose size is greater than 255.  Besides,
; the hardware FIFO probably isn't that big anyway.
; Inputs:
;  - HL: Pointer to buffer
;  - A: FIFO number
; Outputs:
;  - A: Number of bytes read
;  - NC if no bytes to read
; Destroys:
;  - AF
;  - BC
;  - HL
;  - pUsbIndex
	LogUsbLowEvent(lidUsbLowReadPacket, logRegA)
	out	(pUsbIndex), a
	add	a, pUsbPipe
	ld	c, a
.ifndef	UNIT_TESTS
	in	a, (pUsbRxCount)
	or	a
	ret	z
	ld	b, a
	inir
.endif
	scf
	ret


;------ SendControlStall -------------------------------------------------------
SendControlStall:
; Sends a STALL on the control pipe.
; Inputs:
;  - None
; Outputs:
;  - STALL
; Destroys:
;  - AF
;  - pUsbIndex
	LogUsbLowEvent(lidUsbLowSendControlStall, logNoReg)
	xor	a
	out	(pUsbIndex), a
.ifndef	UNIT_TESTS
	ld	a, csr0SendStall | csr0SvdRxPktRdy
	out	(pUsbCsr0), a
.endif
	ret


;------ SendStall --------------------------------------------------------------
SendStall:
; Sends a STALL on a non-control pipe.
; Inputs:
;  - A: Pipe number
; Outputs:
;  - STALL
; Destroys:
;  - AF
;  - pUsbIndex
	LogUsbLowEvent(lidUsbLowSendStall, logRegA)
.ifndef	UNIT_TESTS
	out	(pUsbIndex), a
	ld	a, txCsrSendStall | txCsrClrDataOtg
	out	(pUsbTxCsrCont), a
.endif
	ret


;------ FinishControlRequest ---------------------------------------------------
FinishControlRequest:
; Call this at the end of a control request to mark it as finished.  Not used if
; you have a data stage.
; Inputs:
;  - None
; Output:
;  - Control request finished
; Destroys:
;  - AF
;  - pUsbIndex
	LogUsbLowEvent(lidUsbLowFinishControlReq, logNoReg)
	xor	a
	out	(pUsbIndex), a
.ifndef	UNIT_TESTS
	in	a, (pUsbCsr0)	; Required according to BrandonW
	ld	a, csr0DataEnd | csr0SvdRxPktRdy	; 48h
	out	(pUsbCsr0), a
	in	a, (pUsbCsr0)
.endif
	ret


;------ SendControlPacket ------------------------------------------------------
SendControlPacket:
; Sends a packet to a control pipe, and marks the pipe as having an active Xmit.
; Inputs:
;  - B: Bytes to write
;  - C: Value to write when done: csr0TxPktRdy or csr0TxPktRdy | csr0DataEnd
;  - HL: Pointer to packet data
; Outputs:
;  - Data written, pipe marked as having data ready to TX
;  - NC if pipe not ready; data NOT sent
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL
;  - pUsbIndex
	LogUsbLowEvent(lidUsbLowSendControlPacket, logNoReg)
	xor	a
	ex	de, hl
	call	GetRxPipePtr
	set	usbPipeFlagActiveXmitB, (hl)
	ex	de, hl


;------ WriteControlPacket -----------------------------------------------------
WriteControlPacket:
; Writes a packet of data to the control pipe.
; Inputs:
;  - B: Bytes to write
;  - C: Value to write when done: csr0TxPktRdy or csr0TxPktRdy | csr0DataEnd
;  - HL: Pointer to packet data
; Outputs:
;  - Data written, pipe marked as having data ready to TX
;  - NC if pipe not ready; data NOT sent
; Destroys:
;  - AF
;  - BC
;  - HL
;  - pUsbIndex
	LogUsbLowEvent(lidUsbLowWriteControlPacket, logNoReg)
	xor	a
	out	(pUsbIndex), a
.ifndef	UNIT_TESTS
	in	a, (pUsbCsr0)
	and	csr0TxPktRdy
	ret	nz
	ld	a, b
	or	a
	jr	z, {@}
	push	bc
	ld	c, pUsbPipe
	otir
	pop	bc
@:	ld	a, c
	out	(pUsbCsr0), a
.endif
	scf
	ret


;------ SendPacket -------------------------------------------------------------
SendPacket:
; Sends a packet to a non-control pipe, and marks the pipe as having an active
; Xmit.
; Inputs:
;  - A: Pipe number
;  - B: Bytes to write
;  - HL: Pointer to packet data
; Outputs:
;  - Data written, pipe marked as having data ready to TX
;  - NC if pipe not ready; data NOT sent
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL
;  - pUsbIndex
	LogUsbLowEvent(lidUsbLowSendPacket, logRegA)
	ld	c, a
	ex	de, hl
	call	GetTxPipePtr
	set	usbPipeFlagActiveXmitB, (hl)
	ex	de, hl
	ld	a, c


;------ WritePacket ------------------------------------------------------------
WritePacket:
; Writes a packet of data to a non-control pipe.
; Inputs:
;  - A: Pipe number
;  - B: Bytes to write
;  - HL: Pointer to packet data
; Outputs:
;  - Data written, pipe marked as having data ready to TX
;  - NC if pipe not ready; data NOT sent
; Destroys:
;  - AF
;  - BC
;  - HL
;  - pUsbIndex
	LogUsbLowEvent(lidUsbLowWritePacket, logRegA)
	out	(pUsbIndex), a
.ifndef	UNIT_TESTS
	or	pUsbPipe	; = A0 = 1010 0000
	ld	c, a
	in	a, (pUsbTxCsr)
	and	txCsrTxPktRdy
	ret	nz
	ld	a, b
	or	a
	jr	z, {@}
	otir
@:	ld	a, txCsrTxPktRdy
	out	(pUsbTxCsr), a
.endif
	scf
	ret


;------ FlushRxFifo ------------------------------------------------------------
FlushRxFifo:
; Flushes all received data in an RX FIFO, without copying to RAM.
; Inputs:
;  - A: FIFO number
; Outputs:
;  - FIFO emptied
; Destroys:
;  - AF
;  - pUsbIndex
	LogUsbLowEvent(lidUsbLowFlushRxFifo, logRegA)
	out	(pUsbIndex), a
.ifndef	UNIT_TESTS
	; TODO: So . . . is flushing the control out FIFO the same as flushing the in FIFO?
	or	a
	jr	z, FlushTxFifo
	ld	a, rxCsrFlushFifo; | rxCsrClrDataOtg	; I donno, just try both.
	out	(pUsbRxCsr), a
.endif
	ret

;------ FlushTxFifo ------------------------------------------------------------
FlushTxFifo:
; Flushes all data in TX FIFO if it hasn't been sent already.
; Inputs:
;  - A: FIFO number
; Outputs:
;  - FIFO emptied
; Destroys:
;  - AF
;  - pUsbIndex
	LogUsbLowEvent(lidUsbLowFlushTxFifo, logRegA)
	out	(pUsbIndex), a
.ifndef	UNIT_TESTS
	or	a
	jr	z, {@}
	ld	a, txCsrFifoFlushFifo	; Flush pipe
	out	(pUsbTxCsr), a
	ret
@:	ld	a, csr0ContFlushFifo	; Flush pipe
	out	(pUsbCsr0Cont), a
.endif
	ret


;------ ProcessPacket ----------------------------------------------------------
ProcessPacket:
; Processes a packet, byte-by-byte, using tables.
; Inputs:
;  - DE: Pointer to packet data
;  - HL: Pointer to processing table
;     - .db flagsAndNumberOfEntires (max 64; specify zero for 64)
;        - Bit 7 processPacketApplyBitmask: Set to apply optional bitmask
;        - Bit 6 processPacketNoIncDe: Set to prevent incrementing DE
;     - If bitmask: .db bitmask
;     - .db matchValue1
;     - .dw jumpAddress1
;     - .db matchValue2
;     - .dw jumpAddress2
;     - ...
;     - .dw matchNotFoundAddress
;     - jumpAddress: .db 0 \ .db flagsAndNumberOfEntries \ .db ... ; this will chain to another table
;     - jumpAddress: ld a, 123 \ call doSomething ; not zero, so executes code there
; Output:
;  - Correct code path found based on data
;  - DE: 1 plus address of packet data
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL
processPacketApplyBitmask	.equ	80h
processPacketNoIncDe	.equ	40h
	LogUsbProtEvent(lidUsbProtProcessPacketDE, logRegDE)
	LogUsbProtEvent(lidUsbProtProcessPacketHL, logRegHL)
	ld	a, (hl)
	inc	hl
	ld	c, a
	and	3Fh
	jr	nz, {@}
	ld	a, 64
@:	ld	b, a
	ld	a, (de)
	bit	6, c
	jr	nz, {@}
	inc	de
@:	bit	7, c
	jr	z, {@}
	and	(hl)
	inc	hl
@:	cp	(hl)
	inc	hl
	jr	z, {@}
	inc	hl
	inc	hl
	djnz	{-1@}
@:	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	ld	a, (hl)
	inc	hl
	or	a
	jr	z, ProcessPacket
	dec	hl
	jp	(hl)


;===============================================================================
;====== USB PHY ================================================================
;===============================================================================

;------ InitializePeripheralMode -----------------------------------------------
InitializePeripheralMode:
	LogUsbLowEvent(lidUsbLowInitializePeripheral, logNoReg)
.ifndef	UNIT_TESTS
	; Reset USB controller
	xor	a
	out	(pUsbSystem), a
	; No charge pump for peripheral mode
	out	(pVbusCtrl), a
	nop
	nop
	; Wait for reset to complete
	out	(pUsbSuspendCtrl), a
	ld	hl, 5500	; About 10 ms at 15 MHz
@:	dec	hl		; 10 6
	ld	a, l		; 8  4
	or	h		; 8  4
	jr	nz, {-1@}	; 12 12
	ld	a, usbReset_
	out	(pUsbSystem), a
	; Enable 48 MHz clock to USB circuits and enable PHY
	ld	a, swEnablePhy | swEnableIpClk	; 44h
	out	(pUsbSuspendCtrl), a
	; Screw with GPIO
	in	a, (pGpioData)
	and	0F8h
	out	(pGpioData), a
	; Wait for things to get going
	ld	ix, 0
@:	dec	ix
	ld	a, ixl
	or	ixh
	scf
	ret	z
	in	a, (pUsbSystem)
	;and	~chargePumpClockEnable
	;cp	usbRstO | usbReset_ | ipClockGated	; 1Ah
	and	ipClockGated | phyEnable
	cp	ipClockGated | phyEnable
	jr	nz, {-1@}
; Configure USB protocol stuff
	; Address
	xor	a
	out	(pUsbFAddr), a
	; Other protocol interrupts
	ld	a, usbIntrSuspend | usbIntrReset | usbIntrResume | usbIntrSof
	out	(pUsbIntrMask), a
.endif
ResetPipes:
	LogUsbLowEvent(lidUsbLowResetPipes, logNoReg)
	; Enable correct number of TX pipes
	ld	a, (usbTxPipeCount)
	ld	b, a
	ld	a, 1
@:	rla
	djnz	{-1@}
	dec	a
.ifndef	UNIT_TESTS
	out	(pUsbIntrTxMask), a
.endif
	; Enable correct number of RX pipes
	ld	a, (usbRxPipeCount)
	ld	b, a
	ld	a, 1
@:	rla
	djnz	{-1@}
	dec	a
	dec	a		; Disable RX on control pipe
.ifndef	UNIT_TESTS
	out	(pUsbIntrRxMask), a
.endif
	xor	a
.ifndef	UNIT_TESTS
	out	(pUsbIntrTxMaskCont), a
	out	(pUsbIntrRxMaskCont), a
.endif
	; Pipes
	xor	a
	out	(pUsbIndex), a
	ld	a, csr0SvdRxPktRdy	; Probably flushes RX FIFO
.ifndef	UNIT_TESTS
	out	(pUsbCsr0), a
.endif
	ld	a, csr0ContFlushFifo	; Probably flushes TX FIFO
.ifndef	UNIT_TESTS
	out	(pUsbCsr0Cont), a
.endif
	; Reset each TX pipe
	ld	hl, (usbTxPipe0VarsPtr)
	inc	hl
	ld	a, (usbTxPipeCount)
	ld	b, a
	ld	de, usbPipeVarsSize
	ld	c, 0
@:	add	hl, de
	inc	c
	ld	a, c
	out	(pUsbIndex), a
	cp	b
	jr	z, {@}
	ld	a, txCsrFifoFlushFifo | txCsrClrDataOtg
.ifndef	UNIT_TESTS
	out	(pUsbTxCsr), a
.endif
	ld	a, txCsrContWrDataToggle
.ifndef	UNIT_TESTS
	out	(pUsbTxCsrCont), a
.endif
	ld	a, (hl)
	and	0Fh
	out	(pUsbTxMaxP), a
	jr	{-1@}
@:	; Reset each RX pipe
	xor	a
	out	(pUsbIndex), a
	ld	hl, (usbRxPipe0VarsPtr)
	inc	hl
	ld	a, (usbRxPipeCount)
	ld	b, a
	ld	de, usbPipeVarsSize
@:	add	hl, de
	inc	c
	ld	a, c
	out	(pUsbIndex), a
	cp	b
;	jr	z, {@}
	ret	z
	ld	a, rxCsrFlushFifo
.ifndef	UNIT_TESTS
	out	(pUsbRxCsr), a
.endif
; TODO: I guess this isn't really something you set?
;	ld	a, (hl)
;	and	0Fh
;	out	(pUsbRxMaxP), a
	jr	{-1@}
;@:	ret
	
	
	





.ifdef	NEVER
	ld	b, 1
@:	ld	a, b
	cp	8
	ret	z	;jr	z, {@}
	out	(pUsbIndex), a
	ld	a, txCsrFifoFlushFifo
	out	(pUsbTxCsr), a
	ld	a, txCsrContWrDataToggle
	out	(pUsbTxCsrCont), a
	ld	a, rxCsrFlushFifo
	out	(pUsbRxCsr), a
	xor	a
	out	(pUsbRxCsrCont), a
	
	; TODO: Set pipe FIFO sizes
	
	jr	{-1@}
;@:	; I guess we're done.
;	ret


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
	; Disable the charge pump for peripheral mode
	xor	a
	out	(pVbusCtrl), a
	; Reset PHY
	xor	a
	out	(pUsbSuspendCtrl), a
	ld	hl, 5500	; About 10 ms at 15 MHz
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
	;Release USB controller reset and enable protocol interrupts
	ld	a, usbCoreIntrEnable
	out	(pUsbCoreIntrEnable), a
	ld	a, usbReset_
	out	(pUsbSystem), a
	;Wait until IP clock is enabled
	ld	ix, 0
@:	dec	ix
	ld	a, ixl
	or	ixh
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
	;Enable the bus suspend interrupt
	in	a, (pUsbSuspendCtrl)
	or	usbSuspendIe
	out	(pUsbSuspendCtrl), a
;	or	a
	ret
.endif


;------ DisableUsb -------------------------------------------------------------
DisableUsb:
;Disables USB communication.
;Inputs:      None
;Outputs:     None
	;Hold the USB controller in reset and disable interrupts
	xor	a
	out	(pUsbCoreIntrEnable), a
	out	(pUsbSystem), a
	ret


;------ IsVBusPowered ----------------------------------------------------------
IsVBusPowered:
; Checks whether V-bus is powered.
; Inputs:
;  - None
; Output:
;  - NZ if not powered
;  - Z if powered
	in	a, (pUsbActivity)
	and	vbusFall
;	bit	vbusFallB, a
;	ret	nz
;	in	a, (pZsVbusCtrl)
;	cp	zsVbusIden
	;ret	z
	; What's going on here!?
	ret


;------ EnableUsb --------------------------------------------------------------
EnableUSB:
; Enables USB.  ASSUMES THAT NO CABLE IS CONNECTED.
; This allows USB interrupts to start flowing.
; This should be called before any cable is connected.  If a cable is connected,
; you can still call this, but you should also show an error message.
; Inputs:
;  - None
; Outputs:
;  - None
	LogUsbLowEvent(lidUsbLowEnableUsb, logNoReg)
.ifndef	UNIT_TESTS
	call	FlushUsbInterrupts
	; Hold the USB controller in reset
	xor	a
	out	(pUsbSystem), a
	; Port 4A, pull-up and pull-down switches
	ld	a, pdConM
	out	(pPuPdCtrl), a
	xor	a
	; Port 4B, V-bus control (disable internal charge pump for peripheral mode)
	out	(pVbusCtrl), a
	; Port 4F, a bunch of OTG power-related stuff, I think
	out	(pZsVbusCtrl), a
	; Port 58 and 59, we don't want USB coming on automatically
	out	(pUsbHwEnActivity), a
	out	(pUsbHwEnActivityEnable), a
	; Port 5A, ViewScreen DMA
	out	(pViewScreenDma), a
	; Port 57, line interrupts
	ld	a, cidFall | cidRise | vbusRise | vbusFall
	out	(pUsbIntrEnable), a
	; Port 54, USB suspend control
	ld	a, swDisable48Mhz
	out	(pUsbSuspendCtrl), a
	; Port 5B, ViewScreen and USB protocol interrupts
	ld	a, usbCoreIntrEnable
	out	(pUsbCoreIntrEnable), a
	; Now reset stuff
	call	WaitForControllerReset
	ld	a, usbReset_
	out	(pUsbSystem), a
.endif
	xor	a
	ret
.ifdef	NEVER
;Enables USB communication.
; (Original function by BrandonW)
	; Enable protocol interrupts
	ld	a, usbCoreIntrEnable
	out	(pUsbCoreIntrEnable), a
	ld	a, 0FFh
	out	(pUsbIntrTxMask), a
	xor	a
	out	(pUsbTxCsrCont), a
;	in	a, (pUsbIntrTxMask)	; ?
	ld	a, 0FFh			; NOTA BENE OLD VALUE: 0Eh
	out	(pUsbIntrRxMask), a
	; TODO: Handle other events
	ld	a, usbIntrReset;usbCoreAllIntrMask
	out	(pUsbIntrMask), a
	; Release the controller reset
	call	WaitForControllerReset
	ld	a, usbReset_
	out	(pUsbSystem), a
	xor	a
	ret
.endif


;------ FlushUsbInterrupts -----------------------------------------------------
FlushUsbInterrupts:
; Flushes all pending interrupts.
; TODO: Also flush hardware sources of interrupts?
; NOT SAFE TO USE IN INTERRUPT HANDLER
; Inputs:
;  - None
; Outputs:
;  - None
; Destroys:
;  - HL
;  - A
	LogUsbQueueEvent(lidUsbQueueFlushInts, logNoReg)
	ld	a, 1
	ld	(usbIntRecurseFlag), a
	ld	hl, usbEvQueue
	ld	(usbEvQWritePtr), hl
	ld	(usbEvQReadPtr), hl
	ret


;------ ResetUsb ---------------------------------------------------------------
ResetUsb:
; Resets USB and returns stuff to OS values.
; TODO: End point setup?
; (Original function by BrandonW)
; Inputs:
;  - None
; Outputs:
;  - None
; Destroys:
;  - AF
	; Disable interrupts
	xor	a
	out	(pUsbCoreIntrEnable), a
	; Reset the USB controller
	out	(pUsbSystem), a
	; Re-enable interrupts
	ld	a, usbCoreIntrEnable
	out	(pUsbCoreIntrEnable), a
	; Release controller reset
	call	WaitForControllerReset
	ld	a, usbReset_
	out	(pUsbSystem),a
	xor	a
	ret


;------ ResetController --------------------------------------------------------
ResetController:
; This resets the controller.
; (Original function by BrandonW)
; Inputs:
;  - None
; Outputs:
;  - None
; Destroys:
;  - AF
	LogUsbLowEvent(lidUsbLowReset, logNoReg)
	xor	a
	out	(pUsbSystem), a
WaitForControllerReset:
.ifndef	UNIT_TESTS
	in	a, (pUsbSystem)
	and	usbRstO
	jr	z, WaitForControllerReset
.endif
	ret


;===============================================================================
;====== USB Driver Interface ===================================================
;===============================================================================

;------ SetupDriver ------------------------------------------------------------
SetupDriver:
; Sets up the peripheral-mode driver.
; USB is enabled, interrupts are enabled
; Input:
;  - HL: Pointer to initial data
; Output:
;  - Peripheral mode ready
; Destroys:
;  - AF
;  - BC
;  - DE
;  - HL
;  - IX
	; Prevent USB confusion
	push	hl
	call	DisableUSB
	xor	a
	ld	(usbFlags), a
	call	FlushUsbInterrupts
	pop	hl
	; Global stuff
	ld	de, usbDescriptorsPtr
	ld	bc, (2 * 2) + (1 + 2) + (1 + 2)
	ldir
	; TX pipes
	ld	a, (usbTxPipeCount)
	ld	de, (usbTxPipe0VarsPtr)
@:	ld	bc, usbPipeVarsSize
	ldir
	dec	a
	jr	nz, {-1@}
	; RX pipes
	ld	a, (usbRxPipeCount)
	ld	de, (usbRxPipe0VarsPtr)
@:	ld	bc, usbPipeVarsSize
	ldir
	dec	a
	jr	nz, {-1@}
	ret


;===============================================================================
;====== USB Data ===============================================================
;===============================================================================

;   - .db flagsAndNumberOfEntires (max 64; specify zero for 64)
;        - Bit 7 processPacketApplyBitmask: Set to apply optional bitmask
;        - Bit 6 processPacketNoIncDe: Set to prevent incrementing DE
;     - If bitmask: .db bitmask
;     - .db matchValue1
;     - .dw jumpAddress1
;     - .db matchValue2
;     - .dw jumpAddress2
_controlPipeRequestProcessingTable:
; Check first byte: Request direction
	.db	processPacketApplyBitmask | 2
	.db	80h
	.db	00h	; Host to device
;	.dw	_controlPipeRxReqTable
	.db	80h	; Device to host
;	.dw	_controlPipeTxReqTable
.endmodule