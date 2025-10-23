function Gungame_CancelPlayerImmunity(p_PlayerId)
	if g_RoundCount == 0 then
		return
	end
	
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player 
		or not l_Player:IsValid() 
		or not exports["helpers"]:IsPlayerAlive(p_PlayerId) 
	then
		return
	end
	
	local l_PlayerImmunityTime = l_Player:GetVar("gungame.immunity.time")
	
	if not l_PlayerImmunityTime then
		return
	end
	
	local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
	
	l_Player:SetVar("gungame.immunity.time", nil)
	l_Player:SetVar("gungame.immunity.end", {
		["time"] = l_ServerTime,
		["type"] = IMMUNITY_CANCELLED
	})
	
	exports["helpers"]:SetPlayerRenderColor(p_PlayerId, RENDER_COLOR_DEFAULT)
end

function Gungame_DecreasePlayerLevel(p_PlayerId, p_IsKnife)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	local l_PlayerLevelId = l_Player:GetVar("gungame.level.id") or 1
	local l_PlayerLevelKills = l_Player:GetVar("gungame.level.kills") or 0
	
	local l_PlayerStatsKnifeDeaths = l_Player:GetVar("gungame.stats.knife.deaths") or 0
	local l_PlayerStatsLevelDowns = l_Player:GetVar("gungame.stats.level.downs") or 0
	local l_PlayerStatsPoints = l_Player:GetVar("gungame.stats.points") or 0
	
	l_PlayerLevelKills = g_Config["levels"][l_PlayerLevelId]["kills"] - l_PlayerLevelKills
	l_PlayerLevelId = math.max(l_PlayerLevelId - 1, 1)
	l_PlayerLevelKills = g_Config["levels"][l_PlayerLevelId]["kills"] - l_PlayerLevelKills
	
	l_Player:SetVar("gungame.hegrenade.time", nil)
	
	l_Player:SetVar("gungame.level.id", l_PlayerLevelId)
	l_Player:SetVar("gungame.level.kills", l_PlayerLevelKills > 0 and l_PlayerLevelKills or nil)
	
	l_Player:SetVar("gungame.stats.level.ups", l_PlayerStatsLevelDowns + 1)
	l_Player:SetVar("gungame.stats.points", l_PlayerStatsPoints + g_Config["points.level.down"])
	
	if p_IsKnife then
		l_Player:SetVar("gungame.stats.knife.kills", l_PlayerStatsKnifeDeaths)
	end
	
	Gungame_GivePlayerItems(p_PlayerId)
	Gungame_EmitSoundToPlayer(p_PlayerId, g_Config["level.player.sounds.down"])
end

function Gungame_EmitSoundToAll(p_Sound)
	if #p_Sound == 0 or exports["helpers"]:IsRoundOver() then
		return
	end
	
	SetTimeout(100, function()
		if exports["helpers"]:IsRoundOver() then
			return
		end
		
		exports["helpers"]:EmitSoundToAll(p_Sound, 100, 1.0)
	end)
end

function Gungame_EmitSoundToPlayer(p_PlayerId, p_Sound)
	if #p_Sound == 0 or exports["helpers"]:IsRoundOver() then
		return
	end
	
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	SetTimeout(100, function()
		if not l_Player:IsValid() or exports["helpers"]:IsRoundOver() then
			return
		end
		
		exports["helpers"]:EmitSoundToPlayer(p_PlayerId, p_Sound, 100, 1.0)
	end)
end

function Gungame_GetLeaders()
	local l_Leaders = {}
	
	for i = 0, playermanager:GetPlayerCap() - 1 do
		local l_PlayerIter = GetPlayer(i)
		
		if l_PlayerIter and l_PlayerIter:IsValid() then
			local l_PlayerIterTeam = exports["helpers"]:GetPlayerTeam(i)
			
			if l_PlayerIterTeam ~= Team.None then
				local l_PlayerIterLevelId = l_PlayerIter:GetVar("gungame.level.id") or 1
				local l_PlayerIterWinner = l_PlayerIter:GetVar("gungame.winner")
				
				local l_Index = Gungame_GetLeaderIndex(l_Leaders, l_PlayerIterWinner, l_PlayerIterLevelId)
				
				if l_Index > #l_Leaders then
					table.insert(l_Leaders, 0)
				else
					table.insert(l_Leaders, l_Index, 0)
				end
				
				l_Leaders[l_Index] = {
					["id"] = i,
					["player"] = l_PlayerIter,
					["level.id"] = l_PlayerIterLevelId,
					["winner"] = l_PlayerIterWinner
				}
			end
		end
	end
	
	return l_Leaders
end

function Gungame_GetLeaderIndex(p_Leaders, p_IsWinner, p_LevelId)
	for i = 1, #p_Leaders do
		if p_IsWinner or p_LevelId > p_Leaders[i]["level.id"] then
			return i
		end
	end
	
	return #p_Leaders + 1
end

