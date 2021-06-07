
local ModConfigLoaded, ModConfig = pcall(require, "scripts.modconfig")
local CoopName = "Co-op plus"
local CoopMod = RegisterMod(CoopName, 1)
local CoopGame = Game()
local CoopFont = Font()
local CoopVersion = "1.6"
local CoopMaxPlayers = 4
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
}
local CoopSettings = {
	["ModEnable"] = true,
	["ShowColor"] = true,
	["ShowName"] = true,
	["ShowGhost"] = true,
	["ButtonPressed"] = false,
	["GhostFly"] = false,
	["NameAlpha"] = 4,
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
	local controllers = { }
	local count = 0
	
	for i = 1, CoopGame:GetNumPlayers() do
		local player = CoopGame:GetPlayer(i - 1)
		local index = player.ControllerIndex
		
		if not controllers[index] then
			controllers[index] = true
			count = count + 1
		end
	end
	
	return count
end

local function UpdatePlayersColor()
	for i = 1, CoopPlayers.Max do
		local player = CoopSettings["PlayerColor" .. i]
		local color = CoopColors[player].color
		
		CoopPlayers.Character[i] = color
		CoopPlayers.Name[i] = KColor(color.R, color.G, color.B, CoopSettings["NameAlpha"] / 10)
	end
end

local function UpdatePlayersFly()
	for i = 1, CoopGame:GetNumPlayers() do
		local player = CoopGame:GetPlayer(i - 1)
		
		if player:IsCoopGhost() then
			player:AddCacheFlags(CacheFlag.CACHE_FLYING)
			player:EvaluateItems()
		end
	end
end

local function OnModInit()
	CoopFont:Load("font/pftempestasevencondensed.fnt")
	UpdatePlayersColor()
	UpdatePlayersFly()
	print("Mod " .. CoopName .. " v" .. CoopVersion .. " loaded!")
end

function CoopMod:OnGameRender()
	if ModConfigLoaded and ModConfig.IsVisible then
		return false -- open mod config menu
	end
	
	if not CoopSettings["ModEnable"] then
		return false -- mod disable
	end
	
	if CoopGame:IsPaused() then
		return false -- game in paused
	end
	
	if GetPlayers() < 2 then
		return false -- not enough players
	end
	
	if CoopSettings["ButtonPressed"] and not IsButtonPressed() then
		return false -- Button not pressed
	end
	
	for i = 1, CoopGame:GetNumPlayers() do
		local player = CoopGame:GetPlayer(i - 1)
		
		if not player:IsCoopGhost() or CoopSettings["ShowGhost"] then
			local index = player.ControllerIndex
			
			if CoopSettings["ShowColor"] and CoopPlayers.Character[index] then
				player:SetColor(CoopPlayers.Character[index], 2, 100, false, false)
			end
			
			if CoopFont:IsLoaded() and CoopSettings["ShowName"] then
				local position = Isaac.WorldToScreen(player.Position)
				
				CoopFont:DrawString("P" .. index, position.X - 5, position.Y, CoopPlayers.Name[index] or KColor(1.0, 1.0, 1.0, CoopSettings["NameAlpha"] / 10))
			end
		end
	end
end

function CoopMod:OnChangeFly(player, cache)
	if player:IsCoopGhost() and CoopSettings["GhostFly"] then
		player.CanFly = true
	end
end

CoopMod:AddCallback(ModCallbacks.MC_POST_RENDER, CoopMod.OnGameRender)
CoopMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, CoopMod.OnChangeFly, CacheFlag.CACHE_FLYING)

if ModConfigLoaded then
	local json = require("json")
	
	function CoopMod:OnGameStart()
		if CoopMod:HasData() then
			local setting = json.decode(CoopMod:LoadData())
			
			if setting["Version"] == CoopVersion then
				for key, value in pairs(CoopSettings) do
					if setting[key] then
						CoopSettings[key] = setting[key]
					end
				end
			else
				CoopMod:RemoveData()
			end
		end
		
		OnModInit()
	end
	
	function CoopMod:OnGameExit()
		CoopSettings["Version"] = CoopVersion
		
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
				return CoopSettings["ModEnable"]
			end,
			Display = function()
				local onOff = "Off"
				if CoopSettings["ModEnable"] then
					onOff = "On"
				end
				return "Enamble mod: " .. onOff
			end,
			OnChange = function(currentBool)
				CoopSettings["ModEnable"] = currentBool
			end
		}
	)
	
	ModConfig.AddSpace(CoopName, "General")
	
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
				return CoopSettings["ShowGhost"]
			end,
			Display = function()
				local onOff = "Off"
				if CoopSettings["ShowGhost"] then
					onOff = "On"
				end
				return "Highlight ghost: " .. onOff
			end,
			OnChange = function(currentBool)
				CoopSettings["ShowGhost"] = currentBool
			end,
			Info = "Allows you to turn off the highlighting of dead players"
		}
	)
	
	ModConfig.AddSetting
	(
		CoopName,
		"General",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return CoopSettings["ButtonPressed"]
			end,
			Display = function()
				local onOff = "Off"
				if CoopSettings["ButtonPressed"] then
					onOff = "On"
				end
				return "Show when the button is pressed: " .. onOff
			end,
			OnChange = function(currentBool)
				CoopSettings["ButtonPressed"] = currentBool
			end,
			Info = "Highlights players when the TAB button is pressed"
		}
	)
	
	ModConfig.AddSetting
	(
		CoopName,
		"General",
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
				return "Ghost fly: " .. onOff
			end,
			OnChange = function(currentBool)
				CoopSettings["GhostFly"] = currentBool
				UpdatePlayersFly()
			end,
			Info = "Allows dead players to fly through rocks and obstacles"
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
				end,
				Info = "Change player color"
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
