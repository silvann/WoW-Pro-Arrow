-------------------------------
--      WoWPro_Arrow      --
-------------------------------

-- IMPORTANT: mapid, from the local tables, are STRING

-- Hacks
	-- Remove 751
	-- "Eastern Kingdoms", twice, 770 == Twilight Highlands_terrain1, 14 == certo
	-- Gilneas 539, wrong
	-- and various Gilneas2, 611 == Gilneas City, 678 == "Gilneas_terrain1", 545 == "Gilneas", 679 == "Gilneas_terrain2"
	-- 3 kalindor, 13 == certo, 683 == "Hyjal_terrain1", 748 == Uldum_terrain1
	-- 2 LostIsles, also "The Lost Isles", 681 == TheLostIsles_terrain1, 682 == TheLostIsles_terrain2, 544 == "TheLostIsles", The Lost Isles
	-- 2 "Trial of the Champion", 542 == "TheArgentColiseum", 543 == "TheArgentColiseum" (2 floors, right?)

-- Messages fired
	-- WAYPOINT_ADDED (wpID, x, y, zone, floor, opt)
	-- WAYPOINT_CLEARED (wpID, x, y, zone, floor, opt)
	-- WAYPOINT_DISTANCE (wpID, distance)
	-- WAYPOINT_ARRIVAL (wpID, distance)
	
-- TODO: support label text
-- TODO - tests:
-- see if GetCurrentMapAreaID changes x,y if worlmap changes (I think so)
--- if so, see if you can overcome that by using SetMapToCurrent quickly
-- see eventtrace when browsing world map, if the changedmap triggers

----------
-- Libs --
WoWPro_Arrow = LibStub("AceAddon-3.0"):NewAddon("Arrow")
local mapdata = LibStub("LibMapData-1.0")
local callbacks = LibStub("CallbackHandler-1.0"):New(WoWPro_Arrow)
----------

--------------------------
-- local lua/Blizz APIs --
local twipe, type = wipe, type
local GetPlayerFacing, GetPlayerMapPosition = GetPlayerFacing, GetPlayerMapPosition
local SetMapToCurrentZone, GetCurrentMapAreaID = SetMapToCurrentZone, GetCurrentMapAreaID
local GetCurrentMapDungeonLevel = GetCurrentMapDungeonLevel
local PI = math.pi
local PI2 = math.pi * 2
local atan2, abs = math.atan2, math.abs
--------------------------

---------------------------------
-- local function declarations --
local SetArrowToWaypoint, AddWaypoint, IsArrowSet, ClearArrow
local RemoveWaypoint, ClearWaypoint, CreateCrazyArrow
local IsSameContinent, SetAutoArrow
local TestCoordsAdd, TestZoneAdd, TestFloorAdd
local TestSpecificOpt, TestOptAdd


-- tests, remove later
local Box_OnDragStart, Box_OnDragStop, CreateBox
local MapID_OnUpdate, MapLocal2Name_OnUpdate, MapLocalName_OnUpdate
local MapFileName_OnUpdate
---------------------------------

