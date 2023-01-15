local path = mod_loader.mods[modApi.currentMod].scriptPath
local this = {id = "Mission_Machin_Radio"}
local corpMissions = require(path .."corpMissions")
local switch = require(path .."switch")

local function IsTipImage()
	return Board:GetSize() == Point(6, 6)
end

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

Mission_Machin_Radio = Mission_Infinite:new{
--At this point, self is the table defining the whole mission type
	Name = "Radio Readings",--used in hook check
	--Objectives = objAfterMission:case(2),
	Objectives = { Objective("Stand in the Radio Zone for 3 turns",1), Objective("Protect both Radio Beacons", 1),  }, 
	MapTags = {"machin_radio"},
	Criticals = nil,
	Powered = { true, true},
	TurnLimit = 4,
	BonusPool = {},
	UseBonus = false,
}

function Mission_Machin_Radio:StartMission()
	--At this point, self is the table for the ACTUAL instance of mission; the GetCurrentMission() one that resets on Turn Reset; so I don't need a GetCurrentMission() check here, and it fails anyway
	
	self.machin_tower_active = { false, false}
	--self.machin_goal_zone_amount = 8 --Not used yet, amount is hardcoded for now
	self.machin_icon_anim = { 0,0,0,0,0,0,0,0 } --Should make equal to goalZoneAmount
	self.machin_radio_turns = 0
	self.machin_radio_turns_goal = 3
	self.machin_zone_is_occupied = false
	
	self.Criticals = {}
	for i = 1,2 do	
		local pawn = PAWN_FACTORY:CreatePawn("Machin_mission_radio_unit")
		table.insert(self.Criticals, pawn:GetId())
		Board:AddPawn(pawn, "machin_radio_working_zone")--"tosx_zapper"..i.."_zone")
		pawn:SetPowered(false)
	end

		--local wire = Board:GetZone("machin_radio_goal_zone"):index(1)--tosx_zapwire"..i.."_zone"):index(1)
		--Board:BlockSpawn(wire, BLOCKED_PERM)
		--if Board:GetCustomTile(wire) == "tosx_mission_cableVbreak.png" then --vertical arc
			--Board:AddAnimation(wire, "machin_radio_anim_on", ANIM_NO_DELAY)
		--else --horizontal arc
			--Board:AddAnimation(wire, "tosx_zaparcHs", ANIM_NO_DELAY)
		--end
	--end	
end

function Mission_Machin_Radio:NextTurn()
	local mission = GetCurrentMission()
	if not mission then return end
	
	if Game:GetTeamTurn() == TEAM_ENEMY then
		for i = 1,2 do
			mission.machin_tower_active[i] = false
		end		
	end
	if Game:GetTeamTurn() == TEAM_PLAYER then
		for i = 1,2 do
			mission.machin_tower_active[i] = true
		end		
	end
end
	
