.segment "HEADER"

MAPPER_NUMBER = 3872
SUBMAPPER_NUMBER = 0
MAPPER_BATTERY_FLAG = 0

.byte 'N', 'E', 'S', $1a ; ID
.byt 32         ; PRG section occupies 32*16KiB memory
.byt 1          ; CHR-ROM section occupies 1*8KiB memory
.byt ((MAPPER_NUMBER & $00f) << 4) + (MAPPER_BATTERY_FLAG << 1) ; Flags 6 NNNN FTBM - mapper low nibble, no four screen, no trainer, persistent memory, horizontal mirroring
.byt (MAPPER_NUMBER & $0f0) + %00001000 ; Flags 7 NNNN 10TT - mapper mid nibble, NES 2.0, NES/Famicom
.byt (SUBMAPPER_NUMBER << 4) + ((MAPPER_NUMBER & $f00) >> 8) ; Flags 8 SSSS NNNN - submapper, mapper high nibble
.byt %00000000  ; Flags 9 CCCC PPPP - CHR-ROM size MSB = 0, PRG-ROM size MSB = 0
.byt 0          ; Flags 10 pppp PPPP - PRG-RAM non-volatile = 0, volatile = 0
.byt %00000111 ; Flags 11 cccc CCCC - CHR-NVRAM, CHR-RAM
.byt %00000001  ; Flags 12 .... ..VV - PAL timing
.byt 0          ; Flags 13
.byt 0          ; Flags 14
.byt 0          ; Flags 15