function Gungame_GetPlayerSpawnPoint(p_PlayerId)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player 
		or not l_Player:IsValid() 
		or not exports["helpers"]:IsPlayerAlive(p_PlayerId) 
	then
		return nil
	end
	
	local l_PlayerTeam = exports["helpers"]:GetPlayerTeam(p_PlayerId)
	
	if l_PlayerTeam == Team.T then
		if #g_TeamTerroristSpawnPoints == 0 then
			return nil
		end
		
		local l_Index = math.random(1, #g_TeamTerroristSpawnPoints)
		
		return {
			["origin"] = g_TeamTerroristSpawnPoints[l_Index]["origin"],
			["rotation"] = g_TeamTerroristSpawnPoints[l_Index]["rotation"]
		}
	elseif l_PlayerTeam == Team.CT then
		if #g_TeamCTSpawnPoints == 0 then
			return nil
		end
		
		local l_Index = math.random(1, #g_TeamCTSpawnPoints)
		
		return {
			["origin"] = g_TeamCTSpawnPoints[l_Index]["origin"],
			["rotation"] = g_TeamCTSpawnPoints[l_Index]["rotation"]
		}
	end
	
	return nil
end

function Gungame_GivePlayerArmor(p_PlayerId)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player 
		or not l_Player:IsValid() 
		or not exports["helpers"]:IsPlayerAlive(p_PlayerId) 
	then
		return
	end
	
	exports["helpers"]:GivePlayerArmor(p_PlayerId, "assaultsuit")
end

function Gungame_GivePlayerItems(p_PlayerId)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player 
		or not l_Player:IsValid() 
		or not exports["helpers"]:IsPlayerAlive(p_PlayerId) 
	then
		return
	end
	
	l_Player:GetWeaponManager():RemoveWeapons()
	
	if g_RoundCount ~= 0 then
		local l_PlayerWinner = l_Player:GetVar("gungame.winner")
		
		exports["helpers"]:GivePlayerWeapon(p_PlayerId, "weapon_knife")
		
		if l_PlayerWinner then
			return
		end
		
		local l_PlayerLevelId = l_Player:GetVar("gungame.level.id") or 1
		
		if g_Config["levels"][l_PlayerLevelId]["weapon"] == "weapon_knife" then
			return
		end
		
		exports["helpers"]:GivePlayerWeapon(p_PlayerId, g_Config["levels"][l_PlayerLevelId]["weapon"])
	else
		exports["helpers"]:GivePlayerWeapon(p_PlayerId, "weapon_knife")
		
		if #g_Config["warmup.weapons"] == 0 then
			return
		end
		
		local l_Index = math.random(1, #g_Config["warmup.weapons"])
		
		exports["helpers"]:GivePlayerWeapon(p_PlayerId, g_Config["warmup.weapons"][l_Index])
	end
end

function Gungame_HandlePlayerDeath(p_PlayerId, p_AttackerId, p_Weapon)
	if g_RoundCount == 0 or exports["helpers"]:IsMatchOver() then
		return
	end
	
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	if p_PlayerId ~= p_AttackerId then
		local l_Attacker = GetPlayer(p_AttackerId)
		
		if not l_Attacker or not l_Player:IsValid() then
			return
		end
		
		if exports["helpers"]:IsItemClassnameKnife(p_Weapon) then
			Gungame_DecreasePlayerLevel(p_PlayerId, true)
			
			if exports["afk"]:IsPlayerAFK(p_PlayerId) then
				return
			end
			
			Gungame_IncreasePlayerLevel(p_AttackerId, true)
		else
			if exports["afk"]:IsPlayerAFK(p_PlayerId) then
				return
			end
			
			Gungame_IncreasePlayerKills(p_AttackerId)
		end
	else
		if exports["team"]:IsPlayerInJoinTeamQueue(p_PlayerId) 
			or exports["player"]:IsPlayerInSlapQueue(p_PlayerId) 
			or exports["player"]:IsPlayerInSlayQueue(p_PlayerId) 
		then
			return
		end
		
		Gungame_DecreasePlayerLevel(p_PlayerId)
	end
end

function Gungame_HandlePlayerWin(p_PlayerId)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	local l_PlayerStatsPoints = l_Player:GetVar("gungame.stats.points") or 0
	local l_PlayerStatsWins = l_Player:GetVar("gungame.stats.wins") or 0
	
	l_Player:SetVar("gungame.winner", true)
	
	l_Player:SetVar("gungame.stats.points", l_PlayerStatsPoints + g_Config["points.win.winner"])
	l_Player:SetVar("gungame.stats.wins", l_PlayerStatsWins + 1)
	
	exports["helpers"]:SetConVar("mp_fraglimit", 0)
	exports["helpers"]:SetConVar("mp_maxrounds", 0)
	exports["helpers"]:SetConVar("mp_timelimit", 0)
	exports["helpers"]:SetConVar("mp_winlimit", 0)
	
	exports["helpers"]:TerminateRound(math.random(RoundEndReason_t.CTsWin, RoundEndReason_t.TerroristsWin), "gungame")
end

function Gungame_HasPlayerImmunity(p_PlayerId)
	if g_RoundCount == 0 then
		return false
	end
	
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player 
		or not l_Player:IsValid() 
		or not exports["helpers"]:IsPlayerAlive(p_PlayerId) 
	then
		return false
	end
	
	local l_PlayerImmunityTime = l_Player:GetVar("gungame.immunity.time")
	
	if not l_PlayerImmunityTime then
		return false
	end
	
	local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
	
	if l_ServerTime >= l_PlayerImmunityTime then
		return false
	end
	
	return true
end

function Gungame_IncreasePlayerKills(p_PlayerId)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	local l_PlayerLevelKills = l_Player:GetVar("gungame.level.kills") or 0
	local l_PlayerLevelId = l_Player:GetVar("gungame.level.id") or 1
	
	l_PlayerLevelKills = l_PlayerLevelKills + 1
	
	if l_PlayerLevelKills == g_Config["levels"][l_PlayerLevelId]["kills"] then
		Gungame_IncreasePlayerLevel(p_PlayerId)
	else
		l_Player:SetVar("gungame.level.kills", l_PlayerLevelKills)
	end
end

function Gungame_IncreasePlayerLevel(p_PlayerId, p_IsKnife)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	local l_PlayerLevelId = l_Player:GetVar("gungame.level.id") or 1
	
	local l_PlayerStatsKnifeKills = l_Player:GetVar("gungame.stats.knife.kills") or 0
	local l_PlayerStatsLevelUps = l_Player:GetVar("gungame.stats.level.ups") or 0
	local l_PlayerStatsPoints = l_Player:GetVar("gungame.stats.points") or 0
	
	l_PlayerLevelId = l_PlayerLevelId + 1
	
	l_Player:SetVar("gungame.hegrenade.time", nil)
	l_Player:SetVar("gungame.level.kills", nil)
	
	l_Player:SetVar("gungame.stats.level.ups", l_PlayerStatsLevelUps + 1)
	l_Player:SetVar("gungame.stats.points", l_PlayerStatsPoints + g_Config["points.level.up"])
	
	if p_IsKnife then
		l_Player:SetVar("gungame.stats.knife.kills", l_PlayerStatsKnifeKills)
	end
	
	if l_PlayerLevelId > #g_Config["levels"] then
		Gungame_HandlePlayerWin(p_PlayerId)
		return
	end
	
	l_Player:SetVar("gungame.level.id", l_PlayerLevelId)
	
	Gungame_GivePlayerItems(p_PlayerId)
	Gungame_EmitSoundToPlayer(p_PlayerId, g_Config["level.player.sounds.up"])
	
	if l_PlayerLevelId ~= #g_Config["levels"] then
		return
	end
	
	local l_Leaders = Gungame_GetLeaders()
	
	if p_PlayerId == l_Leaders[1]["id"] then
		Gungame_EmitSoundToAll(g_Config["level.sounds.knife"])
	end
end

function Gungame_LoadConfig()
	config:Reload("gungame")
	
	g_Config = {}
	g_Config["tag"] = config:Fetch("gungame.tag")
	g_Config["immunity.time"] = tonumber(config:Fetch("gungame.immunity.time"))
	g_Config["level.player.sounds.up"] = config:Fetch("gungame.level.player.sounds.up")
	g_Config["level.player.sounds.down"] = config:Fetch("gungame.level.player.sounds.down")
	g_Config["level.sounds.knife"] = config:Fetch("gungame.level.sounds.knife")
	g_Config["points.level.up"] = tonumber(config:Fetch("gungame.points.level.up"))
	g_Config["points.level.down"] = tonumber(config:Fetch("gungame.points.level.down"))
	g_Config["points.win.winner"] = tonumber(config:Fetch("gungame.points.win.winner"))
	
	if type(g_Config["tag"]) ~= "string" then
		g_Config["tag"] = "[Gungame]"
	end
	
	if not g_Config["immunity.time"] or g_Config["immunity.time"] < 0 then
		g_Config["immunity.time"] = 0
	end
	
	if type(g_Config["level.player.sounds.up"]) ~= "string" then
		g_Config["level.player.sounds.up"] = ""
	end
	
	if type(g_Config["level.player.sounds.down"]) ~= "string" then
		g_Config["level.player.sounds.down"] = ""
	end
	
	if type(g_Config["level.sounds.knife"]) ~= "string" then
		g_Config["level.sounds.knife"] = ""
	end
	
	if not g_Config["points.level.up"] then
		g_Config["points.level.up"] = 0
	end
	
	if not g_Config["points.level.down"] then
		g_Config["points.level.down"] = 0
	end
	
	if not g_Config["points.win.winner"] then
		g_Config["points.win.winner"] = 0
	end
	
	g_Config["immunity.time"] = math.floor(g_Config["immunity.time"] * 1000)
	
	Gungame_LoadConfigLevels()
	Gungame_LoadConfigWarmupWeapons()
end

function Gungame_LoadConfigLevels()
	g_Config["levels"] = {}
	
	local l_Levels = config:Fetch("gungame.levels")
	
	if type(l_Levels) ~= "table" then
		l_Levels = {}
	end
	
	for i = 1, #l_Levels do
		local l_Name = l_Levels[i]["name"]
		local l_Weapon = l_Levels[i]["weapon"]
		
		if type(l_Name) ~= "string" or #l_Name == 0 then
			l_Name = nil
		end
		
		if type(l_Weapon) ~= "string" or string.sub(l_Weapon, 1, 7) ~= "weapon_" then
			l_Weapon = nil
		end
		
		if l_Name and l_Weapon then
			local l_Kills = tonumber(l_Levels[i]["kills"])
			
			if not l_Kills or l_Kills < 1 then
				l_Kills = 1
			end
			
			table.insert(g_Config["levels"], {
				["name"] = l_Name,
				["weapon"] = l_Weapon,
				["kills"] = l_Kills
			})
		end
	end
	
	table.insert(g_Config["levels"], {
		["name"] = "Knife",
		["weapon"] = "weapon_knife",
		["kills"] = 1
	})
end

function Gungame_LoadConfigWarmupWeapons()
	g_Config["warmup.weapons"] = {}
	
	local l_Weapons = config:Fetch("gungame.warmup.weapons")
	
	if type(l_Weapons) ~= "table" then
		l_Weapons = {}
	end
	
	for i = 1, #l_Weapons do
		local l_Weapon = l_Weapons[i]
		
		if type(l_Weapon) ~= "string" or string.sub(l_Weapon, 1, 7) ~= "weapon_" then
			l_Weapon = nil
		end
		
		if l_Weapon then
			table.insert(g_Config["warmup.weapons"], l_Weapon)
		end
	end
end

function Gungame_LoadPlayerDisconnectionData(p_PlayerId)
	if g_RoundCount == 0 or exports["helpers"]:IsMatchOver() then
		return
	end
	
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	local l_PlayerSteam = exports["helpers"]:GetPlayerSteam(p_PlayerId)
	
	if not g_Disconnections[l_PlayerSteam] then
		return
	end
	
	if g_Disconnections[l_PlayerSteam]["level.id"] then
		l_Player:SetVar("gungame.level.id", g_Disconnections[l_PlayerSteam]["level.id"])
	end
	
	if g_Disconnections[l_PlayerSteam]["level.kills"] then
		l_Player:SetVar("gungame.level.kills", g_Disconnections[l_PlayerSteam]["level.kills"])
	end
	
	g_Disconnections[l_PlayerSteam] = nil
end

function Gungame_LoadSpawnPoints()
	g_TeamTerroristSpawnPoints = exports["spawnpoints"]:GetMapSpawnPoints(Team.T)
	g_TeamCTSpawnPoints = exports["spawnpoints"]:GetMapSpawnPoints(Team.CT)
end

function Gungame_PrintLeaders()
	local l_Leaders = Gungame_GetLeaders()
	
	local l_Index = 1
	local l_Position = 1
	
	for i = 1, #l_Leaders do
		if l_Leaders[i]["level.id"] ~= l_Leaders[l_Index]["level.id"] then
			l_Index = i
			l_Position = l_Position + 1
		end
		
		if l_Position > 2 then
			break
		end
		
		local l_LeaderName = exports["helpers"]:GetPlayerName(l_Leaders[i]["id"])
		local l_LeaderColor = exports["helpers"]:GetPlayerChatColor(l_Leaders[i]["id"])
		
		if l_Position == 1 then
			playermanager:SendMsg(MessageType.Chat, string.format("{lime}%s{default} %s%s{default} won", g_Config["tag"], l_LeaderColor, l_LeaderName))
		else
			playermanager:SendMsg(MessageType.Chat, string.format("{lime}%s{default} %s%s{default} was {lime}#%d{default} on level {lime}(%d - %s){default}", g_Config["tag"], l_LeaderColor, l_LeaderName, l_Position, l_Leaders[i]["level.id"], g_Config["levels"][l_Leaders[i]["level.id"]]["name"]))
		end
	end
end

function Gungame_RefillPlayerAmmo(p_PlayerId)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player 
		or not l_Player:IsValid() 
		or not exports["helpers"]:IsPlayerAlive(p_PlayerId) 
	then
		return
	end
	
	local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
	local l_PlayerNextAttackTime = exports["helpers"]:GetPlayerNextAttackTime(p_PlayerId)
	
	if l_PlayerNextAttackTime + REFILL_DELAY_TIME > l_ServerTime then
		return
	end
	
	exports["helpers"]:RefillPlayerAmmo(p_PlayerId)
end

function Gungame_RefillPlayerGrenade(p_PlayerId)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player 
		or not l_Player:IsValid() 
		or not exports["helpers"]:IsPlayerAlive(p_PlayerId) 
	then
		return
	end
	
	local l_PlayerGrenadeTime = l_Player:GetVar("gungame.hegrenade.time")
	
	if not l_PlayerGrenadeTime then
		return
	end
	
	local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
	
	if l_PlayerGrenadeTime > l_ServerTime then
		return
	end
	
	exports["helpers"]:GivePlayerWeapon(p_PlayerId, "weapon_hegrenade")
	
	l_Player:SetVar("gungame.hegrenade.time", nil)
end

function Gungame_RemovePlayerImmunity(p_PlayerId)
	if g_RoundCount == 0 then
		return
	end
	
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player 
		or not l_Player:IsValid() 
		or not exports["helpers"]:IsPlayerAlive(p_PlayerId) 
	then
		return
	end
	
	local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
	
	local l_PlayerImmunityEnd = l_Player:GetVar("gungame.immunity.end")
	local l_PlayerImmunityTime = l_Player:GetVar("gungame.immunity.time")
	
	if l_PlayerImmunityTime then
		if l_PlayerImmunityTime > l_ServerTime then
			return
		end
		
		l_Player:SetVar("gungame.immunity.time", nil)
		l_Player:SetVar("gungame.immunity.end", {
			["time"] = l_ServerTime,
			["type"] = IMMUNITY_EXPIRED
		})
		
		exports["helpers"]:SetPlayerRenderColor(p_PlayerId, RENDER_COLOR_DEFAULT)
	elseif l_PlayerImmunityEnd then
		if l_PlayerImmunityEnd["time"] + 3000 > l_ServerTime then
			return
		end
		
		l_Player:SetVar("gungame.immunity.end", nil)
	end
end

function Gungame_ResetPlayerVars(p_PlayerId)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player then
		return
	end
	
	l_Player:SetVar("gungame.death.time", nil)
	l_Player:SetVar("gungame.hegrenade.time", nil)
	l_Player:SetVar("gungame.immunity.end", nil)
	l_Player:SetVar("gungame.immunity.time", nil)
	l_Player:SetVar("gungame.level.id", nil)
	l_Player:SetVar("gungame.level.kills", nil)
	l_Player:SetVar("gungame.respawn.time", nil)
	l_Player:SetVar("gungame.stats.knife.kills", nil)
	l_Player:SetVar("gungame.stats.knife.deaths", nil)
	l_Player:SetVar("gungame.stats.level.ups", nil)
	l_Player:SetVar("gungame.stats.level.downs", nil)
	l_Player:SetVar("gungame.stats.points", nil)
	l_Player:SetVar("gungame.stats.wins", nil)
	l_Player:SetVar("gungame.winner", nil)
	
	l_Player:SendMsg(MessageType.Center, "")
end

function Gungame_ResetVars()
	g_Disconnections = {}
	
	g_RoundCount = 0
	
	g_TeamCTSpawnPoints = {}
	g_TeamTerroristSpawnPoints = {}
	
	g_ThinkFunctionTime = nil
end

function Gungame_RespawnPlayer(p_PlayerId)
	if g_RoundCount == 0 then
		return
	end
	
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	local l_PlayerRespawnTime = l_Player:GetVar("gungame.respawn.time")
	
	if not l_PlayerRespawnTime then
		return
	end
	
	local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
	
	if l_PlayerRespawnTime > l_ServerTime then
		return
	end
	
	l_Player:SetVar("gungame.respawn.time", nil)
	l_Player:Respawn()
end

function Gungame_RespawnPlayerOnRequest(p_PlayerId)
	if g_RoundCount == 0 or not convar:Get("mp_deathcam_skippable") then
		return
	end
	
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	local l_PlayerRespawnTime = l_Player:GetVar("gungame.respawn.time")
	
	if not l_PlayerRespawnTime then
		return
	end
	
	local l_PlayerDeathTime = l_Player:GetVar("gungame.death.time")
	
	if not l_PlayerDeathTime then
		return
	end
	
	local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
	local l_RespawnLockTime = math.max(convar:Get("spec_freeze_time_lock"), 0)
	
	if l_PlayerDeathTime + math.floor(l_RespawnLockTime * 1000) > l_ServerTime then
		return
	end
	
	l_Player:SetVar("gungame.respawn.time", nil)
	l_Player:Respawn()
end

function Gungame_SavePlayerDisconnectionData(p_PlayerId)
	if g_RoundCount == 0 then
		return
	end
	
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player or l_Player:IsFakeClient() then
		return
	end
	
	local l_PlayerSteam = exports["helpers"]:GetPlayerSteam(p_PlayerId)
	
	local l_PlayerLevelId = l_Player:GetVar("gungame.level.id")
	local l_PlayerLevelKills = l_Player:GetVar("gungame.level.kills")
	
	if not l_PlayerLevelId and not l_PlayerLevelKills then
		return
	end
	
	g_Disconnections[l_PlayerSteam] = {
		["level.id"] = l_PlayerLevelId,
		["level.kills"] = l_PlayerLevelKills
	}
end

function Gungame_SetBotQuota(p_Delay)
	local l_Function = function()
		local l_PlayerCount = exports["helpers"]:GetTeamPlayerCount({Team.T, Team.CT}, true)
		
		if l_PlayerCount[Team.T] + l_PlayerCount[Team.CT] ~= 1 then
			exports["helpers"]:SetConVar("bot_quota", 0)
			server:Execute("bot_kick all")
			
			return
		end
		
		exports["helpers"]:SetConVar("bot_quota", BOT_QUOTA)
		
		SetTimeout(500, function()
			for i = 0, playermanager:GetPlayerCap() - 1 do
				local l_PlayerIter = GetPlayer(i)
				
				if l_PlayerIter and l_PlayerIter:IsValid() and l_PlayerIter:IsFakeClient() then
					Gungame_SetPlayerAverageLevel(i)
					
					l_PlayerIter:SwitchTeam(l_PlayerCount[Team.T] ~= 0 and Team.CT or Team.T)
					l_PlayerIter:Respawn()
				end
			end
		end)
	end
	
	if p_Delay then
		SetTimeout(p_Delay, l_Function)
	else
		l_Function()
	end
end

function Gungame_SetConVars()
	local l_Map = server:GetMap()
	
	local l_Config = exports["helpers"]:ParseGameConfig("cfg/swiftly/gungame.cfg")
	local l_MapConfig = exports["helpers"]:ParseGameConfig("cfg/swiftly/gungame/" .. l_Map .. ".cfg")
	
	for key, value in pairs(l_MapConfig) do
		l_Config[key] = value
	end
	
	l_Config["bot_join_team"] = "any"
	l_Config["bot_quota"] = nil
	l_Config["bot_quota_mode"] = "normal"
	l_Config["mp_afterroundmoney"] = 0
	l_Config["mp_autoteambalance"] = 0
	l_Config["mp_backup_round_auto"] = 0
	l_Config["mp_backup_round_file"] = ""
	l_Config["mp_backup_round_file_last"] = ""
	l_Config["mp_backup_round_file_pattern"] = ""
	l_Config["mp_buy_anywhere"] = 0
	l_Config["mp_buytime"] = 0
	l_Config["mp_ct_default_melee"] = ""
	l_Config["mp_ct_default_primary"] = ""
	l_Config["mp_ct_default_secondary"] = ""
	l_Config["mp_death_drop_breachcharge"] = 0
	l_Config["mp_death_drop_c4"] = 0
	l_Config["mp_death_drop_defuser"] = 0
	l_Config["mp_death_drop_grenade"] = 0
	l_Config["mp_death_drop_gun"] = 0
	l_Config["mp_death_drop_healthshot"] = 0
	l_Config["mp_death_drop_taser"] = 0
	l_Config["mp_default_team_winner_no_objective"] = -1
	l_Config["mp_disconnect_kills_bots"] = 0
	l_Config["mp_disconnect_kills_players"] = 1
	l_Config["mp_force_pick_time"] = 30
	l_Config["mp_free_armor"] = 0
	l_Config["mp_halftime"] = 0
	l_Config["mp_join_grace_time"] = 0
	l_Config["mp_limitteams"] = 0
	l_Config["mp_maxmoney"] = 0
	l_Config["mp_playercashawards"] = 0
	l_Config["mp_respawn_immunitytime"] = 0
	l_Config["mp_respawn_on_death_ct"] = 0
	l_Config["mp_respawn_on_death_t"] = 0
	l_Config["mp_solid_teammates"] = 0
	l_Config["mp_startmoney"] = 0
	l_Config["mp_t_default_melee"] = ""
	l_Config["mp_t_default_primary"] = ""
	l_Config["mp_t_default_secondary"] = ""
	l_Config["mp_teamcashawards"] = 0
	
	for l_Key, l_Value in pairs(l_Config) do
		exports["helpers"]:SetConVar(l_Key, l_Value)
	end
	
	Gungame_SetBotQuota()
end

function Gungame_SetPlayerAverageLevel(p_PlayerId)
	if g_RoundCount == 0 then
		return
	end
	
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	local l_Levels = 0
	local l_PlayerCount = 1
	
	for i = 0, playermanager:GetPlayerCap() - 1 do
		local l_PlayerIter = GetPlayer(i)
		
		if l_PlayerIter and l_PlayerIter:IsValid() and not l_PlayerIter:IsFakeClient() then
			local l_PlayerIterLevelId = l_PlayerIter:GetVar("gungame.level.id") or 1
			
			l_Levels = l_Levels + l_PlayerIterLevelId
			l_PlayerCount = l_PlayerCount + 1
		end
	end
	
	l_Player:SetVar("gungame.level.id", math.max(math.floor(l_Levels / l_PlayerCount), 1))
end

function Gungame_SetPlayerImmunity(p_PlayerId)
	if g_Config["immunity.time"] == 0 or g_RoundCount == 0 then
		return
	end
	
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player 
		or not l_Player:IsValid() 
		or not exports["helpers"]:IsPlayerAlive(p_PlayerId) 
	then
		return
	end
	
	local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
	
	l_Player:SetVar("gungame.immunity.time", l_ServerTime + g_Config["immunity.time"])
	
	exports["helpers"]:SetPlayerRenderColor(p_PlayerId, RENDER_COLOR_IMMUNITY)
end

function Gungame_SetPlayerSpawnPoint(p_PlayerId)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player 
		or not l_Player:IsValid() 
		or not exports["helpers"]:IsPlayerAlive(p_PlayerId) 
	then
		return
	end
	
	local l_SpawnPoint = Gungame_GetPlayerSpawnPoint(p_PlayerId)
	
	if not l_SpawnPoint then
		return
	end
	
	exports["helpers"]:TeleportPlayer(p_PlayerId, l_SpawnPoint["origin"], l_SpawnPoint["rotation"])
end

function Gungame_Think()
	if exports["helpers"]:IsMatchOver() then
		return
	end
	
	local l_ServerTime = math.floor(server:GetCurrentTime() * 1000)
	
	local l_LeaderPrimary = nil
	local l_LeaderSecondary = nil
	
	local l_Players = {}
	
	for i = 0, playermanager:GetPlayerCap() - 1 do
		local l_PlayerIter = GetPlayer(i)
		
		if l_PlayerIter and l_PlayerIter:IsValid() then
			if g_RoundCount ~= 0 then
				local l_PlayerIterTeam = exports["helpers"]:GetPlayerTeam(i)
				
				if l_PlayerIterTeam ~= Team.None then
					local l_PlayerIterLevelId = l_PlayerIter:GetVar("gungame.level.id") or 1
					
					if not l_LeaderPrimary then
						l_LeaderPrimary = {
							["id"] = i,
							["player"] = l_PlayerIter,
							["level.id"] = l_PlayerIterLevelId,
							["count"] = 1
						}
					elseif l_PlayerIterLevelId > l_LeaderPrimary["level.id"] then
						l_LeaderSecondary = l_LeaderPrimary
						
						l_LeaderPrimary = {
							["id"] = i,
							["player"] = l_PlayerIter,
							["level.id"] = l_PlayerIterLevelId,
							["count"] = 1
						}
					elseif l_PlayerIterLevelId == l_LeaderPrimary["level.id"] then
						l_LeaderPrimary["id"] = nil
						l_LeaderPrimary["player"] = nil
						l_LeaderPrimary["count"] = l_LeaderPrimary["count"] + 1
					elseif not l_LeaderSecondary or l_PlayerIterLevelId > l_LeaderSecondary["level.id"] then
						l_LeaderSecondary = {
							["id"] = i,
							["player"] = l_PlayerIter,
							["level.id"] = l_PlayerIterLevelId,
							["count"] = 1
						}
					elseif l_PlayerIterLevelId == l_LeaderSecondary["level.id"] then
						l_LeaderSecondary["id"] = nil
						l_LeaderSecondary["player"] = nil
						l_LeaderSecondary["count"] = l_LeaderSecondary["count"] + 1
					end
				end
			end
			
			l_Players[i] = l_PlayerIter
		end
	end
	
	if g_RoundCount ~= 0 then
		if l_LeaderPrimary and l_LeaderPrimary["count"] == 1 then
			l_LeaderPrimary["name"] = exports["helpers"]:GetPlayerName(l_LeaderPrimary["id"])
			l_LeaderPrimary["color"] = exports["helpers"]:GetPlayerHintColor(l_LeaderPrimary["id"])
			
			l_LeaderPrimary["name"] = string.sub(l_LeaderPrimary["name"], 1, HINT_NAME_LENGTH)
			l_LeaderPrimary["name"] = exports["helpers"]:EncodeString(l_LeaderPrimary["name"])
		end
		
		if l_LeaderSecondary and l_LeaderSecondary["count"] == 1 then
			l_LeaderSecondary["name"] = exports["helpers"]:GetPlayerName(l_LeaderSecondary["id"])
			l_LeaderSecondary["color"] = exports["helpers"]:GetPlayerHintColor(l_LeaderSecondary["id"])
			
			l_LeaderSecondary["name"] = string.sub(l_LeaderSecondary["name"], 1, HINT_NAME_LENGTH)
			l_LeaderSecondary["name"] = exports["helpers"]:EncodeString(l_LeaderSecondary["name"])
		end
	end
	
	for l_PlayerIterId, l_PlayerIter in pairs(l_Players) do
		if not g_ThinkFunctionTime or l_ServerTime >= g_ThinkFunctionTime + THINK_FUNCTION_INTERVAL then
			Gungame_RefillPlayerAmmo(l_PlayerIterId)
			Gungame_RefillPlayerGrenade(l_PlayerIterId)
			
			Gungame_RemovePlayerImmunity(l_PlayerIterId)
			Gungame_RespawnPlayer(l_PlayerIterId, false)
		end
		
		if g_RoundCount ~= 0 then
			local l_PlayerIterTeam = exports["helpers"]:GetPlayerTeam(l_PlayerIterId)
			
			if l_PlayerIterTeam ~= Team.None then
				local l_HintTextTop = ""
				local l_HintTextBottom = ""
				
				if l_LeaderPrimary then
					if #l_HintTextTop ~= 0 then
						l_HintTextTop = l_HintTextTop .. "<br>"
					end
					
					if l_LeaderPrimary["count"] > 1 then
						l_HintTextTop = l_HintTextTop 
							.. string.format("1. <font color='#FFEA50'>%s players</font> <font color='#A5FF50'>(%d - %s)</font>", l_LeaderPrimary["count"], l_LeaderPrimary["level.id"], g_Config["levels"][l_LeaderPrimary["level.id"]]["name"])
					else
						l_HintTextTop = l_HintTextTop 
							.. string.format("1. <font color='%s'>%s</font> <font color='#A5FF50'>(%d - %s)</font>", l_LeaderPrimary["color"], l_LeaderPrimary["name"], l_LeaderPrimary["level.id"], g_Config["levels"][l_LeaderPrimary["level.id"]]["name"])
					end
				end
				
				if l_LeaderSecondary then
					if #l_HintTextTop ~= 0 then
						l_HintTextTop = l_HintTextTop .. "<br>"
					end
					
					if l_LeaderSecondary["count"] > 1 then
						l_HintTextTop = l_HintTextTop 
							.. string.format("2. <font color='#FFEA50'>%s players</font> <font color='#FF4500'>(%d - %s)</font>", l_LeaderSecondary["count"], l_LeaderSecondary["level.id"], g_Config["levels"][l_LeaderSecondary["level.id"]]["name"])
					else
						l_HintTextTop = l_HintTextTop 
							.. string.format("2. <font color='%s'>%s</font> <font color='#FF4500'>(%d - %s)</font>", l_LeaderSecondary["color"], l_LeaderSecondary["name"], l_LeaderSecondary["level.id"], g_Config["levels"][l_LeaderSecondary["level.id"]]["name"])
					end
				end
				
				if l_PlayerIterTeam ~= Team.Spectator then
					local l_PlayerIterIsAlive = exports["helpers"]:IsPlayerAlive(l_PlayerIterId)
					local l_PlayerIterLevelId = l_PlayerIter:GetVar("gungame.level.id") or 1
					local l_PlayerIterLevelKills = l_PlayerIter:GetVar("gungame.level.kills") or 0
					
					if l_PlayerIterIsAlive then
						local l_PlayerIterImmunityEnd = l_PlayerIter:GetVar("gungame.immunity.end")
						local l_PlayerIterImmunityTime = l_PlayerIter:GetVar("gungame.immunity.time")
						
						if l_PlayerIterImmunityTime then
							if #l_HintTextBottom ~= 0 then
								l_HintTextBottom = l_HintTextBottom .. "<br>"
							end
							
							l_HintTextBottom = l_HintTextBottom 
								.. string.format("Immunity <font color='#FFA500'>%0.1fs</font>", (l_PlayerIterImmunityTime - l_ServerTime) / 1000)
						elseif l_PlayerIterImmunityEnd then
							if #l_HintTextBottom ~= 0 then
								l_HintTextBottom = l_HintTextBottom .. "<br>"
							end
							
							l_HintTextBottom = l_HintTextBottom 
								.. string.format("Immunity <font color='#FF4500'>%s</font>", l_PlayerIterImmunityEnd.type == IMMUNITY_EXPIRED and "EXPIRED" or "CANCELLED")
						end
					end
					
					if #l_HintTextBottom ~= 0 then
						l_HintTextBottom = l_HintTextBottom .. "<br>"
					end
					
					l_HintTextBottom = l_HintTextBottom 
						.. string.format("Level <font color='%s'>%d - %s</font> <font color='gray'>[#%d]</font>", l_LeaderPrimary and l_PlayerIterLevelId == l_LeaderPrimary["level.id"] and "#A5FF50" or "#FF4500", l_PlayerIterLevelId, g_Config["levels"][l_PlayerIterLevelId]["name"], #g_Config["levels"])
					
					l_HintTextBottom = l_HintTextBottom .. "<br>"
					
					l_HintTextBottom = l_HintTextBottom 
						.. string.format("Kills <font color='#FFEA50'>%d / %d</font>", l_PlayerIterLevelKills, g_Config["levels"][l_PlayerIterLevelId]["kills"])
				end
				
				if #l_HintTextTop ~= 0 and #l_HintTextBottom ~= 0 then
					l_PlayerIter:SendMsg(MessageType.Center, string.format("%s<br><font color='gray'> -------------------------------- </font><br>%s", l_HintTextTop, l_HintTextBottom))
				elseif #l_HintTextTop ~= 0 then
					l_PlayerIter:SendMsg(MessageType.Center, l_HintTextTop)
				elseif #l_HintTextBottom ~= 0 then
					l_PlayerIter:SendMsg(MessageType.Center, l_HintTextBottom)
				end
			end
		end
	end
	
	if not g_ThinkFunctionTime or l_ServerTime >= g_ThinkFunctionTime + THINK_FUNCTION_INTERVAL then
		g_ThinkFunctionTime = l_ServerTime
	end
end