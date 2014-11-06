HidTest:
	ld	hl, hidTestPipeSetupData
	call	SetupDriver
	call	InitializePeripheralMode
	

hidTestErrorCb:
	call	DisableUsb
	ld	hl, hidTestErr
	jp	Menu


hidTestStartCb:
	ld	hl, hidTestStartMsg
	call	PutS
	ret


hidTestStartCb:
	ld	hl, hidTestStopMsg
	call	PutS
	ret
	

hidTestSuspendCb:
	ld	hl, hidTestSuspendMsg
	call	PutS
	ret


hidTestResumeCb:
	ld	hl, hidTestResumeMsg
	call	PutS
	ret

	
hidTestStartMsg:
	.db	"Start ", 0

hidTestStopMsg:
	.db	"Stop ", 0

hidTestSuspendMsg:
	.db	"Sus ", 0

hidTestResumeMsg:
	.db	"Res ", 0


hidTestErr:
	.db	"MASTER ERROR"
	.db	0
	.db	skClear
	.dw	Restart
	.db	0


hidTestPipeSetupData:
	.db	0			; usbFlags
	.db	0			; usbEventFlags
	.dw	hidTestDescriptors	; usbDescriptorsPtr
	.dw	hidTestErrorCb		; usbMasterErrorCb
	.dw	hidTestStartCb		; usbDeviceStartCb
	.dw	hidTestStopCb		; usbDeviceStopCb
	.dw	hidTestSuspendCb	; usbSuspendCb
	.dw	hidTestResumeCb		; usbResumeCb
	; TX pipes
	.db	2
	; Control pipe
	.db	0			; usbPipeFlags
	.db				; usbPipeDataProcCb
	.dw				; usbPipeBufferPtr
	.dw				; usbPipeBufferDataSize
	.dw				; usbPipeBufferReadPtr
	.dw				; usbPipeBufferWritePtr


