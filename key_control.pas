unit key_control;

interface
uses SDL_types, SDL_events, SDL_keyboard, player;

type
	pMovKeyState = ^MovKeyState;
	MovKeyState = record
		u, d, l, r: boolean;
	end;

procedure processKeyEvent(ev: SDL_Event; kstate: pMovKeyState; player: pPlayerState);
procedure keyUpdate(player: pPlayerState; kstate: pMovKeyState);

implementation

procedure setVel(pl: pPlayerState; kstate: pMovKeyState);
var i, dx, dy, vx, vy: int;
begin
	if length(pl^.segments) > 0 then begin
		dx := pl^.x - pl^.segments[0].x;
		dy := pl^.y - pl^.segments[0].y;
	end else begin
		dx := 0;
		dy := 0;
	end;
	
	if kstate^.l and kstate^.r then begin
		if dy <> 0 then pl^.vx := dy else pl^.vx := -1;
	end else if kstate^.r then begin
		pl^.vx := 1;
	end else if kstate^.l then begin
		pl^.vx := -1;
	end else begin
		pl^.vx := 0;
	end;
	
	if kstate^.u and kstate^.d then begin
		if dy <> 0 then pl^.vy := dy else pl^.vy := -1;
	end else if kstate^.u then begin
		pl^.vy := -1;
	end else if kstate^.d then begin
		pl^.vy := 1;
	end else begin
		pl^.vy := 0;
	end;
	
	if (pl^.vx = 0) and (pl^.vy = 0) then begin
		pl^.vx := dx;
		pl^.vy := dy;
	end;
	
	if (pl^.vx = -dx) and (pl^.vy = -dy) then begin
		pl^.vx := dx;
		pl^.vy := dy;
	end;
end;

procedure processKeyEvent(ev: SDL_Event; kstate: pMovKeyState; player: pPlayerState);
var
	oldvx, oldvy: int;
begin
	case ev.eventtype of
	SDL_KEYDOWN:
		case ev.key.keysym.sym of
		SDLK_UP:    kstate^.u := true;
		SDLK_DOWN:  kstate^.d := true;
		SDLK_LEFT:  kstate^.l := true;
		SDLK_RIGHT: kstate^.r := true;
		end;
	SDL_KEYUP:
		case ev.key.keysym.sym of
		SDLK_UP:    kstate^.u := false;
		SDLK_DOWN:  kstate^.d := false;
		SDLK_LEFT:  kstate^.l := false;
		SDLK_RIGHT: kstate^.r := false;
		end;
	end;
	
	oldvx := player^.vx;
	oldvy := player^.vy;
	setVel(player, kstate);
end;

procedure keyUpdate(player: pPlayerState; kstate: pMovKeyState);
begin
	setVel(player, kstate);
end;

end.
