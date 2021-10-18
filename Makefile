CA := ca65
LD := ld65
ROOT_DIR := .
CFLAGS := -Os -Wall -Wextra -Werror -I $(ROOT_DIR)

all: \
	src/send_receive.o \
	system/ines.o \
	chr/tiles.o \
	send_receive.nes

clean:
	rm -f \
		src/send_receive.o \
		system/ines.o \
		chr/tiles.o \
		send_receive.nes \
		send_receive.map \
		send_receive.dbg

src/send_receive.o: src/send_receive.s
	$(CA) $<

system/ines.o: system/ines.s
	$(CA) $<

chr/tiles.o: chr/tiles.s chr/background.chr chr/sprite.chr
	$(CA) $<

send_receive.nes: system/ld65.cfg chr/tiles.o src/send_receive.o
	$(LD) -o $@ \
	-C system/ld65.cfg \
	--dbgfile send_receive.dbg \
	--mapfile send_receive.map \
	src/send_receive.o \
	system/ines.o \
	chr/tiles.o
