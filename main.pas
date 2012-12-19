uses SDL_types, SDL, SDL_video, SDL_events, SDL_keyboard, SDL_timer, SDL_image, tile, player, key_control, world, pickups, color, drunk_ai, resources, hud;

{$COPERATORS ON}
{$PACKRECORDS C}

const
	framedelay: int = 1000 div 40;
var
	screen: pSDL_Surface;

function mainLoop(): int;
var
	i: int;
	
	ev: SDL_Event;

	gotevent: int;
	
	player, player2: playerState;
	seg: playerSegment;
	err: int;
	
	dirKeys: array[0..3] of int;
	
	lastTime, lastFrame, dt: sint32;
	world: pWorldState;
	
	hud: HUDstate;
	
	delay: int;	
begin
	pickupsInit();
		
	dirKeys[0] := knone;
	dirKeys[1] := knone;
	dirKeys[2] := knone;
	dirKeys[3] := knone;
	
	world := newWorld();
	TMboxRandom(world^.map, 20, 29, 0, 0, world^.map^.width, world^.map^.height);
	
	player.x := 6;
	player.y := 6;
	player.vx := 1;
	player.vy := 0;
	player.movDelay := 300;
	player.time := 0;
	for i := 0 to 2 do player.items[i] := nil;
	player.sidewind := false;
	player.sidewindTime := 0;
	player.isRobot := false;
	for i := 1 to 6 do playerAddSegment(@player, seg);
	
	// This is just a convenient way of making a copy of res.snake. It should already be in the display format.
	player.sprite := SDL_DisplayFormatAlpha(res.snake);
	
	worldAddPlayer(world, @player);
	
	
	player2.x := 20;
	player2.y := 20;
	player2.vx := -1;
	player2.vy := 0;
	player2.movDelay := 300;
	player2.time := 0;
	for i := 0 to 2 do player2.items[i] := nil;
	player2.sidewind := false;
	player2.sidewindTime := 0;
	for i := 1 to 6 do playerAddSegment(@player2, seg);
	
	player2.robotDecide := @drunkDecide;
	player2.robotCleanup := @drunkCleanup;
	player2.isRobot := true;
	
	player2.sprite := SDL_DisplayFormatAlpha(res.snake);
	mapColorsRGB(player2.sprite, SnakeCMapGreen , SnakeCMapBlue);
	
	worldAddPlayer(world, @player2);

	for i := 0 to 200 do spawnPickupType(world, @pickupFood);
	spawnPickupType(world, @pickupGun);
	
	hud.player := @player;
	
	lastTime := SDL_GetTicks();
	lastFrame := lastTime;
		
	while true do begin	
		while SDL_PollEvent(@ev) <> 0 do begin
			if gotevent <> 0 then begin
				case ev.eventtype of
				SDL_KEYDOWN:
					processKeyEvent(ev, dirKeys, @player);
				SDL_KEYUP:
					if ev.key.keysym.sym = SDLK_ESCAPE then begin
						cleanupWorld(world);
						dispose(world);
						exit(0)
					end else processKeyEvent(ev, dirKeys, @player);
				SDL_EVENTQUIT: begin
					cleanupWorld(world);
					dispose(world);
					exit(0);
					end;
				end;
			end;
		end;
		
		dt := SDL_GetTicks() - lastTime;
		lastTime := SDL_GetTicks();
		
		updateWorld(world, dt);
		
		err := SDL_FillRect(screen, nil, $00000000);
		if err <> 0 then exit(err);
		drawWorld(world, screen);
		drawHUD(@hud, screen);
		SDL_UpdateRect(screen, 0, 0, 0, 0);
		
		delay := framedelay - (SDL_GetTicks() - lastFrame - framedelay);
		if delay < 0 then delay := 0;
		
		err := SDL_Flip(screen);
		if err <> 0 then exit(err);
		
		lastFrame := SDL_GetTicks();
		SDL_Delay(delay);
	end;
end;

var
	status: int;
	ok: boolean;
begin
	randomize();
	SDL_Init(SDL_INIT_VIDEO);
	screen := SDL_SetVideoMode(800, 480, 32, SDL_HWSURFACE);
	if screen = nil then begin
		writeln(StdErr, 'error:', SDL_GetError());
		exit;
	end;
	
	ok := loadRes();
	if not ok then begin
		SDL_Quit();
		halt(1);
	end;
	
	SDL_WM_SetCaption('snaeks', 'snaeks');
	
	status := mainLoop();
	if status <> 0 then writeln(StdErr, SDL_GetError());
	
	freeRes();
	SDL_Quit();
	halt(status);
end.

