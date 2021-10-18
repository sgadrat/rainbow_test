.export game_init
.export game_tick

.import oam_mirror

.zeropage

	last_received_value: .res 1

.segment "PRG31"

game_init:
	lda #0
	sta last_received_value

	lda #$80
	sta oam_mirror
	lda #1
	sta oam_mirror+1
	lda #0
	sta oam_mirror+2
	sta oam_mirror+3
	rts

game_tick:
	inc last_received_value
	lda last_received_value
	sta oam_mirror+3
	rts
