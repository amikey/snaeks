unit world;

interface
uses sdl_types, SDL, SDL_video, SDL_image, tile, player, pickups, view, coldet;

const
	TileEmpty = 1;

type
	pPickupType = ^PickupType;
	
	aPickup = array of Pickup;
	apPlayerState = array of pPlayerState;
	
	// WorldState keeps track of the state of an entire level.
	pWorldState = ^WorldState;
	WorldState = record 
		tiles: TileSprites;
		map: TileMap;
		pickups: aPickup;
		players: apPlayerState;
	end;

function newWorld(): pWorldState;

procedure worldAddPlayer(world: pWorldState; pl: pPlayerState);
procedure worldAddPickup(world: pWorldState; pu: Pickup);

// spawnPickupType spawns an item of the given type at a random position on the map.
procedure spawnPickupType(world: pWorldState; typ: pPickupType);

procedure updateWorld(world: pWorldState; dt: int);
procedure drawWorld(world: pWorldState; screen: pSDL_Surface);

function isOccupied(world: pointer; x, y: int): boolean;

implementation

function newWorld(): pWorldState;
var
	tilesRaw: pSDL_Surface;
	world: pWorldState;
begin
	new(world);
	world^.tiles := loadTiles('res/tilemap.png', 10, 10);
	if world^.tiles.sprite = nil then begin
		writeln(stderr, SDL_GetError());
		halt(1);
	end;
	
	tilesRaw := world^.tiles.sprite;
	world^.tiles.sprite := SDL_DisplayFormatAlpha(tilesRaw);
	SDL_FreeSurface(tilesRaw);
	
	world^.map := TileMap.init(66, 39);
	world^.map.fillRectRandom(10, 18, 0, 0, 66, 39);
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

procedure spawnPickupType(world: pWorldState; typ: pPickupType);
var
	pu: Pickup;
begin
	pu.x := random(world^.map.width);
	pu.y := random(world^.map.height);
	
	pu.typ := typ;
	
	worldAddPickup(world, pu);
end;

procedure handlePlayer(world: pWorldState; pl: pPlayerState);
var
	item: Pickup;
	i, j: int;
begin
	for i := 0 to high(world^.pickups) do begin
		item := world^.pickups[i];
		if (item.x = pl^.x) and (item.y = pl^.y) then begin
			playerAddItem(pl, item);
			
			for j := i to high(world^.pickups)-1 do begin
				world^.pickups[j] := world^.pickups[j+1];
			end;
			setLength(world^.pickups, length(world^.pickups)-1);
			
			spawnPickupType(world, @pickupFood);
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
	
	world^.map.draw(world^.tiles, screen, view);
	for pu in world^.pickups do drawPickup(pu, screen, view);
	for pl in world^.players do drawPlayer(pl, screen, view);
end;

function isOccupied(world: pointer; x, y: int): boolean;
var
	pl: pPlayerState;
begin
	for pl in pWorldState(world)^.players do begin
		if playerOccupies(pl, x, y) then exit(true);
	end;
	exit(false);
end;

end.
