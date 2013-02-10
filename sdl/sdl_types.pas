unit SDL_types;

{$PACKRECORDS C}

interface
type
	Uint8 = byte;
	Sint8 = shortint;

	Uint16 = word;
	Sint16 = SmallInt;

	Uint32 = LongWord;
	Sint32 = Longint;

	Uint64 = QWord;
	
	int = LongInt;
	Uint = LongWord;

SDL_Bool = LongBool ;

const
	SDL_PRESSED = 1 ;
	SDL_RELEASED = 0;

implementation
end.
