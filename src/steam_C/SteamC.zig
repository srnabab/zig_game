pub const steamInner = @cImport(@cInclude("steam_C/steamC.h"));

const tracy = @import("tracy");

pub var g_rgAchievements = [_]steamInner.Achievement_t{
    steamInner.Achievement_t{ .m_eAchievementID = steamInner.ACH_WIN_ONE_GAME, .m_pchAchievementID = "ACH_WIN_ONE_GAME", .m_rgchName = "Winner", .m_rgchDescription = "", .m_bAchieved = false, .m_iIconImage = 0 },
    steamInner.Achievement_t{ .m_eAchievementID = steamInner.ACH_WIN_100_GAMES, .m_pchAchievementID = "ACH_WIN_100_GAMES", .m_rgchName = "Champion", .m_rgchDescription = "", .m_bAchieved = false, .m_iIconImage = 0 },
    steamInner.Achievement_t{ .m_eAchievementID = steamInner.ACH_TRAVEL_FAR_ACCUM, .m_pchAchievementID = "ACH_TRAVEL_FAR_ACCUM", .m_rgchName = "", .m_rgchDescription = "", .m_bAchieved = false, .m_iIconImage = 0 },
};

pub const Achievement = struct {
    const Self = @This();

    pUserStats: *steamInner.ISteamUserStats,
    StoreStats: bool,

    pub fn UnlockAchievement(self: *Self, achievement: *steamInner.Achievement_t) void {
        const zone = tracy.initZone(@src(), .{ .name = "unlock achievement" });
        defer zone.deinit();

        achievement.m_bAchieved = true;

        // the icon may change once it's unlocked
        achievement.m_iIconImage = 0;

        // mark it down
        _ = steamInner.SetAchievement(self.pUserStats, achievement.m_pchAchievementID);

        // Store stats end of frame
        self.StoreStats = true;
    }

    pub fn ResetAllAchievements(self: *Self) void {
        _ = steamInner.ResetAllStats(self.pUserStats, true);
    }

    pub fn StoreStatsIfNecessary(self: *Self) void {
        if (self.StoreStats) {
            // already set any achievements in UnlockAchievement

            // set stats
            const bSuccess = steamInner.StoreStats(self.pUserStats);
            // If this failed, we never sent anything to the server, try
            // again later.
            self.StoreStats = !bSuccess;
        }
    }
};
