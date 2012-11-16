unit player;

{$COPERATORS ON}

interface
uses SDL_types, SDL, SDL_video, view;

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

procedure drawPlayer(pl: playerState; dst: pSDL_Surface; view: ViewPort);
procedure updatePlayer(pl: pplayerState; dt: sint32);
procedure addSegment(pl: pplayerState; seg: playerSegment);
procedure crawl(pl: pplayerState);

implementation

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

procedure crawl(pl: pplayerState);
begin
	shift(pl);
	pl^.time := 0;
end;

procedure addSegment(pl: pplayerState; seg: playerSegment);
begin
	queueAdd(pl^.queue, seg);
end;

procedure updatePlayer(pl: pplayerState; dt: sint32);
begin
	with pl^ do begin
		time += dt;
		while time >= movDelay do begin
			shift(pl);
			time -= movDelay;
		end;
	end;
end;

function headRect(pl: playerState): SDL_Rect;
var
	dx, dy: int;
	ret: SDL_Rect;
begin
	ret.w := pl.sprite^.w div 4;
	ret.h := pl.sprite^.h div 4;
	
	if length(pl.segments) = 0 then begin
		dx := pl.vx;
		dy := pl.vy;
	end else begin
		dx := pl.x - pl.segments[0].x;
		dy := pl.y - pl.segments[0].y;
	end;
	
	with ret do begin
		if dx = -1 then begin
			x := 0;
			y := 0;
			exit(ret);
		end;
		if dy = -1 then begin
			x := w;
			y := 0;
			exit(ret);
		end;
		if dx = 1 then begin
			x := 2 * w;
			y := 0;
			exit(ret);
		end;
		x := 3 * w;
		y := 0;
		exit(ret);
	end;
end;

function tailRect(pl: playerState; dx, dy: int): SDL_Rect;
var
	ret: SDL_Rect;
begin
	with ret do begin
		w := pl.sprite^.w div 4;
		h := pl.sprite^.h div 4;
		y := ret.h * 3;
		
		if dx = -1 then begin
			x := 0;
			exit(ret);
		end;
		if dy = -1 then begin
			x := w;
			exit(ret);
		end;
		if dx = 1 then begin
			x := 2 * w;
			exit(ret);
		end;
		x := 3 * w;
		exit(ret);
	end;
end;

function segmentRect(pl: playerState; prevSeg, seg, nextSeg: playerSegment): SDL_Rect;
var
	ret: SDL_Rect;
	pdx, pdy, ndx, ndy: int;
begin
	with ret do begin
		w := pl.sprite^.w div 4;
		h := pl.sprite^.h div 4;
		
		pdx := seg.x - prevSeg.x;
		pdy := seg.y - prevSeg.y;
		ndx := nextSeg.x - seg.x;
		ndy := nextSeg.y - seg.y;
		
		y := h;
		if (pdx = -1) and (ndx = -1) then begin
			x := 0;
			exit(ret);
		end;
		if (pdx = 1) and (ndx = 1) then begin
			x := 2 * w;
			exit(ret);
		end;
		if (pdy = -1) and (ndy = -1) then begin
			x := w;
			exit(ret);
		end;
		if (pdy = 1) and (ndy = 1) then begin
			x := 3 * w;		
			exit(ret);
		end;
		
		y := 2 * h;
		if ((pdx = 1) and (ndy = 1)) or ((pdy = -1) and (ndx = -1)) then begin
			x := 0;
			exit(ret);
		end;
		if ((pdx = -1) and (ndy = -1)) or ((pdy = 1) and (ndx = 1)) then begin
			x := 2 * w;
			exit(ret);
		end;
		if ((pdx = -1) and (ndy = 1)) or ((pdy = -1) and (ndx = 1)) then begin
			x := 3 * w;
			exit(ret);
		end;
		if ((pdx = 1) and (ndy = -1)) or ((pdy = 1) and (ndx = -1)) then begin
			x := w;
			exit(ret);
		end;
	end;
end;
	
procedure drawPlayer(pl: playerState; dst: pSDL_Surface; view: ViewPort);
var
	srcRect, dstRect: SDL_Rect;
	seg, tailSeg: playerSegment;
	i: int;
begin
	if length(pl.segments) >= 2 then begin
		seg.x := pl.x;
		seg.y := pl.y;
		srcRect := segmentRect(pl, seg, pl.segments[0], pl.segments[1]);
		dstRect.x := pl.segments[0].x * view.tileBase.w - view.pxOffset.x;
		dstRect.y := pl.segments[0].y * view.tileBase.h - view.pxOffset.y;
		SDL_BlitSurface(pl.sprite, @srcRect, dst, @dstRect);
	end;
	
	for i := 1 to high(pl.segments)-1 do begin
		srcRect := segmentRect(pl, pl.segments[i-1], pl.segments[i], pl.segments[i+1]);
		dstRect.x := pl.segments[i].x * view.tileBase.w - view.pxOffset.x;
		dstRect.y := pl.segments[i].y * view.tileBase.h - view.pxOffset.y;
		SDL_BlitSurface(pl.sprite, @srcRect, dst, @dstRect);
	end;
	
	if length(pl.segments) <> 0 then begin
		if length(pl.segments) = 1 then begin
			tailSeg := pl.segments[0];
			srcRect := tailRect(pl, pl.x-tailSeg.x, pl.y-tailSeg.y);
		end else begin
			tailSeg := pl.segments[high(pl.segments)];
			seg := pl.segments[high(pl.segments)-1];
			srcRect := tailRect(pl, seg.x-tailSeg.x, seg.y-tailSeg.y);
		end;
		
		dstRect.x := tailSeg.x * view.tileBase.w - view.pxOffset.x;
		dstRect.y := tailSeg.y * view.tileBase.h - view.pxOffset.y;
		SDL_BlitSurface(pl.sprite, @srcRect, dst, @dstRect);
	end;
	
	srcRect := headRect(pl);
	dstRect.x := pl.x * view.tileBase.w - view.pxOffset.x;
	dstRect.y := pl.y * view.tileBase.h - view.pxOffset.y;
	SDL_BlitSurface(pl.sprite, @srcRect, dst, @dstRect);
end;

end.

