unit world;

interface
uses sdl_types, SDL, SDL_video, SDL_image, tile, player, pickups, view, coldet;

const
	TileEmpty = 1;

type
	pPickupType = ^PickupType;
	
	aPickup = array of Pickup;
	aPlayerState = array of PlayerState;
	
	WorldState = class(CollisionDetector)
	public
		tiles: TileSprites;
		map: TileMap;
		pickups: aPickup;
		players: aPlayerState;
		
		constructor init();
		
		procedure addPlayer(pl: PlayerState);
		procedure addPickup(pu: Pickup);
		
		{ spawnPickupType spawns an item of the given type at a random position on the map. }
		procedure spawnPickupType(typ: pPickupType);
		
		procedure update(dt: int);
		procedure draw(screen: pSDL_Surface);
		
		function isOccupied(x, y: int): boolean; override;
		
	private
		procedure handlePlayer(pl: PlayerState);
	end;

implementation

constructor WorldState.init();
begin
	self.tiles := loadTiles('res/tilemap.png', 10, 10);
	if self.tiles.sprite = nil then begin
		writeln(stderr, SDL_GetError());
		halt(1);
	end;
		
	self.map := TileMap.init(66, 39);
	self.map.fillRectRandom(10, 18, 0, 0, 66, 39);
end;

procedure WorldState.addPlayer(pl: PlayerState);
begin
	pl.world := self;
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
	pu.x := random(self.map.width);
	pu.y := random(self.map.height);
	
	pu.typ := typ;
	
	self.addPickup(pu);
end;

procedure WorldState.handlePlayer(pl: PlayerState);
var
	item: Pickup;
	i, j: int;
begin
	for i := 0 to high(self.pickups) do begin
		item := self.pickups[i];
		if (item.x = pl.x) and (item.y = pl.y) then begin
			pl.addItem(item);
			
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
	pl: PlayerState;
begin
	for pl in self.players do begin
		tRemaining := dt;
		while tRemaining > 0 do begin
			tRemaining := pl.update(tRemaining);
			self.handlePlayer(pl);
		end;
	end;
end;

procedure WorldState.draw(screen: pSDL_Surface);
var
	pu: Pickup;
	pl: PlayerState;
	view: ViewPort;
begin
	view.pxOffset.x := -4;
	view.pxOffset.y := -4;
	view.pxOffset.w := screen^.w;
	view.pxOffset.h := screen^.h;
	view.tileBase.w := 12;
	view.tileBase.h := 12;
	
	self.map.draw(self.tiles, screen, view);
	for pu in self.pickups do drawPickup(pu, screen, view);
	for pl in self.players do pl.draw(screen, view);
end;

function WorldState.isOccupied(x, y: int): boolean;
var
	pl: PlayerState;
begin
	for pl in self.players do begin
		if pl.occupies(x, y) then exit(true);
	end;
	exit(false);
end;

end.
