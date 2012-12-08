unit player;

{$COPERATORS ON}

interface
uses SDL_types, SDL, SDL_video, view, pickups;

const
	SidewindDelay = 100;

type
	playerSegment = record
		x, y: int;
	end;
	aplayerSegment = array of playerSegment;
	
	pPlayerState = ^PlayerState;
	PlayerState = record
		x, y: int;
		vx, vy: int;
		
		movDelay: int;
		time: int;
		
		sidewind: boolean;
		sidewindTime: int;
		
		sprite: pSDL_Surface;
		
		segments: aPlayerSegment;
		queue: aplayerSegment;
		
		world: pointer;
		isOccupied: function(world: pointer; x, y: int):boolean;
		
		boundingRect: pSDL_Surface;
		
		useDecide: boolean;
		decide: procedure(pl: pPlayerState);
		AIdata: pointer;
	end;

procedure drawPlayer(pl: pPlayerState; dst: pSDL_Surface; view: ViewPort);
function updatePlayer(pl: pPlayerState; dt: sint32): int;

procedure playerAddSegment(pl: pPlayerState; seg: playerSegment);
procedure playerAddItem(pl: pPlayerState; item: Pickup);

// crawl makes the given player shift one tile as soon as possible.
procedure playerCrawl(pl: pPlayerState);

function playerOccupies(pl: pPlayerState; xc, yc: int): boolean;

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

function shiftPlayer(pl: pPlayerState): boolean;
var
	i: int;
	newseg: playerSegment;
	nx, ny: int;
begin
	nx := pl^.x+pl^.vx;
	ny := pl^.y+pl^.vy;
	if pl^.isOccupied(pl^.world, nx, ny) then exit(false);
	
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
			exit(true);
		end;
		
		newseg := queueRemove(queue);
		newseg.x := x;
		newseg.y := y;
		queueAdd(segments, newseg);
		
		x += vx;
		y += vy;
	end;
end;

procedure playerCrawl(pl: pPlayerState);
begin
	if length(pl^.segments) = 0 then begin
		pl^.sidewind := true;
		exit;
	end;
	
	if (pl^.vx = pl^.x - pl^.segments[0].x) and (pl^.vy = pl^.y - pl^.segments[0].y) then begin
		pl^.sidewind := false;
		exit;
	end;
	
	pl^.sidewind := true;
end;

procedure playerAddSegment(pl: pPlayerState; seg: playerSegment);
begin
	queueAdd(pl^.queue, seg);
end;

procedure playerAddItem(pl: pPlayerState; item: Pickup);
var
	seg: playerSegment;
begin
	playerAddSegment(pl, seg);
end;

function updatePlayer(pl: pPlayerState; dt: sint32): int;
var shifted: boolean;
begin
	with pl^ do begin
		if useDecide then decide(pl);
		
		pl^.sidewindTime += dt;
		if pl^.sidewind and (pl^.sidewindTime > SidewindDelay) then begin
			pl^.sidewind := false;
			
			shifted := shiftPlayer(pl);
			if shifted then begin
				pl^.sidewindTime -= SidewindDelay;
				pl^.time := 0;
			end;
			exit(0);
		end;
		
		if time + dt >= movDelay then begin
			shiftPlayer(pl);
			time := 0;
			exit(dt - (movDelay - time));
		end;
		time += dt;
		exit(0);
	end;
end;

function headRect(pl: pPlayerState): SDL_Rect;
var
	dx, dy: int;
	ret: SDL_Rect;
begin
	ret.w := pl^.sprite^.w div 4;
	ret.h := pl^.sprite^.h div 5;
	
	if length(pl^.segments) = 0 then begin
		dx := -pl^.vx;
		dy := -pl^.vy;
	end else begin
		dx := pl^.segments[0].x - pl^.x;
		dy := pl^.segments[0].y - pl^.y;
	end;
	
	with ret do begin
		y := 0;
		if dx = 1 then begin
			x := 0;
			exit(ret);
		end;
		if dy = 1 then begin
			x := w;
			exit(ret);
		end;
		if dx = -1 then begin
			x := 2 * w;
			exit(ret);
		end;
		x := 3 * w;
		exit(ret);
	end;
end;

function tailRect(pl: pPlayerState; dx, dy: int): SDL_Rect;
var
	ret: SDL_Rect;
begin
	with ret do begin
		w := pl^.sprite^.w div 4;
		h := pl^.sprite^.h div 5;
		y := h * 4;
		
		if dx = 1 then begin
			x := 0;
			exit(ret);
		end;
		if dy = 1 then begin
			x := w;
			exit(ret);
		end;
		if dx = -1 then begin
			x := 2 * w;
			exit(ret);
		end;
		x := 3 * w;
		exit(ret);
	end;
