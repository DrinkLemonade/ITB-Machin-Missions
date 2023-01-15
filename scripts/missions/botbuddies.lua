local path = mod_loader.mods[modApi.currentMod].scriptPath
local this = {id = "Mission_Machin_Botbuddies"}
local corpMissions = require(path .."corpMissions")

local mod = mod_loader.mods[modApi.currentMod]
local modApiExt = require(mod.scriptPath.."modApiExt/modApiExt")

Mission_Machin_Botbuddies = Mission_Infinite:new{
--At this point, self is the table defining the whole mission type
	Name = "Train the Robots",--used in hook check
	Objectives = { Objective("Kill 2 Vek with the Artillery-Bot",1), Objective("Kill 2 Vek with the Laser-Bot", 1),  }, 
	MapTags = {"Machin_botbuddies"},
	Criticals = nil,
	TurnLimit = 4,
	BonusPool = {},
	UseBonus = false,
	SpawnStartMod = 1,
	SpawnMod = 1,
	Bots = nil, --Not sure why I need this
}

local function IsTipImage()
	return Board:GetSize() == Point(6, 6)
end

Machin_mission_artillery_buddy = Pawn:new
	{
		Name = "Artillery-Bot",
		Health = 1, --3
		MoveSpeed = 3,
		Image = "art_buddy", 
		SkillList = { "Machin_mission_artillery_buddy_atk" },
		Portrait = "enemy/machin_artillery_buddy",
		SoundLocation = "/enemy/snowart_1/",
		DefaultTeam = TEAM_PLAYER,
		--DefaultFaction = FACTION_BOTS,
		ImpactMaterial = IMPACT_METAL
	}

Machin_mission_artillery_buddy_atk = {   
	Name = "Vk8 Rockets Mark I",
	Description = "Launch Rockets at 3 tiles.",
	ArtillerySize = 7,--base is 5, but let's cheat a little in the player's favor
	Explosion = "ExploArt1",
	Rarity = 0,
	Damage = 1,
	Class = "Unique",
	Icon = "weapons/ranged_tribomb.png",
	ImpactSound = "/impact/generic/explosion",
	Projectile = "effects/shot_artimech.png",
	TipImage = {
		Unit = Point(2,3),
		Enemy = Point(2,1),
		Enemy2 = Point(3,1),
		Target = Point(2, 1),
		CustomPawn = "Machin_mission_artillery_buddy",
	}
}
Machin_mission_artillery_buddy_atk = LineArtillery:new(Machin_mission_artillery_buddy_atk)

function Machin_mission_artillery_buddy_atk:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local dir = GetDirection(p2-p1)
	
	ret:AddArtillery(SpaceDamage(p2, self.Damage),self.Projectile)
	ret:AddDamage(SpaceDamage(p2 + DIR_VECTORS[(dir + 1)% 4], self.Damage))
	ret:AddDamage(SpaceDamage(p2 + DIR_VECTORS[(dir - 1)% 4], self.Damage))
	
	if not IsTipImage() then
			ret:AddDelay(0.016)
			ret:AddScript("Machin_mission_artillery_buddy_atk:CheckTempKillcount()")
	end
	return ret
end

function Machin_mission_artillery_buddy_atk:ResetTempKillcount()
	local m = GetCurrentMission()
	if not m or not Board then return end
	
	m.temp_killcount = 0
end

function Machin_mission_artillery_buddy_atk:CheckTempKillcount()
	local m = GetCurrentMission()
	if not m or not Board then return end
	
	if m.temp_killcount > 0 then
		m.machin_artillery_kills = m.machin_artillery_kills+m.temp_killcount
		if m.machin_artillery_kills == m.machin_artillery_kills_goal then
			local fx = SkillEffect()
			local chance = math.random()
			if chance > 0.3 then
				fx:AddVoice("Mission_Machin_Botbuddy_Trained", -1)
				Board:AddEffect(fx)
			end
		end
	end
end

Machin_mission_laser_buddy = Pawn:new
	{
		Name = "Laser-Bot",
		Health = 1, --2
		MoveSpeed = 3,
		Portrait = "enemy/machin_laser_buddy",
		Image = "las_buddy", 
		SkillList = { "Machin_mission_laser_buddy_atk" },  
		SoundLocation = "/enemy/snowlaser_1/",
		DefaultTeam = TEAM_PLAYER,
		--DefaultFaction = FACTION_BOTS,
		ImpactMaterial = IMPACT_METAL
	}

