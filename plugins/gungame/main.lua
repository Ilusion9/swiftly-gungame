AddEventHandler("OnPluginStart", function(p_Event)
	local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
	
	g_PluginIsLoading = true
	g_PluginIsLoadingLate = l_ServerTime > 0
	
	Gungame_ResetVars()
	Gungame_LoadConfig()
end)

AddEventHandler("OnAllPluginsLoaded", function(p_Event)
	if g_PluginIsLoadingLate then
		server:Execute("mp_restartgame 3")
		
		for i = 0, playermanager:GetPlayerCap() - 1 do
			Gungame_ResetPlayerVars(i)
		end
		
		Gungame_SetConVars()
	end
	
	if g_PluginIsLoading then
		if not g_ThinkTimer then
			Gungame_Think()
			g_ThinkTimer = SetTimer(THINK_INTERVAL, Gungame_Think)
		end
	end
	
	g_PluginIsLoading = nil
	g_PluginIsLoadingLate = nil
end)

AddEventHandler("OnMapLoad", function(p_Event, p_Map)
	Gungame_ResetVars()
	Gungame_LoadConfig()
	
	if not g_PluginIsLoading then
		if not g_ThinkTimer then
			Gungame_Think()
			g_ThinkTimer = SetTimer(THINK_INTERVAL, Gungame_Think)
		end
	end
	
	SetTimeout(100, function()
		Gungame_SetConVars()
	end)
end)

AddEventHandler("OnMapUnload", function(p_Event, p_Map)
	if g_ThinkTimer then
		StopTimer(g_ThinkTimer)
		g_ThinkTimer = nil
	end
end)

AddEventHandler("OnPostCsIntermission", function(p_Event)
	Gungame_PrintLeaders()
	
	for i = 0, playermanager:GetPlayerCap() - 1 do
		local l_PlayerIter = GetPlayer(i)
		
		if l_PlayerIter and l_PlayerIter:IsValid() then
			l_PlayerIter:SetVar("gungame.level.id", nil)
			l_PlayerIter:SetVar("gungame.level.kills", nil)
			l_PlayerIter:SetVar("gungame.winner", nil)
			
			l_PlayerIter:SendMsg(MessageType.Center, "")
		end
	end
end)

AddEventHandler("OnPostRoundPrestart", function(p_Event)
	Gungame_LoadSpawnPoints()
	
	if exports["helpers"]:IsWarmupPeriod() then
		return
	end
	
	g_RoundCount = g_RoundCount + 1
	
	for i = 0, playermanager:GetPlayerCap() - 1 do
		local l_PlayerIter = GetPlayer(i)
		
		if l_PlayerIter and l_PlayerIter:IsValid() then
			l_PlayerIter:SetVar("gungame.respawn.time", nil)
			
			l_PlayerIter:SendMsg(MessageType.Center, "")
		end
	end
end)

AddEventHandler("OnPostRoundEnd", function(p_Event)
	exports["helpers"]:SetTeamScore(Team.T, 0)
	exports["helpers"]:SetTeamScore(Team.CT, 0)
end)

AddEventHandler("OnPostRoundAnnounceWarmup", function(p_Event)
	g_RoundCount = 0
	
	for i = 0, playermanager:GetPlayerCap() - 1 do
		local l_PlayerIter = GetPlayer(i)
		
		if l_PlayerIter and l_PlayerIter:IsValid() then
			l_PlayerIter:SendMsg(MessageType.Center, "")
		end
	end
end)

AddEventHandler("OnPostRoundMvp", function(p_Event)
	local l_PlayerId = p_Event:GetInt("userid")
	
	exports["helpers"]:SetPlayerMVPs(l_PlayerId, 0)
end)

AddEventHandler("Helpers_OnTerminateRound", function(p_Event, p_Reason, p_Identifier)
	if p_Identifier == "gungame" or p_Identifier == "map" then
		return EventResult.Continue
	end
	
	local l_PlayerCount = exports["helpers"]:GetPlayerCount(true)
	
	if l_PlayerCount == 0 then
		return EventResult.Continue
	end
	
	exports["helpers"]:SetTeamScore(Team.T, 0)
	exports["helpers"]:SetTeamScore(Team.CT, 0)
	
	return EventResult.Stop
end)

AddEventHandler("OnEntitySpawned", function(p_Event, p_EntityPtr)
	local l_Entity = CBaseEntity(p_EntityPtr)
	
	if not l_Entity or not l_Entity:IsValid() then
		return
	end
	
	local l_EntityClassname = l_Entity:GetClassname()
	
	if l_EntityClassname == "chicken" 
		or l_EntityClassname == "func_bomb_target" 
		or l_EntityClassname == "func_hostage_rescue" 
		or l_EntityClassname == "point_servercommand" 
	then
		l_Entity:Despawn()
		return
	end
	
	if string.sub(l_EntityClassname, 1, 7) == "weapon_" then
		if #l_Entity.UniqueHammerID ~= 0 then
			l_Entity:Despawn()
		end
	end
end)

