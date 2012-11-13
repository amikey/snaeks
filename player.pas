unit player;

interface
uses SDL_types, SDL, SDL_video;

type
	pplayerState = ^playerState;
	playerState = record
		x, y: int;
		vx, vy: int;
		
		movDelay: int;
		time: int;
		
		sprite: pSDL_Surface;
	end;

function drawPlayer(pl: playerState; dst: pSDL_Surface): int;
procedure updatePlayer(pl: pplayerState; dt: uint32);

implementation
{$COPERATORS ON}

procedure updatePlayer(pl: pplayerState; dt: uint32);
begin
	with pl^ do begin
		time += dt;
		if time < movDelay then exit;
		
		x += vx;
		y += vy;
		time -= movDelay;
	end;
end;

function drawPlayer(pl: playerState; dst: pSDL_Surface): int;
var
	dstRect: SDL_Rect;
begin
	dstRect.x := pl.x * pl.sprite^.w;
	dstRect.y := pl.y * pl.sprite^.h;
		
	exit(SDL_BlitSurface(pl.sprite, nil, dst, @dstRect));
end;
end.

