#include "steam_C/steamC.h"
#include "steam/steam_api.h"

bool S_CALLTYPE SteamAPI_RestartAppIfNecessary_C(uint32 unOwnAppID) {
    SteamAPI_RestartAppIfNecessary(unOwnAppID);
}

