
local this = {}
local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local path = scriptPath .."missions/"
local personality = require(scriptPath .."personality")

local function file_exists(name)
	local f = io.open(name, "r")
	if f then io.close(f) return true else return false end
end

local function loadDialog(file)
	local name = file:sub(1, -5)
	
	if file_exists(file) then
	--	LOG("loading dialog from '".. file .."'")
		local dialog = require(name)
		
		for person, t in pairs(dialog) do
	--		LOG("adding ".. person)
			personality.AddDialog(Personality[person], t, false)
		end
	else
	--	LOG("unable to find dialog file '".. file .."'")
	end
end
-------------------------------

local function loadMissionDialog(missionId, file)
	local name = file:sub(1, -5)
	
	if file_exists(file) then
	--	LOG("loading dialog from '".. file .."'")
		local dialog = require(name)
		
		for person, t in pairs(dialog) do
			personality.AddMissionDialog(Personality[person], missionId, t)
		end
	else
	--	LOG("unable to find dialog file '".. file .."'")
	end
end

--local missions = {
	--"botbuddies",
	--"radio",
	--"detonate",
	--"hyperfuel",
--}
local missions = {}

function this:init(mod)
--local options = mod_loader:getModConfig()[mod.id].options --> hmmmm
local loop = 1

--Removed for being hacky, causing bugs, and maybe not even working anyway
--if not (self.options and not self.options['enable_missions_many'].enabled) then
--loop = 30
--end

for i = 1,loop do
	if not (self.options and not self.options['enable_mission_detonate'].enabled) then
	table.insert(missions,"detonate")
	end
	if not (self.options and not self.options['enable_mission_radio'].enabled) then
	table.insert(missions,"radio")
	end
	if not (self.options and not self.options['enable_mission_botbuddies'].enabled) then
	table.insert(missions,"botbuddies")
	end
	if not (self.options and not self.options['enable_mission_hyperfuel'].enabled) then
	table.insert(missions,"hyperfuel")
	end
end
	
	for _, mission in ipairs(missions) do
		self[mission] = require(path .. mission)
		self[mission]:init(mod)
		--LOG("Init mod -- Required and init'd this:")
		--LOG(mission)
	end
end

function this:load(mod, options, version)
	require(path .."voice_units"):load()
	loadDialog(path .. "extra_dialog.lua")
	
	for _, mission in ipairs(missions) do
		self[mission]:load(mod, options, version)
		--LOG("Load mod -- Loaded and loaded dialogue of this:")
		--LOG(mission)
		loadMissionDialog(self[mission].id, path .. mission .."_dialog.lua")
	end
end

return this