unit scaler;

interface
uses SDL_types, SDL, SDL_video;

function drawScaled(src: pSDL_Surface; srcr: pSDL_Rect; dst: pSDL_Surface; dstr: pSDL_Rect): boolean;

implementation

function drawScaled(src: pSDL_Surface; srcr: pSDL_Rect; dst: pSDL_Surface; dstr: pSDL_Rect): boolean;
var
	convsrc: pSDL_Surface;
	srcpx, dstpx: ^uint8;
	sb, db: ^uint8;
	pixelByte: uint8;
	
	x, y, dx, dy: int;
	offset: int;
	allsrc, alldst: SDL_Rect;
	
	pxOffset, spitch, dpitch: int;
begin
	convsrc := SDL_ConvertSurface(src, src^.format, SDL_SWSURFACE);
	if convsrc = nil then exit(false);
	
	if srcr = nil then begin
		allsrc.x := 0;
		allsrc.y := 0;
		allsrc.w := convsrc^.w;
		allsrc.h := convsrc^.h;
		srcr := @allsrc;
	end;
	
	if dstr = nil then begin
		alldst.x := 0;
		alldst.y := 0;
		alldst.w := dst^.w;
		alldst.h := dst^.h;
		dstr := @alldst;
	end;
	
	if SDL_MUSTLOCK(dst) then SDL_LockSurface(dst);
	srcpx := convsrc^.pixels;
	dstpx := dst^.pixels;
	
	pxOffset := convsrc^.format^.BytesPerPixel;
	spitch := convsrc^.pitch;
	dpitch := dst^.pitch;
	
	for x := srcr^.x to srcr^.x+srcr^.w-1 do begin
		for y := srcr^.y to srcr^.y+srcr^.h-1 do begin
			dx := dstr^.x + 2*(x - srcr^.x);
			dy := dstr^.y + 2*(y - srcr^.y);
			sb := srcpx + y*spitch + x*pxOffset;
			db := dstpx + dy*dpitch + dx*pxOffset;
			
			for offset := 0 to convsrc^.format^.BytesPerPixel-1 do begin
				pixelByte := (sb + offset)^;
				(db + offset)^                     := pixelByte;
				(db + offset + pxOffset)^          := pixelByte;
				(db + offset + dpitch)^            := pixelByte;
				(db + offset + pxOffset + dpitch)^ := pixelByte;
			end;
		end;
	end;
	
	if SDL_MUSTLOCK(dst) then SDL_UnlockSurface(dst);
end;

end.
