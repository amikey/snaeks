unit resources;

interface
uses tile, SDL, SDL_video;

type
	resType = record
		snake: pSDL_Surface;
		tiles: TileSprites;
	end;

var
	res: resType;

function loadRes(): boolean;
procedure freeRes();

implementation
uses SDL_image;

function loadRes(): boolean;
var
	rawSnake: pSDL_Surface;
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
	end;
	
	exit(true);
end;

procedure freeRes();
begin
	SDL_FreeSurface(res.snake);
	SDL_FreeSurface(res.tiles.sprite);
	setLength(res.tiles.rects, 0);
end;

end.