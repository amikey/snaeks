uses SDL_types, SDL, SDL_video, SDL_events, SDL_keyboard, SDL_timer, SDL_image, tile, player, key_control, world, pickups, color, robot, resources, hud, gameover;

{$COPERATORS ON}
{$PACKRECORDS C}

const
	framedelay: int = 1000 div 60;
var
	screen: pSDL_Surface;

function mainLoop(): int;
var
	i: int;
	
	ev: SDL_Event;

	gotevent: int;
	kstate: MovKeyState;
	
	player, player2: pPlayerState;
	seg: playerSegment;
	err: int;
	
	lastTime, lastFrame, dt: sint32;
	world: pWorldState;
	
	hud: HUDstate;
	
	delay: int;
	
	gameEnded: boolean;
	gameOverS: GameOverScreen;
begin
	{$ifdef DEBUG}
	debugOverlay := SDL_DisplayFormat(screen);
	SDL_SetColorkey(debugOverlay, SDL_SRCCOLORKEY or SDL_RLEACCEL, 0);
	SDL_SetAlpha(debugOverlay, SDL_SRCALPHA, 120);
	
	debugSquare := SDL_CreateRGBSurface(SDL_SWSURFACE, 12, 12, 24, 0, 0, 0, 0);
	SDL_FillRect(debugSquare, nil, $00ff00);
	{$endif}
	
	pickupsInit();
	
	world := newWorld();
	TMboxRandom(world^.map, 20, 29, 0, 0, world^.map^.width, world^.map^.height);
	
	gameEnded := false;
	
	player := newPlayer(6, 6, 1, 0);
	player^.movDelay := 200;
	player^.isRobot := false;
	for i := 1 to 6 do playerAddSegment(player, seg);
	
	// This is just a convenient way of making a copy of res.snake. It should already be in the display format.
	player^.sprite := SDL_DisplayFormatAlpha(res.snake);
	
	worldAddPlayer(world, player);	
	
	player2 := newPlayer(20, 20, -1, 0);
	player2^.movDelay := 200;
	for i := 1 to 6 do playerAddSegment(player2, seg);
	
	robotInit(player2);
	
	player2^.sprite := SDL_DisplayFormatAlpha(res.snake);
	mapColorsRGB(player2^.sprite, SnakeCMapGreen , SnakeCMapBlue);
	
	worldAddPlayer(world, player2);

	for i := 0 to 8 do spawnPickupType(world, @pickupFood);
	spawnPickupType(world, @pickupGun);
	
	hud.player := player;
	
	lastTime := SDL_GetTicks();
	lastFrame := lastTime;
	
	kstate.u := false;
	kstate.d := false;
	kstate.l := false;
	kstate.r := false;
	
	while true do begin	
		while SDL_PollEvent(@ev) <> 0 do begin
			case ev.eventtype of
			SDL_KEYDOWN:
				processKeyEvent(ev, @kstate, player);
			SDL_KEYUP:
				if ev.key.keysym.sym = SDLK_ESCAPE then begin
					cleanupWorld(world);
					dispose(world);
					exit(0)
				end else processKeyEvent(ev, @kstate, player);
			SDL_EVENTQUIT: begin
				cleanupWorld(world);
				dispose(world);
				exit(0);
				end;
			end;
		end;
		
		dt := SDL_GetTicks() - lastTime;
		lastTime := SDL_GetTicks();
		
		keyUpdate(player, @kstate);
		updateWorld(world, dt);
		
		err := SDL_FillRect(screen, nil, $00000000);
		if err <> 0 then exit(err);
		drawWorld(world, screen);
		
		if (not gameEnded) and isGameOver(world, player) then begin
			gameOverS := initGameOver(player);
			gameEnded := true;
		end else if not gameEnded then begin
			drawHUD(@hud, screen);
		end else begin
			drawGameOver(screen, gameOverS);
		end;
		
		{$ifdef DEBUG}
		SDL_BlitSurface(debugOverlay, nil, screen, nil);
		SDL_FillRect(debugOverlay, nil, 0);
		{$endif}
		
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

