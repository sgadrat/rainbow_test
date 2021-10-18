.feature at_in_identifiers

.importzp _sp0, _sp1, _fp0, _fp1
.importzp _r0, _r1, _r2, _r3, _r4, _r5, _r6, _r7
.importzp _s0, _s1, _s2, _s3, _s4, _s5, _s6, _s7
.importzp _tmp0, _tmp1

.import main
.import nmi
.import irq
.import __DATA_RUN__
.import __DATA_LOAD__
.import __DATA_SIZE__

.include "rainbow-constants.s"

.segment "VECTORS"
	.word _nmi
	.word __STARTUP_LOAD__
	.word irq

.segment "FIXED_BANK"
	sei        ; disable IRQs
	ldx #$40
	cld        ; disable decimal mode
	stx $4017  ; disable APU frame IRQ
	ldx #$FF
	txs        ; Set up stack

rainbow_init:
	; Enable ESP
	lda #%00000001
	sta RAINBOW_FLAGS

	; Configure rainbow mapper
	lda #%00010110 ; ssmmrccp - horizontal mirroring, CHR-ROM, 8k CHR window, 16k+8k+8k PRG banking
	sta RAINBOW_CONFIGURATION

	; Select the PRG bank just before the last for the variable 8k window (emulating 16k variable + 16k fixed banking)
	lda #%00111110 ; c.BBBBbb - PRG-ROM, befor the last bank
	sta RAINBOW_PRG_BANKING_3

	; Select the first CHR-BANK
	lda #%00000000 ; .......u - bank number's upper bit (always zero if not in 1K CHR window)
	sta RAINBOW_CHR_BANKING_UPPER
	lda #%00000000 ; BBBBBBBB - first bank
	sta RAINBOW_CHR_BANKING_1

	; Select the first WRAM bank
	lda #%00000000 ; ccBBBBbb - WRAM, first bank
	sta RAINBOW_WRAM_BANKING

	; Disable scanline IRQ
	sta RAINBOW_IRQ_DISABLE

	; Disable sound extension
	;lda #%00000000 ; E...FFFF - disable, (don't care of frequency) ; useless - the value in A is already good
	sta RAINBOW_PULSE_CHANNEL_1_FREQ_HIGH
	sta RAINBOW_PULSE_CHANNEL_2_FREQ_HIGH
	sta RAINBOW_SAW_CHANNEL_FREQ_HIGH

	; Wait for ESP to be ready
	lda #<esp_cmd_clear_buffers ; Clear RX/TX buffers
	ldx #>esp_cmd_clear_buffers
	jsr esp_send_cmd_short

	ldx #2              ; Wait two frames for the clear to happen
	bit PPUSTATUS
	vblank_wait:
		bit PPUSTATUS
		bpl vblank_wait
	dex
	bne vblank_wait

	wait_empty_buffer:        ; Be really sure that the clear happened
		bit RAINBOW_FLAGS
		bmi wait_empty_buffer

	lda #<esp_cmd_get_esp_status ; Wait for ESP to be ready
	ldx #>esp_cmd_get_esp_status
	jsr esp_send_cmd_short
	jsr esp_wait_answer

	lda RAINBOW_DATA ; Burn garbage byte

	.( ; Message length, must be 1
		ldx RAINBOW_DATA
		cpx #1
		beq ok
			jmp fatal_failure
		ok:
	.)

	.( ; Message type, must be READY
		lda RAINBOW_DATA
		cmp #FROMESP_MSG_READY
		beq ok
			jmp fatal_failure
		ok:
	.)

program:
	;TODO

fatal_failure:
	jmp fatal_failure

_nmi:
	; Save CPU registers
	php
	pha
	txa
	pha
	tya
	pha

	;TODO

	; Restore CPU registers
	pla
	tay
	pla
	tax
	pla
	plp

	rti
