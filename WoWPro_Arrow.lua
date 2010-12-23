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


WoWPro_Arrow = LibStub("AceAddon-3.0"):NewAddon("Arrow")
local mapdata = LibStub("LibMapData-1.0")
local callbacks = LibStub("CallbackHandler-1.0"):New(WoWPro_Arrow)

local wp_defaults = {
["cleararrival"] = true,
["arrivaldistance"] = 10,
["autosetarrow"] = true,
["icon"] = nil,
["distMsgs"] = nil,
}

--localized continent names
local continentNames = {GetMapContinents()}

local waypoints = {}

local arrowWaypoint

local locale = GetLocale()

local allZoneIDs = mapdata:GetAllMapIDs()

local localeZones

local enUSZones = {
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

local function IsValidZoneID(id)
	for _,zoneid in pairs(allZoneIDs) do
		if id == zoneid then
			return true
		end
	end
	return false
end

local function CreateLocaleZones()
	if locale == "enUS" then
		return nil
	else
		local tbl = {}
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
		
		local mt = {}
		mt.__index = tbl
		setmetatable(enUSZones, tbl)
		return tbl
	end
end

function WoWPro_Arrow:SetArrowToWaypoint(wpID)
-- test first
	arrowWaypoint = wpID
	self.arrow:Show()
end

--simple
-- TODO: support label text
function WoWPro_Arrow:AddWaypoint(x, y, zone, floor)
	return WoWPro_Arrow:AddWaypointOpt(x, y, zone, floor)
end

-- with options
function WoWPro_Arrow:AddWaypointOpt(x, y, zone, floor, opt)
	if type(tonumber(x)) ~= "number" or type(tonumber(y)) ~= "number" then
		print("Invalid coordinate(s)")
		return nil
	end
	
	local zoneid = nil
	if zone then
		if type(zone) == "string" then
			-- look-up in the English table first (more stable), with the locale fallback
			zoneid = enUSZones[zone]
			if not zoneid then
				-- look-up if it's a zone filename
				zoneid = mapdata:MapAreaId(zone)
			end
		elseif type(zone) == "number" then
			-- check to see if it's a zone id
			if IsValidZoneID(zone) then
				zoneid = zone
			end
		end
		
		-- input zone is not valid, trying to use current
		if not zoneid then
			print("Warning: Invalid input zone")
			zoneid = GetCurrentMapAreaID()
		end
	-- if zone is not given, try to use current
	else
		print("Warning: Invalid input zone")
		zoneid = GetCurrentMapAreaID()
	end
	
	zoneid = tonumber(zoneid)
	
	-- if, after all that, zoneid still invalid, return nil
	if not IsValidZoneID(zoneid) then
		print("Fail, can't find the zone")
		return nil
	end
	
	--floor tests
	local validFloor = 0
	local numFloors = mapdata:MapFloors(zoneid)
	if floor then
		if (type(tonumber(floor)) ~= "number") or (tonumber(floor) >= numFloors) then
			print("Warning: Invalid floor, using '0'")
		else
			validFloor = tonumber(floor)
		end
	end
	
	-- deal with opt later
	local opt = opt or wp_defaults
	
	-- saving waypoint as and in a table
	local waypoint = {x, y, zoneid, validFloor, opt}
	local wpID = tonumber(zoneid..(mapdata:EncodeLoc(x, y, validFloor)))
	
	if waypoints[wpID] then
		-- there's a waypoint in that location; override?
		print("Warning: there was a waypoint in that location; overridind")
	end
	
	waypoints[wpID] = waypoint
	WoWPro_Arrow:SetArrowToWaypoint(wpID)
	
	callbacks:Fire("WAYPOINT_ADDED", wpID, x, y, zone, floor, opt)

	return wpID
end

-- return x,y,zone,floor,opt
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

function WoWPro_Arrow:GetAllWaypoints()
	return waypoints
end

-- see if the arrow is poiting for this waypoint
-- if called with no parameter, return waypointID
local function IsArrowSet(wpID)
	if wpID and arrowWaypoint then
		return (wpID == arrowWaypoint)
	else
		return arrowWaypoint
	end
end

local function ClearArrow()
	if IsArrowSet() then
		arrowWaypoint = nil
	end
	-- Hide arrow
	-- or try to acquire a new waypoint if auto is set
end

function WoWPro_Arrow:RemoveWaypoint(wpID)
	if IsArrowSet(wpID) then
		ClearArrow()
	end

	if not wpID or not waypoints[wpID] then
		return false
	else
		waypoints[wpID] = nil
		-- clear from minimap and worldmap
		return true
	end
end

function WoWPro_Arrow:RemoveAllWaypoints()
	for wpID,_ in pairs(waypoints) do
		WoWPro_Arrow:RemoveWaypoint(wpID)
	end
end
		

function WoWPro_Arrow:ClearWaypoint(wpID)
	local x, y, zone, floor, opt = WoWPro_Arrow:GetWaypoint(wpID)
	local event = WoWPro_Arrow:RemoveWaypoint(wpID)
	if event then
		callbacks:Fire("WAYPOINT_CLEARED", wpID, x, y, zone, floor, opt)
	end
	return event
end

local function Box_OnDragStart(self, button, down)
	self:StartMoving()
end

local function Box_OnDragStop(self, button, down)
	self:StopMovingOrSizing()
end

local function CreateBox(stringname)
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

local function MapID_OnUpdate(self, elapsed)
	local mapid = GetCurrentMapAreaID()
	if not mapid then
		self.Text:SetText("id: nil")
	else
		mapid = tostring(mapid)
		self.Text:SetFormattedText("%s %d", "id: ", mapid)
	end
	self.Text:Show()
end

local function MapFileName_OnUpdate(self, elapsed)
	local filename = GetMapInfo()
	if not filename then
		self.Text:SetText("filename: nil")
	else
		filename = tostring(filename)
		self.Text:SetFormattedText("%s %s", "zone: ", filename)
	end
	self.Text:Show()
end

local function MapLocalName_OnUpdate(self, elapsed)
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

local function MapLocal2Name_OnUpdate(self, elapsed)
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

local function CreateCrazyArrow(name, parent)
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

    frame:Hide()

    local PI2 = math.pi * 2

    -- Set up the OnUpdate handler
    frame:SetScript("OnUpdate", function(self, elapsed)
	
		if not arrowWaypoint then
			self:Hide()
			return
		end
	
        -- Get the current location
        local cmap = GetCurrentMapAreaID()
        local cx, cy = GetPlayerMapPosition("player")
		local ccontinent = continentNames[mapdata:GetContinentFromMap(cmap)]
        local x, y, zone, floor, opt = WoWPro_Arrow:GetWaypoint(arrowWaypoint)
		local continent = continentNames[mapdata:GetContinentFromMap(zone)]
		
		if (continent ~= ccontinent) then
			self.arrow:SetVertexColor(1,1,1,0.5)
			self.subtitle:SetFormattedText("Go to continent %s", continent)
		else
		
			local distance, xd, yd = mapdata:DistanceWithinContinent(cmap, 0, cx, cy, zone, floor, x, y)

			local angle = math.atan2(xd, yd)
			if angle > 0 then
				angle = PI2 - angle
			else
				angle = -angle
			end

			local facing = GetPlayerFacing()
			local faceangle = angle - facing

			local perc = math.abs((math.pi - math.abs(faceangle)) / math.pi)
			local gr,gg,gb = 0,1,0
			local mr,mg,mb = 1,0,0
			local br,bg,bb = 1,1,0
			local r,g,b = ColorGradient(perc, br, bg, bb, mr, mg, mb, gr, gg, gb)
			
		    self.arrow:SetVertexColor(r,g,b)
			self.arrow:SetRotation(faceangle)

			self.subtitle:SetFormattedText("%.1f yards", distance)
		end
    end)

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

function WoWPro_Arrow:OnInitialize()
	self.frameMapID = CreateBox("frameMapID")
	self.frameMapID:SetScript("OnUpdate", MapID_OnUpdate)
	self.frameMapFileName = CreateBox("frameMapFileName")
	self.frameMapFileName:SetScript("OnUpdate", MapFileName_OnUpdate)
	self.frameMapLocalName = CreateBox("frameMapLocalName")
	self.frameMapLocalName:SetScript("OnUpdate", MapLocalName_OnUpdate)
	self.frameMapLocal2Name = CreateBox("frameMapLocal2Name")
	self.frameMapLocal2Name:SetScript("OnUpdate", MapLocal2Name_OnUpdate)
	self.arrow = CreateCrazyArrow("WoWProArrow")
    self.arrow:SetPoint("CENTER", 0, 0)
    self.arrow:Hide()
end

-- local function CreateLocalZonesTable(self)
	-- local tbl = {}
	-- local mapIDs = mapdata:GetAllMapIDs()
		-- for i,mapid in ipairs(mapIDs) do
			-- local localzone = mapdata:MapLocalize(mapid)
			-- tbl[localzone] = tostring(mapid)
		-- -- if mapid ~= 751 and mapid ~= 539 and mapid ~= 542 then
			-- -- if mapid == 770 then
				-- -- localzone = "Twilight Highlands (phased1)"
			-- -- else
				-- -- localzone = mapdata:MapLocalize(mapid)
				-- -- if localzone == "Gilneas2" then
					-- -- if mapid == 611 then
						-- -- localzone = "Gilneas City"
					-- -- elseif mapid == 678 then
						-- -- localzone = "Gilneas (Phased1)"
					-- -- elseif mapid == 545 then
						-- -- localzone = "Gilneas"
					-- -- elseif mapid == 679 then
						-- -- localzone = "Gilneas (Phased2)"
					-- -- end
				-- -- elseif localzone == "Kalimdor" then
					-- -- if mapid == 683 then
						-- -- localzone = "Hyjal (Phased1)"
					-- -- elseif mapid == 748 then
						-- -- localzone = "Uldum (Phased1)"
					-- -- end
				-- -- elseif localzone == "LostIsles" then
					-- -- if mapid == 681 then
						-- -- localzone = "The Lost Isles (Phased1)"
					-- -- elseif mapid == 682 then
						-- -- localzone = "The Lost Isles (Phased2)"
					-- -- end
				-- -- end
			-- -- end
			-- -- tbl[localzone] = tostring(mapid)
		-- -- end
	-- end
	-- return tbl
-- end

function WoWPro_Arrow:TestCallback(self, map,floor,w,h)
	callbacks:Fire("ArrowMapChanged", map, floor)
	print("MapChanged: ", map, floor)
end

function WoWPro_Arrow:OnEnable()
	WoWPro_ArrowDB = {}
	--WoWPro_ArrowDB.localzones = CreateLocalZonesTable(self)
	-- mapdata.RegisterCallback(self, "MapChanged", "TestCallback")
	-- WoWProArrow.RegisterCallback(self, "ArrowMapChanged", "TestCallbackArrow")
end