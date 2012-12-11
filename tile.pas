unit tile;

interface
uses math, types, SDL_types, SDL_video, SDL_image, view;

const
	TM_INVALID_TILE_INDEX = 1;

type
	TileSprites = record
		sprite: pSDL_Surface;
		rects: array of SDL_Rect;
	end;
	
	pTileMap = ^TileMap;
	TileMap = record
		i:      array of uint32;
		skip:   sint32;           // Skip this many elements of `i` between lines.
		width:  sint32;
		height: sint32;
	end;

// newTileMap creates a new TileMap with the given width and height,
// with all indices initialized to 0.
function newTileMap(w, h: int): pTileMap;

// loadTiles loads tile sprites from the given file.
// w and h are the number of columns and the number of rows of sprites in the file, respectively.
// All tile sprites must have the same dimmensions.
// If loading fails, sprite = nil.
function loadTiles(fname: pchar; w, h: int): TileSprites;

// TMfillRectRandom fills the given rectangle with indices in the range [ifrom, ito).
procedure TMfillRectRandom(tm: pTileMap; ifrom, ito: int; sx, sy, w, h: int);
		
// TMindex returns the index at the given coordinates.
function TMindex(tm: pTileMap; x: sint32; y: sint32): uint32;
		
function TMdraw(tm: pTileMap; sprites: TileSprites; dst: pSDL_Surface; view: ViewPort): int;

implementation

function loadTiles(fname: pchar; w, h: int): TileSprites;
var
	tiles: TileSprites;
	rawSprite: pSDL_Surface;
	rect: SDL_Rect;
	tw, th: int;
	x, y: int;
begin
	rawSprite := IMG_Load(fname);
	if RawSprite = nil then begin
		tiles.sprite := nil;
		exit(tiles);
	end;
	
	tiles.sprite := SDL_DisplayFormatAlpha(rawSprite);
	if tiles.sprite = nil then begin
		exit(tiles);
	end;
	
	rect.w := tiles.sprite^.w div w;
	rect.h := tiles.sprite^.h div h;
	
	setLength(tiles.rects, w * h);
	for y := 0 to h-1 do begin
		for x := 0 to w-1 do begin
			rect.x := x * rect.w;
			rect.y := y * rect.h;
			tiles.rects[y*w + x] := rect;
		end;
	end;
	exit(tiles);
end;

function newTileMap(w, h: int): pTileMap;
var
	j: int;
	tm: pTileMap;
begin
	new(tm);
	setLength(tm^.i, w*h);
	tm^.width := w;
	tm^.height := h;
	tm^.skip := 0;
	for j := 0 to h*w-1 do tm^.i[j] := 0;
	exit(tm);
end;

procedure TMfillRectRandom(tm: pTileMap; ifrom, ito: int; sx, sy, w, h: int);
var
	ind, x, y: int;
begin
	for y := sy to sy+h-1 do begin
		for x := sx to sx+w-1 do begin
			ind := ifrom + random(ito-ifrom);
			tm^.i[y*(tm^.width+tm^.skip) + x] := ind;
		end;
	end;
end;

function TMindex(tm: pTileMap; x: sint32; y: sint32): uint32;
begin
	exit(tm^.i[y*(tm^.width+tm^.skip) + x]);
end;

function TMdraw(tm: pTileMap; sprites: TileSprites; dst: pSDL_Surface; view: ViewPort): int;
var
	x, y: int;
	startx, starty, endx, endy: int;
	srcr, dstr: SDL_Rect;
	ind: uint32;
begin
	startx := view.pxOffset.x div view.tileBase.w;
	starty := view.pxOffset.y div view.tileBase.h;
	
	endx := ceil(startx + view.pxOffset.w/view.tileBase.w);
	endy := ceil(starty + view.pxOffset.h/view.tileBase.h);
	
	if endx > tm^.width then endx := tm^.width-1;
	if endy > tm^.height then endy := tm^.height-1;

	for y := starty to endy do begin
		for x := startx to endx do begin
			ind := TMindex(tm, x, y);
			if (ind < 0) or (ind > high(sprites.rects)) then begin
				exit(TM_INVALID_TILE_INDEX);
			end;
			
			srcr := sprites.rects[ind];
			
			dstr.x := x * view.tileBase.w - view.pxOffset.x;
			dstr.y := y * view.tileBase.h - view.pxOffset.y + view.tileBase.h - sprites.rects[ind].h;
			dstr.w := sprites.rects[ind].w;
			dstr.h := sprites.rects[ind].h;
			
			SDL_BlitSurface(sprites.sprite, @srcr, dst, @dstr);
		end;
	end;
	exit(0);
end;

end.