---------------
-- Constants --
local wpDefaults = { -- Waypoint default options
["cleararrival"] = true,
["arrivaldistance"] = 10,
["autosetarrow"] = true,
["autosetnear"] = true,
["icon"] = "Interface\\GossipFrame\\AvailableQuestIcon",
["distMsgs"] = {},
["label"] = "WoWPro_Arrow",
}
local continentNames = {GetMapContinents()} -- localized continent names
local locale = GetLocale() -- localization
local allZoneIDs = mapdata:GetAllMapIDs() -- Map IDs covered by lib
local enUSZones = { -- enUS/Default localized zones
	["Dire Maul"] = "699",
	["The Hinterlands"] = "26",
	["Icecrown Citadel"] = "604",
	["The Cape of Stranglethorn"] = "673",
	["Blackrock Spire"] = "721",
	["Hellfire Peninsula"] = "465",
	["Twilight Highlands (phased1)"] = "770",
	["Hrothgar's Landing"] = "541",
	["Arathi Highlands"] = "16",
	["Westfall"] = "39",
	["Isle of Conquest"] = "540",
	["Orgrimmar"] = "321",
	["Eastern Kingdoms"] = "14",
	["Undercity"] = "382",
	["Desolace"] = "101",
	["Warsong Gulch"] = "443",
	["Kalimdor"] = "13",
	["Ahn'kahet: The Old Kingdom"] = "522",
	["The Vortex Pinnacle"] = "769",
	["Darnassus"] = "381",
	["Azuremyst Isle"] = "464",
	["Gilneas"] = "545",
	["Ruins of Ahn'Qiraj"] = "717",
	["Ahn'Qiraj Temple"] = "766",
	["Blackwing Lair"] = "755",
	["Un'Goro Crater"] = "201",
	["The Lost Isles (Phased1)"] = "681",
	["Ironforge"] = "341",
	["Dalaran"] = "504",
	["Stormwind Stockade"] = "690",
	["Burning Steppes"] = "29",
	["Wetlands"] = "40",
	["Gilneas (Phased2)"] = "679",
	["Halls of Stone"] = "526",
	["Howling Fjord"] = "491",
	["Arathi Basin"] = "461",
	["Ruins of Gilneas City"] = "685",
	["Naxxramas"] = "535",
	["Darkshore"] = "42",
	["Loch Modan"] = "35",
	["Blade's Edge Mountains"] = "475",
	["Durotar"] = "4",
	["Silithus"] = "261",
	["Onyxia's Lair"] = "718",
	["The Lost Isles (Phased2)"] = "682",
	["Molten Core"] = "696",
	["Ashenvale"] = "43",
	["Violet Hold"] = "536",
	["Kelp'thar Forest"] = "610",
	["Blackfathom Deeps"] = "688",
	["Grim Batol"] = "757",
	["The Bastion of Twilight"] = "758",
	["Blackrock Depths"] = "704",
	["Nagrand"] = "477",
	["Wintergrasp"] = "501",
	["Shimmering Expanse"] = "615",
	["Terokkar Forest"] = "478",
	["Eversong Woods"] = "462",
	["Silvermoon City"] = "480",
	["Zangarmarsh"] = "467",
	["The Lost Isles"] = "544",
	["Ebon Hold"] = "502",
	["Zul'Gurub"] = "697",
	["Maraudon"] = "750",
	["Blackrock Caverns"] = "753",
	["The Forge of Souls"] = "601",
	["Tanaris"] = "161",
	["Stormwind City"] = "301",
	["Borean Tundra"] = "486",
	["Utgarde Pinnacle"] = "524",
	["Grizzly Hills"] = "490",
	["Hyjal (Phased1)"] = "683",
	["Northrend"] = "485",
	["Razorfen Downs"] = "760",
	["Swamp of Sorrows"] = "38",
	["Deepholm"] = "640",
	["Gilneas (Phased1)"] = "678",
	["The Culling of Stratholme"] = "521",
	["Abyssal Depths"] = "614",
	["Stranglethorn Vale"] = "689",
	["Halls of Reflection"] = "603",
	["Northern Barrens"] = "11",
	["Lost City of the Tol'vir"] = "747",
	["The Battle for Gilneas"] = "736",
	["Throne of the Four Winds"] = "773",
	["Blasted Lands"] = "19",
	["Elwynn Forest"] = "30",
	["Throne of the Tides"] = "767",
	["Mulgore"] = "9",
	["Isle of Quel'Danas"] = "499",
	["Felwood"] = "182",
	["Tol Barad Peninsula"] = "709",
	["The Nexus"] = "520",
	["Baradin Hold"] = "752",
	["Vashj'ir"] = "613",
	["Shadowfang Keep"] = "764",
	["The Exodar"] = "471",
	["Ahn'Qiraj: The Fallen Kingdom"] = "772",
	["The Battle for Gilneas (Old City Map)"] = "677",
	["Mount Hyjal"] = "606",
	["Silverpine Forest"] = "21",
	["Tol Barad"] = "708",
	["Dustwallow Marsh"] = "141",
	["Zul'Farrak"] = "686",
	["Deadwind Pass"] = "32",
	["Thunder Bluff"] = "362",
	["Alterac Valley"] = "401",
	["Uldum (Phased1)"] = "748",
	["Eye of the Storm"] = "482",
	["Bloodmyst Isle"] = "476",
	["Azjol-Nerub"] = "533",
	["Ulduar"] = "529",
	["Moonglade"] = "241",
	["Drak'Tharon Keep"] = "534",
	["Gilneas City"] = "611",
	["Outland"] = "466",
	["Ragefire Chasm"] = "680",
	["Stonetalon Mountains"] = "81",
	["Scarlet Monastery"] = "762",
	["The Ruby Sanctum"] = "609",
	["Southern Barrens"] = "607",
	["The Stonecore"] = "768",
	["Badlands"] = "17",
	["Dragonblight"] = "488",
	["Redridge Mountains"] = "36",
	["Shattrath City"] = "481",
	["The Eye of Eternity"] = "527",
	["Utgarde Keep"] = "523",
	["Ruins of Gilneas"] = "684",
	["Zul'Drak"] = "496",
}
---------------

