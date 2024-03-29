
local ModConfigLoaded, ModConfig = pcall(require, "scripts.modconfig")
local CoopName = "Co-op plus"
local CoopMod = RegisterMod(CoopName, 1)
local CoopGame = Game()
local CoopFont = Font()
local CoopVersion = "1.15"
local CoopInit = false
local CoopStart = false
local CoopMirrorRoom = false
local CoopPlayers = {
	Max = 4,
	Character = { },
	Name = { },
}
local CoopColors = {
	{name = "Red", color = Color(1.0, 0.4, 0.4)},
	{name = "Blue", color = Color(0.0, 0.4, 1.0)},
	{name = "Green", color = Color(0.0, 0.95, 0.1)},
	{name = "Yellow", color = Color(0.89, 0.8, 0.22)},
	{name = "White", color = Color(0.9, 0.9, 0.9)},
	{name = "Black", color = Color(0.1, 0.1, 0.1)},
	{name = "Purple", color = Color(0.5, 0.0, 0.5)},
	{name = "Aqua", color = Color(0.0, 0.9, 0.9)},
	{name = "Orange", color = Color(1.0, 0.64, 0.0)},
}
local CoopSettings = {
	["ShowColor"] = true,
	["ShowName"] = true,
	["UseButton"] = false,
	["TearColor"] = true,
	["GhostShow"] = true,
	["GhostFly"] = true,
	["NameAlpha"] = 3,
}

for i = 1, CoopPlayers.Max do
	CoopSettings["PlayerColor" .. i] = i
end

local function IsButtonPressed()
	for i = 1, CoopGame:GetNumPlayers() do
		local player = CoopGame:GetPlayer(i - 1)
		
		if Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex) then
			return true
		end
	end
	
	return false
end

local function GetPlayers()
	local count = 0
	
	for i = 1, CoopGame:GetNumPlayers() do
		local player = CoopGame:GetPlayer(i - 1)
		
		if player.Index == player:GetMainTwin().Index then
			count = count + 1
		end
	end
	
	return count
end

local function GetAlivePlayerPosition()
	for i = 1, CoopGame:GetNumPlayers() do
		local player = CoopGame:GetPlayer(i - 1)
		
		if not player:IsCoopGhost() then
			return player.Position
		end
	end
	
	return Vector.Zero
end

local function GetRoomCenter()
	local room = CoopGame:GetRoom()
	local shape = room:GetRoomShape()
	
	if shape == RoomShape.ROOMSHAPE_1x1 or shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IV then
		return Vector(320.0, 280.0)
	elseif shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV then
		return Vector(320.0, 420.0)
	elseif shape == RoomShape.ROOMSHAPE_2x1 or shape == RoomShape.ROOMSHAPE_IIH then
		return Vector(580.0, 280.0)
	elseif shape == RoomShape.ROOMSHAPE_2x2 or shape == RoomShape.ROOMSHAPE_LTL or shape == RoomShape.ROOMSHAPE_LTR or shape == RoomShape.ROOMSHAPE_LBL or shape == RoomShape.ROOMSHAPE_LBR then
		return Vector(580.0, 420.0)
	end
	
	return room:GetCenterPos()
end

local function GetScreenSize()
	local room = CoopGame:GetRoom()
	local pos = room:WorldToScreenPosition(Vector.Zero) - room:GetRenderScrollOffset() - CoopGame.ScreenShakeOffset
	
	local rx = pos.X + 60 * 26 / 40
	local ry = pos.Y + 140 * (26 / 40)
	
	return Vector(rx*2 + 13*26, ry*2 + 7*26)
end

local function GetEmptyPlayerSlot()
	local index = 0
	
	::search::
	index = index + 1
	for i = 1, CoopGame:GetNumPlayers() do
		local player = CoopGame:GetPlayer(i - 1)
		
		if player:GetData()["CoopIndex"] == index then
			goto search
		end
	end
	
	return index
end

local function UpdatePlayersColor()
	for i = 1, CoopPlayers.Max do
		local colorId = CoopSettings["PlayerColor" .. i]
		local colorValue = CoopColors[colorId].color
		
		CoopPlayers.Character[i] = colorValue
		CoopPlayers.Name[i] = KColor(colorValue.R, colorValue.G, colorValue.B, CoopSettings["NameAlpha"] / 10)
	end
end

local function UpdatePlayersEvaluate()
	for i = 1, CoopGame:GetNumPlayers() do
		local player = CoopGame:GetPlayer(i - 1)
		
		player:AddCacheFlags(CacheFlag.CACHE_FLYING)
		player:AddCacheFlags(CacheFlag.CACHE_TEARCOLOR)
		player:EvaluateItems()
	end
