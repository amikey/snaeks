unit coldet;

interface
uses SDL_types;

type
	CollisionDetector = class
		function isOccupied(x, y: int): boolean; virtual;
	end;

implementation
function CollisionDetector.isOccupied(x, y: int): boolean; begin end;

end.
