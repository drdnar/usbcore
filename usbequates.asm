;====== Physical Layer Ports ===================================================
; Signals from USB transceiver PHY.  cf. Toshiba TC260 Z7USBOTGC1
pUsbXcvr		.equ	49h
xcvrDiDif		.equ	1	; Input
xcvrDiDifB		.equ	0
xcvrDop			.equ	2	; Input
xcvrDopB		.equ	1
xcvrDom			.equ	4	; Input
xcvrDomB		.equ	2
xcvrNdoe		.equ	8	; Input
xcvrNdoeB		.equ	3
xcvrSpeed		.equ	16	; Input
xcvrSpeedB		.equ	4
; Directly interfaces with control signals from the PHY
pPuPdCtrl		.equ	4Ah
puCon			.equ	1	; Input
puConB			.equ	0
puLo			.equ	2	; Input
puLoB			.equ	1
pdCon			.equ	4	; Input
pdConB			.equ	2
puConM1			.equ	8	; I/O. Pull-up switches on D-. 0=open, 1=closed
puConM1B		.equ	3
puConM2			.equ	16	; I/O. Same, should be 0 for normal operation
puConM2B		.equ	4
pdConM			.equ	32	; I/O. Pull-down switch.
pdConMB			.equ	5
; See Toshiba ZSVBUS datasheet
pVbusCtrl		.equ	4Bh
vbusVal			.equ	1	; I
vbusValB		.equ	0
vbusSes			.equ	2	; I
vbusSesB		.equ	1
vbusLo			.equ	4	; I
vbusLoB			.equ	2
vbusChg			.equ	8	; I
vbusChgB		.equ	3
vbusEn			.equ	16	; I
vbusEnB			.equ	4
vbusBypassEn		.equ	32	; I/O. Set to disable internal charge pump. cf. port 3A
vbusBypassEnB		.equ	5
zsvbusEn		.equ	64	; I. Possibly combination of values from USB core (vbusBypassEn AND vbusEn?)
zsvbusEnB		.equ	6
; 
pUsbSystem		.equ	4Ch
usbSuspend		.equ	1	; I. From USB core. Set if USB core is suspended and therefore wasting power unless disabled
usbSuspendB		.equ	0
usbRstO			.equ	2	; I. From USB core. Set when USB core is reset by external USB signal
usbRstOB		.equ	1
sofPulse		.equ	4	; I. From USB core
sofPulseB		.equ	2
usbReset_		.equ	8	; I/O. Active low; reset to enable power-up reset
usbReset_B		.equ	3
ipClockGated		.equ	16	; I. If reset, USB core is frozen, even if 48 MHz crystal is on
ipClockGatedB		.equ	4
phyEnable		.equ	32	; I. SET when PHY is enabled; RESET when PHY is in power-down
phyEnableB		.equ	5
chargePumpClockEnable	.equ	64	; I. Set if charge pump is getting clock
chargePumpClockEnableB	.equ	6
; These bitfields are also used with:
; pUsbIntrStatus pUsbIntrEnable pUsbHwEnActivity pUsbHwEnActivityEnable
pUsbActivity		.equ	4Dh
dipFall			.equ	01h	; From PHY
dipFallB		.equ	0
dipRise			.equ	02h
dipRiseB		.equ	1
dimFall			.equ	04h	; From PHY
dimFallB		.equ	2
dimRise			.equ	08h
dimRiseB		.equ	3
cidFall			.equ	10h	; From CID pin
cidFallB		.equ	4
cidRise			.equ	20h
cidRiseB		.equ	5
vbusRise		.equ	40h	; VBUS, obviously
vbusRiseB		.equ	6
vbusFall		.equ	80h
vbusFallB		.equ	7
; Port 4E: No function?
; The PHY allows VBUS to be discharged externally to expedite SRP inital
; conditions. See page 32 of the OTG specification.
pZsVbusCtrl		.equ	4Fh
zsVbusIden		.equ	1	; I
zsVbusIdenB		.equ	0
zsVbusSelVal		.equ	2	; I/O
zsVbusSelValB		.equ	1
internalUsbIoDischarge	.equ	4	; I/O
internalUsbIoDischargeB	.equ	2
srpStart		.equ	8	; I/O
srpStartB		.equ	3
zsVbusDischarge		.equ	16	; I
zsVbusDischargeB	.equ	4
zsVbusTimeOut		.equ	32	; I
zsVbusTimeOutB		.equ	5
zsVbusTimeOutIe		.equ	64	; I/O. This enables timeOutIntr in 55h. You must also clear srpStart.
zsVbusTimeOutIeB	.equ	6	; If this occurs, it's an error condition, so handle it accordingly.
extDischargeEnable	.equ	128	; I/O. Set this to enable the external charge pump, see port 50h
extDischargeEnableB	.equ	7
; See extDischargeEnable in pZsVbusCtrl.
; The ASIC has a built-in charge pump, but it also allows an external charge
; pump to be used.  If it's used, set extDischargeEnable in pZsVbusCtrl. This
; port controls some kind of timer in .48828125 ms (1/32768*16) increments.
pZsVbusSetValue		.equ	50h
; The USB parts run on a 48 MHz clock.  This is different than the clock the
; Z80 CPU uses.  The 48 MHz clock comes from a quartz crystal.  Like any quartz
; crystal, after power-up the crystal needs some time before its frequency is
; stable.
; For power-saving, the calculator can keep the 48 MHz clock turned off when
; USB is not in-use.  When you enable the 48 MHz crystal, the ASIC will wait
; some time before allowing the clock to reach the USB circuits.  These ports
; control that wait time.
; These ports are clocked by the 32768 Hz crystal, in 2-tick increments
; (0.061 ms).
; These normally seem to be set to 0 for some reason?  
; TODO: Maybe TI actually always leaves the 48 MHz crystal active?
p48MhzGateTime		.equ	51h
; This port controls when the charge pump gets it 1.5 MHz (48 Mhz / 32) clock.
pChargePumpEnableTime	.equ	52h
; This controls when the PD pin is deactivated. PD=1 kills power to the
; comparators and band gap circuits.
pPdEnableTime		.equ	53h
; There are two ways of disabling the 48 MHz clock when the controllers enters
; its suspend mode (USB_SUSPEND=1 (bit 0 of 4C)).
; 1. Get an interrupt by setting USB_suspend_IE=1---which enables
; USB_suspend_Intr (active high, bit 3 of 54)---, and then manually
; disable the crystal by setting SW_Disable_48MHz (bit 1 of 54).
; 2. Let hardware do it automatically.  Just set HW_Disable_48MHz_EN=1.
pUsbSuspendCtrl		.equ	54h
usbSuspendIe		.equ	1	; I/O. Set to allow interrupt
usbSuspendIeB		.equ	0
swDisable48Mhz		.equ	2	; I/O. Master disable signal
swDisable48MhzB		.equ	1
swEnableIpClk		.equ	4	; I/O. Set to enable 48 MHz to USB core
swEnableIpClkB		.equ	2
hwEnable48Mhz		.equ	8	; I
hwEnable48MhzB		.equ	3
hwDisable48MhzEn	.equ	16	; I/O
hwDisable48MhzEnB	.equ	4
hwDisable48Mhz		.equ	32	; I
hwDisable48MhzB		.equ	5
swEnablePhy		.equ	64	; I/O. Set to take PHY out of power-down mode
swEnablePhyB		.equ	6
swEnableChgPumpClock	.equ	128	; I/O. Set to enable 1.5 MHz clock to charge pump
swEnableChgPumpClockB	.equ	7
; This is for non-internal-signal interrupts.  See also port 5B.
pUsbCoreIntrStatus	.equ	55h
usbSuspendIntr_		.equ	1
usbSuspendIntrB_	.equ	0
vbusTimeOutIntr_	.equ	2
vbusTimeOutIntrB_	.equ	1
usbIntrStatusInt_	.equ	4	; Active LOW. See ports 56, 57
usbIntrStatusInt_B	.equ	2
vscreenIntr_		.equ	8	; Active LOW. Occurs if DMA misses a byte, and bit 2 of 5B is set
vscreenIntr_B		.equ	3
usbCoreInt_		.equ	16	; Real time status of interrupt from USB core. Bit 0 of 5B must set for this to trigger
usbCoreInt_B		.equ	4
; Pin interrupt thingies
; Maskable interrupts on DIP, DIM, CID, and VBUS
pUsbIntrStatus		.equ	56h
pUsbIntrEnable		.equ	57h
; These events can trigger an interrupt AND automatically enable the 48 MHz clock.
; Bit 3 (hwEnable48Mhz) of port 54 (pUsbSuspendCtrl) will be set when that happens.
; 59 enables the event, 58 identifies which triggered it.
; This is a latching signal, so you must zero and then rewrite when turning USB off again.
; The wake-up will also clear SW_Disable_48MHz (P:54 bit 1).
pUsbHwEnActivity	.equ	58h
pUsbHwEnActivityEnable	.equ	59h
; The ViewScreen is based on DMA.  You must also enable DMA in the USB core for this to work.
pViewScreenDma		.equ	5Ah
viewScreenDmaEnable	.equ	1
viewScreenDmaEnableB	.equ	0
; Some more interrupt-enables
pUsbCoreIntrEnable	.equ	5Bh
usbCoreIntrEnable	.equ	1	; I/O
usbCoreIntrEnableB	.equ	0
vscreenIntrEnable	.equ	4	; I/O
vscreenIntrEnableB	.equ	2