end

local function OnModInit()
	UpdatePlayersColor()
	UpdatePlayersEvaluate()
	
	if not CoopInit then
		CoopFont:Load("font/pftempestasevencondensed.fnt")
		print("Mod " .. CoopName .. " v" .. CoopVersion .. " loaded!")
		
		CoopInit = true
	end
	
	CoopStart = false
end

function CoopMod:OnGameRender()
	if ModConfigLoaded and ModConfig.IsVisible then
		return false -- open mod config menu
	end
	
	if CoopGame:IsPaused() then
		return false -- game in paused
	end
	
	if not CoopStart then
		if GetPlayers() < 2 then
			return false -- not enough players
		end
		
		CoopStart = true
	end
	
	local showColor = true
	
	if CoopSettings["UseButton"] and not IsButtonPressed() then
		showColor = false
	end
	
	for i = 1, CoopGame:GetNumPlayers() do
		local player = CoopGame:GetPlayer(i - 1)
		
		if player:GetData()["CoopIndex"] == nil then
			local twin = player:GetMainTwin():GetData()["CoopIndex"]
			
			if twin ~= nil then
				player:GetData()["CoopIndex"] = twin
			else
				player:GetData()["CoopIndex"] = GetEmptyPlayerSlot()
			end
			
			player:AddCacheFlags(CacheFlag.CACHE_FLYING)
			player:AddCacheFlags(CacheFlag.CACHE_TEARCOLOR)
			player:EvaluateItems()
		end
		
		if player:IsCoopGhost() and not CoopSettings["GhostShow"] then
			if CoopGame:IsGreedMode() then
				player.Position = GetAlivePlayerPosition()
			else
				player.Position = GetRoomCenter()
			end
			
			player.ControlsCooldown = 1000
			
			if player.Visible then
				player.ControlsEnabled = false
				player.Visible = false
			end
		end
		
		if not player.Visible and (not player:IsCoopGhost() or CoopSettings["GhostShow"]) and (player:GetPlayerType() ~= PlayerType.PLAYER_THEFORGOTTEN_B or player:IsCoopGhost()) then
			player.Position = GetAlivePlayerPosition()
			player.ControlsCooldown = 0
			player.ControlsEnabled = true
			player.Visible = true
		end
		
		if (not player:IsCoopGhost() or CoopSettings["GhostShow"]) and showColor then
			local index = player:GetData()["CoopIndex"]
			
			if CoopSettings["ShowColor"] and CoopPlayers.Character[index] then
				player:SetColor(CoopPlayers.Character[index], 2, 100, false, false)
			end
			
			if CoopFont:IsLoaded() and CoopSettings["ShowName"] and player.Visible then
				local position = Isaac.WorldToScreen(player.Position)
				
				if CoopMirrorRoom then
					local screenCenter = GetScreenSize() / 2
					position.X = position.X - (position - screenCenter).X * 2
				end
				
				CoopFont:DrawString("P" .. index, position.X - 5, position.Y, CoopPlayers.Name[index] or KColor(1.0, 1.0, 1.0, CoopSettings["NameAlpha"] / 10))
			end
		end
	end
end

function CoopMod:OnEvaluateCache(player, cache)
	if CoopStart then
		if cache == CacheFlag.CACHE_FLYING and player:IsCoopGhost() and CoopSettings["GhostFly"] then
			player.CanFly = true
		end
		
		if cache == CacheFlag.CACHE_TEARCOLOR and CoopSettings["TearColor"] then
			local index = player:GetData()["CoopIndex"]
			
			if CoopPlayers.Character[index] then
				player.TearColor = CoopPlayers.Character[index]
			end
		end
	end
end

function CoopMod:OnChangeRoom()
	CoopMirrorRoom = CoopGame:GetLevel():GetCurrentRoom():IsMirrorWorld()
end

CoopMod:AddCallback(ModCallbacks.MC_POST_RENDER, CoopMod.OnGameRender)
CoopMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, CoopMod.OnEvaluateCache)
CoopMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, CoopMod.OnChangeRoom)

