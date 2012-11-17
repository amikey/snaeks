unit world;

interface
uses sdl_types, SDL_video, tile, player, pickups, view, coldet;

const
	TileEmpty = 1;

type
	pPickupType = ^PickupType;
	
	aPickup = array of Pickup;
	apPlayerState = array of pPlayerState;
	
	WorldState = class(CollisionDetector)
	public
		map: TileMap;
		pickups: aPickup;
		players: apPlayerState;
		
		constructor init();
		
		procedure addPlayer(pl: pPlayerState);
		procedure addPickup(pu: Pickup);
		
		{ spawnPickupType spawns an item of the given type at a random position on the map. }
		procedure spawnPickupType(typ: pPickupType);
		
		procedure update(dt: int);
		procedure draw(screen: pSDL_Surface);
		
		function isOccupied(x, y: int): boolean; override;
		
	private
		procedure handlePlayer(pl: pPlayerState);
	end;

implementation

constructor WorldState.init();
begin
end;

procedure WorldState.addPlayer(pl: pPlayerState);
begin
	pl^.world := self;
	setLength(self.players, length(self.players)+1);
	self.players[high(self.players)] := pl;
end;

procedure WorldState.addPickup(pu: Pickup);
begin
	setLength(self.pickups, length(self.pickups)+1);
	self.pickups[high(self.pickups)] := pu;
end;

procedure WorldState.spawnPickupType(typ: pPickupType);
var
	pu: Pickup;
begin
	{pu.x := random(self.map.width);
	pu.y := random(self.map.height);}
	
	pu.x := random(60);
	pu.y := random(38);
	
	pu.typ := typ;
	
	self.addPickup(pu);
end;

procedure WorldState.handlePlayer(pl: pPlayerState);
var
	item: Pickup;
	i, j: int;
begin
	for i := 0 to high(self.pickups) do begin
		item := self.pickups[i];
		if (item.x = pl^.x) and (item.y = pl^.y) then begin
			addItem(pl, item);
			
			for j := i to high(self.pickups)-1 do begin
				self.pickups[j] := self.pickups[j+1];
			end;
			setLength(self.pickups, length(self.pickups)-1);
			
			self.spawnPickupType(@pickupFood);
		end;
	end;
end;

procedure WorldState.update(dt: int);
var
	tRemaining: int;
	pl: pPlayerState;
begin
	for pl in self.players do begin
		tRemaining := dt;
		while tRemaining > 0 do begin
			tRemaining := updatePlayer(pl, tRemaining);
			self.handlePlayer(pl);
		end;
	end;
end;

procedure WorldState.draw(screen: pSDL_Surface);
var
	pu: Pickup;
	pl: pPlayerState;
	view: ViewPort;
begin
	view.pxOffset.x := 0;
	view.pxOffset.y := 0;
	view.tileBase.w := 12;
	view.tileBase.h := 12;
	
	for pu in self.pickups do drawPickup(pu, screen, view);
	for pl in self.players do drawPlayer(pl^, screen, view);
end;

function WorldState.isOccupied(x, y: int): boolean;
var
	pl: pPlayerState;
begin
	for pl in self.players do begin
		if playerOccupies(pl, x, y) then exit(true);
	end;
	exit(false);
end;

end.
