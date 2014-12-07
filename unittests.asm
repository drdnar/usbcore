unitTestsMenuShow:
	call	SetFullScrnWind
	ld	hl, unitTestsMenu
	jp	Menu

	.db	0
unitTestsMenu:
;		 1234567890123456 C 0123456789012345
	.db	"UNIT TESTS", 0
	.db	"1. Start driver", chNewLine
	.db	"2. Queue tests", chNewLine
	.db	"3. Buffering tests"
	.db	0
	.db	sk1
	.dw	_doStartDriver
	.db	sk2
	.dw	_queueTestsMenu
	.db	sk3
	.dw	_bufferTests - 1
	.db	skClear
	.dw	Restart
	.db	0

_queueTests:
;		 1234567890123456 C 0123456789012345
	.db	"QUEUE TESTS", 0
	.db	"1. Flush queue", chNewLine
	.db	"2. Add event", chNewLine
	.db	"3. Run one queue event", chNewLine
	.db	"4. Run all queue events", chNewLine
	.db	"5. Add byte", chNewLine
	.db	"6. Add word", chNewLine
	.db	0
	.db	sk1
	.dw	_flushQueue
	
	.db	sk5
	.dw	_queueByte
	.db	sk6
	.dw	_queueWord
	.db	skClear
	.dw	unitTestsMenuShow
	.db	0

_bufferTests:
	.db	"BUFFER TESTS", 0
	.db	"1. TX Buffer", chNewLine
	.db	"2. RX Buffer", chNewLine
	.db	0
	.db	sk1
	.dw	_txBufferMenuShow
	.db	sk2
	.dw	_rxBufferMenuShow
	.db	skClear
	.dw	unitTestsMenuShow
	.db	0

_txBufferMenu:
	.db	"TX BUFFER TESTS", 0
	.db	"1. Flush buffer", chNewLine
	.db	"2. Add byte", chNewLine
	.db	"3. Remove byte", chNewLine
	.db	"4. Set data size", chNewLine
	.db	"5. TX packet", chNewLine
	.db	0
	.db	sk1
	.dw	_flushTxBuffer
	.db	sk2
	.dw	_txAddByte
	.db	sk3
	.dw	_txRemoveByte
	.db	sk4
	.dw	_txSetDataSize
	.db	skClear
	.dw	_bufferTests - 1
	.db	0

_rxBufferMenu:
	.db	"RX BUFFER TESTS", 0
	.db	"1. Flush buffer", chNewLine
	.db	"2. Add byte", chNewLine
	.db	"3. Remove byte", chNewLine
	.db	"4. Set data size", chNewLine
	.db	"5. RX packet", chNewLine
	.db	0
	.db	sk1
	.dw	_flushRxBuffer
	.db	sk2
	.dw	_rxAddByte
	.db	sk3
	.dw	_rxRemoveByte
	.db	sk4
	.dw	_rxSetDataSize
	.db	skClear
	.dw	_bufferTests - 1
	.db	0

_flushTxBuffer:
	xor	a
	call	FlushTxBuffer
	jp	_txBufferMenuShow

_flushRxBuffer:
	xor	a
	call	FlushRxBuffer
	jp	_rxBufferMenuShow
	
_txAddByte:
	call	ClearWind
	ld	hl, _writeCountStr
	call	PutS
	xor	a
	call	GetTxPipePtr
	push	hl
	pop	ix
	call	GetBufferWriteByteCount
	call	DispHL
	call	NewLine
	ld	hl, _addByteStr
	call	PutS
	call	GetHexByte
	ld	b, a
	xor	a
	call	WriteTxBufferByte
	jp	_txBufferMenuShow

_rxAddByte:
	call	ClearWind
	ld	hl, _writeCountStr
	call	PutS
	xor	a
	call	GetRxPipePtr
	push	hl
	pop	ix
	call	GetBufferWriteByteCount
	call	DispHL
	call	NewLine
	ld	hl, _addByteStr
	call	PutS
	call	GetHexByte
	call	WriteBufferByte
	jp	_rxBufferMenuShow

_txRemoveByte:
	call	ClearWind
	ld	hl, _readCountStr
	call	PutS
	xor	a
	call	GetTxPipePtr
	push	hl
	pop	ix
	call	GetBufferReadByteCount
	call	DispHL
	call	NewLine
	ld	hl, _valueStr
	call	PutS
	call	ReadBufferByte
	call	DispByte
	call	GetKey
	jp	_txBufferMenuShow

_rxRemoveByte:
	call	ClearWind
	ld	hl, _readCountStr
	call	PutS
	xor	a
	call	GetRxPipePtr
	push	hl
	pop	ix
	call	GetBufferReadByteCount
	call	DispHL
	call	NewLine
	ld	hl, _valueStr
	call	PutS
	xor	a
	call	ReadRxBufferByte
	call	DispByte
	call	GetKey
	jp	_rxBufferMenuShow

