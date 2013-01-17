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
				
		victory: pSDL_Surface;
		defeat: pSDL_Surface;
	end;

var
	res: resType;

function loadRes(): boolean;
procedure freeRes();

implementation
uses SDL_image;

function loadRes(): boolean;
var
	rawSnake, rawBanner: pSDL_Surface;
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
		
		rawBanner := IMG_Load('res/victory.png');
		if rawBanner = nil then exit(false);
		
		victory := SDL_DisplayFormatAlpha(rawBanner);
		if victory = nil then exit(false);
		SDL_FreeSurface(rawBanner);
		
		rawBanner := IMG_Load('res/defeat.png');
		if rawBanner = nil then exit(false);
		
		defeat := SDL_DisplayFormatAlpha(rawBanner);
		if defeat = nil then exit(false);
		SDL_FreeSurface(rawBanner);
	end;
	
	exit(true);
end;

procedure freeRes();
begin
	SDL_FreeSurface(res.snake);
	SDL_FreeSurface(res.tiles.sprite);
	SDL_FreeSurface(res.victory);
	SDL_FreeSurface(res.defeat);
	setLength(res.tiles.rects, 0);
end;

end.
