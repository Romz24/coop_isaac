
local ModConfigLoaded, ModConfig = pcall(require, "scripts.modconfig")
local CoopName = "Co-op plus"
local CoopMod = RegisterMod(CoopName, 1)
local CoopGame = Game()
local CoopFont = Font()
local CoopVersion = "1.0"
local CoopColors = {
	Character = {
		Color(1.0, 0.4, 0.4),
		Color(0.0, 0.4, 1.0),
		Color(0.4, 0.8, 0.4),
		Color(0.89, 0.8, 0.22),
	},
	Name = { },
}
local CoopSettings = {
	["ModEnable"] = true,
	["ShowColor"] = true,
	["ShowName"] = true,
	["ShowGhost"] = true,
	["ButtonPressed"] = false,
}

for index, color in ipairs(CoopColors.Character) do
	CoopColors.Name[index] = KColor(color.R, color.G, color.B, 0.4)
end

CoopFont:Load("font/pftempestasevencondensed.fnt")

local function IsButtonPressed(players)
	for i = 1, players do
		local player = CoopGame:GetPlayer(i - 1)
		
		if player ~= nil and Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex) then
			return true
		end
	end
	
	return false
end

function CoopMod:OnGameRender()
	if ModConfigLoaded and ModConfig.IsVisible then
		return false -- open mod config menu
	end
	
	if CoopSettings["ModEnable"] == false then
		return false -- mod disable
	end
	
	if CoopGame:IsPaused() then
		return false -- game in paused
	end
	
	local players = CoopGame:GetNumPlayers()
	
	if players < 2 then
		return false -- not enough players
	end
	
	if CoopSettings["ButtonPressed"] and IsButtonPressed(players) == false then
		return false -- Button not pressed
	end
	
	for i = 1, players do
		local player = CoopGame:GetPlayer(i - 1)
		
		if player ~= nil then
			if player:IsCoopGhost() == false or CoopSettings["ShowGhost"] then
				if CoopSettings["ShowColor"] then
					player:SetColor(CoopColors.Character[i], 2, 100, false, false)
				end
				
				if (CoopFont:IsLoaded() and CoopSettings["ShowName"]) then
					local position = Isaac.WorldToScreen(player.Position)
					
					CoopFont:DrawStringUTF8("P" .. i, position.X - 5, position.Y, CoopColors.Name[i])
				end
			end
		end
	end
end

CoopMod:AddCallback(ModCallbacks.MC_POST_RENDER, CoopMod.OnGameRender)

if ModConfigLoaded then
	local json = require("json")
	
	function CoopMod:OnGameStart()
		if CoopMod:HasData() then
			local setting = json.decode(CoopMod:LoadData())
			
			if setting["Version"] == CoopVersion then
				CoopSettings = setting
			else
				CoopMod:RemoveData()
			end
		end
	end
	
	function CoopMod:OnGameExit()
		CoopSettings["Version"] = CoopVersion
		
		CoopMod:SaveData(json.encode(CoopSettings))
	end
	
	CoopMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, CoopMod.OnGameStart)
	CoopMod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, CoopMod.OnGameExit)
	
	ModConfig.AddSpace(CoopName, "Info")
	ModConfig.AddText(CoopName, "Info", function() return CoopName end)
	ModConfig.AddSpace(CoopName, "Info")
	ModConfig.AddText(CoopName, "Info", function() return "Version " .. CoopVersion end)
	ModConfig.AddSpace(CoopName, "Info")
	ModConfig.AddText(CoopName, "Info", function() return "by Romzes" end)
	
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
				return 'Enamble mod: ' .. onOff
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
				return 'Show color: ' .. onOff
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
				return 'Show name: ' .. onOff
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
				return 'Show ghost: ' .. onOff
			end,
			OnChange = function(currentBool)
				CoopSettings["ShowGhost"] = currentBool
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
				return CoopSettings["ButtonPressed"]
			end,
			Display = function()
				local onOff = "Off"
				if CoopSettings["ButtonPressed"] then
					onOff = "On"
				end
				return 'Show when the button is pressed: ' .. onOff
			end,
			OnChange = function(currentBool)
				CoopSettings["ButtonPressed"] = currentBool
			end
		}
	)
end
