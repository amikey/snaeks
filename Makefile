all: snaeks

snaeks: *.pas sdl/*.pas
	./fpclean -g -Fi./sdl -Fu./sdl -osnaeks main.pas

clean:
	rm *.o *.ppu sdl/*.ppu sdl/*.o snaeks