function Mission_Machin_Radio:UpdateMission() --!!! will this update every move?
	local mission = GetCurrentMission()
	if not mission then return end
	
	local zoneTiles = extract_table(Board:GetZone("machin_radio_goal_zone"))
	for i, p in ipairs(zoneTiles) do
		Board:MarkSpaceDesc(p, "machin_mission_zone_info")
	end
		
	--Stepping on/off animation, powering up/down
	if Board:GetBusyState() == 0 then
			local zoneTiles = extract_table(Board:GetZone("machin_radio_goal_zone"))
			mission.machin_zone_is_occupied = false
			--LOG("Tiles in zone: ", #zoneTiles)
			for i, p in ipairs(zoneTiles) do
				if not (p == nil) then --Might not be necessary anymore
					if Board:IsPawnSpace(p) then
						if Board:GetPawn(p):GetTeam() == TEAM_PLAYER then
							mission.machin_zone_is_occupied = true
							if mission.machin_icon_anim[i] == 0 then
								--Board:AddAnimation(p, "machin_radio_anim_on", ANIM_NO_DELAY)
								--mission.machin_icon_anim[i] = true
							end
						else
							--mission.machin_icon_anim[i] = 0
							--Board:AddAnimation(p, nil, ANIM_NO_DELAY)
						end
					else
						mission.machin_icon_anim[i] = 0
					end
				end
			end
			
			for i = 1, 2 do
				local pawn = Board:GetPawn(self.Criticals[i])
				if pawn and not pawn:IsDead() then--and pawn:GetSpace() == Board:GetZone("machin_radio_working_zone") then--:index(1) then
					--No reason for the "radio towers" to move out their zone, is there?
					--point =  Board:GetZone("machin_radio_goal_zone"):index(1)
					if mission.machin_zone_is_occupied and not self.Powered[i] then
						pawn:SetPowered(true)
						self.Powered[i] = true
						-- Depowered pawns don't get set to active each team turn
						-- So I have to manually activate them, but I need to know if they've fired yet this turn
						-- (since I don't want to reactivate them if they get power again after firing)
						-- So the cannon weapons set flags that are cleared between turns
						if mission.machin_tower_active[i] then
							pawn:SetActive(true)
						else
							pawn:SetActive(false)
						end			
						local effect = SkillEffect()
						--local damage = SpaceDamage(point,0)
						--if Board:GetCustomTile(point) == "tosx_mission_cableVbreak.png" then --vertical arc
							--damage.sAnimation = "tosx_zaparcV"
						--else --horizontal arc
							--damage.sAnimation = "tosx_zaparcH"
						--end
						--effect:AddDamage(damage)
						local chance = math.random()
						if chance > 0.2 then
							effect:AddVoice("Mission_Machin_Radio_On", -1)--!!! ruled dialog low%?
						end
						Board:AddEffect(effect)
					elseif self.Powered[i] and not mission.machin_zone_is_occupied then
						pawn:SetPowered(false)
						self.Powered[i] = false
					end
				else
					self.Powered[i] = false
				end
			end
		end
	--make specific, variable-sized wire regions to check for unbroken road terrain?
end


function Mission_Machin_Radio:UpdateObjectives()
	local radio_alive = countAlive(self.Criticals)

	if self.machin_radio_turns >= self.machin_radio_turns_goal then
		Game:AddObjective("Stand in the Radio Zone (".. tostring(self.machin_radio_turns) .."/".. tostring(self.machin_radio_turns_goal) .." turns)", OBJ_COMPLETE, REWARD_REP, 1)
	else
		Game:AddObjective("Stand in the Radio Zone (".. tostring(self.machin_radio_turns) .."/".. tostring(self.machin_radio_turns_goal) .." turns)", OBJ_STANDARD, REWARD_REP, 1)
	end
	
	if radio_alive == 2 then
		Game:AddObjective("Protect both Radio Beacons", OBJ_STANDARD, REWARD_REP, 1)
	else
		Game:AddObjective("Protect both Radio Beacons", OBJ_FAILED, REWARD_REP, 1)
	end
end

function Mission_Machin_Radio:GetCompletedObjectives()
	local ret = copy_table(self.Objectives)
	local radio_alive = countAlive(self.Criticals)
	
	if self.machin_radio_turns < self.machin_radio_turns_goal then
		ret[1] = ret[1]:Failed()
	end
	
	if radio_alive < 2 then
		ret[2] = ret[2]:Failed()
	end
	
	return ret
end

Machin_mission_radio_unit = Pawn:new{
	Name = "Radio Beacon",
	Health = 2,
	Image = "machin_radio_beacon",
	MoveSpeed = 0,
	Neutral = true,--Don't show up in player unit list
	--SkillList = { "Machin_mission_radio_unitAtk" },
	DefaultTeam = TEAM_PLAYER,
	IgnoreSmoke = true,
	SoundLocation = "/support/civilian_truck/",
	Pushable = false,
	Corporate = true,
}

Machin_mission_radio_unitAtk = Skill:new{
	Name = "Discharge",
	Description = "Generate lightning to damage a target.",
	Damage = 2,
	Range = 15,
	Class = "Unique",
	--Icon = "weapons/tosx_zapper_bolt.png",
	LaunchSound = "/support/civilian_truck/move",
	TipImage = {
		Unit = Point(2,3),
		Enemy = Point(1,1),
		Target = Point(1,1),
		CustomPawn = "Machin_mission_radio_unit"
	}
}
function Mission_Machin_Radio:Deactivate(i)
	local mission = GetCurrentMission()
	if not mission then return end
	
	mission.machin_tower_active[i] = false
end


function this:init(mod)
	modApi:appendAsset("img/combat/tiles_grass/machin_mission_radio_zone.png", mod.resourcePath .."img/tileset/machin_mission_radio_zone.png")
	modApi:appendAsset("img/units/mission/machin_radio_tower.png", mod.resourcePath .."img/units/mission/machin_radio_tower.png")
	modApi:appendAsset("img/units/mission/machin_radio_tower_a.png", mod.resourcePath .."img/units/mission/machin_radio_tower_a.png")
	modApi:appendAsset("img/units/mission/machin_radio_tower_d.png", mod.resourcePath .."img/units/mission/machin_radio_tower_d.png")
	modApi:appendAsset("img/units/mission/machin_radio_tower_ns.png", mod.resourcePath .."img/units/mission/machin_radio_tower_ns.png")
	modApi:appendAsset("img/units/mission/machin_radio_tower_off.png", mod.resourcePath .."img/units/mission/machin_radio_tower_off.png")
	--modApi:appendAsset("img/effects/tosx_zaparc_V.png", mod.resourcePath .."img/effects/tosx_zaparc_V.png")
	--modApi:appendAsset("img/effects/tosx_zaparc_H.png", mod.resourcePath .."img/effects/tosx_zaparc_H.png")
	modApi:appendAsset("img/effects/machin_radio_anim_on.png", mod.resourcePath .."img/effects/machin_radio_anim_on.png")
	modApi:appendAsset("img/effects/machin_radio_anim_off.png", mod.resourcePath .."img/effects/machin_radio_anim_off.png")
	--modApi:appendAsset("img/effects/tosx_zap_bolt.png", mod.resourcePath .."img/effects/tosx_zap_bolt.png")
	--modApi:appendAsset("img/weapons/tosx_zapper_bolt.png", mod.resourcePath.. "img/weapons/tosx_zapper_bolt.png")
	
	local a = ANIMS
	a.machin_radio_beacon = a.generator1:new{Image = "units/mission/machin_radio_tower.png", PosX = -18, PosY = -26, NumFrames = 1}
	a.machin_radio_beaconoff = a.machin_radio_beacon:new{Image = "units/mission/machin_radio_tower_off.png"}
	a.machin_radio_beacond = a.machin_radio_beacon:new{Image = "units/mission/machin_radio_tower_d.png", PosX = -20, PosY = -26, Time = 0.2, NumFrames = 12, Loop = false}
	a.machin_radio_beacona = a.machin_radio_beacon:new{Image = "units/mission/machin_radio_tower_a.png", NumFrames = 4, Time = 0.25, Loop = true}
	a.machin_radio_beacon_ns = a.machin_radio_beacon:new{Image = "units/mission/machin_radio_tower_ns.png"}
	
	--Little wifi icons that will appear when a mech is in the radio zone
	--Currently unimplemented
	a.machin_radio_anim_on = a.BaseUnit:new{Image = "effects/machin_radio_anim_on.png", PosX = 0, PosY = 0, NumFrames = 3, Time = 1, Loop = true}
	a.machin_radio_anim_off = a.BaseUnit:new{Image = "effects/machin_radio_anim_off.png", PosX = 0, PosY = 0, NumFrames = 2, Time = 1.5, Loop = true}

	--a.tosx_zaparcV = a.BaseUnit:new{Image = "effects/tosx_zaparc_V.png", PosX = -37, PosY = -19, NumFrames = 4, Time = 0.1, Loop = false}
	--a.tosx_zaparcH = a.tosx_zaparcV:new{Image = "effects/tosx_zaparc_H.png"}
	
	--a.tosx_zap_bolt = a.BaseUnit:new{Image = "effects/tosx_zap_bolt.png", PosX = -14, PosY = -90, NumFrames = 1, Time = 0.25, Loop = false}
	
	for i = 0, 3 do
		modApi:addMap(mod.resourcePath .."maps/machin_radio".. i ..".map")
	end
	
	TILE_TOOLTIPS.machin_mission_zone_info = {"Radio Zone", "Your bonus objective is to end your turns with one of your units occupying one of these tiles."}
end

function this:load(mod, options, version)
	local hook = function(mission)
		--LOG(tostring(mission.id))
		--LOG(tostring(GetCurrentMission()))
		if mission.Name == "Radio Readings" then --GetCurrentMission() == "Mission_Machin_Radio" doesn't seem to work, but this'll do
			if mission.machin_zone_is_occupied == true then
				--LOG("Zone occupied!")
					if tonumber(Board:GetTurn()) > 0 then --Don't count mechs as "spending a turn in the zone" right after deploying
						mission.machin_radio_turns = mission.machin_radio_turns+1
						--LOG("turn:")
						--LOG(tostring(Board:GetTurn()))
					end
			else
				--LOG("Zone not occupied!")
			end
		else
			--LOG("Not in radio mission right now")
		end
	end
	modApi:addPreEnvironmentHook(hook)	
		
	corpMissions.Add_Missions_Low("Mission_Machin_Radio", "Corp_Desert")
end

return this