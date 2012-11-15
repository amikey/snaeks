unit tile;

interface
uses types, sdl_types, sdl_video;

const
	TM_INVALID_TILE_INDEX = 1;

type
	TileSprite = pSDL_Surface;
	TileMap = record
		i:      array of uint32;
		skip:   sint32;           { Skip this many elements of `i` between lines. }
		width:  sint32;
		height: sint32;
	end;

function IAIndex(ar: TileMap; x: sint32; y: sint32): uint32;

{function tileSurface(surf: array of pSDL_Surface; indices: TileMap; dest: pSDL_Surface): uint32;}

implementation

function IAIndex(ar: TileMap; x: sint32; y: sint32): uint32;
begin
	IAIndex := ar.i[y*(ar.width+ar.skip) + x];
end;


function tileSurface(dest: pSDL_Surface; xoffset: sint32; yoffset: sint32;
                     tiles: array of pSDL_Surface; indices: TileMap; tbaseh: sint32): uint32;
var
	x, y: sint32;
	dstr: SDL_Rect;
	index: uint32;
begin
	for y := 0 to indices.height do begin
		for x := 0 to indices.width do begin
			index := IAIndex(indices, x, y);
			if (index < 0) or (index > high(tiles)) then begin
				exit(TM_INVALID_TILE_INDEX);
			end;
			
			dstr.x := xoffset + x * tiles[0]^.w;
			dstr.y := yoffset + y * tiles[0]^.h - tbaseh;
			dstr.w := tiles[0]^.w;
			dstr.h := tiles[0]^.h;
			
			SDL_BlitSurface(tiles[index], nil, dest, @dstr);
		end;
	end;
	exit(0);
end;

end.
