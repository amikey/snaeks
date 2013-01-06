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
		
		// index of the previous point in the NodePool.
		prev: int;
	end;
	
	aWaypoint = array of Waypoint;
	apWaypoint = array of pWaypoint;
	aint = array of int;

// pathTo returns the shortest path between the given points. The path doesn't include the starting point.
// If no path can be found, the returned array has length 0.
function pathTo(world: pWorldState; fromp, top: Waypoint; cutoff: double = -1): aWaypoint;

function pathToNearest(world: pWorldState; fromp: Waypoint; top: aWaypoint; cutoff: double = -1): aWaypoint;

implementation
uses tile;

type
	pPointQueue = ^PointQueue;
	PointQueue = record
		points: array of int;
		
		// first and last non-empty index of `points`
		first, last: int;
	end;
	
	pNodePool = ^NodePool;
	NodePool = record
		nodes: aWaypoint;
		len: int;
	end;

function newNodePool(len: int; cap: int = -1): NodePool;
var
	ret: NodePool;
	zeroval: Waypoint;
	i: int;
begin
	if cap = -1 then cap := len;
	ret.len := len;
	
	zeroval.x := 0;
	zeroval.y := 0;
	zeroval.len := 0;
	zeroval.dist := 0;
	zeroval.prev := -1;
	
	setLength(ret.nodes, cap);
	for i := 0 to len-1 do begin
		ret.nodes[i] := zeroval;
	end;
	
	exit(ret);
end;

function NPappend(np: NodePool; node: Waypoint): NodePool;
var
	ret: NodePool;
	i: int;
begin
	ret := np;
	if ret.len + 1 > length(ret.nodes) then begin
		setLength(ret.nodes, length(ret.nodes)*2);
	end;
	ret.nodes[ret.len] := node;
	ret.len += 1;
	exit(ret);
end;

function NPind(np: NodePool; ind: int): pWaypoint; inline;
begin
	exit(@(np.nodes[ind]));
end;

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

procedure PQinsert(pq: pPointQueue; point: int; all: NodePool);
var
	where, i: int;
begin
	where := pq^.first;
	
	while (where <= pq^.last) and
			(NPind(all, point)^.dist >= NPind(all, pq^.points[where])^.dist) do begin
		where += 1;
	end;
	
	for i := pq^.last downto where do pq^.points[i+1] := pq^.points[i];
	pq^.points[where] := point;
	pq^.last += 1;
end;

procedure PQadd(pq: pPointQueue; point: int; all: NodePool);
var
	newlen: int;
begin
	if PQlen(pq) < length(pq^.points) div 2 then begin
		PQcompact(pq);
		PQinsert(pq, point, all);
		exit;
	end;
	
	if pq^.last < high(pq^.points) then begin
		PQinsert(pq, point, all);
		exit;
	end;
	
	newlen := length(pq^.points) * 2;
	setLength(pq^.points, newlen);
	PQinsert(pq, point, all);
end;

function PQremove(pq: pPointQueue): int;
var
	ret: int;
begin
	if PQlen(pq) < length(pq^.points) div 2 then begin
		PQcompact(pq);
	end;
	
	ret := pq^.points[pq^.first];
	pq^.first += 1;
	exit(ret);
end;

function PQcontains(pq: pPointQueue; wp: int): boolean;
var
	curr, currind: int;
begin
	for curr := pq^.first to pq^.last do begin
		currind := pq^.points[curr];
		if currind = wp then exit(true);
	end;
	exit(false);
end;


function estimate(fromp, top: Waypoint): double;
begin
	exit(sqrt((top.x-fromp.x)*(top.x-fromp.x) + (top.y-fromp.y)*(top.y-fromp.y)));
end;

function neighborsOf(wp: int; world: pWorldState; all: pNodePool): aint;
const
	xoff: array[1..4] of int = (-1,  1,  0,  0);
	yoff: array[1..4] of int = ( 0,  0,  1, -1);
var
	ret: aint;
	seekwp: pWaypoint;
	extantwp: int;
	newwp: Waypoint;
	x, y, i, j: int;
	next: int;
begin
	next := 0;
	
	setLength(ret, 4);
	for i := low(xoff) to high(xoff) do begin
		x := NPind(all^, wp)^.x + xoff[i];
		y := NPind(all^, wp)^.y + yoff[i];
		if (not TMinBounds(world^.map, x, y)) or isOccupied(world, x, y) then continue;
		extantwp := -1;
		for j := 0 to all^.len-1 do begin
			seekwp := NPind(all^, j);
			if (seekwp^.x = x) and (seekwp^.y = y) then begin
				extantwp := j;
				break;
			end;
		end;
		
		if extantwp = -1 then begin
			newwp.x := x;
			newwp.y := y;
			newwp.prev := -1;
			all^ := NPappend(all^, newwp);
			extantwp := all^.len - 1;
		end;
		
		ret[next] := extantwp;
		next += 1;
	end;
	
	setLength(ret, next);
	exit(ret);
end;

function trace(all: NodePool; endp: int): aWaypoint;
var
	curr: Waypoint;
	ret: aWaypoint;
	i, j: int;
	dummy: int;
begin
	curr := NPind(all, endp)^;
	setLength(ret, 0);
	
	while curr.prev <> -1 do begin
		setLength(ret, length(ret)+1);
		ret[high(ret)] := curr;
		curr := NPind(all, curr.prev)^;
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
	wp, neighbor: int;
	neighborptr: pWaypoint;
	newneighbors: apWaypoint;
	origin: pWaypoint;
	path: aWaypoint;
	newlen: double;
begin
	all := newNodePool(1, 1000);
	open := newPQ();
	closed := newPQ();
	
	origin := NPind(all, 0);
	origin^ := fromp;
	origin^.len := 0;
	origin^.dist := origin^.len + estimate(origin^, top);
	origin^.prev := -1;
	PQadd(open, 0, all);
	
	while PQlen(open) <> 0 do begin
		if (cutoff >= 0) and (PQlen(closed) > 0) and
				(NPind(all, closed^.points[closed^.last])^.len > cutoff) then begin
			cleanupPQ(open);
			cleanupPQ(closed);
			setLength(path, 0);
			exit(path);
		end;
		
		wp := PQremove(open);
		if (NPind(all, wp)^.x = top.x) and (NPind(all, wp)^.y = top.y) then begin
			path := trace(all, wp);
			cleanupPQ(open);
			cleanupPQ(closed);
			exit(path);
		end;
		
		PQadd(closed, wp, all);
		for neighbor in neighborsOf(wp, world, @all) do begin
			if PQcontains(closed, neighbor) then continue;
			
			neighborptr := NPind(all, neighbor);
			newlen := NPind(all, wp)^.len + estimate(NPind(all, wp)^, neighborptr^);
			if (not PQcontains(open, neighbor)) or (newlen <= neighborptr^.len) then begin
				neighborptr^.prev := wp;
				neighborptr^.len := newlen;
				neighborptr^.dist := neighborptr^.len + estimate(neighborptr^, top);
				if not PQcontains(open, neighbor) then PQadd(open, neighbor, all);
			end;
		end;
	end;
	
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
