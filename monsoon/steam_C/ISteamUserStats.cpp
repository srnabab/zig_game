#include "steam_C/steamC.h"
#include "steam/steam_api.h"

bool SetAchievement(ISteamUserStats * self, const char *pchName)
{
    return self->SetAchievement(pchName);
}

bool ResetAllStats(ISteamUserStats * self, bool bAchievementsToo)
{
    return self->ResetAllStats(bAchievementsToo);
}

bool StoreStats(ISteamUserStats * self)
{
    return self->StoreStats();
}
