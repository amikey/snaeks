unit drunk_ai;

{$COPERATORS ON}
{$PACKRECORDS C}

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
	rnd := random(4);
	{ rotate rnd times clockwise }
	i := 0;
	while (i < 3) and (rnd <> 0) do begin
		rot(player);
		rnd -= 1;
		
		while player.world.isOccupied(player.x+player.vx, player.y+player.vy) do begin
			rot(player);
			i += 1;
		end;
	end;
	
	player.crawl();
end;

end.