if ModConfigLoaded then
	local json = require("json")
	
	function CoopMod:OnGameStart()
		if CoopMod:HasData() then
			local setting = json.decode(CoopMod:LoadData())
			
			for key, value in pairs(CoopSettings) do
				if setting[key] ~= nil then
					CoopSettings[key] = setting[key]
				end
			end
		end
		
		OnModInit()
	end
	
	function CoopMod:OnGameExit()
		CoopMod:SaveData(json.encode(CoopSettings))
	end
	
	CoopMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, CoopMod.OnGameStart)
	CoopMod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, CoopMod.OnGameExit)
	
	ModConfig.AddSpace(CoopName, "Info")
	ModConfig.AddText(CoopName, "Info", "Mod " .. CoopName)
	ModConfig.AddSpace(CoopName, "Info")
	ModConfig.AddText(CoopName, "Info", "Version " .. CoopVersion)
	ModConfig.AddSpace(CoopName, "Info")
	ModConfig.AddText(CoopName, "Info", "by Romzes")
	
	ModConfig.AddSetting
	(
		CoopName,
		"General",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return CoopSettings["ShowColor"]
			end,
			Display = function()
				local onOff = "Off"
				if CoopSettings["ShowColor"] then
					onOff = "On"
				end
				return "Show color: " .. onOff
			end,
			OnChange = function(currentBool)
				CoopSettings["ShowColor"] = currentBool
			end
		}
	)
	
	ModConfig.AddSetting
	(
		CoopName,
		"General",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return CoopSettings["ShowName"]
			end,
			Display = function()
				local onOff = "Off"
				if CoopSettings["ShowName"] then
					onOff = "On"
				end
				return "Show name: " .. onOff
			end,
			OnChange = function(currentBool)
				CoopSettings["ShowName"] = currentBool
			end
		}
	)
	
	ModConfig.AddSetting
	(
		CoopName,
		"General",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return CoopSettings["TearColor"]
			end,
			Display = function()
				local onOff = "Off"
				if CoopSettings["TearColor"] then
					onOff = "On"
				end
				return "Change tear color: " .. onOff
			end,
			OnChange = function(currentBool)
				CoopSettings["TearColor"] = currentBool
				
				UpdatePlayersEvaluate()
			end,
			Info = "Make the color of tears the same as the color of the player"
		}
	)
	
	ModConfig.AddSetting
	(
		CoopName,
		"General",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return CoopSettings["UseButton"]
			end,
			Display = function()
				local onOff = "Off"
				if CoopSettings["UseButton"] then
					onOff = "On"
				end
				return "Use button: " .. onOff
			end,
			OnChange = function(currentBool)
				CoopSettings["UseButton"] = currentBool
			end,
			Info = "Highlights players and name only when the TAB key is pressed"
		}
	)
	
	ModConfig.AddSetting
	(
		CoopName,
		"Ghost",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return CoopSettings["GhostShow"]
			end,
			Display = function()
				local onOff = "Off"
				if CoopSettings["GhostShow"] then
					onOff = "On"
				end
				return "Visible: " .. onOff
			end,
			OnChange = function(currentBool)
				CoopSettings["GhostShow"] = currentBool
			end,
			Info = "Allows you to hide ghost so they don't interfere with the game"
		}
	)
	
	ModConfig.AddSetting
	(
		CoopName,
		"Ghost",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return CoopSettings["GhostFly"]
			end,
			Display = function()
				local onOff = "Off"
				if CoopSettings["GhostFly"] then
					onOff = "On"
				end
				return "Enable fly: " .. onOff
			end,
			OnChange = function(currentBool)
				CoopSettings["GhostFly"] = currentBool
				
				UpdatePlayersEvaluate()
			end,
			Info = "Allows ghost to fly through rocks and obstacles"
		}
	)
	
	for i = 1, CoopPlayers.Max do
		ModConfig.AddSetting
		(
			CoopName,
			"Color",
			{
				Type = ModConfigMenu.OptionType.NUMBER,
				CurrentSetting = function()
					return CoopSettings["PlayerColor" .. i]
				end,
				Minimum = 1,
				Maximum = #CoopColors,
				Display = function()
					return "Player " .. i .. ": " .. CoopColors[CoopSettings["PlayerColor" .. i]].name
				end,
				OnChange = function(currentNum)
					CoopSettings["PlayerColor" .. i] = currentNum
					
					UpdatePlayersColor()
					UpdatePlayersEvaluate()
				end,
				Info = "Change player model color"
			}
		)
	end
	
	ModConfig.AddSpace(CoopName, "Color")
	
	ModConfig.AddSetting
	(
		CoopName,
		"Color",
		{
			Type = ModConfigMenu.OptionType.NUMBER,
			CurrentSetting = function()
				return CoopSettings["NameAlpha"]
			end,
			Minimum = 1,
			Maximum = 10,
			Display = function()
				return "Name alpha: " .. CoopSettings["NameAlpha"] / 10
			end,
			OnChange = function(currentNum)
				CoopSettings["NameAlpha"] = currentNum
				
				UpdatePlayersColor()
			end,
			Info = "Change player name alpha"
		}
	)
else
	OnModInit()
end
