
local path = mod_loader.mods[modApi.currentMod].scriptPath
local getModUtils = require(path .."getModUtils")
local this = {}

local pawns = {
	tosx_mission_juggernaut = "Mission_tosx_Juggernaut_Destroyed",
	Machin_mission_radio_unit = "Mission_Machin_Radio_Destroyed",
	Machin_mission_laser_array = "Mission_Machin_Laser_Array_Destroyed",
	Machin_mission_warhead = "Mission_Machin_Warhead_Destroyed",
	Machin_mission_laser_buddy = "Mission_Machin_Botbuddy_Destroyed",
	Machin_mission_artillery_buddy = "Mission_Machin_Botbuddy_Destroyed",
}

function this:load()
	local modUtils = getModUtils()
	
	modUtils:addPawnKilledHook(function(mission, pawn)
		local pawnType = pawn:GetType()
		local voice = pawns[pawnType]
		if not voice then return end
		
		local chance = math.random()
		if chance > 0.5 then
			local fx = SkillEffect()
			fx:AddVoice(voice, -1)
			Board:AddEffect(fx)
		end
	end)
end

return this