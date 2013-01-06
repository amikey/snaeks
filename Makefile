all: snaeks

snaeks: *.pas sdl/*.pas
	./fpclean -S2 -Si -gw -gv -Fi./sdl -Fu./sdl -osnaeks main.pas

clean:
	rm *.o *.ppu sdl/*.ppu sdl/*.o snaeks
