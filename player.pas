unit player;

interface
uses SDL_types, SDL, SDL_video;

type
	playerSegment = record
		x, y: int;
	end;
	
	aplayerSegment = array of playerSegment;
	
	pplayerState = ^playerState;
	playerState = record
		x, y: int;
		vx, vy: int;
		
		movDelay: int;
		time: int;
		
		sprite: pSDL_Surface;
		
		segments: aplayerSegment;
		queue: aplayerSegment;
	end;

function drawPlayer(pl: playerState; dst: pSDL_Surface): int;
procedure updatePlayer(pl: pplayerState; dt: uint32);
procedure addSegment(pl: pplayerState; seg: playerSegment);

implementation
{$COPERATORS ON}

function queueAdd(var queue: aplayerSegment; seg: playerSegment): playerSegment;
var
	i: int;
begin
	setLength(queue, length(queue)+1);
	for i := high(queue) downto 1 do queue[i] := queue[i-1];
	queue[0] := seg;
	exit(seg);
end;

function queueRemove(var queue: aplayerSegment): playerSegment;
var
	ret: playerSegment;
	i: int;
begin
	ret := queue[high(queue)];
	setLength(queue, high(queue));
	exit(ret);
end;

procedure shift(pl: pplayerState);
var
	i: int;
	newseg: playerSegment;
begin
	with pl^ do begin
		if length(queue) = 0 then begin
			for i := high(segments) downto 1 do begin
				segments[i].x := segments[i-1].x;
				segments[i].y := segments[i-1].y;
			end;
			segments[0].x := x;
			segments[0].y := y;
			
			x += vx;
			y += vy;
			exit;
		end;
		
		newseg := queueRemove(queue);
		newseg.x := x;
		newseg.y := y;
		queueAdd(segments, newseg);
		
		x += vx;
		y += vy;
	end;
end;

procedure addSegment(pl: pplayerState; seg: playerSegment);
begin
	queueAdd(pl^.queue, seg);
end;

procedure updatePlayer(pl: pplayerState; dt: uint32);
begin
	with pl^ do begin
		time += dt;
		while time >= movDelay do begin
			shift(pl);
			time -= movDelay;
		end;
	end;
end;

function drawPlayer(pl: playerState; dst: pSDL_Surface): int;
var
	dstRect: SDL_Rect;
	seg: playerSegment;
	i: int;
begin
	dstRect.x := pl.x * pl.sprite^.w;
	dstRect.y := pl.y * pl.sprite^.h;
		
	SDL_BlitSurface(pl.sprite, nil, dst, @dstRect);
	
	for i := 0 to high(pl.segments) do begin
		dstRect.x := pl.segments[i].x * pl.sprite^.w;
		dstRect.y := pl.segments[i].y * pl.sprite^.h;
		SDL_BlitSurface(pl.sprite, nil, dst, @dstRect);
	end;
end;
end.

