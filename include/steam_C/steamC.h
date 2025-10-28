#ifndef STEAMC_H
#define STEAMC_H 1

#include <stdbool.h>
#include <stdint.h>

// test
typedef enum EAchievements
{
	ACH_WIN_ONE_GAME = 0,
	ACH_WIN_100_GAMES = 1,
	ACH_HEAVY_FIRE = 2,
	ACH_TRAVEL_FAR_ACCUM = 3,
	ACH_TRAVEL_FAR_SINGLE = 4,
}EAchievements;

typedef struct Achievement_t
{
	EAchievements m_eAchievementID;
	const char *m_pchAchievementID;
	const char * m_rgchName;
	const char *m_rgchDescription;
	bool m_bAchieved;
	int m_iIconImage;
} Achievement_t; 

#define _ACH_ID( id, name ) { id, #id, name, "", 0, 0 }

typedef struct ISteamUserStats ISteamUserStats;


#define S_CALLTYPE_ __cdecl 

#ifdef __cplusplus
extern "C" {
#endif

#define k_uAppIdInvalid_C 0U
extern bool S_CALLTYPE_ SteamAPI_RestartAppIfNecessary_C(uint32_t unOwnAppID);
extern bool S_CALLTYPE_ SteamAPI_Init_C(void);
extern void S_CALLTYPE_ SteamAPI_Shutdown_C(void);
extern ISteamUserStats* SteamUserStats_C(void);

extern bool SetAchievement(ISteamUserStats * self, const char *pchName);
extern bool ResetAllStats(ISteamUserStats * self, bool bAchievementsToo);
extern bool StoreStats(ISteamUserStats * self);

#ifdef __cplusplus
}
#endif

#endif
