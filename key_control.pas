unit key_control;

interface
uses SDL_types, player;

const
	knone  = 0;
	kup    = 1;
	kdown  = 2;
	kleft  = 3;
	kright = 4;

procedure setKey(k: int; var kqueue: array of int);
procedure unsetKey(k: int; var kqueue: array of int);
procedure setVel(pl: pplayerState; kqueue: array of int);

implementation

procedure setKey(k: int; var kqueue: array of int);
var
	i: int;
begin
	for i := 0 to 3 do begin
		if kqueue[i] = knone then begin
			kqueue[i] := k;
			exit;
		end;
	end;
end;

procedure unsetKey(k: int; var kqueue: array of int);
var
	i, j: int;
begin
	for i := 0 to 3 do begin
		if kqueue[i] = knone then exit;
		if kqueue[i] = k then begin
			for j := i to 2 do begin
				kqueue[j] := kqueue[j+1];
				if kqueue[j+1] = knone then exit;
			end;
			kqueue[3] := knone;
		end;
	end;
end;

procedure setVel(pl: pplayerState; kqueue: array of int);
var i: int;
begin
	for i := 3 downto 0 do begin
		case kqueue[i] of
		kleft: begin
			pl^.vx := -1;
			pl^.vy :=  0;
			exit;
		end;
		kright: begin
			pl^.vx :=  1;
			pl^.vy :=  0;
			exit;
		end;
		kup: begin
			pl^.vx :=  0;
			pl^.vy := -1;
			exit;
		end;
		kdown: begin
			pl^.vx :=  0;
			pl^.vy :=  1;
			exit;
		end;
		knone:
		end;
	end;
end;
end.
