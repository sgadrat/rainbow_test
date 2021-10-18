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

oam_mirror = $0200

.zeropage
	tmpfield1: .res 1
	tmpfield2: .res 1
	nmi_processing: .res 1

.segment "VECTORS"
	.word _nmi
	.word nes_init
	.word irq

.segment "FIXED_BANK"

.include "rainbow-routines.s"

nes_init:
	sei        ; disable IRQs
	ldx #$40
	cld        ; disable decimal mode
	stx $4017  ; disable APU frame IRQ
	ldx #$FF
	txs        ; Set up stack
	; fallthrough to rainbow_init

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

	; Message length, must be 1
	ldx RAINBOW_DATA
	cpx #1
	beq :+
		jmp fatal_failure
	:

	; Message type, must be READY
	lda RAINBOW_DATA
	cmp #FROMESP_MSG_READY
	beq :+
		jmp fatal_failure
	:

	; fallthrough to program

program:
	; Wait for two vblanks to be sure PPU is ready
	jsr wait_vbi
	jsr wait_vbi

	; Reset scrolling
	lda #$00
	sta scroll_x
	sta scroll_y

	; Move all sprites offscreen
	ldx #$00
	clr_sprites:
		lda #$fe
		sta oam_mirror, x    ;move all sprites off screen
		inx
		bne clr_sprites

	; Set palettes (background - black, sprites - white)
	bit PPUADDR
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR

	lda #$0f
	ldx #4*4
	:
		sta PPUDATA
		dex
		bne :-

	ldx #4
	:
		lda #$0f
		sta PPUDATA
		lda #$20
		sta PPUDATA
		sta PPUDATA
		sta PPUDATA
		dex
		bne :-

	; Enable rendering
	lda #%10010000  ;
	sta ppuctrl_val ; Reactivate NMI
	sta PPUCTRL     ;
	jsr wait_next_frame ; Avoid re-enabling mid-frame
	lda #%00011110 ; Enable sprites and background rendering
	sta PPUMASK    ;

	program_loop:
		;TODO
		jmp program_loop

fatal_failure:
	jmp fatal_failure

wait_next_frame:
	lda #1
	sta nmi_processing
	:
		lda nmi_processing
		bne :-
	rts

wait_vbi:
	bit PPUSTATUS
	:
		bit PPUSTATUS
		bpl :-
	rts

_nmi:
	; Save CPU registers
	php
	pha
	txa
	pha
	tya
	pha

	; Do not draw anything if not ready
	lda nmi_processing
	beq end

	; reload PPU OAM (Objects Attributes Memory) with fresh data from cpu memory
	lda #<oam_mirror
	sta OAMADDR
	lda #>oam_mirror
	sta OAMDMA

	; Scroll
	lda ppuctrl_val
	sta PPUCTRL
	lda PPUSTATUS
	lda scroll_x
	sta PPUSCROLL
	lda scroll_y
	sta PPUSCROLL

	; Inform that NMI is handled
	lda #$00
	sta nmi_processing

	; Restore CPU registers
	pla
	tay
	pla
	tax
	pla
	plp

	rti
