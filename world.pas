unit world;

interface
uses sdl_types, SDL, SDL_video, SDL_image, tile, player, pickups, view, resources;

const
	TileEmpty = 1;

type
	pPickupType = ^PickupType;
	apPickupType = array of pPickupType;
	
	aPickup = array of Pickup;
	apPlayerState = array of pPlayerState;
	
	Coord = record
		x: int;
		y: int;
	end;
	
	// WorldState keeps track of the state of an entire level.
	pWorldState = ^WorldState;
	WorldState = record
		map: pTileMap;
		pickups: aPickup;
		players: apPlayerState;
		
		dropQueue: apPickupType;
	end;

function newWorld(): pWorldState;

procedure worldAddPlayer(world: pWorldState; pl: pPlayerState);
procedure worldAddPickup(world: pWorldState; pu: Pickup);

// spawnPickupType spawns an item of the given type at a random position on the map.
// If no empty position can be found, the item is added to dropQueue.
// Returns true if the item was spawned, false otherwise.
function spawnPickupType(world: pWorldState; typ: pPickupType): boolean;

procedure updateWorld(world: pWorldState; dt: int);
procedure drawWorld(world: pWorldState; screen: pSDL_Surface);

function isOccupied(world: pointer; x, y: int): boolean;

procedure cleanupWorld(world: pWorldState);

implementation

function newWorld(): pWorldState;
var
	world: pWorldState;
begin
	new(world);
	world^.map := newTileMap(66, 39);
	TMfillRectRandom(world^.map, 10, 18, 0, 0, 66, 39);
	setLength(world^.pickups, 0);
	setLength(world^.players, 0);
	setLength(world^.dropQueue, 0);
	exit(world);
end;

procedure worldAddPlayer(world: pWorldState; pl: pPlayerState);
begin
	pl^.world := pointer(world);
	pl^.isOccupied := @isOccupied;
	
	setLength(world^.players, length(world^.players)+1);
	world^.players[high(world^.players)] := pl;
end;

procedure worldAddPickup(world: pWorldState; pu: Pickup);
begin
	setLength(world^.pickups, length(world^.pickups)+1);
	world^.pickups[high(world^.pickups)] := pu;
end;

// isEmpty returns true for coordinates where there's no obstacles and no pickups.
function isEmpty(world: pWorldState; x, y: int): boolean;
var
	pu: Pickup;
begin
	if isOccupied(world, x, y) then exit(false);
	for pu in world^.pickups do begin
		if (pu.x = x) and (pu.y = y) then exit(false);
	end;
	
	exit(true);
end;

function internalSpawn(world: pWorldState; typ: pPickupType): boolean;
var
	pu: Pickup;
	index, i, j, w, h: int;
	pos: array of Coord;
begin
	w := world^.map^.width;
	h := world^.map^.height;
	setLength(pos, w * h);
	for j := 0 to h-1 do begin
		for i := 0 to w-1 do begin
			pos[j*h + i].x := i;
			pos[j*h + i].y := j;
		end;
	end;
	
	while true do begin
		if length(pos) = 0 then exit(false);
		
		index := random(length(pos));
		pu.x := pos[index].x;
		pu.y := pos[index].y;
		
		if isEmpty(world, pu.x, pu.y) then break;
		
		pos[index] := pos[high(pos)];
		setLength(pos, length(pos)-1);
	end;
	
	pu.typ := typ;
	
	worldAddPickup(world, pu);
	exit(true);
end;

function spawnPickupType(world: pWorldState; typ: pPickupType): boolean;
var
	ok: boolean;
begin
	ok := internalSpawn(world, typ);
	if ok then exit(true);
	
	setLength(world^.dropQueue, length(world^.dropQueue)+1);
	world^.dropQueue[high(world^.dropQueue)] := typ;
	exit(false);
end;

// emptyDropQueue spawns as many items from dropQueue as possible
procedure emptyDropQueue(world: pWorldState);
var
	i: int;
	ok: boolean;
begin
	for i := 0 to high(world^.dropQueue) do begin
		ok := spawnPickupType(world, world^.dropQueue[i]);
		if not ok then break;
	end;
	setLength(world^.dropQueue, length(world^.dropQueue)-i);
end;

// handlePlayer is called every time a player moves.
procedure handlePlayer(world: pWorldState; pl: pPlayerState);
var
	item: Pickup;
	i, j: int;
begin
	emptyDropQueue(world);
	
	for i := 0 to high(world^.pickups) do begin
		item := world^.pickups[i];
		if (item.x = pl^.x) and (item.y = pl^.y) then begin
			playerAddItem(pl, item);
			
			for j := i to high(world^.pickups)-1 do begin
				world^.pickups[j] := world^.pickups[j+1];
			end;
			setLength(world^.pickups, length(world^.pickups)-1);
			
			if item.typ^.simpleFood then begin
				spawnPickupType(world, @pickupFood);
			end else begin
				spawnPickupType(world, @pickupGun);
			end;
		end;
	end;
end;

procedure updateWorld(world: pWorldState; dt: int);
var
	tRemaining: int;
	pl: pPlayerState;
begin
	for pl in world^.players do begin
		tRemaining := dt;
		while tRemaining > 0 do begin
			tRemaining := updatePlayer(pl, tRemaining);
			handlePlayer(world, pl);
		end;
	end;
end;

procedure drawWorld(world: pWorldState; screen: pSDL_Surface);
var
	pu: Pickup;
	pl: pPlayerState;
	view: ViewPort;
begin
	view.pxOffset.x := -4;
	view.pxOffset.y := -4;
	view.pxOffset.w := screen^.w;
	view.pxOffset.h := screen^.h;
	view.tileBase.w := 12;
	view.tileBase.h := 12;
	
	TMdraw(world^.map, res.tiles, screen, view);
	for pu in world^.pickups do drawPickup(pu, screen, view);
	for pl in world^.players do drawPlayer(pl, screen, view);
end;

function isOccupied(world: pointer; x, y: int): boolean;
var
	pl: pPlayerState;
	ind: int;
begin
	for pl in pWorldState(world)^.players do begin
		if playerOccupies(pl, x, y) then exit(true);
	end;
	
	ind := TMindex(pWorldState(world)^.map, x, y);
	if (ind >= wallTilesIndicesFrom) and (ind <= wallTilesIndicesTo) then exit(true);
	
	exit(false);
end;

procedure cleanupWorld(world: pWorldState);
var
	pl: pPlayerState;
begin
	for pl in world^.players do cleanupPlayer(pl);
end;

end.

