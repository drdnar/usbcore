	.db	0
unitTestsMenu:
;		 1234567890123456 C 0123456789012345
;	.db	"            UNIT TESTS
	.db	"           "
	.db	80h, ('U'|80h), ('N'|80h), ('I'|80h), ('T'|80h), (' '|80h)
	.db	('T'|80h), ('E'|80h), ('S'|80h), ('T'|80h), ('S'|80h)
	.db	80h, chNewLine
	.db	"1. Start driver", chNewLine
	.db	"2. Queue tests", chNewLine
	.db	"3. Buffering tests"
	.db	0
	.db	sk1
	.dw	_doStartDriver
	.db	sk2
	.dw	_queueTests - 1
	.db	sk3
	.dw	_bufferTests - 1
	.db	skClear
	.dw	Restart
	.db	0

_queueTests:
;		 1234567890123456 C 0123456789012345
;	.db	"            QUEUE TESTS
	.db	"            "
	.db	80h, ('Q'|80h), ('U'|80h), ('E'|80h), ('U'|80h), ('E'|80h), (' '|80h)
	.db	('T'|80h), ('E'|80h), ('S'|80h), ('T'|80h), ('S'|80h)
	.db	80h, chNewLine
	.db	"1. Show queue", chNewLine
	.db	"2. Flush queue", chNewLine
	.db	"3. Add event", chNewLine
	.db	"4. Run one queue event", chNewLine
	.db	"5. Run all queue events", chNewLine
	.db	"6. Add byte", chNewLine
	.db	"7. Add word", chNewLine
	.db	0
	.db	sk1
	.dw	_showQueue
	.db	sk2
	.dw	_doStartDriver
	.db	sk3
	.dw	_flushQueue
	
	.db	sk6
	.dw	_queueByte
	.db	sk7
	.dw	_queueWord
	.db	skClear
	.dw	unitTestsMenu - 1
	.db	0

_bufferTests:
;		 1234567890123456 C 0123456789012345
;	.db	"           BUFFER TESTS
	.db	"           "
	.db	80h, ('B'|80h), ('U'|80h), ('F'|80h), ('F'|80h), ('E'|80h), ('R'|80h), (' '|80h)
	.db	('T'|80h), ('E'|80h), ('S'|80h), ('T'|80h), ('S'|80h)
	.db	80h, chNewLine
	.db	"1. Show buffer", chNewLine
	.db	"2. Flush byffer", chNewLine
	.db	"3. Add byte", chNewLine
	.db	"4. Remove byte", chNewLine
	.db	"5. TX packet", chNewLine
	.db	"6. RX packet", chNewLine
	.db	0
	.db	skClear
	.dw	unitTestsMenu - 1
	.db	0

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
_dumpHeader:
	.db	"      00 01 02 03 04 05 06 07", chNewLine, 0
_writeStr:
	.db	"Write ptr: ", 0
_readStr:
	.db	"Read ptr: ", 0
_showQueue:
	call	ClearWind
	ld	hl, _dumpHeader
	call	PutS
	ld	ix, usbEvQueue
	ld	c, 4
_showQueueLineLoop:
	push	ix
	pop	hl
	call	DispHL
	ld	a, ':'
	call	PutC
	ld	b, 8
_showQueueByteLoop:
	ld	a, ' '
	call	PutC
	ld	a, (usbEvQWritePtr)
	ld	hl, flags + mTextFlags
	cp	ixl
	jr	z, {@}
	ld	a, (usbEvQReadPtr)
	cp	ixl
	jr	nz, {2@}
@:	set	mTextInverse, (hl)
;	ld	a, '.'
;	call	PutC
@:	ld	a, (ix)
	inc	ix
	call	DispByte
	res	mTextInverse, (hl)
	djnz	_showQueueByteLoop
	call	NewLine
	dec	c
	jr	nz, _showQueueLineLoop
	ld	hl, _writeStr
	call	PutS
	ld	hl, (usbEvQWritePtr)
	call	DispHL
	call	NewLine
	ld	hl, _readStr
	call	PutS
	ld	hl, (usbEvQReadPtr)
	call	DispHL
	call	NewLine
	call	ClearAllShiftFlags
	ld	a, cursorOtherMask
	ld	(flags + mCursorFlags), a
	ld	a, chCurUnderline
	ld	(cursorChar), a
	call	CursorOn
	call	GetKey
	call	CursorOff
	ld	hl, _queueTests
	jp	Menu