_txSetDataSize:
	call	ClearWind
	ld	hl, _dataSizeStr
	call	PutS
	xor	a
	call	GetTxPipePtr
	push	hl
	pop	ix
	call	GetHexByte
	ld	(ix + usbPipeBufferDataSize + 1), a
	call	GetHexByte
	ld	(ix + usbPipeBufferDataSize), a
	jp	_txBufferMenuShow
	
_rxSetDataSize:
	call	ClearWind
	ld	hl, _dataSizeStr
	call	PutS
	xor	a
	call	GetRxPipePtr
	push	hl
	pop	ix
	call	GetHexByte
	ld	(ix + usbPipeBufferDataSize + 1), a
	call	GetHexByte
	ld	(ix + usbPipeBufferDataSize), a
	jp	_rxBufferMenuShow







_doStartDriver:
	ld	hl, hidDriverSetupData
	call	SetupDriver
	call	InitializePeripheralMode
	ld	hl, unitTestsMenu
	jp	Menu

_flushQueue:
	call	FlushUsbInterrupts
	ld	hl, _queueTests
	jp	Menu

_queueByte:
	call	ClearWind
	ld	hl, _enterData
	call	PutS
	call	GetHexByte
	call	Usb._QueueUsbByteA
	ld	hl, _queueTests
	jp	Menu

_queueWord:
	call	ClearWind
	ld	hl, _enterData
	call	PutS
	call	GetHexByte
	call	Usb._QueueUsbByteA
	call	GetHexByte
	call	Usb._QueueUsbByteA
	ld	hl, _queueTests
	jp	Menu

_enterData:
	.db	"Enter data: ", 0
;		 1234567890123456 C 0123456789012345
_writeStr:
	.db	"Write ptr: ", 0
_readStr:
	.db	"Read ptr: ", 0
_flagsConfStr:
	.db	"Flags/Conf: ", 0
_dataProcCbStr:
	.db	"Proc Cb: ", 0
_dataSizeStr:
	.db	"Data size: ", 0
_bufferPtrStr:
	.db	"Buffer root: ", 0
_writeCountStr:
	.db	"Write count: ", 0
_addByteStr:
	.db	"Add byte: ", 0
_readCountStr:
	.db	"Read count: ", 0
_valueStr:
	.db	"Value: ", 0


.ifndef	SMALL_FONT
lineLength	.equ	8
.else
lineLength	.equ	16
.endif




_queueVars:
	.db	2
	.dw	_writeStr
	.dw	usbEvQWritePtr
	.dw	_readStr
	.dw	usbEvQReadPtr

_txBufferVars:	;usbPipeBufferPtr
	.db	6
	.dw	_flagsConfStr
	.dw	hidTxPipe0Vars + usbPipeFlags
	.dw	_dataProcCbStr
	.dw	hidTxPipe0Vars + usbPipeDataProcCb
	.dw	_bufferPtrStr
	.dw	hidTxPipe0Vars + usbPipeBufferPtr
	.dw	_dataSizeStr
	.dw	hidTxPipe0Vars + usbPipeBufferDataSize
	.dw	_readStr
	.dw	hidTxPipe0Vars + usbPipeBufferReadPtr
	.dw	_writeStr
	.dw	hidTxPipe0Vars + usbPipeBufferWritePtr

_rxBufferVars:	;usbPipeBufferPtr
	.db	6
	.dw	_flagsConfStr
	.dw	hidRxPipe0Vars + usbPipeFlags
	.dw	_dataProcCbStr
	.dw	hidRxPipe0Vars + usbPipeDataProcCb
	.dw	_bufferPtrStr
	.dw	hidRxPipe0Vars + usbPipeBufferPtr
	.dw	_dataSizeStr
	.dw	hidRxPipe0Vars + usbPipeBufferDataSize
	.dw	_readStr
	.dw	hidRxPipe0Vars + usbPipeBufferReadPtr
	.dw	_writeStr
	.dw	hidRxPipe0Vars + usbPipeBufferWritePtr



_queueTestsMenu:
	ld	ix, usbEvQueue
	ld	c, 32 / lineLength
	ld	iy, _queueVars
	ld	hl, _queueTests
	jr	_windowedHexViewThingy

_txBufferMenuShow:
	ld	ix, hidControlTxBuffer
	ld	c, 64 / lineLength
	ld	iy, _txBufferVars
	ld	hl, _txBufferMenu
	jr	_windowedHexViewThingy

_rxBufferMenuShow:
	ld	ix, hidControlRxBuffer
	ld	c, 64 / lineLength
	ld	iy, _rxBufferVars
	ld	hl, _rxBufferMenu
	jr	_windowedHexViewThingy

;------ ------------------------------------------------------------------------
_windowedHexViewThingy:
	ld	a, 13
	ld	(windTop), a
	add	a, a
	ld	(windBottom), a
	push	hl
	call	ShowHexDump
	pop	hl
	xor	a
	ld	(windTop), a
	ld	a, 13
	ld	(windBottom), a
	jp	Menu


;------ ------------------------------------------------------------------------