;====== USB Core ===============================================================
; And now crazy stuff.
; Current USB device address.
pUsbFAddr		.equ	80h
; Something to do with power
;In the USB practice, SOFTCONN (or SoftConnect) means the function which enables/disables D+ (or D-) pull-up resistor under VBUS monitoring.
pUsbPower		.equ	81h
usbPowerEnSuspend	.equ	1
usbPowerEnSuspendB	.equ	0
usbPowerSuspendM	.equ	2
usbPowerResume		.equ	4
usbPowerReset		.equ	8
; Outgoing data pipe events
pUsbIntrTx		.equ	82h
pUsbIntrTxCont		.equ	83h
; Incoming data pipe events
pUsbIntrRx		.equ	84h
pUsbIntrRxCont		.equ	85h
; USB interrupt event ID
pUsbIntrId		.equ	86h
usbIntrSuspend		.equ	01h
usbIntrSuspendB		.equ	0
usbIntrEp0		.equ	01h	; "FOR EP0 INTERRUPT"
usbIntrEp0B		.equ	0
usbIntrResume		.equ	02h
usbIntrResumeB		.equ	1
usbIntrReset		.equ	04h
usbIntrResetB		.equ	2
usbIntrBabble		.equ	04h
usbIntrBabbleB		.equ	2
usbIntrSof		.equ	08h
usbIntrSofB		.equ	3
usbIntrConnect		.equ	10h
usbIntrConnectB		.equ	4
usbIntrDisconnect	.equ	20h
usbIntrDisconnectB	.equ	5
usbIntrSessReq		.equ	40h
usbIntrSessReqB		.equ	6
usbIntrVbusError	.equ	80h	; "FOR SESSION END"
usbIntrVbusErrorB	.equ	7
; USB pipe interrupts
pUsbIntrTxMask		.equ	87h
pUsbIntrTxMaskCont	.equ	88h
pUsbIntrRxMask		.equ	89h
pUsbIntrRxMaskCont	.equ	8Ah
; USB interrupt mask
pUsbIntrMask		.equ	8Bh
; USB frame counter
pUsbFrame		.equ	8Ch
pUsbFrameCont		.equ	8Dh
; USB endpoint to control
pUsbIndex		.equ	8Eh
; DEVCTL
; Reads 91 when connected to PC and charging
pUsbDevCtl		.equ	8Fh
usbCtrlSession		.equ	01h	; Not sure what SESSION means
usbCtrlSessionB		.equ	0
;usbCtrlHostReq?		.equ	02h	; No idea, this is just called HR, so I'm making a guess
;usbCtrlHostReqB		.equ	1
usbCtrlHostMode		.equ	04h
usbCtrlHostModeB	.equ	2
usbCtrlVBus		.equ	18h
usbCtrlVBusB		.equ	3
usbCtrlLowSpeedDevice	.equ	20h	; Not valid in peripheral mode?
usbCtrlLowSpeedDeviceB	.equ	5
usbCtrlFullSpeedDevice	.equ	40h	; Not valid in peripheral mode?
usbCtrlFullSpeedDeviceB	.equ	6
usbCtrlBDevice		.equ	80h
usbCtrlBDeviceB		.equ	7

