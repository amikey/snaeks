unit resources;

interface
uses tile, SDL, SDL_video;

const
	// First and last (inclusive) index of wall tiles.
	wallTilesIndicesFrom = 20;
	wallTilesIndicesTo   = 29;

type
	resType = record
		snake: pSDL_Surface;
		tiles: TileSprites;
		
		itemsHUD: pSDL_Surface;
		
		itemIcons: pSDL_Surface;
		iconGunRect: SDL_Rect;
	end;

var
	res: resType;

function loadRes(): boolean;
procedure freeRes();

implementation
uses SDL_image;

function loadRes(): boolean;
var
	rawSnake, rawItemsHUD, rawIcons: pSDL_Surface;
begin
	if res.snake <> nil then freeRes();
	
	with res do begin
		rawSnake := IMG_Load('res/snake.png');
		if rawSnake = nil then exit(false);
		
		snake := SDL_DisplayFormatAlpha(rawSnake);
		if snake = nil then exit(false);
		SDL_FreeSurface(rawSnake);
	
		tiles := loadTiles('res/tilemap.png', 10, 10);
		if tiles.sprite = nil then exit(false);
		
		rawItemsHUD := IMG_Load('res/item_box.png');
		if rawItemsHUD = nil then exit(false);
		
		itemsHUD := SDL_DisplayFormatAlpha(rawItemsHUD);
		if itemsHUD = nil then exit(false);
		SDL_FreeSurface(rawItemsHUD);
		
		rawIcons := IMG_Load('res/item_icons.png');
		if rawIcons = nil then exit(false);
		
		itemIcons := SDL_DisplayFormatAlpha(rawIcons);
		if itemIcons = nil then exit(false);
		SDL_FreeSurface(rawIcons);
		
		iconGunRect.x := 0;
		iconGunRect.y := 0;
		iconGunRect.w := 40;
		iconGunRect.h := 40;
	end;
	
	exit(true);
end;

procedure freeRes();
begin
	SDL_FreeSurface(res.snake);
	SDL_FreeSurface(res.tiles.sprite);
	SDL_FreeSurface(res.itemsHUD);
	SDL_FreeSurface(res.itemIcons);
	setLength(res.tiles.rects, 0);
end;

end.
