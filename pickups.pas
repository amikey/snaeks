unit pickups;

interface
uses SDL_types, SDL, SDL_video, SDL_image, view;

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
	srcRect, dstRect: SDL_Rect;
begin
	srcRect.x := 12;
	srcRect.y := 0;
	srcRect.w := 12;
	srcRect.h := 12;
	
	dstRect.x := pu.x * view.tileBase.w - view.pxOffset.x;
	dstRect.y := pu.y * view.tileBase.h - view.pxOffset.y;
	dstRect.w := view.tileBase.w;
	dstRect.h := view.tileBase.h;
	
	SDL_BlitSurface(pu.typ^.sprite, @srcRect, screen, @dstRect);
end;
	
function pickupsInit(): string;
var
	rect: SDL_Rect;
begin
	with pickupFood do begin
		sprite := IMG_Load('res/tilemap.png');
		if sprite = nil then begin
			writeln(stderr, SDL_GetError());
			exit;
		end;
		
		sprite := SDL_DisplayFormatAlpha(sprite);
	end;
	
	exit('');
end;

end.
