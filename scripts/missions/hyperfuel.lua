local path = mod_loader.mods[modApi.currentMod].scriptPath
local this = {id = "Mission_Machin_Hyperfuel"}
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

Mission_Machin_Hyperfuel = Mission_Infinite:new{
--At this point, self is the table defining the whole mission type
	Name = "Fuel the Laser Array",
	Objectives = { Objective("Fuel the Laser Array",1), Objective("Protect the Laser Array", 1),  }, 
	MapTags = {"Machin_hyperfuel"},
	CriticalUnit = nil,
	TurnLimit = 4,
	Powered = true,
	BonusPool = {},
	UseBonus = false,
	SpawnStartMod = -2,
	GlobalSpawnMod = 2, --still tweaking the numbers. +0 at start, +2 after was doable flawlessly, but only barely.
	--AcidSpawn = 0,--until I figure out how to remove acid on laser-array/truck zones. although maybe that does it?
}

function Mission_Machin_Hyperfuel:StartMission()
machin_delivered_fuel = false
local pawn = PAWN_FACTORY:CreatePawn("Machin_mission_laser_array")
self.CriticalUnit = pawn:GetId()
Board:AddPawn(pawn, Board:GetZone("Machin_laser_zone"):index(1))
Board:SetAcid(pawn:GetSpace(),false)
pawn:SetPowered(false)

local pawn = PAWN_FACTORY:CreatePawn("Machin_mission_truck")
self.Activator = pawn:GetId()
Board:AddPawn(pawn, Board:GetZone("Machin_truck_zone"):index(1))
Board:SetAcid(pawn:GetSpace(),false)

--local drop_zone = Board:GetZone("Machin_drop_zone"):index(1)
--Board:BlockSpawn(drop_zone, BLOCKED_PERM)
	--if Board:GetCustomTile(drop_zone) == "machin_mission_fuel_drop_zone.png" then
		--Board:AddAnimation(drop_zone, "machin_drop_zone_animation", ANIM_NO_DELAY)
	--end
end



function Mission_Machin_Hyperfuel:UpdateObjectives()
	local laser_pawn = Board:GetPawn(self.CriticalUnit)
	local laser_alive = Board:IsPawnAlive(self.CriticalUnit)
	
	local truck_alive = Board:IsPawnAlive(self.Activator)
	--local laser_on = Board:GetPawn(check_id):IsPowered()
	
	if machin_delivered_fuel then
		Game:AddObjective("Fuel the Laser Array", OBJ_COMPLETE, REWARD_REP, 1)
	elseif truck_alive and laser_alive then
		Game:AddObjective("Fuel the Laser Array", OBJ_STANDARD, REWARD_REP, 1)	
	else
		Game:AddObjective("Fuel the Laser Array", OBJ_FAILED, REWARD_REP, 1)
	end

	if laser_alive then
		Game:AddObjective("Protect the Laser Array", OBJ_STANDARD, REWARD_REP, 1)
	else
		Game:AddObjective("Protect the Laser Array", OBJ_FAILED, REWARD_REP, 1)	
	end

end

function Mission_Machin_Hyperfuel:GetCompletedObjectives()
	local ret = copy_table(self.Objectives)
	local laser_pawn = Board:GetPawn(self.CriticalUnit)
	local laser_alive = Board:IsPawnAlive(self.CriticalUnit)
	
	local truck_alive = Board:IsPawnAlive(self.Activator)
	--local laser_on = Board:GetPawn(check_id):IsPowered()
	
	if (not machin_delivered_fuel) then
		ret[1] = ret[1]:Failed()
	end
	
	if not Board:IsPawnAlive(self.CriticalUnit) then
		ret[2] = ret[2]:Failed()
	end
	
	return ret
end

Machin_mission_truck = Pawn:new{
	Name = "Hyperfuel Truck",
	Health = 1,
	Image = "Machin_Truck",
	MoveSpeed = 3,
	SkillList = { "Machin_fuel_attack" },
	SoundLocation = "/mech/brute/tank/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Corporate = false,
	Mission = true,
	Flying = false,
	IsPortrait = true,
}

Machin_fuel_attack = Skill:new{  
	Name = "Unload Hyperfuel",
	Description = "Pushes a target. Also activates the Laser Array on hit.",
	Class = "Unique",
	PathSize = 1,
	Icon = "weapons/machin_hyperfuel_icon.png",
	Rarity = 0,
	LaunchSound = "/weapons/science_repulse",
	Range = 1,
	PathSize = 1,
	Damage = 0,
	PowerCost = 0,
	Acid = 0,
	Push = 1,
	TipImage = {
		Unit = Point(2,3),
		Enemy = Point(2,2),
		Target = Point(2,2),
		CustomPawn = "Machin_mission_truck",
	}
}

