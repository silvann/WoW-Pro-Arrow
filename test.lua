-- local function CreateLocalZonesTable(self)
	-- local tbl = {}
	-- local mapIDs = mapdata:GetAllMapIDs()
		-- for i,mapid in ipairs(mapIDs) do
			-- local localzone = mapdata:MapLocalize(mapid)
			-- tbl[localzone] = tostring(mapid)
		-- if mapid ~= 751 and mapid ~= 539 and mapid ~= 542 then
			-- if mapid == 770 then
				-- localzone = "Twilight Highlands (phased1)"
			-- else
				-- localzone = mapdata:MapLocalize(mapid)
				-- if localzone == "Gilneas2" then
					-- if mapid == 611 then
						-- localzone = "Gilneas City"
					-- elseif mapid == 678 then
						-- localzone = "Gilneas (Phased1)"
					-- elseif mapid == 545 then
						-- localzone = "Gilneas"
					-- elseif mapid == 679 then
						-- localzone = "Gilneas (Phased2)"
					-- end
				-- elseif localzone == "Kalimdor" then
					-- if mapid == 683 then
						-- localzone = "Hyjal (Phased1)"
					-- elseif mapid == 748 then
						-- localzone = "Uldum (Phased1)"
					-- end
				-- elseif localzone == "LostIsles" then
					-- if mapid == 681 then
						-- localzone = "The Lost Isles (Phased1)"
					-- elseif mapid == 682 then
						-- localzone = "The Lost Isles (Phased2)"
					-- end
				-- end
			-- end
			-- tbl[localzone] = tostring(mapid)
		-- end
	-- end
	-- return tbl
-- end

-- function WoWPro_Arrow:TestCallback(self, map,floor,w,h)
	-- callbacks:Fire("ArrowMapChanged", map, floor)
	-- print("MapChanged: ", map, floor)
-- end

-- function WoWPro_Arrow:OnEnable()
	-- WoWPro_ArrowDB = {}
	-- WoWPro_ArrowDB.localzones = CreateLocalZonesTable(self)
	-- mapdata.RegisterCallback(self, "MapChanged", "TestCallback")
	-- WoWProArrow.RegisterCallback(self, "ArrowMapChanged", "TestCallbackArrow")
-- end