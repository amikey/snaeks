unit gameover;

interface
uses sdl_types, sdl_video, world, player;

type
	GameOverScreen = record
		victory: boolean;
		time: int;  // the time at which victory/defeat was registered.
	end;

// isGameOver returns true if the given player has won or lost.
function isGameOver(world: pWorldState; player: pPlayerState): boolean;

// initGameOver makes a new GameOverScreen record.
function initGameOver(player: pPlayerState): GameOverScreen;

// drawGameOver draws the victory/defeat screen.
procedure drawGameOver(screen: pSDL_Surface; gos: GameOverScreen);

implementation
uses sdl_timer, resources, math;

const
	BannerAnimationTime = 800;

function isGameOver(world: pWorldState; player: pPlayerState): boolean;
begin
	if length(world^.players) <= 1 then exit(true);
	if player^.isDead then exit(true);
	exit(false);
end;

function initGameOver(player: pPlayerState): GameOverScreen;
var
	ret: GameOverScreen;
begin
	ret.victory := not player^.isDead;
	ret.time := SDL_GetTicks();
	exit(ret);
end;

procedure drawGameOver(screen: pSDL_Surface; gos: GameOverScreen);
var
	dst: SDL_Rect;
	banner: pSDL_Surface;
begin
	if gos.victory then banner := res.victory
	else banner := res.defeat;
	
	dst.x := 0;
	if SDL_GetTicks() - gos.time < BannerAnimationTime then begin
		dst.y := floor(double(-banner^.h) * (1 - (SDL_GetTicks() - gos.time)/BannerAnimationTime));
	end else begin
		dst.y := 0;
	end;
	
	SDL_BlitSurface(banner, nil, screen, @dst);
end;

end.