Machin_mission_laser_buddy_atk = LaserDefault:new{  
	Name = "BKR Beam Mark I",
	Description = "Piercing beam, damage reduced by range.",
	Class = "Unique",
	LaunchSound = "/weapons/shield_bash",
	Rarity      = 0,
	Damage      = 2,
	PowerCost   = 0,
	Icon = "weapons/prime_lasermech.png",
	TipImage = {
		Unit = Point(2,4),
		Enemy = Point(2,2),
		Friendly = Point(2,1),
		Target = Point(2,2),
		Mountain = Point(2,0),
		CustomPawn = "Machin_mission_laser_buddy"
	}
}
--Machin_mission_laser_buddy_atk = LineArtillery:new(Machin_mission_artillery_buddy_atk)

function Machin_mission_laser_buddy_atk:GetSkillEffect(p1,p2) --Just copying the contents of LaserDefault, to be safe	
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)
	local target = p1 + DIR_VECTORS[direction]

	self:AddLaser(ret, target, direction)
	
	if not IsTipImage() then
			ret:AddDelay(1.016)--Not sure why, but a longer delay was necessary here.
			ret:AddScript("Machin_mission_laser_buddy_atk:CheckTempKillcount()")
	end

	return ret
end

function Machin_mission_laser_buddy_atk:ResetTempKillcount() --I could just reuse artillery buddy's code, but at this point I just want to finish this damn mission
	local m = GetCurrentMission()
	if not m or not Board then return end
	m.temp_killcount = 0
end

function Machin_mission_laser_buddy_atk:CheckTempKillcount()
	local m = GetCurrentMission()
	if not m or not Board then return end
	
	if m.temp_killcount > 0 then
		m.machin_laser_kills = m.machin_laser_kills+m.temp_killcount
		if m.machin_laser_kills == m.machin_laser_kills_goals then
			local fx = SkillEffect()
			local chance = math.random()
			if chance > 0.3 then
				fx:AddVoice("Mission_Machin_Botbuddy_Trained", -1)
				Board:AddEffect(fx)
			end
		end
	end
end

function Mission_Machin_Botbuddies:StartMission()
	self.temp_killcount = 0
	
	local pawn = PAWN_FACTORY:CreatePawn("Machin_mission_artillery_buddy")
	Board:AddPawn(pawn, Board:GetZone("Machin_bot1_zone"):index(1))
	self.machin_artillery_id = pawn:GetId()
	pawn:SetTeam(TEAM_PLAYER)
	self.machin_artillery_kills = 0
	self.machin_artillery_kills_goal = 2
	
	local pawn = PAWN_FACTORY:CreatePawn("Machin_mission_laser_buddy")
	Board:AddPawn(pawn, Board:GetZone("Machin_bot2_zone"):index(1))
	self.machin_laser_id = pawn:GetId()
	pawn:SetTeam(TEAM_PLAYER)
	self.machin_laser_kills = 0
	self.machin_laser_kills_goal = 2
end

function Mission_Machin_Botbuddies:UpdateObjectives()
	local art_check_id = self.machin_artillery_id
	local art_bot_alive = Board:IsPawnAlive(art_check_id)
	local art_kills = self.machin_artillery_kills
	local art_goal = self.machin_artillery_kills_goal
	
	local las_check_id = self.machin_laser_id
	local las_bot_alive = Board:IsPawnAlive(las_check_id)
	local las_kills = self.machin_laser_kills
	local las_goal = self.machin_laser_kills_goal

	if art_kills >= art_goal then
		Game:AddObjective("Kill ".. tostring(art_goal) .." Vek with the\nArtillery-Bot (".. tostring(art_kills) .."/".. tostring(art_goal) .." killed)", OBJ_COMPLETE, REWARD_REP, 1)
	elseif art_bot_alive then
		Game:AddObjective("Kill ".. tostring(art_goal) .." Vek with the\nArtillery-Bot (".. tostring(art_kills) .."/".. tostring(art_goal) .." killed)", OBJ_STANDARD, REWARD_REP, 1)	
	else
		Game:AddObjective("Kill ".. tostring(art_goal) .." Vek with the\nArtillery-Bot (".. tostring(art_kills) .."/".. tostring(art_goal) .." killed)", OBJ_FAILED, REWARD_REP, 1)
	end
	
	if las_kills >= las_goal then
		Game:AddObjective("Kill ".. tostring(las_goal) .." Vek with the\nLaser-Bot (".. tostring(las_kills) .."/".. tostring(las_goal) .." killed)", OBJ_COMPLETE, REWARD_REP, 1)
	elseif las_bot_alive then
		Game:AddObjective("Kill ".. tostring(las_goal) .." Vek with the\nLaser-Bot (".. tostring(las_kills) .."/".. tostring(las_goal) .." killed)", OBJ_STANDARD, REWARD_REP, 1)	
	else
		Game:AddObjective("Kill ".. tostring(las_goal) .." Vek with the\nLaser-Bot (".. tostring(las_kills) .."/".. tostring(las_goal) .." killed)", OBJ_FAILED, REWARD_REP, 1)
	end
end

