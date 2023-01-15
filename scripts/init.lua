
local mod = {
	id = "machin_island_missons",
	name = "Machin Missions",
	description = "Adds new missions unique to each island.",
	version = "0.1.1",
	modApiVersion = "2.5.5",
	icon = "img/icons/mod_icon.png",
}

local function getModOptions(mod)
    return mod_loader:getModConfig()[mod.id].options
end

local function getOption(options, name, defaultVal)
	if options and options[name] then
		return options[name].enabled
	end
	if defaultVal then return defaultVal end
	return true
end

function mod:metadata()

--[[	modApi:addGenerationOption(
		"enable_missions_many", "Always generate mod missions",
		"Makes it so this mod's missions will appear on (almost) every playthrough.",
		{enabled = true}
	)--]]
	--Causes issues and... probably didn't even work, anyway.
	
	modApi:addGenerationOption(
		"enable_mission_detonate", "Mission: Detonate the Warheads",
		"Enable this mission.",
		{enabled = true}
	)
	modApi:addGenerationOption(
		"enable_mission_radio", "Mission: Radio Readings",
		"Enable this mission.",
		{enabled = true}
	)
	modApi:addGenerationOption(
		"enable_mission_botbuddies", "Mission: Train the Robots",
		"Enable this mission.",
		{enabled = true}
	)
	modApi:addGenerationOption(
		"enable_mission_hyperfuel", "Mission: Fuel the Laser Array",
		"Enable this mission.",
		{enabled = true}
	)
end


function mod:init()
	local scriptPath = self.scriptPath
	local resourcePath = self.resourcePath	
	
	self.modApiExt = require(scriptPath .."modApiExt/modApiExt")
	self.modApiExt:init()
		
	self.missions = require(scriptPath .."missions/init")
	self.missions:init(self)
	
end

function mod:load(options, version)
	local scriptPath = self.scriptPath
	self.modApiExt:load(self, options, version)
	self.missions:load(self, options, version)
	require(scriptPath .."libs/menu"):load()
	require(scriptPath .."libs/selected"):load()
	require(scriptPath .."libs/highlighted"):load()
end

local function init(self)
	machin_missions_modApiExt = require(self.scriptPath.."modApiExt/modApiExt"):init()

	-- Rest of your init function
end

local function load(self, options, version)
	machin_missions_modApiExt:load(self, options, version)

local hook = function(mission)
end
modApi:addPreEnvironmentHook(hook)	
	
local hook = function(m, pawn)
--	LOG(pawn:GetMechName() .. " was killed!")
end
modApiExt:addPawnKilledHook(hook)	
	
local hook = function(mission, pawn, weaponId, p1, p2)
--LOG(string.format("%s has finished using %s at %s!", pawn:GetMechName(), weaponId, p2:GetString()))
end
modApiExt:addSkillEndHook(hook)

local hook = function(mission, pawn, weaponId, p1, p2)
--LOG(string.format("%s is using %s at %s!", pawn:GetMechName(), weaponId, p2:GetString()))
end
modApiExt:addSkillStartHook(hook)	

local hook = function(mission, pawn, weaponId, p1, p2, skillEffect)
end
modApiExt:addSkillBuildHook(hook)	

local hook = function(mission)
end
modApi:addPreEnvironmentHook(hook)

end

return mod