function Machin_fuel_attack:GetTargetArea(point)
	local ret = PointList()
	-- if adjacent tile is a unit, allow target and just push
	for i = DIR_START, DIR_END do
		ret:push_back(DIR_VECTORS[i] + point)
		if self.Range == 7 then
			for k = 2, self.Range do
				local curr = DIR_VECTORS[i]*k + point
				if Board:IsValid(curr) and not Board:IsBlocked(curr, Pawn:GetPathProf()) then
					ret:push_back(DIR_VECTORS[i]*k + point)
				end
			end
		end
	end
	
	return ret
end

function Machin_fuel_attack:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)
	local backwards = GetDirection(p1 - p2)
	local target = p2
	local damage = SpaceDamage(target, self.Damage, direction)
	local move = PointList()
	
	--if self.Range == 7 then
	if self.Range == 7 and not Board:IsBlocked(p2, Pawn:GetPathProf()) then
		target = p1 + DIR_VECTORS[(direction + 2) % 4]
		damage = SpaceDamage(target, self.Damage, backwards)
		--move:push_back(p1)
		move:push_back(p2)
		ret:AddBurst(p1,"Emitter_Burst_$tile",DIR_NONE)
		ret:AddLeap(move, NO_DELAY)
		damage.sAnimation = "machin_fuelpush_"..backwards
		ret:AddBounce(p1,2)
	else
		damage.sAnimation = "machin_fuelpush_"..direction
		ret:AddBounce(p1,2)	
	end
	
	--damage.iAcid = self.Acid
	
	ret:AddMelee(p2 - DIR_VECTORS[direction], damage, 0.2) --0.2 is the delay before the ammo animation
	--ret:AddScript([[Pawn:ResetUses()]])
	
	--local selfDamage = SpaceDamage(p1,0)
	--selfDamage.sAnimation = "AmmoDrop1"	
	--ret:AddDamage(selfDamage)
	
	if Board:IsPawnSpace(p2) then
		local check_id = Board:GetPawn(p2):GetId()
		if check_id == GetCurrentMission().CriticalUnit then --we're hitting the laser array
			if Board:IsPawnAlive(check_id) and not Board:GetPawn(check_id):IsPowered() then
				ret:AddScript([[Mission_Machin_Hyperfuel:PowerLaserArray()]])
			end
		end
	end
	
	return ret
end

function Mission_Machin_Hyperfuel:PowerLaserArray()
	local id = GetCurrentMission().CriticalUnit
	laser = Board:GetPawn(id)
	laser:SetPowered(true)
	laser:SetActive(true)
	laser.Powered = true
	machin_delivered_fuel = true
	local effect = SkillEffect()
	effect:AddVoice("Mission_Machin_Fuel_Delivered", -1)
	Board:AddEffect(effect)
end

Machin_mission_laser_array = Pawn:new{
	Name = "Laser Array",
	Health = 2,
	Image = "Machin_Laser_Array",
	MoveSpeed = 2,
	SkillList = { "Machin_array_attack" },
	SoundLocation = "/support/train",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Corporate = true,
	Mission = true,
	Flying = false,
	IsPortrait = true,
	Pushable = false,
	Massive = true,
	Corpse = true,
	Powered = false,
}

Machin_array_attack = LaserDefault:new{  
	Name = "Prototype Beam",
	Description = "Fire a powerful piercing beam.",
	Class = "Unique",
	LaunchSound = "/weapons/shield_bash",
	Rarity      = 0,
	Damage      = 4,
	PowerCost   = 0,
	Icon = "weapons/prime_lasermech.png",
	TipImage = {
		Unit = Point(2,4),
		Enemy = Point(2,2),
		Friendly = Point(2,1),
		Target = Point(2,2),
		Mountain = Point(2,0),
		CustomPawn = "Machin_mission_laser_array"
	}
}

