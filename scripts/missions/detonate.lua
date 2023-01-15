local path = mod_loader.mods[modApi.currentMod].scriptPath
local this = {id = "Mission_Machin_Detonate"}
local corpMissions = require(path .."corpMissions")

-- returns number of pawns alive
-- in a list of pawn id's.
local function countAlive(list)
	assert(type(list) == 'table', "table ".. tostring(list) .." not a table")
	local ret = 0
	for _, id in ipairs(list) do
		if type(id) == 'number' then
			ret = ret + (Board:IsPawnAlive(id) and 1 or 0)
		else
			error("variable of type ".. type(id) .." is not a number")
		end
	end
	
	return ret
end

Mission_Machin_Detonate = Mission_Infinite:new{
--At this point, self is the table defining the whole mission type
	Name = "Detonate the Warheads",
	Objectives = { Objective("Detonate 2 Warheads total",1), Objective("Detonate 4 Warheads total", 1),  }, 
	MapTags = {"Machin_detonate"},
	Criticals = nil,
	TurnLimit = 4,
	BonusPool = {},
	WarheadAmount = 4,
	UseBonus = false,
	SpawnStartMod = -1,
	SpawnMod = -2,--plus one leaper per turn, works out to -1
}

function Mission_Machin_Detonate:StartMission()
self.Criticals = {}	
--	local pawn = PAWN_FACTORY:CreatePawn("Machin_mission_warhead")
--	table.insert(self.Criticals, pawn:GetId())
--	Board:AddPawn(pawn, Board:GetZone("tosx_juggernaut_zone"):index(1))
	for i = 1, self.WarheadAmount do
		local pawn = PAWN_FACTORY:CreatePawn("Machin_mission_warhead")
		table.insert(self.Criticals, pawn:GetId())
		Board:AddPawn(pawn, "Machin_warhead_zone"..i)
	end	
end

function Mission_Machin_Detonate:UpdateObjectives()	
	if countAlive(self.Criticals) < 3 then
		Game:AddObjective("Detonate 2 Warheads total", OBJ_COMPLETE, REWARD_REP, 1)
	else
		Game:AddObjective("Detonate 2 Warheads total", OBJ_STANDARD, REWARD_REP, 1)	
	end

	if countAlive(self.Criticals) == 0 then
		Game:AddObjective("Detonate 4 Warheads total", OBJ_COMPLETE, REWARD_REP, 1)
	else
		Game:AddObjective("Detonate 4 Warheads total", OBJ_STANDARD, REWARD_REP, 1)	
	end

end

function Mission_Machin_Detonate:GetCompletedObjectives()
	local ret = copy_table(self.Objectives)
	
	if countAlive(self.Criticals) > 2 then
		ret[1] = ret[1]:Failed()
	end
	
	if countAlive(self.Criticals) > 0 then
		ret[2] = ret[2]:Failed()
	end
	
	return ret
end

function Mission_Machin_Detonate:UpdateSpawning()
	local count = self:GetSpawnCount()
	for i = 1, count do 
		if i == 1 then -- Make first spawn a leaper each turn
			Board:SpawnPawn(self:NextPawn( { "Leaper" } ), "")
		else
			Board:SpawnPawn(self:NextPawn(),"")
		end
	end
end

Machin_mission_warhead = Pawn:new{
	Name = "Buried Warhead",
	Health = 1,
	Image = "Machin_Warhead",
	MoveSpeed = 0,
	SoundLocation = "/support/train",
	DefaultTeam = TEAM_ENEMY,
	ImpactMaterial = IMPACT_METAL,
	Corporate = false,
	Mission = true,
	Explodes = true,
	Pushable = false,
	Flying = false,
	IsPortrait = false,
	Neutral = true,
	Minor = true,
}

function this:init(mod)

	modApi:appendAsset("img/units/enemy/machin_warhead.png", mod.resourcePath .."img/units/mission/machin_warhead.png")
	modApi:appendAsset("img/units/enemy/machin_warhead_d.png", mod.resourcePath .."img/units/mission/machin_warhead_d.png")
	modApi:appendAsset("img/units/enemy/machin_warhead_ns.png", mod.resourcePath .."img/units/mission/machin_warhead_ns.png")

	local a = ANIMS
	a.Machin_Warhead = a.BaseUnit:new{Image = "units/enemy/machin_warhead.png", PosX = -37, PosY = -19}
	a.Machin_Warhead_ns = a.BaseUnit:new{Image = "units/enemy/machin_warhead_ns.png", PosX = -37, PosY = -19}
	a.Machin_Warheadd = a.Machin_Warhead:new{Image = "units/enemy/machin_warhead_d.png", PosX = -37, PosY = -19, NumFrames = 13, Time = 0.14, Loop = false }

	for i = 0, 3 do
		modApi:addMap(mod.resourcePath .."maps/machin_detonate".. i ..".map")
	end
end

function this:load(mod, options, version)
	self.modApiExt = require(mod.scriptPath .."modApiExt/modApiExt")
	
	self.modApiExt:addPawnKilledHook(function(mission, pawn)
		-- I could probably make the warheads deal more damage or push this way, I think?--
	end)
	
	corpMissions.Add_Missions_Low("Mission_Machin_Detonate", "Corp_Grass")
end

return this