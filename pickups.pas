unit pickups;

interface
uses SDL_types, SDL, SDL_video, SDL_image, view;

type
	PickupType = record
		// simpleFood has a different sprite and the effect of increasing snake lenght by 1.
		simpleFood: boolean;
		
		// HUD icon, if any. Freed after the item is used.
		icon: pSDL_Surface;
	end;
	
	pPickup = ^Pickup;
	Pickup = record
		x, y: int;
		typ: ^PickupType;
	end;

var
	pickupFood: PickupType;

procedure pickupsInit();
procedure drawPickup(pu: Pickup; screen: pSDL_Surface; view: ViewPort);

implementation
uses resources;

procedure drawPickup(pu: Pickup; screen: pSDL_Surface; view: ViewPort);
var
	srcRect, dstRect: SDL_Rect;
begin
	if pu.typ^.simpleFood then begin
		srcRect := res.tiles.rects[1];
	end else begin
		srcRect := res.tiles.rects[2];
	end;
	
	srcRect.w := 12;
	srcRect.h := 12;
	
	dstRect.x := pu.x * view.tileBase.w - view.pxOffset.x;
	dstRect.y := pu.y * view.tileBase.h - view.pxOffset.y;
	dstRect.w := view.tileBase.w;
	dstRect.h := view.tileBase.h;
	
	SDL_BlitSurface(res.tiles.sprite, @srcRect, screen, @dstRect);
end;
	
procedure pickupsInit();
var
	rect: SDL_Rect;
begin
	pickupFood.simpleFood := true;
	pickupFood.icon := nil;	
end;

end.
