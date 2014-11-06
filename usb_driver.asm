.define	USB_CORE_DRIVER
; Global data:
;  - Flags
;     - Device started (has address)
;     - USB suspended
;     - A cable connected error
;     - Set address pending
;     - Master error
;  - Enabled pipes map
;     - No events can be issued on non-enabled pipe
;  - Set address temp
;  - Descriptors tables ptr
;  - Master error callback
;  - Device start (B cable connect) callback
;  - Device stop (B cable disconnect) callback
;  - Bus suspend callback
;  - Bus resume callback
;  - Control pipe TX buffer
;  - Control pipe RX buffer
;
; Pipe array:
;  - Flags
;     - Callback invocation mode
;        - On interrupt
;        - On event check
;     - Automatic buffering flag/buffer data ready to send flag
;        - If set for TX pipe, driver will automatically break send data up
;          into packets as needed, and send packets until buffer is empty
;           - Must call send packet function to start TX
;        - If set for RX pipe, driver will automatically combine received
;          packets.  RX callback is called after each packet because it is
;          not always possible to tell when RX complete without protocol
;     - Automatic buffering complete flag
;        - Set when all data for TX sent
;        - Set when non-full-packet RX
;  - Packet TX/TX callback
;     - If automatic buffering enabled, called after buffer is empty/full
;     - If no automatic buffering, called after TX/RX completes
;  - Buffer ptr
;  - Buffer size
;  - Buffer read ptr
;  - Buffer write ptr
;
; Functions:
;  - Release DPC
;  - Send buffered packet
;  - Buffer received packet
;
; Errors:
;  - A cable connected
;  - B cable disconnected
;  - Host demands stall

;  - PacketRx
;  - PacketTxFinished

; So this is how your peripheral-mode driver will work:
;  - Call the initialize routine to place the driver into peripheral mode
;     - This routine will set up interrupts, enable controller, set up descriptor vectors
;  - When a B-style cable is connected,
;     - The driver will call the device start callback after address is set
;     - The driver will emit descriptors as needed
;     - When the host has configured the calculator, usbPeripheralConfigured will be set
;  - At this point, you can use the send calls to send data
;  - When the host requests data, usbHostRequestsData will be set
;  - You need to poll the event flags regularly in your own event loop.


; USB events

;===============================================================================
;====== USB Event Queueing Subsystem ===========================================
;===============================================================================
; Some USB events may take a while to process.  Additionally, some USB ports can
; indicate multiple events, but reading one ACKS all.  So it is useful to queue
; USB events to prevent events from being lost.

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
;  - DE: Event processing callback address
;  - HL: Argument word
	push	hl
	call	QueueUsbWord
	pop	de
	call	QueueUsbWord
	jr	_ProcessUsbEvents


;------ QueueUsbEventByte ------------------------------------------------------
_QueueUsbEventByte:
; Queues a USB event, and then goes on to processing pending events.
; Inputs:
;  - DE: Event processing callback address
;  - A: Argument byte
	call	QueueUsbWord
	call	QueueUsbByteA
	jr	_ProcessUsbEvents


;------ QueueUsbEventNull ------------------------------------------------------
_QueueUsbEventNull:
; Queues a USB event, and then goes on to processing pending events.
; Input:
;  - DE: Event processing callback address
	call	QueueUsbWord


;------ ProcessUsbEvents -------------------------------------------------------
_ProcessUsbEvents:
	ld	hl, usbIntRecurseFlag
	dec	(hl)
	jr	z, {@}
	inc	(hl)
	jp	_ExitUsbInterrupt
@:	ei
@:	call	_DequeueUsbWord
	jp	nz, {@}
	di
	ld	hl, usbIntRecurseFlag
.ifndef	DEBUG
	inc	(hl)
.else
	ld	a, (hl)
	or	a
	call	nz, Panic
	inc	a
	ld	(hl), a
.endif
	pop	de
	pop	bc
	pop	hl
	pop	af
	ei
	ret
@:	ex	de, hl
	call	CallHL
	jr	{-2@}


