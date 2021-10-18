.export game_init
.export game_tick

.import oam_mirror
.import wait_next_frame
.import esp_send_cmd_short, esp_get_msg
.importzp tmpfield1, tmpfield2

.include "rainbow-constants.s"

rainbow_buffer = $0300

.zeropage

	last_received_value: .res 1

.segment "PRG31"

game_init:
	; Init state
	lda #0
	sta last_received_value

	; Place progress sprites
	lda #$80
	sta oam_mirror
	lda #1
	sta oam_mirror+1
	sta oam_mirror+1+4
	lda #0
	sta oam_mirror+2
	sta oam_mirror+2+4
	sta oam_mirror+3
	sta oam_mirror+3+4

	; Connect to server
	jsr connect

	rts

game_tick:
.scope
	; Send a message
	lda #<send_data_cmd
	ldx #>send_data_cmd
	jsr esp_send_cmd_short

	; Check incoming message
	lda #<rainbow_buffer
	sta tmpfield1
	lda #>rainbow_buffer
	sta tmpfield2
	jsr esp_get_msg
	cpy #0
	beq end_receive

		; Length
		lda rainbow_buffer
		cmp #152
		bne fail

		; Type
		lda rainbow_buffer+1
		cmp #FROM_ESP::MESSAGE_FROM_SERVER
		bne fail

		; Padding
		ldx #150
		:
			lda rainbow_buffer+1, x
			sta tmpfield1
			cpx tmpfield1
			bne fail

			dex
			bne :-

		; Value
		lda rainbow_buffer+152
		sta last_received_value

		; Everything went well
		jmp end_receive

		fail:
			; Place error sprite
			lda #$88
			sta oam_mirror+4
			lda last_received_value
			sta oam_mirror+4+3

	end_receive:

	; Place progress sprite
	lda last_received_value
	sta oam_mirror+3

	send_data_cmd:
		.byt 11, TO_ESP::SERVER_SEND_MESSAGE, 1,2,3,4,5,6,7,8,9,10

	rts
.endscope

connect:
	; Get configured server info
	lda #<get_config_cmd
	ldx #>get_config_cmd
	jsr esp_send_cmd_short

	jsr wait_next_frame

	lda #<rainbow_buffer
	sta tmpfield1
	lda #>rainbow_buffer
	sta tmpfield2
	:
		jsr esp_get_msg
		cpy #0
		beq :-

	; Convert result to set_server command
	lda #TO_ESP::SERVER_SET_SETTINGS
	sta rainbow_buffer+1

	; Send the set_server command
	lda #<rainbow_buffer
	ldx #>rainbow_buffer
	jsr esp_send_cmd_short

	; Set protocol
	lda #<set_protocol_cmd
	ldx #>set_protocol_cmd
	jsr esp_send_cmd_short

	; Connect to server
	lda #<connect_cmd
	ldx #>connect_cmd
	jsr esp_send_cmd_short

	; Give the ESP some rest (not sure that it is necessary)
	jsr wait_next_frame

	rts

	get_config_cmd:
		.byt 1, TO_ESP::SERVER_GET_CONFIG_SETTINGS
	set_protocol_cmd:
		.byt 2, TO_ESP::SERVER_SET_PROTOCOL, SERVER_PROTOCOLS::UDP
	connect_cmd:
		.byt 1, TO_ESP::SERVER_CONNECT
