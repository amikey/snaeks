unit hud;

{$COPERATORS ON}
{$PACKRECORDS C}

interface
uses SDL_types, SDL_video, player, resources, pickups;

type
	pHUDstate = ^HUDstate;
	HUDstate = record
		player: pPlayerState;
	end;

procedure drawHUD(h: pHUDstate; dst: pSDL_Surface);

implementation

procedure drawHUD(h: pHUDstate; dst: pSDL_Surface);
var
	srcRect, dstRect, dstRect2: SDL_Rect;
	it: pPickupType;
	i: int;
begin
	dstRect.x := 6;
	dstRect.y := 6;
	
	for i := 0 to 2 do begin
		SDL_BlitSurface(res.itemsHUD, nil, dst, @dstRect);
		
		it := h^.player^.items[i];
		if it <> nil then begin
			srcRect := it^.iconRect;
			dstRect2 := dstRect;
			dstRect2.x += 2;
			dstRect2.y += 2;			
			dstRect2.w := srcRect.w;
			dstRect2.h := srcRect.h;
			
			SDL_BlitSurface(it^.icon, @srcRect, dst, @dstRect);
		end;
		
		dstRect.x += res.itemsHUD^.w + 4;
	end;
end;

end.