AddEventHandler("OnPostItemEquip", function(p_Event)
	local l_Item = p_Event:GetInt("defindex")
	
	if l_Item ~= ITEM_HEGRENADE then
		return
	end
	
	local l_PlayerId = p_Event:GetInt("userid")
	local l_Player = GetPlayer(l_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	l_Player:SetVar("gungame.hegrenade.time", nil)
end)

AddEventHandler("OnPostWeaponFire", function(p_Event)
	local l_PlayerId = p_Event:GetInt("userid")
	
	Gungame_CancelPlayerImmunity(l_PlayerId)
end)

AddEventHandler("OnPostHegrenadeDetonate", function(p_Event)
	local l_PlayerId = p_Event:GetInt("userid")
	local l_Player = GetPlayer(l_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
	
	l_Player:SetVar("gungame.hegrenade.time", l_ServerTime + 100)
end)

AddEventHandler("OnClientKeyStateChange", function(p_Event, p_PlayerId, p_Key, p_IsPressed)
	if not p_IsPressed or p_Key ~= "space" then
		return
	end
	
	Gungame_RespawnPlayerOnRequest(p_PlayerId)
end)

AddEventHandler("OnPlayerDamage", function(p_Event, p_PlayerId, p_AttackerId, p_DamageInfoPtr, p_InflictorPtr, p_AbilityPtr)
	if exports["helpers"]:IsPlayerInSlayQueue(p_PlayerId) then
		return EventResult.Continue
	end
	
	if Gungame_HasPlayerImmunity(p_PlayerId) then
		p_Event:SetReturn(false)
		return EventResult.Handled
	end
	
	return EventResult.Continue
end)

AddEventHandler("OnPostPlayerConnectFull", function(p_Event)
	local l_PlayerId = p_Event:GetInt("userid")
	
	Gungame_SetPlayerAverageLevel(l_PlayerId)
	Gungame_LoadPlayerDisconnectionData(l_PlayerId)
end)

AddEventHandler("OnPlayerDisconnect", function(p_Event)
	local l_PlayerId = p_Event:GetInt("userid")
	
	Gungame_SavePlayerDisconnectionData(l_PlayerId)
	Gungame_SetBotQuota(100)
end)

AddEventHandler("OnPostPlayerSpawn", function(p_Event)
	local l_PlayerId = p_Event:GetInt("userid")
	local l_Player = GetPlayer(l_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	l_Player:SetVar("gungame.hegrenade.time", nil)
	
	if g_RoundCount ~= 0 then
		l_Player:SetVar("gungame.death.time", nil)
		l_Player:SetVar("gungame.immunity.end", nil)
		l_Player:SetVar("gungame.immunity.time", nil)
		l_Player:SetVar("gungame.respawn.time", nil)
		
		l_Player:SendMsg(MessageType.Center, "")
		
		exports["helpers"]:SetPlayerRenderColor(l_PlayerId, RENDER_COLOR_DEFAULT)
	end
	
	Gungame_SetPlayerSpawnPoint(l_PlayerId)
	
	SetTimeout(200, function()
		if not l_Player:IsValid() then
			return
		end
		
		Gungame_GivePlayerArmor(l_PlayerId)
		Gungame_GivePlayerItems(l_PlayerId)
		
		Gungame_SetPlayerImmunity(l_PlayerId)
	end)
end)

AddEventHandler("OnPostPlayerDeath", function(p_Event)
	local l_PlayerId = p_Event:GetInt("userid")
	local l_Player = GetPlayer(l_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	local l_AttackerId = p_Event:GetInt("attacker")
	local l_Weapon = p_Event:GetString("weapon")
	
	l_Player:SetVar("gungame.hegrenade.time", nil)
	
	if g_RoundCount ~= 0 then
		local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
		local l_RespawnTime = exports["helpers"]:GetRespawnTime()
		
		l_Player:SetVar("gungame.death.time", l_ServerTime)
		l_Player:SetVar("gungame.respawn.time", l_ServerTime + l_RespawnTime)
		
		l_Player:SendMsg(MessageType.Center, "")
		
		exports["helpers"]:SetPlayerRenderColor(l_PlayerId, RENDER_COLOR_DEFAULT)
	end
	
	Gungame_HandlePlayerDeath(l_PlayerId, l_AttackerId, "weapon_" .. l_Weapon)
end)

AddEventHandler("OnPostPlayerTeam", function(p_Event)
	if p_Event:GetBool("disconnect") then
		return
	end
	
	local l_PlayerId = p_Event:GetInt("userid")
	local l_Player = GetPlayer(l_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	if g_RoundCount ~= 0 then
		local l_Team = p_Event:GetInt("team")
		
		l_Player:SetVar("gungame.death.time", nil)
		l_Player:SetVar("gungame.respawn.time", nil)
		
		if l_Team > Team.Spectator then
			local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
			
			l_Player:SetVar("gungame.respawn.time", l_ServerTime + 100)
		end
		
		l_Player:SendMsg(MessageType.Center, "")
	end
	
	if l_Player:IsFakeClient() then
		return
	end
	
	Gungame_SetBotQuota(100)
end)

AddEventHandler("Stats_OnPlayerGetStats", function(p_Event, p_PlayerId, p_Stats)
	local l_Wins = p_Stats["custom1"]
	local l_LevelUps = p_Stats["custom2"]
	local l_LevelDowns = p_Stats["custom3"]
	local l_KnifeKills = p_Stats["custom4"]
	local l_KnifeDeaths = p_Stats["custom5"]
	
	p_Event:SetReturn({
		string.format("Wins: %d", l_Wins),
		string.format("Levels: %d / %d", l_LevelUps, l_LevelDowns),
		string.format("Knives: %d / %d", l_KnifeKills, l_KnifeDeaths)
	})
end)

AddEventHandler("Stats_OnPlayerGetTop", function(p_Event, p_PlayerId, p_Stats)
	local l_Header = {
		"Wins",
		"Levels",
		"Knives"
	}
	
	local l_Body = {}
	
	for i = 1, #p_Stats do
		local l_Wins = p_Stats[i]["custom1"]
		local l_LevelUps = p_Stats[i]["custom2"]
		local l_LevelDowns = p_Stats[i]["custom3"]
		local l_KnifeKills = p_Stats[i]["custom4"]
		local l_KnifeDeaths = p_Stats[i]["custom5"]
		
		table.insert(l_Body, {
			string.format("%d", l_Wins),
			string.format("%d / %d", l_LevelUps, l_LevelDowns),
			string.format("%d / %d", l_KnifeKills, l_KnifeDeaths)
		})
	end
	
	p_Event:SetReturn({
		["header"] = l_Header,
		["body"] = l_Body
	})
end)

AddEventHandler("Stats_OnPlayerSetStats", function(p_Event, p_PlayerId)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player then
		return
	end
	
	local l_PlayerStatsKnifeKills = l_Player:GetVar("gungame.stats.knife.kills") or 0
	local l_PlayerStatsKnifeDeaths = l_Player:GetVar("gungame.stats.knife.deaths") or 0
	local l_PlayerStatsLevelUps = l_Player:GetVar("gungame.stats.level.ups") or 0
	local l_PlayerStatsLevelDowns = l_Player:GetVar("gungame.stats.level.downs") or 0
	local l_PlayerStatsPoints = l_Player:GetVar("gungame.stats.points") or 0
	local l_PlayerStatsWins = l_Player:GetVar("gungame.stats.wins") or 0
	
	local l_Stats = {
		["points"] = l_PlayerStatsPoints,
		["custom1"] = l_PlayerStatsWins,
		["custom2"] = l_PlayerStatsLevelUps,
		["custom3"] = l_PlayerStatsLevelDowns,
		["custom4"] = l_PlayerStatsKnifeKills,
		["custom5"] = l_PlayerStatsKnifeDeaths
	}
	
	l_Player:SetVar("gungame.stats.knife.kills", nil)
	l_Player:SetVar("gungame.stats.knife.deaths", nil)
	l_Player:SetVar("gungame.stats.level.ups", nil)
	l_Player:SetVar("gungame.stats.level.downs", nil)
	l_Player:SetVar("gungame.stats.points", nil)
	l_Player:SetVar("gungame.stats.wins", nil)
	
	p_Event:SetReturn(l_Stats)
end)

AddEventHandler("Team_OnPlayerJoinTeam", function(p_Event, p_PlayerId, p_Team, p_Force)
	if p_Force or p_Team == Team.Spectator then
		return EventResult.Continue
	end
	
	local l_PlayerCount = exports["helpers"]:GetTeamPlayerCount({Team.T, Team.CT}, true)
	
	if p_Team == Team.T then
		if l_PlayerCount[Team.T] > l_PlayerCount[Team.CT] then
			return EventResult.Handled
		end
	elseif p_Team == Team.CT then
		if l_PlayerCount[Team.CT] > l_PlayerCount[Team.T] then
			return EventResult.Handled
		end
	end
	
	return EventResult.Continue
end)