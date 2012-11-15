unit pickups;

interface
uses SDL_types, SDL, SDL_video, view;

type
	PickupType = record
		sprite: pSDL_Surface;
		icon: pSDL_Surface;
	end;
	
	pPickup = ^Pickup;
	Pickup = record
		x, y: int;
		typ: ^PickupType;
	end;

var
	pickupFood: PickupType;

function pickupsInit(): string;

procedure drawPickup(pu: Pickup; screen: pSDL_Surface; view: ViewPort);

implementation

procedure drawPickup(pu: Pickup; screen: pSDL_Surface; view: ViewPort);
var
	dstRect: SDL_Rect;
begin
	dstRect.x := pu.x * view.tileBase.w - view.pxOffset.x;
	dstRect.y := pu.y * view.tileBase.h - view.pxOffset.y;
	dstRect.w := view.tileBase.w;
	dstRect.h := view.tileBase.h;
	
	SDL_BlitSurface(pu.typ^.sprite, nil, screen, @dstRect);
end;
	
function pickupsInit(): string;
var
	rect: SDL_Rect;
begin
	with pickupFood do begin
		sprite := SDL_CreateRGBSurface(SDL_SWSURFACE or SDL_SRCALPHA, 12, 12, 32, 0, 0, 0, 0);
		if sprite = nil then begin
			writeln(stderr, SDL_GetError());
			exit;
		end;
		
		rect.x := 3;
		rect.y := 3;
		rect.w := 6;
		rect.h := 6;
		SDL_FillRect(sprite, nil, $00000000);
		SDL_FillRect(sprite, @rect, $ffffff00);
	end;
	
	exit('');
end;

end.
