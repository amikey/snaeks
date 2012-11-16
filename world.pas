unit world;

interface
uses sdl_types, SDL_video, tile, player, pickups, view;

const
	TileEmpty = 1;

type
	pWorldState = ^WorldState;
	pPickupType = ^PickupType;
	
	aPickup = array of Pickup;
	apPlayerState = array of pPlayerState;
	
	WorldState = record
		map: TileMap;
		pickups: aPickup;
		players: apPlayerState;
	end;

procedure addPlayer(world: pWorldState; pl: pPlayerState);
procedure addPickup(world: pWorldState; pu: Pickup);

{ spawnPickupType spawns an item of the given type at a random position on the map. }
procedure spawnPickupType(world: pWorldState; typ: pPickupType);

procedure drawWorld(world: pWorldState; screen: pSDL_Surface);

implementation

procedure addPlayer(world: pWorldState; pl: pPlayerState);
begin
	setLength(world^.players, length(world^.players)+1);
	world^.players[high(world^.players)] := pl;
end;

procedure addPickup(world: pWorldState; pu: Pickup);
begin
	setLength(world^.pickups, length(world^.pickups)+1);
	world^.pickups[high(world^.pickups)] := pu;
end;

procedure spawnPickupType(world: pWorldState; typ: pPickupType);
var
	pu: Pickup;
begin
	{pu.x := random(world^.map.width);
	pu.y := random(world^.map.height);}
	
	pu.x := random(60);
	pu.y := random(40);
	
	pu.typ := typ;
	
	addPickup(world, pu);
end;

procedure drawWorld(world: pWorldState; screen: pSDL_Surface);
var
	pu: Pickup;
	pl: pPlayerState;
	view: ViewPort;
begin
	view.pxOffset.x := 0;
	view.pxOffset.y := 0;
	view.tileBase.w := 12;
	view.tileBase.h := 12;
	
	for pu in world^.pickups do drawPickup(pu, screen, view);
	for pl in world^.players do drawPlayer(pl^, screen, view);
end;

end.