;#define MGC_M_DEVCTL_BDEVICE    0x80   
;#define MGC_M_DEVCTL_FSDEV      0x40
;#define MGC_M_DEVCTL_LSDEV      0x20
;#define MGC_M_DEVCTL_VBUS       0x18
;#define MGC_S_DEVCTL_VBUS       3
;#define MGC_M_DEVCTL_HM         0x04
;#define MGC_M_DEVCTL_HR         0x02
;#define MGC_M_DEVCTL_SESSION    0x01
pUsbTxMaxP		.equ	90h
;------ TX CSR -----------------------------------------------------------------
pUsbTxCsr		.equ	91h
pUsbTxCsrCont		.equ	92h
; These TX CSR defines are valid in all modes
txCsrTxPktRdy		.equ	01h
txCsrTxPktRdyB		.equ	0
txCsrFifoNotEmpty	.equ	02h
txCsrFifoNotEmptyB	.equ	1
txCsrFifoFlushFifo	.equ	08h
txCsrFifoFlushFifoB	.equ	3
txCsrClrDataOtg		.equ	40h
txCsrClrDataOtgB	.equ	6
; These three equates refer to pUsbTxCsrCont (92h)
txCsrContDmaMode	.equ	04h
txCsrContDmaModeB	.equ	2
txCsrContFrcDataOtg	.equ	08h	; This may or may not refer to full-speed
txCsrContFrcDataOtgB	.equ	3	; TODO: VERIFY THAT THESE ARE APPLY TO THE FDRC
txCsrContDmaEnab	.equ	10h	; Used for the ViewScreen
txCsrContDmaEnabB	.equ	4
;txCsrContMode		.equ	20h	; A one-bit mode setting?
;txCsrContModeB		.equ	5	; I have no idea.
;txCsrContIso		.equ	40h
;txCsrContIsoB		.equ	6
;txCsrContAutoSet	.equ	80h
;txCsrContAutoSetB	.equ	7
; These TX CSR defines are valid only in peripheral mode
txCsrUnderRun		.equ	04h
txCsrUnderRunB		.equ	2
txCsrSendStall		.equ	10h
txCsrSendStallB		.equ	4h
txCsrSentStall		.equ	20h	; So, I'm guessing bit 4 is the request for send-stall
txCsrSentStallB		.equ	5	; and bit 5 confirms when the stall has been sent
txCsrIncompTx		.equ	80h
txCsrIncompTxB		.equ	7
; These TX CSR defines are valid only in host mode
txCsrError		.equ	04h
txCsrErrorB		.equ	2
txCsrRxStall		.equ	20h
txCsrRxStallB		.equ	5
txCsrNakTimeOut		.equ	80h
txCsrNakTimeOutB	.equ	7
; These .equates refer to pUsbTxCsrCont (92h)
txCsrContDataToggle	.equ	01h
txCsrContDataToggleB	.equ	0
txCsrContWrDataToggle	.equ	02h
txCsrContWrDataToggleB	.equ	1
;------ CSR 0 ------------------------------------------------------------------
pUsbCsr0		.equ	91h
pUsbCsr0Cont		.equ	92h
; These CSR0 defines are valid in all modes
csr0RxPktRdy		.equ	01h
csr0RxPktRdyB		.equ	0
csr0TxPktRdy		.equ	02h
csr0TxPktRdyB		.equ	1
; This equate refers to pUsbCsr0Cont (92h)
csr0ContFlushFifo	.equ	01h
csr0ContFlushFifoB	.equ	0
; These CSR0 defines are valid only in peripheral mode
csr0SentStall		.equ	04h
csr0SentStallB		.equ	2
csr0DataEnd		.equ	08h
csr0DataEndB		.equ	3
csr0SetupEnd		.equ	10h
csr0SetupEndB		.equ	4
csr0SendStall		.equ	20h
csr0SendStallB		.equ	5
csr0SvdRxPktRdy		.equ	40h
csr0SvdRxPktRdyB	.equ	6
csr0SvdSetupEnd		.equ	80h
csr0SvdSetupEndB	.equ	7
; These CSR0 defines are valid only in host mode
csr0RxStall		.equ	04h
csr0RxStallB		.equ	2
csr0SetupPkt		.equ	08h
csr0SetupPktB		.equ	3
csr0Error		.equ	10h
csr0ErrorB		.equ	4
csr0ReqPkt		.equ	20h
csr0ReqPktB		.equ	5
csr0StatusPkt		.equ	40h
csr0StatusPktB		.equ	6
csr0NakTimeout		.equ	80h
csr0NakTimeoutB		.equ	7
; These three bits refer to pUsbCsr0Cont (92h)
csr0ContDataToggle	.equ	02h	; "data toggle control"
csr0ContDataToggleB	.equ	1
csr0ContWrDataToggle	.equ	04h	; "set to allow setting"
csr0ContWrDataToggleB	.equ	2
csr0ContNoPing		.equ	08h
csr0ContNoPingB		.equ	3
;------ RX Stuff ---------------------------------------------------------------
pUsbRxMapP		.equ	93h
pUsbRxCsr		.equ	94h
pUsbRxCsrCont		.equ	95h
; These RX CSR defines are valid in all modes
rxCsrRxPktRdy		.equ	01h
rxCsrRxPktRdyB		.equ	0
rxCsrFifoFull		.equ	02h
rxCsrFifoFullB		.equ	1
rxCsrDataError		.equ	08h
rxCsrDataErrorB		.equ	3
rxCsrFlushFifo		.equ	10h
rxCsrFlushFifoB		.equ	4
rxCsrClrDataOtg		.equ	80h
rxCsrClrDataOtgB	.equ	7
; These equates refer to pUsbRxCsrCont (95h)
rxCsrContIncompTx	.equ	01h
rxCsrContIncompTxB	.equ	0
rxCsrContDmaMode	.equ	08h
rxCsrContDmaModeB	.equ	3
rxCsrContDisNyet	.equ	10h
rxCsrContDisNyetB	.equ	4
rxCsrContDmaEnab	.equ	20h
rxCsrContDmaEnabB	.equ	5
rxCsrContAutoClear	.equ	80h
rxCsrContAutoClearB	.equ	7
; These RX CSR defines are valid only in peripheral mode
rxCsrOverrun		.equ	04h
rxCsrOverrunB		.equ	2
rxCsrSendStall		.equ	20h
rxCsrSendStallB		.equ	5
rxCsrSentStall		.equ	40h
rxCsrSentStallB		.equ	6
; This equate refer to pUsbRxCsrCont (95h)
rxCsrContIso		.equ	40h
rxCsrContIsoB		.equ	6
; These RX CSR defines are valid only in host mode
rxCsrError		.equ	04h
rxCsrErrorB		.equ	2
rxCsrReqPkt		.equ	20h
rxCsrReqPktB		.equ	5
rxCsrRxStall		.equ	40h
rxCsrRxStallB		.equ	6
; This equate refer to pUsbRxCsrCont (95h)
rxCsrContAutoReq	.equ	40h
rxCsrContAutoReqB	.equ	6
;------ More Stuff -------------------------------------------------------------
pUsbCount0		.equ	96h
pUsbRxCount		.equ	96h
pUsbRxCountCont		.equ	97h
pUsbTxType		.equ	98h
pUsbTxInterval		.equ	99h
pUsbNakLimit0		.equ	99h
pUsbRxType		.equ	9Ah
pUsbRxInterval		.equ	9Bh
;pUsbFifoSize		.equ	9Ch	; TODO: Verify these equates
;uUsbConfigData		.equ	9Ch	; TODO: Verify these equates
; More ports
pUsbPipe		.equ	0A0h
pUsbControlPipe		.equ	0A0h


