unit player;

{$COPERATORS ON}

interface
uses SDL_types, SDL, SDL_video, view, pickups, coldet;

type
	playerSegment = record
		x, y: int;
	end;
	aplayerSegment = array of playerSegment;
	
	PlayerState = class
	public
		x, y: int;
		vx, vy: int;
		
		movDelay: int;
		time: int;
		
		sprite: pSDL_Surface;
		
		segments: aplayerSegment;
		queue: aplayerSegment;
		
		world: CollisionDetector;
		
		constructor init();
		
		procedure draw(dst: pSDL_Surface; view: ViewPort);
		function update(dt: sint32): int;
		procedure addSegment(seg: playerSegment);
		procedure addItem(item: Pickup);
		
		{ crawl makes the given player shift one tile immediately. }
		{ The time counter is reset. }
		procedure crawl();
		
		function occupies(xc, yc: int): boolean;
	private
		function shift(): boolean;
		function headRect(): SDL_Rect;
		function segmentRect(prevSeg, seg, nextSeg: playerSegment): SDL_Rect;
		function tailRect(dx, dy: int): SDL_Rect;
	end;

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

constructor PlayerState.init();
begin
end;

function PlayerState.shift(): boolean;
var
	i: int;
	newseg: playerSegment;
	nx, ny: int;
begin
	nx := self.x+self.vx;
	ny := self.y+self.vy;
	if self.world.isOccupied(nx, ny) then exit(false);
	
	with self do begin
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

procedure PlayerState.crawl();
var
	shifted: boolean;
begin
	shifted := self.shift();
	if shifted then self.time := 0;
end;

procedure PlayerState.addSegment(seg: playerSegment);
begin
	queueAdd(self.queue, seg);
end;

procedure PlayerState.addItem(item: Pickup);
var
	seg: playerSegment;
begin
	self.addSegment(seg);
end;

function PlayerState.update(dt: sint32): int;
begin
	with self do begin
		if time + dt >= movDelay then begin
			self.shift();
			time := 0;
			exit(dt - (movDelay - time));
		end;
		time += dt;
		exit(0);
	end;
end;

function PlayerState.headRect(): SDL_Rect;
var
	dx, dy: int;
	ret: SDL_Rect;
begin
	ret.w := self.sprite^.w div 4;
	ret.h := self.sprite^.h div 5;
	
	if length(self.segments) = 0 then begin
		dx := -self.vx;
		dy := -self.vy;
	end else begin
		dx := self.segments[0].x - self.x;
		dy := self.segments[0].y - self.y;
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

function PlayerState.tailRect(dx, dy: int): SDL_Rect;
var
	ret: SDL_Rect;
begin
	with ret do begin
		w := self.sprite^.w div 4;
		h := self.sprite^.h div 5;
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

function PlayerState.segmentRect(prevSeg, seg, nextSeg: playerSegment): SDL_Rect;
var
	ret: SDL_Rect;
	pdx, pdy, ndx, ndy: int;
begin
	with ret do begin
		w := self.sprite^.w div 4;
		h := self.sprite^.h div 5;
		
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
	
procedure PlayerState.draw(dst: pSDL_Surface; view: ViewPort);
var
	srcRect, dstRect: SDL_Rect;
	seg, tailSeg: PlayerSegment;
	i: int;
begin
	{ draw the head }
	srcRect := self.headRect();
	dstRect.x := self.x * view.tileBase.w - view.pxOffset.x;
	dstRect.y := self.y * view.tileBase.h - view.pxOffset.y;
	SDL_BlitSurface(self.sprite, @srcRect, dst, @dstRect);
	
	{ draw the first segment }
	if length(self.segments) >= 2 then begin
		seg.x := self.x;
		seg.y := self.y;
		srcRect := self.segmentRect(seg, self.segments[0], self.segments[1]);
		dstRect.x := self.segments[0].x * view.tileBase.w - view.pxOffset.x;
		dstRect.y := self.segments[0].y * view.tileBase.h - view.pxOffset.y;
		SDL_BlitSurface(self.sprite, @srcRect, dst, @dstRect);
	end;
	
	{ draw the other segments }
	for i := 1 to high(self.segments)-1 do begin
		srcRect := self.segmentRect(self.segments[i-1], self.segments[i], self.segments[i+1]);
		dstRect.x := self.segments[i].x * view.tileBase.w - view.pxOffset.x;
		dstRect.y := self.segments[i].y * view.tileBase.h - view.pxOffset.y;
		SDL_BlitSurface(self.sprite, @srcRect, dst, @dstRect);
	end;
	
	{ draw the last segment }
	if length(self.segments) <> 0 then begin
		if length(self.segments) = 1 then begin
			tailSeg := self.segments[0];
			srcRect := self.tailRect(tailSeg.x-self.x, tailSeg.y-self.y);
		end else begin
			tailSeg := self.segments[high(self.segments)];
			seg := self.segments[high(self.segments)-1];
			srcRect := self.tailRect(tailSeg.x-seg.x, tailSeg.y-seg.y);
		end;
		
		dstRect.x := tailSeg.x * view.tileBase.w - view.pxOffset.x;
		dstRect.y := tailSeg.y * view.tileBase.h - view.pxOffset.y;
		SDL_BlitSurface(self.sprite, @srcRect, dst, @dstRect);
	end;
end;

function PlayerState.occupies(xc, yc: int): boolean;
var
	seg: PlayerSegment;
begin
	for seg in self.segments do begin
		if (seg.x = xc) and (seg.y = yc) then exit(true);
	end;
	exit(false);
end;

end.

