unit player;

{$COPERATORS ON}

interface
uses SDL_types, SDL, SDL_video, view, pickups;

const
	SidewindDelay = 80;

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
		
		deathDelay: int;
		deathTime: int;
		
		isDead: boolean;
		
		sprite: pSDL_Surface;
		
		segments: aPlayerSegment;
		queue: aPlayerSegment;
		
		items: array[0..2] of pPickupType;
		
		world: pointer;
		isOccupied: function(world: pointer; x, y: int):boolean;
		
		isRobot: boolean;
		// robotDecide should set vx and vy.
		robotDecide: procedure(pl: pPlayerState);
		robotCleanup: procedure(pt: pointer);
		robotData: pointer;
	end;
	
	PlayerUpdateState = record
		time: int;
		moved: boolean;
	end;

function newPlayer(x, y, vx, vy: int): pPlayerState;
procedure drawPlayer(pl: pPlayerState; dst: pSDL_Surface; view: ViewPort);
function updatePlayer(pl: pPlayerState; dt: sint32): PlayerUpdateState;

procedure playerAddSegment(pl: pPlayerState; seg: playerSegment);
procedure playerAddItem(pl: pPlayerState; item: Pickup);

function playerOccupies(pl: pPlayerState; xc, yc: int): boolean;

procedure cleanupPlayer(pl: pPlayerState);

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

function newPlayer(x, y, vx, vy: int): pPlayerState;
var
	ret: pPlayerState;
	seg: PlayerSegment;
	i: int;
begin
	new(ret);
	ret^.x := x;
	ret^.y := y;
	ret^.vx := vx;
	ret^.vy := vy;
	
	ret^.isDead := false;
	
	ret^.movDelay := 200;
	ret^.time := 0;
	
	ret^.deathDelay := 180;
	ret^.deathTime := 0;
	
	for i := 0 to 2 do ret^.items[i] := nil;
	
	ret^.isRobot := false;
	
	setLength(ret^.segments, 0);
	setLength(ret^.queue, 0);
	
	seg.x := x - vx;
	seg.y := y - vy;
	queueAdd(ret^.segments, seg);
	exit(ret);
end;

function shiftPlayer(pl: pPlayerState): boolean;
var
	i: int;
	newseg: playerSegment;
	nx, ny, dx, dy: int;
begin
	dx := pl^.x - pl^.segments[0].x;
	dy := pl^.y - pl^.segments[0].y;
	if (dx <> pl^.vx) or (dy <> pl^.vy) then begin
		if dx = pl^.vx then pl^.vx := 0;
		if dy = pl^.vy then pl^.vy := 0;
	end;
	
	if (pl^.vx <> 0) and (pl^.vy <> 0) then begin
		if (pl^.vx <> dx) and (pl^.vx <> -dx) then pl^.vy := 0
		else pl^.vx := 0;
	end;
	
	nx := pl^.x+pl^.vx;
	ny := pl^.y+pl^.vy;
	if pl^.isOccupied(pl^.world, nx, ny) then exit(false);
	
	if length(pl^.queue) = 0 then begin
		for i := high(pl^.segments) downto 1 do begin
			pl^.segments[i].x := pl^.segments[i-1].x;
			pl^.segments[i].y := pl^.segments[i-1].y;
		end;
		pl^.segments[0].x := pl^.x;
		pl^.segments[0].y := pl^.y;
		
		pl^.x += pl^.vx;
		pl^.y += pl^.vy;
		exit(true);
	end;
	
	newseg := queueRemove(pl^.queue);
	newseg.x := pl^.x;
	newseg.y := pl^.y;
	queueAdd(pl^.segments, newseg);
	
	pl^.x += pl^.vx;
	pl^.y += pl^.vy;

	exit(true);
end;

procedure playerAddSegment(pl: pPlayerState; seg: playerSegment);
begin
	queueAdd(pl^.queue, seg);
end;

procedure playerAddItem(pl: pPlayerState; item: Pickup);
var
	seg: playerSegment;
	i: int;
begin
	if item.typ^.simpleFood then begin
		playerAddSegment(pl, seg);
	end else if item.typ^.poison then begin
		pl^.isDead := true;
	end else begin
		for i := 0 to 2 do begin
			if pl^.items[i] = nil then begin
				pl^.items[i] := item.typ;
				exit();
			end;
		end;
	end;
end;

function updatePlayer(pl: pPlayerState; dt: sint32): PlayerUpdateState;
var
	shifted: boolean;
	ret: PlayerUpdateState;
	dx, dy: int;
begin
	ret.time := 0;
	ret.moved := false;
	
	if pl^.isOccupied(pl^.world, pl^.x+pl^.vx, pl^.y+pl^.vy) then begin
		pl^.deathTime += dt;
		if pl^.deathTime >= pl^.deathDelay then pl^.isDead := true;
		// Death should be treated as moving, since the dead player is removed from the map.
		ret.moved := true;
		exit(ret);
	end;
	pl^.deathTime := 0;
	
	dx := pl^.x - pl^.segments[0].x;
	dy := pl^.y - pl^.segments[0].y;
	
	if (pl^.vx <> dx) or (pl^.vy <> dy) then begin
		if pl^.time + dt >= SidewindDelay then begin
			shiftPlayer(pl);
			pl^.time := 0;
			ret.time := dt - (SidewindDelay - pl^.time);
			ret.moved := true;
		end;
	end else if pl^.time + dt >= pl^.movDelay then begin
		shiftPlayer(pl);
		pl^.time := 0;
		ret.time := dt - (pl^.movDelay - pl^.time);
		ret.moved := true;
	end;
	
	pl^.time += dt;
	exit(ret);
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

procedure cleanupPlayer(pl: pPlayerState);
begin
	SDL_FreeSurface(pl^.sprite);
	if pl^.isRobot and (pl^.robotCleanup <> nil) then pl^.robotCleanup(pl^.robotData);
end;

end.

