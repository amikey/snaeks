unit robot;

{$COPERATORS ON}
{$PACKRECORDS C}

interface
uses SDL_types, player, SDL_video;

procedure robotDecide(player: pPlayerState);
procedure robotCleanup(pt: pointer);


implementation
uses path, world, pickups;

function foodWaypoints(world: pWorldState): aWaypoint;
var
	ret: aWaypoint;
	p: Pickup;
	i: int;
begin
	setLength(ret, length(world^.pickups));
	for i := low(world^.pickups) to high(world^.pickups) do begin
		p := world^.pickups[i];
		ret[i].x := p.x;
		ret[i].y := p.y;
	end;
	exit(ret);
end;

procedure robotDecide(player: pPlayerState);
var
	path: aWaypoint;
	world: pWorldState;
	wp: Waypoint;
	
	surf: pSDL_Surface;
	src, dst: SDL_Rect;
	i: int;
begin
	world := player^.world;
	wp.x := player^.x;
	wp.y := player^.y;
	
	path := pathToNearest(world, wp, foodWaypoints(world), 200);
	if length(path) = 0 then exit;
	
	wp := path[low(path)];
	player^.vx := wp.x - player^.x;
	player^.vy := wp.y - player^.y;
end;

procedure robotCleanup(pt: pointer); begin end; // Uses no data.

end.