------------------------
-- "global" variables --
local waypoints = {}
local arrowWaypoint
local localeZones
local currentZoneID
local currentFloor
local currentContinent
local waypointsOrder = {}
------------------------

-----------------
-- Public APIs --
-----------------

-- simple add waypoint
function WoWPro_Arrow:AddWaypoint(x, y, zone, floor)
	return AddWaypoint(x, y, zone, floor, nil)
end

-- or add with options table
function WoWPro_Arrow:AddWaypointOpt(x, y, zone, floor, opt)
	return AddWaypoint(x, y, zone, floor, opt)
end

-- Set arrow to an existent waypoint
function WoWPro_Arrow:SetArrowToWaypoint(wpID)
	return SetArrowToWaypoint(wpID)
end

-- get waypoint info (x,y,zone,floor,opt), given wpID
function WoWPro_Arrow:GetWaypoint(wpID)
	if not wpID then
		return nil
	end
	
	local waypoint = waypoints[wpID]
	
	if waypoint then
		return unpack(waypoint)
	else
		return nil
	end
end

-- get all waypoints, as a table, indexed by wpID
function WoWPro_Arrow:GetAllWaypoints()
	return waypoints
end

-- remove waypoint (will not trigger msg)
function WoWPro_Arrow:RemoveWaypoint(wpID)
	return RemoveWaypoint(wpID)
end

-- remove all waypoints
function WoWPro_Arrow:RemoveAllWaypoints()
	for wpID,_ in pairs(waypoints) do
		RemoveWaypoint(wpID)
	end
end

-- set a options for a waypoint dinamically, after creation
function WoWPro_Arrow:SetWaypointOpt(wpID, opt, ...)
	if not wpID or not waypoints[wpID] or not opt then
		print("Invalid Waypoint")
		return nil
	end
	
	local validOpt = ...
	local optOrig = waypoints[wpID][5]
	
	if type(opt) == "table" then
		for k,v in pairs(opt) do
			validOpt = TestSpecificOpt(k, v)
			if validOpt ~= nil then
				optOrig.k = validOpt
			end
		end
		return true
	end
	
	if type(opt) == "string" and validOpt ~= nil then 
		validOpt = TestSpecificOpt(opt, validOpt)
		if validOpt ~= nil then
			optOrig.opt = validOpt
			return true
		end
	end
	return nil
end

-- name says it all. Only works for waypoints in the same continent
-- as current
function WoWPro_Arrow:GetNearestWaypoint()
	local distMin, wpidMin
	local cx, cy = GetPlayerMapPosition("player")
	for wpid,waypoint in pairs(waypoints) do
		local x, y, zoneid, floor = unpack(waypoint)
		local dist
		if IsSameContinent(zoneid, currentZoneID) then
			dist = mapdata:DistanceWithinContinent(currentZoneID, currentFloor, cx, cy, zoneid, floor, x, y)
			if not distMin or dist < distMin then
				distMin = dist
				wpidMin = wpid
			end
		end
	end
	return wpidMin
end

