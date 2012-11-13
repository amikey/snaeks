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
	
	{$IFDEF CPU64}
	int = Int64;
	Uint = QWord;
	{$ELSE}
	int = LongInt;
	Uint = LongWord;
	{$ENDIF}

SDL_Bool = LongBool ;

const
	SDL_PRESSED = 1 ;
	SDL_RELEASED = 0;

implementation
end.
