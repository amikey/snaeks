unit tile;

interface
uses math, types, sdl_types, sdl_video, view;

const
	TM_INVALID_TILE_INDEX = 1;

type
	TileSprites = record
		sprite: pSDL_Surface;
		rects: array of SDL_Rect;
	end;
	
	TileMap = class
	public
		i:      array of uint32;
		skip:   sint32;           { Skip this many elements of `i` between lines. }
		width:  sint32;
		height: sint32;
		
		constructor init();
		constructor initZero(w, h: int);
		
		procedure fillRectRandom(indices: array of int; sx, sy, w, h: int);
		
		function index(x: sint32; y: sint32): uint32;
		
		function draw(sprites: TileSprites; dst: pSDL_Surface; view: ViewPort): int;
	end;

implementation

constructor TileMap.init();
begin
end;

constructor TileMap.initZero(w, h: int);
begin
	setLength(self.i, w*h);
	self.width := w;
	self.height := h;
	self.skip := 0;
end;

procedure TileMap.fillRectRandom(indices: array of int; sx, sy, w, h: int);
var
	ind, x, y: int;
begin
	for y := sy to sy+h-1 do begin
		for x := sx to sx+w-1 do begin
			ind := indices[low(indices)+random(length(indices))];
			self.i[y*(self.width+self.skip) + x] := ind;
		end;
	end;
end;

function TileMap.index(x: sint32; y: sint32): uint32;
begin
	exit(self.i[y*(self.width+self.skip) + x]);
end;

function TileMap.draw(sprites: TileSprites; dst: pSDL_Surface; view: ViewPort): int;
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
	
	if endx > self.width then endx := self.width-1;
	if endy > self.height then endy := self.height-1;

	for y := starty to endy do begin
		for x := startx to endx do begin
			ind := self.index(x, y);
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