function this:init(mod)

	modApi:appendAsset("img/units/mission/machin_truck.png", mod.resourcePath .."img/units/mission/machin_truck.png")
	modApi:appendAsset("img/units/mission/machin_truck_a.png", mod.resourcePath .."img/units/mission/machin_truck_a.png")
	modApi:appendAsset("img/units/mission/machin_truck_ns.png", mod.resourcePath .."img/units/mission/machin_truck_ns.png")
	modApi:appendAsset("img/units/mission/machin_truck_d.png", mod.resourcePath .."img/units/mission/machin_truck_d.png")
	modApi:appendAsset("img/weapons/machin_hyperfuel_icon.png", mod.resourcePath.. "img/weapons/machin_hyperfuel_icon.png")
	modApi:appendAsset("img/effects/machin_fuelpush_U.png", mod.resourcePath.. "img/effects/machin_fuelpush_U.png")
	modApi:appendAsset("img/effects/machin_fuelpush_D.png", mod.resourcePath.. "img/effects/machin_fuelpush_D.png")
	modApi:appendAsset("img/effects/machin_fuelpush_L.png", mod.resourcePath.. "img/effects/machin_fuelpush_L.png")
	modApi:appendAsset("img/effects/machin_fuelpush_R.png", mod.resourcePath.. "img/effects/machin_fuelpush_R.png")
	
	local a = ANIMS
	a.Machin_Truck = a.BaseUnit:new{Image = "units/mission/machin_truck.png", PosX = -17, PosY = 2}
	a.Machin_Trucka = a.Machin_Truck:new{Image = "units/mission/machin_truck_a.png", PosX = -17, PosY = 2, NumFrames = 2, Time = 0.4, Loop = true }
	a.Machin_Truckd = a.Machin_Truck:new{Image = "units/mission/machin_truck_d.png", PosX = -17, PosY = 12, NumFrames = 1, Time = 1.5, Loop = false }
	a.Machin_Truck_ns = a.Machin_Truck:new{Image = "units/mission/machin_truck_ns.png", PosX = -17, PosY = 2}
	
	a.machin_fuelpush_0 = Animation:new{
	Image = "effects/machin_fuelpush_U.png",
	NumFrames = 8,
	Time = 0.06,
	PosX = -10,
	PosY = -4
	}

	a.machin_fuelpush_1 = a.machin_fuelpush_0:new{
		Image = "effects/machin_fuelpush_R.png",
		PosX = -10,
		PosY = 11
	}

	a.machin_fuelpush_2 = a.machin_fuelpush_0:new{
		Image = "effects/machin_fuelpush_D.png",
		PosX = -30,
		PosY = 11
	}

	a.machin_fuelpush_3 = a.machin_fuelpush_0:new{
		Image = "effects/machin_fuelpush_L.png",
		PosX = -30,
		PosY = -4
	}
	
	
	modApi:appendAsset("img/units/mission/machin_laser_array.png", mod.resourcePath .."img/units/mission/machin_laser_array.png")
	modApi:appendAsset("img/units/mission/machin_laser_array_a.png", mod.resourcePath .."img/units/mission/machin_laser_array_a.png")
	modApi:appendAsset("img/units/mission/machin_laser_array_ns.png", mod.resourcePath .."img/units/mission/machin_laser_array_ns.png")
	modApi:appendAsset("img/units/mission/machin_laser_array_broken.png", mod.resourcePath .."img/units/mission/machin_laser_array_broken.png")
	modApi:appendAsset("img/units/mission/machin_laser_array_off.png", mod.resourcePath .."img/units/mission/machin_laser_array_off.png")
	modApi:appendAsset("img/units/mission/machin_laser_array_w.png", mod.resourcePath .."img/units/mission/machin_laser_array_w.png")
	modApi:appendAsset("img/units/mission/machin_laser_array_broken_w.png", mod.resourcePath .."img/units/mission/machin_laser_array_broken_w.png")
	modApi:appendAsset("img/units/mission/machin_laser_array_off_w.png", mod.resourcePath .."img/units/mission/machin_laser_array_off_w.png")
		
	local a = ANIMS
	a.Machin_Laser_Array = a.BaseUnit:new{Image = "units/mission/machin_laser_array.png", PosX = -17, PosY = -10}
	a.Machin_Laser_Arraya = a.Machin_Laser_Array:new{Image = "units/mission/machin_laser_array_a.png", PosX = -17, PosY = -10, NumFrames = 4, Time = 0.4, Loop = true }
	a.Machin_Laser_Array_ns = a.Machin_Laser_Array:new{Image = "units/mission/machin_laser_array_ns.png", PosX = -17, PosY = -10 }
	a.Machin_Laser_Array_broken = a.Machin_Laser_Array:new{Image = "units/mission/machin_laser_array_broken.png", PosX = -17, PosY = -10 }
	a.Machin_Laser_Arrayoff = a.Machin_Laser_Array:new{Image = "units/mission/machin_laser_array_off.png", PosX = -17, PosY = -10 }
	a.Machin_Laser_Arrayw = a.BaseUnit:new{Image = "units/mission/machin_laser_array_w.png", PosX = -17, PosY = -10}
	a.Machin_Laser_Arrayw_broken = a.Machin_Laser_Array:new{Image = "units/mission/machin_laser_array_broken_w.png", PosX = -17, PosY = -10 }
	a.Machin_Laser_Arraywoff = a.Machin_Laser_Array:new{Image = "units/mission/machin_laser_array_off_w.png", PosX = -17, PosY = -10 }

	for i = 0, 3 do
		modApi:addMap(mod.resourcePath .."maps/machin_hyperfuel".. i ..".map")
	end
		--TILE_TOOLTIPS.machin_mission_tile_drop_zone = {"Drop Zone", "One of your bonus objectives is to bring the Hyperfuel Truck to this tile."}
end

function this:load(mod, options, version)
	self.modApiExt = require(mod.scriptPath .."modApiExt/modApiExt")
	
	self.modApiExt:addPawnKilledHook(function(mission, pawn)
		-- maybe dead trucks should drop some weird hazard?--
	end)
	
	corpMissions.Add_Missions_Low("Mission_Machin_Hyperfuel", "Corp_Factory")
end

return this