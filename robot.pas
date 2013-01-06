unit robot;

{$COPERATORS ON}
{$PACKRECORDS C}

interface
uses SDL_types, player, SDL_video;

var
	debugOverlay: pSDL_Surface;
	debugSquare: pSDL_Surface;

procedure robotInit(player: pPlayerState);
procedure robotDecide(player: pPlayerState);
procedure robotCleanup(pt: pointer);


implementation
uses path, world, pickups;

type
	pRobotData = ^RobotData;
	RobotData = record
		path: aWaypoint;
	end;


procedure robotInit(player: pPlayerState);
var
	data: pRobotData;
begin
	player^.isRobot := true;
	player^.robotDecide := @robotDecide;
	player^.robotCleanup := @robotCleanup;
	new(data);
	player^.robotData := data;
end;

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
	dst: SDL_Rect;
begin
	world := player^.world;
	wp.x := player^.x;
	wp.y := player^.y;
	
	path := pathToNearest(world, wp, foodWaypoints(world));
	if length(path) = 0 then exit;
	
	wp := path[low(path)];
	player^.vx := wp.x - player^.x;
	player^.vy := wp.y - player^.y;
	
	dst.x := 4 + player^.x * 12;
	dst.y := 4 + player^.y * 12;
	SDL_BlitSurface(debugSquare, nil, debugOverlay, @dst);
	
	for wp in path do begin
		dst.x := 4 + wp.x * 12;
		dst.y := 4 + wp.y * 12;
		SDL_BlitSurface(debugSquare, nil, debugOverlay, @dst);
	end;
end;

procedure robotCleanup(pt: pointer);
begin
	if pt <> nil then dispose(pRobotData(pt));
end;

end.
