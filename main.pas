uses SDL_types, SDL, SDL_video, SDL_events, SDL_keyboard, SDL_timer, SDL_image, tile, player, key_control, world, pickups;

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
	
	lastTime, dt: sint32;
	world: WorldState;
begin
	randomize();
	
	pickupsInit();
	
	dirKeys[0] := knone;
	dirKeys[1] := knone;
	dirKeys[2] := knone;
	dirKeys[3] := knone;
	
	player.x := 2;
	player.y := 2;
	player.vx := 1;
	player.vy := 0;
	player.movDelay := 300;
	player.time := 0;

	player.sprite := IMG_Load('res/snake.png');
	if player.sprite = nil then begin
		writeln(SDL_GetError());
		exit(1);
	end;
	
	player.sprite := SDL_DisplayFormatAlpha(player.sprite);
	
	addPlayer(@world, @player);
	for i := 0 to 5 do spawnPickupType(@world, @pickupFood);
	
	for i := 1 to 6 do addSegment(@player, seg);
	
	lastTime := SDL_GetTicks();
		
	while true do begin
		SDL_Delay(20);
		
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
		drawWorld(@world, screen);
		SDL_UpdateRect(screen, 0, 0, 0, 0);
		err := SDL_Flip(screen);
		if err <> 0 then exit(err);
	end;
end;

var
	status: int;
begin
	SDL_Init(SDL_INIT_VIDEO);
	screen := SDL_SetVideoMode(800, 480, 32, SDL_HWSURFACE);
	if screen = nil then begin
		writeln(StdErr, 'error:', SDL_GetError());
		exit;
	end;
	
	status := mainLoop();
	if status <> 0 then writeln(StdErr, SDL_GetError());
	
	SDL_Quit;
end.