_processUsbEventMasterError:
	call	_DequeueUsbByteA
	ld	hl, (usbMasterErrorCb)
	call	CallHL
	ret


_processUsbEventBConnect:
	call	InitializePeripheralMode
	call	c, Panic
	ret


_processUsbEventUsbProtocol:
	call	_DequeueUsbByteA
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
	push	af
	ld	hl, (usbSuspendCb)
	call	CallHl
	pop	af
	ret

_pueResume:
	push	af
	ld	hl, (usbResumeCb)
	call	CallHl
	pop	af
	ret

_pueReset:
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
	ret


_processUsbEventTxComplete:
	call	_DequeueUsbByteA
	ld	c, 0
	ld	hl, usbTxPipe0 + usbPipeDataProcCb
@:	or	a
	ret	z
	rra
	call	c, _pueTxCompleteProcess
	inc	c
	ld	de, usbPipeVarsSize
	add	hl, de
	jr	{-1@}
_pueTxCompleteProcess:
	push	af
	push	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	dec	hl
	dec	hl
	dec	hl
	ex	de, hl
	ld	a, c
	call	CallHL
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
	LogUsbIntEvent8(lidUsbIntDo, a)
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
	pop	de
	pop	bc
	pop	hl
	pop	af
	ei
	ret


_handleVscreenIntr:
	; Never use this.
	LogUsbIntEventNull(lidUsbIntVScreen)
	jp	Panic

_handleVbusTimeoutIntr:
	; Toshiba PHY discharge timeout occurred
	; This is basically an OTG SRP timeout
	; TODO: Make dealing with this configurable? Or something?
	LogUsbIntEventNull(lidUsbIntVBusTimeout)
	jp	Panic

_handleLineIntr:
	in	a, (pUsbIntrStatus)
	LogUsbIntEvent8(lidUsbIntLine, a)
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
	LogUsbIntEvent8(lidUsbIntLineBDisconnect, c)
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
	ld	de, (usbDeviceStopCb)
	jp	QueueUsbEventNull
_bCableConnect:
	LogUsbIntEvent8(lidUsbIntLineBConnect, c)
	ld	a, vbusRise
	call	_clearUsbLineEvent
	ld	de, _processUsbEventBConnect
	jp	_QueueUsbEventNull
_aCableConnect:
	LogUsbIntEvent8(lidUsbIntLineAConnect, c)
	ld	a, cidFall
	call	_clearUsbLineEvent
	ld	a, usbErrACable
	ld	de, _processUsbEventMasterError
	jp	_QueueUsbEventByte
_aCableDisconnect:
	LogUsbIntEvent8(lidUsbIntLineADisconnect, c)
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
; TODO: This shouldn't leave interrupts disabled so long.
; It should, once the event is identified, enable interrupts
	; TODO: For a dual-role host/peripheral driver, here we should check
	; pUsbDevCtl for whether we're in host or peripheral mode.
	in	a, (pUsbIntrId)
	or	a
	jr	z, {@}
	LogUsbIntEvent8(lidUsbIntProt, a)
	ld	de, _processUsbEventUsbProtocol
	jp	_QueueUsbEventByte
@:	; Check for TX complete
	in	a, (pUsbIntrTx)
	or	a
	jr	z, {@}
	LogUsbIntEvent8(lidUsbIntTxComplete, a)
	ld	de, _processUsbEventTxComplete
	jp	_QueueUsbEventByte
@:	; Check for RX complete
	in	a, (pUsbIntrRx)
	or	a
	jr	z, {@}
	LogUsbIntEvent8(lidUsbIntRxComplete, a)
	ld	de, _processUsbEventRxComplete
	jp	_QueueUsbEventByte
	; It shouldn't be possible to get here.
@:	call	Panic


;===============================================================================
;====== USB Protocol Subsystem =================================================
;===============================================================================

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
	out	(pUsbIndex), a
	add	a, pUsbPipe
	ld	c, a
	in	a, (pUsbRxCount)
	or	a
	ret	z
	ld	b, a
	inir
	scf
	ret

