CA := ca65
LD := ld65
ROOT_DIR := .
CFLAGS := -Os -Wall -Wextra -Werror -I $(ROOT_DIR)

all: \
	src/ping.o \
	system/ines.o \
	chr/tiles.o \
	ping.nes

clean:
	rm -f \
		src/ping.o \
		system/ines.o \
		chr/tiles.o \
		ping.nes \
		ping.map \
		ping.dbg

src/ping.o: src/ping.s
	$(CA) $<

system/ines.o: system/ines.s
	$(CA) $<

chr/tiles.o: chr/tiles.s chr/background.chr chr/sprite.chr
	$(CA) $<

ping.nes: system/ld65.cfg chr/tiles.o src/ping.o
	$(LD) -o $@ \
	-C system/ld65.cfg \
	--dbgfile ping.dbg \
	--mapfile ping.map \
	src/ping.o \
	system/ines.o \
	src/main.o \
	chr/tiles.o
