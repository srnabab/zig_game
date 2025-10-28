#include "sqlite3/sqlite3.h"

#ifndef SQLITE3_ALLOC_FUNC_H
#define SQLITE3_ALLOC_FUNC_H

#include "SDL3/SDL_begin_code.h"

#define ALIGNMENT 8

extern void* SDLCALL SDL_SQLite_malloc(int size);
extern void SDLCALL SDL_SQLite_free(void* mem);
extern void* SDLCALL SDL_SQLite_realloc(void* mem, int size);
extern int SDLCALL SDL_SQLite_memSize(void* mem);
extern int SDLCALL SDL_SQLite_RoundUp(int size);
extern void SDLCALL SDL_SQLite_shutDown(void*);
extern int SDLCALL SDL_SQLite_Init(void*);

#include "SDL3/SDL_close_code.h"

#endif