-- ending public APIs --
------------------------

--------------------
-- util functions --
--------------------

-- set color gradient given percentage
-- from TomTomLite
local function ColorGradient(perc, ...)
    local num = select("#", ...)
    local hexes = type(select(1, ...)) == "string"

    if perc == 1 then
        return select(num-2, ...), select(num-1, ...), select(num, ...)
    end

    num = num / 3

    local segment, relperc = math.modf(perc*(num-1))
    local r1, g1, b1, r2, g2, b2
    r1, g1, b1 = select((segment*3)+1, ...), select((segment*3)+2, ...), select((segment*3)+3, ...)
    r2, g2, b2 = select((segment*3)+4, ...), select((segment*3)+5, ...), select((segment*3)+6, ...)

    if not r2 or not g2 or not b2 then
        return r1, g1, b1
    else
        return r1 + (r2-r1)*relperc,
        g1 + (g2-g1)*relperc,
        b1 + (b2-b1)*relperc
    end
end

-- set alpha gradient given percentage
local function AlphaGradient(perc, goodAlpha, badAlpha)
	local goodAlpha = goodAlpha or 1.0
	local badAlpha = badAlpha or 0.2
	
	return ((goodAlpha-badAlpha)*perc + badAlpha)
end

-- check if a mapID is valid, according to the lib and some hacks
local function IsValidZoneID(id)
	for _,zoneid in pairs(allZoneIDs) do
		if id == zoneid and zoneid ~= 542  -- wrong TheArgentColiseum
						and zoneid ~= 751 then -- not real?
			return true
		end
	end
	return false
end

-- if localization is not enUS, build localized table, based on lib and hacks
-- also set fallback tables
local function CreateLocaleZones()
	local mt = {}
	local tbl = {}
	if locale == "enUS" then
		mt.__index = function(self, key)
			return mapdata:MapAreaId(key)
		end
	else
		mtlocale = {}
		for i,zoneid in ipairs(allZoneIDs) do
			local localzone
			if zoneid ~= 751 and zoneid ~= 539 then
				localzone = mapdata:MapLocalize(zoneid)
				tbl[localzone] = zoneid
			end
		end
		tbl["Gilneas"] = 545
		if locale == "esMX" then
			tbl["Ciudad de Gilneas"] = 611
		end
				
		mt.__index = function(self, key)
			return tbl[key]
		end
		mtlocal.__index = function(self, key)
			return mapdata:MapAreaId(key)
		end
		setmetatable(tbl, mtlocal)
	end
	setmetatable(enUSZones, mt)
	return tbl
end
--------------------

-----------------------------------------
-- local implementation, function, etc --
-----------------------------------------

function WoWPro_Arrow:OnInitialize()
	self.arrow = CreateCrazyArrow("WoWProArrow")
    self.arrow:SetPoint("CENTER", 0, 0)
    self.arrow:Hide()
	
	-- TESTS: remove later --
	self.frameMapID = CreateBox("frameMapID")
	self.frameMapID:SetScript("OnUpdate", MapID_OnUpdate)
	self.frameMapFileName = CreateBox("frameMapFileName")
	self.frameMapFileName:SetScript("OnUpdate", MapFileName_OnUpdate)
	self.frameMapLocalName = CreateBox("frameMapLocalName")
	self.frameMapLocalName:SetScript("OnUpdate", MapLocalName_OnUpdate)
	self.frameMapLocal2Name = CreateBox("frameMapLocal2Name")
	self.frameMapLocal2Name:SetScript("OnUpdate", MapLocal2Name_OnUpdate)
	-------------------------
	
end

function WoWPro_Arrow:OnEnable()
	CreateLocaleZones()
	mapdata.RegisterCallback(self, "MapChanged", "MapChangedCallback")
end

