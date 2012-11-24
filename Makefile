all: snaeks

snaeks: *.pas sdl/*.pas
	./fpclean -S2 -gw3 -Fi./sdl -Fu./sdl -osnaeks main.pas

clean:
	rm *.o *.ppu sdl/*.ppu sdl/*.o snaeks
