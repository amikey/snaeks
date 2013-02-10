{
  Additional SDL wrapper code by Paweł Stępień <pvl.staven@gmail.com>, 2012.
  Distributed under the "don't sue me and I'm not gonna sue you either" license.
}
{
  SDL_image:  An example image loading library for use with SDL
  Copyright (C) 1997-2012 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
}
unit SDL_image;

interface
uses SDL_types, SDL, SDL_video;

type
	IMG_InitFlags = (
		IMG_INIT_JPG  = $00000001, 
		IMG_INIT_PNG  = $00000002,
    		IMG_INIT_TIF  = $00000004,
    		IMG_INIT_WEBP = $00000008
    );
	
function IMG_Init(flags: sint32): sint32; cdecl;
function IMG_Load(imgfile: pchar): pSDL_Surface; cdecl;
procedure IMG_Quit(); cdecl;

function IMG_GetError(): pchar;

implementation
function IMG_Init(flags: sint32): sint32; cdecl; external 'SDL_image';
function IMG_Load(imgfile: pchar): pSDL_Surface; cdecl; external 'SDL_image';
procedure IMG_Quit(); cdecl; external 'SDL_image';
function IMG_GetError(): pchar; begin exit(SDL_GetError()); end;

end.