-- tentar fazer local depois
-- see map lib, if worlmap is open, msg isnt sent? no :(
function WoWPro_Arrow:MapChangedCallback(self, map, floor, ...)
	local worldMapZoneID = GetCurrentMapAreaID()
	SetMapToCurrentZone()
	currentZoneID = GetCurrentMapAreaID()
	currentContinent = mapdata:GetContinentFromMap(currentZoneID)
	currentFloor = GetCurrentMapDungeonLevel()
	-- restoring if worldmap is shown
	if WorldMapFrame:IsVisible() then
		SetMapByID(worldMapZoneID)
	end
	print(currentZoneID)
end

function SetArrowToWaypoint(wpID)
	-- TODO: falta mais coisas?
	if wpID and waypoints[wpID] then
		arrowWaypoint = wpID
		WoWPro_Arrow.arrow:Show()
		return true
	else
		return false
	end
end

function IsSameContinent(ZoneID1, ZoneID2)
	if ZoneID1 and ZoneID2 and IsValidZoneID(ZoneID1) and IsValidZoneID(ZoneID2) then
		return mapdata:GetContinentFromMap(ZoneID1) == mapdata:GetContinentFromMap(ZoneID2)
	else
		return false
	end
end

function SetAutoArrow()
	local wpIDNear = WoWPro_Arrow:GetNearestWaypoint()
	if wpIDNear then
		local opt = waypoints[wpIDNear][5]
		if opt.autosetarrow and opt.autosetnear then
			SetArrowToWaypoint(wpIDNear)
			return wpIDNear
		end
	end

	local opt
	for i,wpID in ipairs(waypointsOrder) do
		if wpID then
			opt = waypoints[wpID][5]
			if opt.autosetarrow then
				SetArrowToWaypoint(wpID)
				return wpID
			end
		end
	end
	return false
end

function TestCoordsAdd(x, y)
	--TODO: check also boundaries?
	-- using current if coords not provided or invalid
	if type(tonumber(x)) ~= "number" or type(tonumber(y)) ~= "number" then
		if x or y then
			print("Invalid coordinate(s), using current position")
		end
		return GetPlayerMapPosition("player")
	end
	return x, y
end

function TestZoneAdd(zone)
	local zoneid
	if zone then
		if type(zone) == "string" then
			-- look-up in the English table first (more stable), with the locale fallback
			-- and/or assuming it's a zone filename fallback
			zoneid = tonumber(enUSZones[zone])
		elseif type(zone) == "number" then
			-- check to see if it's a zone id
			zoneid = zone
		end
	else	
		-- if zone is not given, try to use current
		zoneid = currentZoneID
	end
	
	if IsValidZoneID(zoneid) then
		return zoneid
	else
		print("Fail, can't find the zone")
		return nil
	end
end

function TestFloorAdd(floor)
	local numFloors = mapdata:MapFloors(zoneid)
	if floor then
		if not numFloors or (type(tonumber(floor)) ~= "number") or (tonumber(floor) >= numFloors) then
			print("Warning: Invalid floor, using '0'")
			return 0
		else
			return tonumber(floor)
		end
	end
	return 0
end

function TestSpecificOpt(k, value)
	if value ~= nil then
		if (k == "cleararrival" or k == "autosetarrow" or k == "autosetnear") and type(value) == "boolean" then
			return value
		elseif k == "arrivaldistance" and type(value) == "number" and value > 0 then
			return value
		elseif k == "distMsgs" then
			if type(value) == "table" then
				-- copy just the array part and if distance is valid
				local tbl = {}
				for i,v in ipairs(value) do
					if type(v) == "number" and v > 0 then
						tinsert(tbl, v)
					end
				end
				return tbl
			elseif type(value) == "number" and value > 0 then
				return {value}
			end
		elseif (k == "label" or k == "icon") and type(value) == "string" then
			return value
		end
	end
	return nil
end

function TestOptAdd(opt)
	if not opt or type(opt) ~= "table" then
		return wpDefaults
	end

	for k,v in pairs(wpDefaults) do
		opt.k = TestSpecificOpt(opt.k) or v
	end
	return opt
end



function AddWaypoint(x, y, zone, floor, opt)
	print("And here")
	local x, y = TestCoordsAdd(x, y)
	local zoneid = TestZoneAdd(zone)
	if not x or not y or not zoneid then
		print("Fail, waypoint not added")
		return nil
	end
	local floor = TestFloorAdd(floor, zoneid)
	local opt = TestOptAdd(opt)
	
	-- saving waypoint as and in a table
	local waypoint = {x, y, zoneid, floor, opt}
	local wpID = tonumber(currentZoneID..(mapdata:EncodeLoc(x, y, 0)))
	
	if waypoints[wpID] then
		-- there's a waypoint in that location; override?
		print("Warning: there was a waypoint in that location; overridind")
	end
	
	waypoints[wpID] = waypoint
	table.insert(waypointsOrder, 1, wpID)
	
	print("Got here?")
	
	SetAutoArrow()
	
	callbacks:Fire("WAYPOINT_ADDED", wpID, x, y, zoneid, floor, opt)

	return wpID
end


-- see if the arrow is poiting for this waypoint
-- if called with no parameter, return waypointID
function IsArrowSet(wpID)
	if wpID and arrowWaypoint then
		return (wpID == arrowWaypoint)
	else
		return arrowWaypoint
	end
end

function ClearArrow()
	if IsArrowSet() then
		arrowWaypoint = nil
	end
	WoWPro_Arrow.arrow:Hide()
	-- Hide arrow
	-- or try to acquire a new waypoint if auto is set
end

function RemoveWaypoint(wpID)
	if IsArrowSet(wpID) then
		ClearArrow()
	end

	if not wpID or not waypoints[wpID] then
		return false
	else
		twipe(waypoints[wpID])
		-- clear from minimap and worldmap
		return true
	end
end

function ClearWaypoint(wpID)
	local x, y, zone, floor, opt = WoWPro_Arrow:GetWaypoint(wpID)
	local event = WoWPro_Arrow:RemoveWaypoint(wpID)
	if event then
		callbacks:Fire("WAYPOINT_CLEARED", wpID, x, y, zone, floor, opt)
	end
	return event
end

local function OnUpdateArrow(self, elapsed)

	-- Get the current position
	local cx, cy = GetPlayerMapPosition("player")
	-- if the player is in an instance without a map then hide
	if (cx == 0 and cy == 0) or not arrowWaypoint then
		self:Hide()
		return
	end
	local x, y, zone, floor, opt = WoWPro_Arrow:GetWaypoint(arrowWaypoint)
		
	local continent = mapdata:GetContinentFromMap(zone)
	
	self.title:SetFormattedText(opt.label)
	self.icon:SetTexture(opt.icon)
	
	if (continent ~= currentContinent) then
		self.arrow:SetVertexColor(1,1,1,0.5)
		self.arrow:SetRotation(0)
		self.subtitle:SetFormattedText("Go to continent %s", continentNames[continent])
	
	elseif (floor ~= currentFloor) then
		self.arrow:SetVertexColor(1,1,1,0.5)
		if floor > currentFloor then
			self.arrow:SetRotation(0)
		else
			self.arrow:SetRotation(180)
		end
		self.subtitle:SetFormattedText("Go to floor %d", floor)

	else	
		local distance, xd, yd = mapdata:DistanceWithinContinent(currentZoneID, currentFloor, cx, cy, zone, floor, x, y)

		local angle = atan2(xd, yd)
		if angle > 0 then
			angle = PI2 - angle
		else
			angle = -angle
		end

		local facing = GetPlayerFacing()
		local faceangle = angle - facing

		local perc = abs((PI - abs(faceangle)) / PI)
		local gr,gg,gb = 0,1,0
		local mr,mg,mb = 1,1,0
		local br,bg,bb = 1,0,0
		local r,g,b = ColorGradient(perc, br, bg, bb, mr, mg, mb, gr, gg, gb)
		
		local a = AlphaGradient(perc)
		
		self.arrow:SetVertexColor(gr,gg,gb,a)
		self.arrow:SetRotation(faceangle)

		self.subtitle:SetFormattedText("%.1f yards", distance)
	end
end

function CreateCrazyArrow(name, parent)
    parent = parent or UIParent
    local frame = CreateFrame("Button", name, parent)

    frame:SetSize(128, 128)
    frame.arrow = frame:CreateTexture("OVERLAY")
    frame.arrow:SetAllPoints()
    frame.arrow:SetTexture("Interface\\Addons\\WoWPro_Arrow\\images\\arrow-grey")

    frame.title = frame:CreateFontString("OVERLAY", name .. "Title", "GameFontHighlight")
    frame.info = frame:CreateFontString("OVERLAY", name .. "Info", "GameFontHighlight")
    frame.subtitle = frame:CreateFontString("OVERLAY", name .. "Subtitle", "GameFontHighlight")

    frame.title:SetPoint("TOP", frame, "BOTTOM", 0, 0)
    frame.info:SetPoint("TOP", frame.title, "BOTTOM", 0, 0)
    frame.subtitle:SetPoint("TOP", frame.info, "BOTTOM", 0, 0)
	
	frame.icon = frame:CreateTexture("OVERLAY")
	frame.icon:SetWidth(15)
	frame.icon:SetHeight(15)
	frame.icon:SetPoint("RIGHT", frame.title, "LEFT", -8, 0)

    frame:Hide()

    -- Set up the OnUpdate handler
    frame:SetScript("OnUpdate", OnUpdateArrow)

    -- Code to handle moving the frame
    frame:SetMovable(true)
	frame:SetUserPlaced(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        -- self:SetUserPlaced(false)
        self:StopMovingOrSizing()
    end)
    -- frame:SetScript("OnHide", frame:GetScript("OnDragStop"))
    -- self:RestorePosition(frame)

    return frame
end
-----------------------------------------





-- local TESTS function implementation, remove later!

function Box_OnDragStart(self, button, down)
	self:StartMoving()
end

function Box_OnDragStop(self, button, down)
	self:StopMovingOrSizing()
end

function CreateBox(stringname)
	local name = nil
	if stringname and type(stringname) == "string" then
		name = stringname
	end
	local frame = CreateFrame("Button", name, UIParent)
	
	frame:SetWidth(200)
	frame:SetHeight(32)
	frame:SetToplevel(1)
	frame:SetFrameStrata("LOW")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen()
	frame:RegisterForDrag("LeftButton")
	frame:RegisterForClicks("RightButtonUp")
	frame:SetPoint("TOP", Minimap, "BOTTOM", -100, -10)

	frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.Text:SetJustifyH("CENTER")
	frame.Text:SetPoint("CENTER", 0, 0)

	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	frame:SetBackdropColor(0,0,0,0.4)
	frame:SetBackdropBorderColor(1,0.8,0,0.8)

			-- Set behavior scripts
	-- frame:SetScript("OnUpdate", Box_OnUpdate)
	frame:SetScript("OnDragStop", Box_OnDragStop)
	frame:SetScript("OnDragStart", Box_OnDragStart)
		
	-- Show the frame
	frame:Show()
	
	return frame
end

function MapID_OnUpdate(self, elapsed)
	local mapid = GetCurrentMapAreaID()
	if not mapid then
		self.Text:SetText("id: nil")
	else
		mapid = tostring(mapid)
		self.Text:SetFormattedText("%s %d", "id: ", mapid)
	end
	self.Text:Show()
end

function MapFileName_OnUpdate(self, elapsed)
	local filename = GetMapInfo()
	if not filename then
		self.Text:SetText("filename: nil")
	else
		filename = tostring(filename)
		self.Text:SetFormattedText("%s %s", "zone: ", filename)
	end
	self.Text:Show()
end

function MapLocalName_OnUpdate(self, elapsed)
	local mapid = GetCurrentMapAreaID()
	local localname = mapdata:MapLocalize(mapid)
	if not localname then
		self.Text:SetText("localname: nil")
	else
		localname = tostring(localname)
		self.Text:SetFormattedText("%s %s", "local: ", localname)
	end
	self.Text:Show()
end

function MapLocal2Name_OnUpdate(self, elapsed)
	local mapid = GetCurrentMapAreaID()
	local localname = GetZoneText()
	if not localname then
		self.Text:SetText("localname: nil")
	else
		localname = tostring(localname)
		self.Text:SetFormattedText("%s %s", "local2: ", localname)
	end
	self.Text:Show()
end