;====== USB Protocol ===========================================================
.ifdef	NEVER

;------ Default Pipe Stuff -----------------------------------------------------

; Descriptors
usbDescTypeDevice	.equ	1
usbDescTypeConfig	.equ	2
usbDescTypeString	.equ	3
usbDescTypeIntrfc	.equ	4
usbDescTypeEndpoint	.equ	5
usbDescTypeDevQualifier	.equ	6
usbDescTypeSpeedConfig	.equ	7
usbDescTypeInterfPower	.equ	8
usbDescTypeProtocol	.equ	21h
usbDescTypeFunct	.equ	21h

; Feature selectors
usbFeatrDevRemoteWakeup	.equ	1
usbFeatrEndpointHalt	.equ	0
usbFeatrTestMode	.equ	2

; Offsets in RX packet
bmRequestTypeOffset	.equ	0
bRequestOffset		.equ	1
wValueOffset		.equ	2
wIndexOffset		.equ	4
wLengthOffset		.equ	6

bmRequestDirection	.equ	80h	; 1 = device-to-host
bmRequestDirectionB	.equ	7
bmRequestType		.equ	60h
bmRequestTypeStandard	.equ	0
bmRequestTypeClass	.equ	32
bmRequestTypeVendor	.equ	64
bmRequestRecipient	.equ	1Fh
bmRequestRecipDevice	.equ	0
bmRequestRecipInterface	.equ	1
bmRequestRecipEndpoint	.equ	2
bmRequestRecipOther	.equ	3

; Request codes, see also page 250 in PDF
bRequestGetStatus	.equ	0
bRequestClearFeature	.equ	1
bRequestSetFeature	.equ	3
bRequestSetAddress	.equ	5
bRequestGetDesc		.equ	6
bRequestSetDesc		.equ	7
bRequestGetConfig	.equ	8
bRequestSetConfig	.equ	9
bRequestGetInterf	.equ	10
bRequestSetInterf	.equ	11
bRequestSyncFrame	.equ	12

wIndexEPNumber		.equ	0Fh
wIndexEPDirection	.equ	80h
wIndexEPDirectionB	.equ	7
wIndexInterNumer	.equ	wIndexOffset


;------ ------------------------------------------------------------------------

endpntControl		.equ	0
endpntIsochronous	.equ	1
endpntBulk		.equ	2
endpntInterrupt		.equ	3

usbVersion		.equ	110h

usbClassHid		.equ	3

hidSubClassBoot		.equ	1
hidProtocolKbd		.equ	1
hidProtocolMouse	.equ	2
.endif