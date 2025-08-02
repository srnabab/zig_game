#include "steam_C/steamC.h"
#include "steam/steam_api.h"

// SteamAPI_RestartAppIfNecessary ensures that your executable was launched through Steam.
//
// Returns true if the current process should terminate. Steam is now re-launching your application.
//
// Returns false if no action needs to be taken. This means that your executable was started through
// the Steam client, or a steam_appid.txt file is present in your game's directory (for development).
// Your current process should continue if false is returned.
//
// NOTE: If you use the Steam DRM wrapper on your primary executable file, this check is unnecessary
// since the DRM wrapper will ensure that your application was launched properly through Steam.
bool S_CALLTYPE SteamAPI_RestartAppIfNecessary_C(uint32 unOwnAppID) {
    return SteamAPI_RestartAppIfNecessary(unOwnAppID);
}

// See "Initializing the Steamworks SDK" above for how to choose an init method.
// Returns true on success
bool S_CALLTYPE SteamAPI_Init_C(void){
    return SteamAPI_Init();
}

ISteamUserStats * SteamUserStats_C() {
    return SteamUserStats();
}

// SteamAPI_Shutdown should be called during process shutdown if possible.
void S_CALLTYPE SteamAPI_Shutdown_C(void) {
    SteamAPI_Shutdown();
}

