unit path;

{$COPERATORS ON}

interface
uses SDL_types, world;

type
	pWaypoint = ^Waypoint;
	Waypoint = record
		x, y: int;
		len: double;
		dist: double;
		
		prev: pWaypoint;
	end;
	
	aWaypoint = array of Waypoint;
	apWaypoint = array of pWaypoint;

// pathTo returns the shortest path between the given points. The path doesn't include the starting point.
// If no path can be found, the returned array has length 0.
function pathTo(world: pWorldState; fromp, top: Waypoint; cutoff: double = -1): aWaypoint;

function pathToNearest(world: pWorldState; fromp: Waypoint; top: aWaypoint; cutoff: double = -1): aWaypoint;

implementation
uses tile;

type
	pPointQueue = ^PointQueue;
	PointQueue = record
		points: apWayPoint;
		
		// first and last non-empty index of "points"
		first, last: int;
	end;
	
	pNodePool = ^NodePool;
	NodePool = apWaypoint;

function newPQ(): pPointQueue;
var
	ptr: pPointQueue;
begin
	new(ptr);
	setLength(ptr^.points, 10000);
	ptr^.first := 0;
	ptr^.last := -1;
	exit(ptr);
end;

function PQlen(pq: pPointQueue): int;
begin
	exit(pq^.last - pq^.first + 1);
end;

procedure cleanupPQ(ptr: pPointQueue);
begin 
	setLength(ptr^.points, 0);
	dispose(ptr);
end;

procedure PQcompact(pq: pPointQueue);
var
	dst, elements, len: int;
	asize, newasize: int;
begin
	elements := pq^.last - pq^.first + 1;
	for dst := 0 to elements-1 do begin
		pq^.points[dst] := pq^.points[pq^.first+dst];
	end;
	pq^.first := 0;
	pq^.last := elements - 1;
	
	if length(pq^.points) < 100000 then exit();
	
	asize := length(pq^.points) div 2;
	newasize := 2 << 17;  // 131072
	while newasize < asize do newasize := newasize << 1;
	setLength(pq^.points, newasize);
end;

procedure PQinsert(pq: pPointQueue; point: pWaypoint);
var
	where, i: int;
begin
	where := pq^.first;
	
	while (where <= pq^.last) and (point^.dist >= pq^.points[where]^.dist) do begin
		where += 1;
	end;
	
	for i := pq^.last downto where do pq^.points[i+1] := pq^.points[i];
	pq^.points[where] := point;
	pq^.last += 1;
end;

procedure PQadd(pq: pPointQueue; point: pWaypoint);
var
	newlen: int;
begin
	if PQlen(pq) < length(pq^.points) div 2 then begin
		PQcompact(pq);
		PQinsert(pq, point);
		exit;
	end;
	
	if pq^.last < high(pq^.points) then begin
		PQinsert(pq, point);
		exit;
	end;
	
	newlen := length(pq^.points) * 2;
	setLength(pq^.points, newlen);
	PQinsert(pq, point);
end;

function PQremove(pq: pPointQueue): pWaypoint;
var
	ret: pWaypoint;
begin
	if PQlen(pq) < length(pq^.points) div 2 then begin
		PQcompact(pq);
	end;
	
	ret := pq^.points[pq^.first];
	pq^.first += 1;
	exit(ret);
end;

function PQcontains(pq: pPointQueue; wp: pWaypoint): boolean;
var
	curr: int;
	currp: pWaypoint;
begin
	for curr := pq^.first to pq^.last do begin
		currp := pq^.points[curr];
		if currp = wp then exit(true);
	end;
	exit(false);
end;

// PQlookup finds a waypoint with the same coordinates as `wp` in the queue.
// If no such point can be found, it returns `wp`.
function PQlookup(pq: pPointQueue; wp: pWaypoint): pWaypoint;
var
	curr: int;
	currp: pWaypoint;
begin
	for curr := pq^.first to pq^.last do begin
		currp := pq^.points[curr];
		if (currp^.x = wp^.x) and (currp^.y = wp^.y) then exit(currp);
	end;
	exit(wp);
end;

function estimate(fromp, top: Waypoint): double;
begin
	exit(sqrt((top.x-fromp.x)*(top.x-fromp.x) + (top.y-fromp.y)*(top.y-fromp.y)));
end;

function neighborsOf(wp: Waypoint; world: pWorldState; all: pNodePool): apWaypoint;
const
	xoff: array[1..4] of int = ( 0,  1,  0, -1);
	yoff: array[1..4] of int = (-1,  0,  1,  0);