end;

function segmentRect(pl: pPlayerState; prevSeg, seg, nextSeg: playerSegment): SDL_Rect;
var
	ret: SDL_Rect;
	pdx, pdy, ndx, ndy: int;
begin
	with ret do begin
		w := pl^.sprite^.w div 4;
		h := pl^.sprite^.h div 5;
		
		pdx := seg.x - prevSeg.x;
		pdy := seg.y - prevSeg.y;
		ndx := nextSeg.x - seg.x;
		ndy := nextSeg.y - seg.y;
		
		y := h;
		if (pdx = 1) and (ndx = 1) then begin
			x := 0;
			exit(ret);
		end;
		if (pdx = -1) and (ndx = -1) then begin
			x := 2 * w;
			exit(ret);
		end;
		if (pdy = 1) and (ndy = 1) then begin
			x := w;
			exit(ret);
		end;
		if (pdy = -1) and (ndy = -1) then begin
			x := 3 * w;		
			exit(ret);
		end;
		
		y := 2 * h;
		if (pdy = -1) and (ndx = -1) then begin
			x := 0;
			exit(ret);
		end;
		if (pdx = 1) and (ndy = -1) then begin
			x := w;
			exit(ret);
		end;
		if (pdy = 1) and (ndx = 1) then begin
			x := 2 * w;
			exit(ret);
		end;
		if (pdx = -1) and (ndy = 1) then begin
			x := 3 * w;
			exit(ret);
		end;
		
		y := 3 * h;
		if (pdy = 1) and (ndx = -1) then begin
			x := 0;
			exit(ret);
		end;
		if (pdx = -1) and (ndy = -1) then begin
			x :=  w;
			exit(ret);
		end;
		if (pdy = -1) and (ndx = 1) then begin
			x := 2 * w;
			exit(ret);
		end;
		if (pdx = 1) and (ndy = 1) then begin
			x := 3 * w;
			exit(ret);
		end;
	end;
end;
	
procedure drawPlayer(pl: pPlayerState; dst: pSDL_Surface; view: ViewPort);
var
	srcRect, dstRect: SDL_Rect;
	seg, tailSeg: PlayerSegment;
	i: int;
begin
	// draw the head
	srcRect := headRect(pl);
	dstRect.x := pl^.x * view.tileBase.w - view.pxOffset.x;
	dstRect.y := pl^.y * view.tileBase.h - view.pxOffset.y;
	SDL_BlitSurface(pl^.sprite, @srcRect, dst, @dstRect);
	
	// draw the first segment
	if length(pl^.segments) >= 2 then begin
		seg.x := pl^.x;
		seg.y := pl^.y;
		srcRect := segmentRect(pl, seg, pl^.segments[0], pl^.segments[1]);
		dstRect.x := pl^.segments[0].x * view.tileBase.w - view.pxOffset.x;
		dstRect.y := pl^.segments[0].y * view.tileBase.h - view.pxOffset.y;
		SDL_BlitSurface(pl^.sprite, @srcRect, dst, @dstRect);
	end;
	
	// draw the other segments
	for i := 1 to high(pl^.segments)-1 do begin
		srcRect := segmentRect(pl, pl^.segments[i-1], pl^.segments[i], pl^.segments[i+1]);
		dstRect.x := pl^.segments[i].x * view.tileBase.w - view.pxOffset.x;
		dstRect.y := pl^.segments[i].y * view.tileBase.h - view.pxOffset.y;
		SDL_BlitSurface(pl^.sprite, @srcRect, dst, @dstRect);
	end;
	
	// draw the last segment
	if length(pl^.segments) <> 0 then begin
		if length(pl^.segments) = 1 then begin
			tailSeg := pl^.segments[0];
			srcRect := tailRect(pl, tailSeg.x-pl^.x, tailSeg.y-pl^.y);
		end else begin
			tailSeg := pl^.segments[high(pl^.segments)];
			seg := pl^.segments[high(pl^.segments)-1];
			srcRect := tailRect(pl, tailSeg.x-seg.x, tailSeg.y-seg.y);
		end;
		
		dstRect.x := tailSeg.x * view.tileBase.w - view.pxOffset.x;
		dstRect.y := tailSeg.y * view.tileBase.h - view.pxOffset.y;
		SDL_BlitSurface(pl^.sprite, @srcRect, dst, @dstRect);
	end;
end;

function playerOccupies(pl: pPlayerState; xc, yc: int): boolean;
var
	seg: PlayerSegment;
begin
	if (pl^.x = xc) and (pl^.y = yc) then exit(true);
	
	for seg in pl^.segments do begin
		if (seg.x = xc) and (seg.y = yc) then exit(true);
	end;
	exit(false);
end;

end.

