unit hud;

{$COPERATORS ON}
{$PACKRECORDS C}

interface
uses SDL_types, SDL_video, player, resources;

type
	pHUDstate = ^HUDstate;
	HUDstate = record
		player: pPlayerState;
	end;

procedure drawHUD(h: pHUDstate; dst: pSDL_Surface);

implementation

procedure drawHUD(h: pHUDstate; dst: pSDL_Surface);
var
	dstRect: SDL_Rect;
	i: int;
begin
	dstRect.x := 6;
	dstRect.y := 6;
	
	for i := 1 to 3 do begin
		SDL_BlitSurface(res.itemsHUD, nil, dst, @dstRect);
		dstRect.x += res.itemsHUD^.w + 4;
	end;
end;

end.