var
	ret: apWaypoint;
	seekwp, extantwp: pWaypoint;
	x, y, i: int;
	next: int;
begin
	next := 0;
	
	setLength(ret, 4);
	for i := low(xoff) to high(xoff) do begin
		x := wp.x + xoff[i];
		y := wp.y + yoff[i];
		if (not TMinBounds(world^.map, x, y)) or isOccupied(world, x, y) then continue;
		
		extantwp := nil;
		for seekwp in all^ do begin
			if (seekwp^.x = x) and (seekwp^.y = y) then begin
				extantwp := seekwp;
				break;
			end;
		end;
		
		if extantwp = nil then begin
			new(extantwp);
			extantwp^.prev := nil;
			setLength(all^, length(all^)+1);
			all^[high(all^)] := extantwp;
		end;
		
		extantwp^.x := x;
		extantwp^.y := y;
		//extantwp.len := wp.len + estimate(wp, newwp);
		
		ret[next] := extantwp;
		next += 1;
	end;
	
	setLength(ret, next);
	exit(ret);
end;

function trace(all: NodePool; endp: pWaypoint): aWaypoint;
var
	curr: Waypoint;
	ret: aWaypoint;
	i, j: int;
	dummy: int;
begin
	curr := endp^;
	setLength(ret, 0);
	
	dummy := 0;
	while curr.prev <> nil do begin
		dummy += 1;
		if dummy > 1000 then begin
			writeln('path too long');
			exit(ret);
		end;
		
		setLength(ret, length(ret)+1);
		ret[high(ret)] := curr;
		curr := curr.prev^;
	end;
	
	// Reverse the path.
	i := low(ret);
	j := high(ret);
	while i < j do begin
		curr := ret[i];
		ret[i] := ret[j];
		ret[j] := curr;
		
		i += 1;
		j -= 1;
	end;
	
	exit(ret);
end;

function pathTo(world: pWorldState; fromp, top: Waypoint; cutoff: double = -1): aWaypoint;
var
	all: NodePool;
	open, closed: pPointQueue;
	wp, neighbor: pWaypoint;
	newneighbors: apWaypoint;
	path: aWaypoint;
	newlen: double;
	dummy: int;
begin
	open := newPQ();
	closed := newPQ();
	
	setLength(all, 1);
	new(all[0]);
	wp := all[0];
	wp^ := fromp;
	wp^.len := 0;
	wp^.dist := wp^.len + estimate(wp^, top);
	wp^.prev := nil;
	PQadd(open, wp);
	
	while PQlen(open) <> 0 do begin
		dummy := PQlen(open);
		if (cutoff >= 0) and (PQlen(closed) > 0) and (closed^.points[closed^.last]^.len > cutoff) then begin
			cleanupPQ(open);
			cleanupPQ(closed);
			setLength(path, 0);
			exit(path);
		end;
		
		wp := PQremove(open);
		if (wp^.x = top.x) and (wp^.y = top.y) then begin
			path := trace(all, wp);
			cleanupPQ(open);
			cleanupPQ(closed);
			exit(path);
		end;
		
		PQadd(closed, wp);
		for neighbor in neighborsOf(wp^, world, @all) do begin
			if PQcontains(closed, neighbor) then continue;
			
			newlen := wp^.len + estimate(wp^, neighbor^);
			if (not PQcontains(open, neighbor)) or (newlen <= neighbor^.len) then begin
				neighbor^.prev := wp;
				neighbor^.len := newlen;
				neighbor^.dist := neighbor^.len + estimate(neighbor^, top);
				if not PQcontains(open, neighbor) then PQadd(open, neighbor);
			end;
		end;
	end;
	
	for wp in all do dispose(wp);
	cleanupPQ(open);
	cleanupPQ(closed);
	exit(path);
end;

function pathToNearest(world: pWorldState; fromp: Waypoint; top: aWaypoint; cutoff: double = -1): aWaypoint;
var
	path, npath: aWaypoint;
	len: double;
	wp: Waypoint;
begin
	setLength(path, 0);
	
	len := cutoff;
	for wp in top do begin
		npath := pathTo(world, fromp, wp, len);
		if (length(npath) > 0) and ((npath[high(npath)].len < len) or (len < 0)) then begin
			path := npath;
			len := path[high(path)].len;
		end;
	end;
	
	exit(path);
end;

end.
