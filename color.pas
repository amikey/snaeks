unit color;

interface
uses SDL_types, SDL, SDL_video;

const
	SnakeColorBody  = $ff21c821;
	SnakeColorEdgeD = $ff61d561;
	SnakeColorEdgeL = $ff88ff88;
	SnakeColorEyes  = $fffff854;
	
	SnakeCMapGreen: array[0..3] of uint32 =
		(SnakeColorBody, SnakeColorEdgeD, SnakeColorEdgeL, SnakeColorEyes);
	
	SnakeCMapBlue: array[0..3] of uint32 =
		($ff5f7cff,      $ff3e54b5,       $ffc6dcff,       SnakeColorEyes);

type
	ColorRGBA = record
		r, g, b, a: uint8;
	end;

procedure mapColorsRGB(surf: pSDL_Surface; fromc, toc: array of uint32);

implementation
type
	puint8 = ^uint8;
	puint32 = ^uint32;

function mapColorRGB(col: ColorRGBA; fromc, toc: array of uint32): ColorRGBA;
var
	i: int;
	ret: ColorRGBA;
begin
	for i := low(fromc) to high(fromc) do begin
		if 		(col.r = (fromc[i] and $00ff0000) >> 16) and
				(col.g = (fromc[i] and $0000ff00) >> 8) and
				(col.b = (fromc[i] and $000000ff)) then begin
			ret.a := col.a;
			ret.r := (toc[i] and $00ff0000) >> 16;
			ret.g := (toc[i] and $0000ff00) >> 8;
			ret.b := (toc[i] and $000000ff);
			exit(ret);
		end;
	end;
	exit(col);
end;

procedure mapColorsRGB(surf: pSDL_Surface; fromc, toc: array of uint32);
var
	x, y, i: int;
	color: ColorRGBA;
	fmt: SDL_PixelFormat;
	pixel, temp, alpha: uint32;
begin
	fmt := surf^.format^;
	
	if SDL_MUSTLOCK(surf) then SDL_LockSurface(surf);
	
	for y := 0 to surf^.h-1 do begin
		for x := 0 to surf^.w-1 do begin
			pixel := puint32(puint8(surf^.pixels) + y * surf^.pitch + x * fmt.BytesPerPixel)^;
			temp := pixel and fmt.Rmask;
			temp := temp >> fmt.Rshift;
			temp := temp << fmt.Rloss;
			color.r := temp;
			
			temp := pixel and fmt.Gmask;
			temp := temp >> fmt.Gshift;
			temp := temp << fmt.Gloss;
			color.g := temp;
			
			temp := pixel and fmt.Bmask;
			temp := temp >> fmt.Bshift;
			temp := temp << fmt.Bloss;
			color.b := temp;
			
			alpha := pixel and fmt.Amask;
			
			color := mapColorRGB(color, fromc, toc);
			
			pixel := 0;
			temp := color.r;
			temp := temp >> fmt.Rloss;
			temp := temp << fmt.Rshift;
			temp := temp and fmt.Rmask;
			pixel := pixel or temp;
			
			temp := color.g;
			temp := temp >> fmt.Gloss;
			temp := temp << fmt.Gshift;
			temp := temp and fmt.Gmask;
			pixel := pixel or temp;
			
			temp := color.b;
			temp := temp >> fmt.Bloss;
			temp := temp << fmt.Bshift;
			temp := temp and fmt.Bmask;
			pixel := pixel or temp;
			
			pixel := pixel or alpha;
			
			puint32(puint8(surf^.pixels) + y * surf^.pitch + x * fmt.BytesPerPixel)^ := pixel;
		end;
	end;
	
	if SDL_MUSTLOCK(surf) then SDL_UnlockSurface(surf);
end;

end.
