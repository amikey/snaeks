unit key_control;

interface
uses SDL_types, SDL_events, SDL_keyboard, player;

type
	paint = ^aint;
	aint = array of int;

const
	knone  = 0;
	kup    = 1;
	kdown  = 2;
	kleft  = 3;
	kright = 4;

procedure processKeyEvent(ev: SDL_Event; kqueue: paint; player: pPlayerState);
procedure keyUpdate(player: pPlayerState; kqueue: paint);

implementation

procedure setKey(k: int; var kqueue: paint);
var
	i, j: int;
begin
	for i := 0 to 3 do begin
		if kqueue^[i] = knone then begin
			kqueue^[i] := k;
			exit;
		end;
		
		if kqueue^[i] = k then begin
			for j := i to 2 do kqueue^[j] := kqueue^[j+1];
			kqueue^[3] := knone;
		end;
	end;
end;

procedure unsetKey(k: int; kqueue: paint);
var
	i, j: int;
begin
	for i := 0 to 3 do begin
		if kqueue^[i] = knone then exit;
		if kqueue^[i] = k then begin
			for j := i to 2 do begin
				kqueue^[j] := kqueue^[j+1];
			end;
			kqueue^[3] := knone;
		end;
	end;
end;

function backwards(pl: pPlayerState; dir: int): boolean;
var
	x, y: int;
	seg: playerSegment;
begin
	if length(pl^.segments) = 0 then exit(false);
	
	x := 0;
	y := 0;
	
	case dir of
	kleft: x := -1;
	kright: x := 1;
	kup: y := -1;
	kdown: y := 1;
	end;
	
	seg := pl^.segments[0];
	exit((seg.x = pl^.x + x) and (seg.y = pl^.y + y));
end;

procedure setVel(pl: pPlayerState; kqueue: paint);
var i, dx, dy: int;
begin
	if length(pl^.segments) > 0 then begin
		dx := pl^.x - pl^.segments[0].x;
		dy := pl^.y - pl^.segments[0].y;
	end else begin
		dx := 0;
		dy := 0;
	end;
	
	for i := 3 downto 0 do begin
		if backwards(pl, kqueue^[i]) then continue;
		case kqueue^[i] of
		kleft: begin
			pl^.vx := -1;
			pl^.vy :=  0;
		end;
		kright: begin
			pl^.vx :=  1;
			pl^.vy :=  0;
		end;
		kup: begin
			pl^.vx :=  0;
			pl^.vy := -1;
		end;
		kdown: begin
			pl^.vx :=  0;
			pl^.vy :=  1;
		end;
		knone:
		end;
		if (dx <> pl^.vx) or (dy <> pl^.vy) then exit();
	end;
end;

procedure processKeyEvent(ev: SDL_Event; kqueue: paint; player: pPlayerState);
var
	oldvx, oldvy: int;
begin
	case ev.eventtype of
	SDL_KEYDOWN:
		case ev.key.keysym.sym of
		SDLK_UP: setKey(kup, kqueue);
		SDLK_DOWN: setKey(kdown, kqueue);
		SDLK_LEFT: setKey(kleft, kqueue);
		SDLK_RIGHT: setKey(kright, kqueue);
		end;
	SDL_KEYUP:
		case ev.key.keysym.sym of
		SDLK_UP: unsetKey(kup, kqueue);
		SDLK_DOWN: unsetKey(kdown, kqueue);
		SDLK_LEFT: unsetKey(kleft, kqueue);
		SDLK_RIGHT: unsetKey(kright, kqueue);
		end;
	end;
	
	oldvx := player^.vx;
	oldvy := player^.vy;
	setVel(player, kqueue);
	if (player^.vx <> oldvx) or (player^.vy <> oldvy) then playerCrawl(player);
end;

procedure keyUpdate(player: pPlayerState; kqueue: paint);
begin
	setVel(player, kqueue);
	playerCrawl(player);
end;

end.
