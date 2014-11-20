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



_doStartDriver:
	ld	hl, hidDriverSetupData
	call	SetupDriver
	call	InitializePeripheralMode
	ld	hl, unitTestsMenu
	jp	Menu


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
