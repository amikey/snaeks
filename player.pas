unit player;

interface
uses SDL_types, SDL, SDL_video;

type
	playerState = record
		x, y: int;
		
		sprite: pSDL_Surface;
	end;

function drawPlayer(pl: playerState; dst: pSDL_Surface): int;

implementation

function drawPlayer(pl: playerState; dst: pSDL_Surface): int;
var
	dstRect: SDL_Rect;
begin
	dstRect.x := pl.x * pl.sprite^.w;
	dstRect.y := pl.y * pl.sprite^.h;
		
	exit(SDL_BlitSurface(pl.sprite, nil, dst, @dstRect));
end;
end.

