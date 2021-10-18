;-------------------------------------------------------------------------------
; Invariable messages
;-------------------------------------------------------------------------------

esp_cmd_clear_buffers:
	.byt 1, TO_ESP::BUFFER_CLEAR_RX_TX

esp_cmd_get_esp_status:
	.byt 1, TO_ESP::ESP_GET_STATUS

;-------------------------------------------------------------------------------
; Utility routines
;-------------------------------------------------------------------------------

; Shorter call convetion for esp_send_cmd
;  register A - address of the command data (lsb)
;  register X - address of the command data (msb)
;
; Overwrites all registers, tmpfield1 and tmpfield2
esp_send_cmd_short:
.scope
	sta tmpfield1
	stx tmpfield2
	;rts ; Fallthrough to esp_send_cmd
.endscope

; Send a command to the ESP
;  tmpfield1,tmpfield2 - address of the command data
;
; Command data follows the format
;  First byte is the message length (number of bytes following this first byte).
;  Second byte is the command opcode.
;  Any remaining bytes are parameters for the command.
;
; Overwrites all registers
esp_send_cmd:
.scope
	ldy #0
	lda (tmpfield1), y
	sta ESP_DATA

	tax
	iny
	copy_one_byte:
		lda (tmpfield1), y
		sta ESP_DATA
		iny
		dex
		bne copy_one_byte

	rts
.endscope

; Retrieve a message from ESP
;  tmpfield1,tmpfield2 - address where the message is stored
;
; Message data follows the format
;  First byte is the message length (number of bytes following this first byte).
;  Second byte is the message type.
;  Any remaining bytes are payload of the message.
;
; Output
;  - Retrieved message is stored at address pointed by tmpfield1,tmpfield2
;  - Y number of bytes retrieved (zero if there was no message, message length otherwise)
;
; Note
;  - Y returns the contents of the "message length" field, so it is one less than the number
;    of bytes writen in memory.
;  - First byte of destination is always written (to zero if there was no message)
;  - It is indistinguishable if there was a message with a length field of zero or there
;    was no message.
;
; Overwrites all registers
esp_get_msg:
.scope
	ldy #0

	bit ESP_CONFIG
	bmi store_msg

		; No message, set msg_len to zero
		lda #0
		sta (tmpfield1), y
		jmp end

	store_msg:
		lda ESP_DATA ; Garbage byte
		nop
		lda ESP_DATA ; Message length
		sta (tmpfield1), y

		tax
		inx
		copy_one_byte:
			dex
			beq end

			iny
			lda ESP_DATA
			sta (tmpfield1), y

			jmp copy_one_byte

	end:
	rts
.endscope

; Wait for ESP data to be ready to read
esp_wait_answer:
.scope
	wait_ready_bit:
		bit ESP_CONFIG
		bpl wait_ready_bit
	rts
.endscope
