uses SDL_types, SDL, SDL_video, SDL_events, SDL_keyboard, SDL_timer, tile, player, key_control;

{function IMG_Init(flags: sint32): sint32; cdecl; external 'SDL_image';}
{$COPERATORS ON}
{$PACKRECORDS C}

var
	screen: pSDL_Surface;


function mainLoop(): int;
var
	i: int;
	
	ev: SDL_Event;
	gotevent: int;
	player: playerState;
	seg: playerSegment;
	err: int;
	
	dirKeys: array[0..3] of int;
	
	lastTime, dt: uint32;
begin
	dirKeys[0] := knone;
	dirKeys[1] := knone;
	dirKeys[2] := knone;
	dirKeys[3] := knone;
	
	player.x := 2;
	player.y := 2;
	player.vx := 1;
	player.vy := 0;
	player.movDelay := 400;
	player.sprite := SDL_CreateRGBSurface(SDL_SWSURFACE, 10, 10, 32, 0, 0, 0, 0);
	if player.sprite = nil then exit(1);
	SDL_FillRect(player.sprite, nil, $0000ff00);
	
	for i := 1 to 5 do addSegment(@player, seg);
	
	lastTime := SDL_GetTicks();
		
	while true do begin
		SDL_Delay(50);
		
		gotevent := SDL_PollEvent(@ev);
		if gotevent <> 0 then begin
			case ev.eventtype of
			SDL_KEYDOWN:
				case ev.key.keysym.sym of
				SDLK_UP: setKey(kup, dirKeys);
				SDLK_DOWN: setKey(kdown, dirKeys);
				SDLK_LEFT: setKey(kleft, dirKeys);
				SDLK_RIGHT: setKey(kright, dirKeys);
				end;
			SDL_KEYUP:
				case ev.key.keysym.sym of
				SDLK_ESCAPE:
					exit(0);
				SDLK_UP: unsetKey(kup, dirKeys);
				SDLK_DOWN: unsetKey(kdown, dirKeys);
				SDLK_LEFT: unsetKey(kleft, dirKeys);
				SDLK_RIGHT: unsetKey(kright, dirKeys);
				end;
			SDL_EVENTQUIT:
				exit(0);
			end;
		end;
		
		setVel(@player, dirKeys);
		
		dt := SDL_GetTicks() - lastTime;
		updatePlayer(@player, dt);
		lastTime := SDL_GetTicks();
		
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

