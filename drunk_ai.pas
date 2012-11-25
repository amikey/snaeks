unit drunk_ai;

interface
uses SDL_types, player;

procedure drunkDecide(player: PlayerState);

implementation

{ rot rotates the player 90º clockwise. }
procedure rot(pl: PlayerState);
begin
	if pl.vx = 1 then begin
		pl.vx := 0;
		pl.vy := 1;
		exit;
	end;
	
	if pl.vy = 1 then begin
		pl.vy := 0;
		pl.vx := -1;
		exit;
	end;
	
	if pl.vx = -1 then begin
		pl.vx := 0;
		pl.vy := -1;
		exit;
	end;
	
	{if pl.vy = -1 then begin}
	pl.vy := 0;
	pl.vx := 1;
	{end;}
end;

procedure drunkDecide(player: PlayerState);
var
	rnd, i: int;
begin
	rnd := random(3);
	{ rotate rnd times clockwise }
	for i := 0 to rnd do rot(player);
	player.crawl();
end;

end.