function Mission_Machin_Botbuddies:GetCompletedObjectives()
	local ret = copy_table(self.Objectives)
	
	if self.machin_artillery_kills < self.machin_artillery_kills_goal then
		ret[1] = ret[1]:Failed()
	end
	
	if self.machin_laser_kills < self.machin_laser_kills_goal then
		ret[2] = ret[2]:Failed()
	end
	
	return ret
end


function this:init(mod)
	modApi:appendAsset("img/units/mission/machin_laser_buddy.png", mod.resourcePath .."img/units/mission/machin_laser_buddy.png")
	modApi:appendAsset("img/units/mission/machin_laser_buddy_a.png", mod.resourcePath .."img/units/mission/machin_laser_buddy_a.png")
	modApi:appendAsset("img/units/mission/machin_laser_buddy_d.png", mod.resourcePath .."img/units/mission/machin_laser_buddy_d.png")
	modApi:appendAsset("img/units/mission/machin_laser_buddy_ns.png", mod.resourcePath .."img/units/mission/machin_laser_buddy_ns.png")
	modApi:appendAsset("img/units/mission/machin_laser_buddy_off.png", mod.resourcePath .."img/units/mission/machin_laser_buddy_off.png")
	
	local a = ANIMS
	a.las_buddy = a.snowlaser1:new{Image = "units/mission/machin_laser_buddy.png", PosX = -17}
	a.las_buddya = a.snowlaser1a:new{Image = "units/mission/machin_laser_buddy_a.png", PosX = -17}
	a.las_buddyd = a.snowlaser1d:new{Image = "units/mission/machin_laser_buddy_d.png", PosX = -17}
	a.las_buddy_ns = a.las_buddy:new{Image = "units/mission/machin_laser_buddy_ns.png"}
	a.las_buddyoff = a.las_buddy:new{Image = "units/mission/machin_laser_buddy_off.png"}--shouldn't be displayed barring a bug
	
	modApi:appendAsset("img/units/mission/machin_artillery_buddy.png", mod.resourcePath .."img/units/mission/machin_artillery_buddy.png")
	modApi:appendAsset("img/units/mission/machin_artillery_buddy_a.png", mod.resourcePath .."img/units/mission/machin_artillery_buddy_a.png")
	modApi:appendAsset("img/units/mission/machin_artillery_buddy_d.png", mod.resourcePath .."img/units/mission/machin_artillery_buddy_d.png")
	modApi:appendAsset("img/units/mission/machin_artillery_buddy_ns.png", mod.resourcePath .."img/units/mission/machin_artillery_buddy_ns.png")
	modApi:appendAsset("img/units/mission/machin_artillery_buddy_off.png", mod.resourcePath .."img/units/mission/machin_artillery_buddy_off.png")
	
	local a = ANIMS
	a.art_buddy = a.snowart1:new{Image = "units/mission/machin_artillery_buddy.png"}
	a.art_buddya = a.snowart1a:new{Image = "units/mission/machin_artillery_buddy_a.png"}
	a.art_buddyd = a.snowart1d:new{Image = "units/mission/machin_artillery_buddy_d.png"}
	a.art_buddy_ns = a.art_buddy:new{Image = "units/mission/machin_artillery_buddy_ns.png"}
	a.art_buddyoff = a.art_buddy:new{Image = "units/mission/machin_artillery_buddy_off.png"}--shouldn't be displayed barring a bug

	for i = 0, 3 do
		modApi:addMap(mod.resourcePath .."maps/machin_botbuddies".. i ..".map")
	end
	
	modApi:appendAsset("img/portraits/enemy/machin_artillery_buddy.png", mod.resourcePath.. "img/portraits/mission/machin_artillery_buddy.png")
	modApi:appendAsset("img/portraits/enemy/machin_laser_buddy.png", mod.resourcePath.. "img/portraits/mission/machin_laser_buddy.png")
end


function this:load(mod, options, version)
	local hook = function(m, pawn)
		if m.Name == "Train the Robots" then
			if pawn:GetTeam() == TEAM_ENEMY then
				m.temp_killcount = m.temp_killcount+1
			end
		end
	end
	modApiExt:addPawnKilledHook(hook)
	
	local hook = function(mission, pawn, weaponId, p1, p2)
		local m = GetCurrentMission()
		if not m or not Board then return end
		if pawn:GetId() == mission.machin_artillery_id then
			if not IsTipImage() then
				Machin_mission_artillery_buddy_atk:ResetTempKillcount()
			end
		elseif pawn:GetId() == mission.machin_laser_id then
			if not IsTipImage() then
				Machin_mission_laser_buddy_atk:ResetTempKillcount()
			end
		end
	end
	modApiExt:addSkillStartHook(hook)

	corpMissions.Add_Missions_Low("Mission_Machin_Botbuddies", "Corp_Snow")
end

return this