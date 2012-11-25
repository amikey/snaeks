uses SDL_types, SDL, SDL_video, SDL_events, SDL_keyboard, SDL_timer, SDL_image, tile, player, key_control, world, pickups, color;

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
	pickupsInit();
	
	dirKeys[0] := knone;
	dirKeys[1] := knone;
	dirKeys[2] := knone;
	dirKeys[3] := knone;
	
	player := PlayerState.init();
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
	mapColorsRGB(player.sprite, SnakeCMapGreen , SnakeCMapBlue);
	
	world := WorldState.init();
	world.addPlayer(player);
	for i := 0 to 5 do world.spawnPickupType(@pickupFood);
	
	for i := 1 to 6 do player.addSegment(seg);
	
	lastTime := SDL_GetTicks();
		
	while true do begin
		SDL_Delay(20);
		
		while SDL_PollEvent(@ev) <> 0 do begin
			if gotevent <> 0 then begin
				case ev.eventtype of
				SDL_KEYDOWN:
					processKeyEvent(ev, dirKeys, player);
				SDL_KEYUP:
					if ev.key.keysym.sym = SDLK_ESCAPE then exit(0)
					else processKeyEvent(ev, dirKeys, player);
				SDL_EVENTQUIT:
					exit(0);
				end;
			end;
		end;
				
		dt := SDL_GetTicks() - lastTime;
		
		world.update(dt);
		lastTime := SDL_GetTicks();
		
		err := SDL_FillRect(screen, nil, $00000000);
		if err <> 0 then exit(err);
		world.draw(screen);
		SDL_UpdateRect(screen, 0, 0, 0, 0);
		err := SDL_Flip(screen);
		if err <> 0 then exit(err);
	end;
end;

var
	status: int;
begin
	randomize();
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

