AddEventHandler("Help_OnGetCommands", function(p_Event)
	local l_Commands = p_Event:GetReturn() or {}
	
	l_Commands["gungame"] = {
		["description"] = "Shows gamemode details",
		["usage"] = "sw_gungame"
	}
	
	p_Event:SetReturn(l_Commands)
end)

commands:Register("gungame", function(p_PlayerId, p_Args, p_ArgsCount, p_Silent, p_Prefix)
	local l_Player = GetPlayer(p_PlayerId)
	
	if not l_Player or not l_Player:IsValid() then
		return
	end
	
	if p_Prefix ~= "sw_" then
		l_Player:SendMsg(MessageType.Chat, string.format("{yellow}%s{default} See console for output", g_Config["tag"]))
	end
	
	l_Player:SendMsg(MessageType.Console, string.format("%s\n", g_Config["tag"]))
	l_Player:SendMsg(MessageType.Console, string.format("%s Description\n", g_Config["tag"]))
	l_Player:SendMsg(MessageType.Console, string.format("%s - The Terrorists and Counter-Terrorists must kill each other to gain levels\n", g_Config["tag"]))
	l_Player:SendMsg(MessageType.Console, string.format("%s - The first player to complete all levels wins the map\n", g_Config["tag"]))
	l_Player:SendMsg(MessageType.Console, string.format("%s\n", g_Config["tag"]))
end)