;------ ReadPacketByte ---------------------------------------------------------
ReadPacketByte:
; Reads a byte from a packet.  Just one.
; Inputs:
;   - C: Pipe number
; Outputs:
;   - A: Byte read
;   - Z: No bytes left?


;------ WritePacket ------------------------------------------------------------
WritePacket:
; Writes a packet of data to a pipe
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
	out	(pUsbIndex), a
	add	a, pUsbPipe
	ld	c, a
	in	a, (pUsbTxCsr)
	and	txCsrTxPktRdy	; Same as csr0TxPktRdy, so this also works the control pipe
	ret	nz
	ld	a, b
	or	a
	jr	z, {@}
	otir
@:	ld	a, txCsrTxPktRdy
	out	(pUsbTxCsr), a
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
	out	(pUsbIndex), a
	ld	a, rxCsrClrDataOtg | rxCsrFlushFifo	; I donno, just try both.
	out	(pUsbRxCsr), a
	push	hl
	
	pop	hl
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
	out	(pUsbIndex), a
	or	a
	jr	z, {@}
	ld	a, txCsrFifoFlushFifo	; Flush pipe
	out	(pUsbTxCsr), a
	ret
@:	ld	a, csr0ContFlushFifo	; Flush pipe
	out	(pUsbCsr0Cont), a
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
;     - jumpAddress: .db 0 ; this will chain to another table
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
	or	a
	jr	z, ProcessPacket
	jp	(hl)


;===============================================================================
;====== USB PHY ================================================================
;===============================================================================

;------ InitializePeripheralMode -----------------------------------------------
InitializePeripheralMode:
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
ResetPipes:
	; Enable correct number of TX pipes
	ld	a, (usbTxPipeCount)
	ld	b, a
	ld	a, 1
@:	rla
	djnz	{-1@}
	dec	a
	out	(pUsbIntrTxMask), a
	; Enable correct number of RX pipes
	ld	a, (usbRxPipeCount)
	ld	b, a
	ld	a, 1
@:	rla
	djnz	{-1@}
	dec	a
	dec	a		; Disable RX on control pipe
	out	(pUsbIntrRxMask), a
	xor	a
	out	(pUsbIntrTxMaskCont), a
	out	(pUsbIntrRxMaskCont), a
	; Pipes
	xor	a
	out	(pUsbIndex), a
	ld	a, csr0ContFlushFifo
	out	(pUsbCsr0Cont), a
	ld	b, 1
@:	ld	a, b
	cp	8
	jr	z, {@}
	out	(pUsbIndex), a
	ld	a, txCsrFifoFlushFifo
	out	(pUsbTxCsr), a
	ld	a, txCsrContWrDataToggle
	out	(pUsbTxCsrCont), a
	ld	a, rxCsrFlushFifo
	out	(pUsbRxCsr), a
	xor	a
	out	(pUsbRxCsrCont), a
	jr	{-1@}
@:	; I guess we're done.
	ret

	
.ifdef	NEVER
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
; Inputs:
;  - None
; Outputs:
;  - None
; Destroys:
;  - HL
;  - A
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
	xor	a
	out	(pUsbSystem), a
WaitForControllerReset:
	in	a, (pUsbSystem)
	and	usbRstO
	jr	z, WaitForControllerReset
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
	call	DisableUSB
	; Global stuff
	ld	de, usbDescriptorsPtr
	ld	bc, 8 * 2 + 2
	ldir
	; TX pipes
	ld	a, (usbTxPipeCount)
	inc	hl
	ld	de, (usbTxPipe0VarsPtr)
@:	ldi
	inc	de
	ld	bc, 10
	ldir
	dec	a
	jr	nz, {-1@}
	; RX pipes
	ld	a, (usbRxPipeCount)
	inc	hl
	ld	de, (usbRxPipe0VarsPtr)
@:	ldi
	inc	de
	ld	bc, 10
	ldir
	dec	a
	jr	nz, {-1@}
	ret