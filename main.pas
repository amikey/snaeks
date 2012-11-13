uses SDL_types, SDL, SDL_video, SDL_events, SDL_keyboard, tile, player;

{function IMG_Init(flags: sint32): sint32; cdecl; external 'SDL_image';}
{$COPERATORS ON}

var
	screen: pSDL_Surface;

function mainLoop(): int;
var
	ev: SDL_Event;
	gotevent: int;
	player: playerState;
	err: int;
begin
	player.x := 2;
	player.y := 2;
	player.sprite := SDL_CreateRGBSurface(SDL_SWSURFACE, 10, 10, 32, 0, 0, 0, 0);
	if player.sprite = nil then exit(1);
	SDL_FillRect(player.sprite, nil, $0000ff00);
	
	while SDL_WaitEvent(nil) <> 0 do begin
		gotevent := SDL_PollEvent(@ev);
		if gotevent = 0 then exit(1);
		
		case ev.eventtype of
		SDL_KEYDOWN:
			case ev.key.keysym.sym of
			SDLK_ESCAPE:
				exit(0);
			SDLK_UP:
				player.y -= 1;
			SDLK_DOWN:
				player.y += 1;
			SDLK_LEFT:
				player.x -= 1;
			SDLK_RIGHT:
				player.x += 1;
			end;
		SDL_EVENTQUIT:
			exit(0);
		end;
		
		err := SDL_FillRect(screen, nil, $00000000);
		if err <> 0 then exit(err);
		err := drawPlayer(player, screen);
		if err <> 0 then exit(err);
		SDL_UpdateRect(screen, 0, 0, 0, 0);
		err := SDL_Flip(screen);
		if err <> 0 then exit(err);
	end;
end;

var
	status: int;
begin
	SDL_Init(SDL_INIT_VIDEO);
	screen := SDL_SetVideoMode(800, 600, 32, SDL_HWSURFACE);
	if screen = nil then begin
		writeln(StdErr, 'error:', SDL_GetError());
		exit;
	end;
	
	status := mainLoop();
	if status <> 0 then writeln(StdErr, SDL_GetError());
	
	SDL_Quit;
end.

