-- Define the screen dimensions
local SCREEN_WIDTH = LCD_W
local SCREEN_HEIGHT = LCD_H

-- Define the GPS coordinates for the runway ends
local RUNWAY_START = {lat = 41.4690194, lon = -081.9988222}
local RUNWAY_END =   {lat = 41.4693306, lon = -081.9988083}

-- Define the bounding box for the airfield (latitude and longitude of corners)
local AIRFIELD_BOUNDING_BOX = {
    topLeft =     {lat = 41.4702556, lon = -081.9990639},
    bottomRight = {lat = 41.4679472, lon = -081.9985306}
}

-- Define the bounding box for the aligned box (latitude and longitude of corners)
local ALIGNED_BOUNDING_BOX = {
    topLeft = {lat = (AIRFIELD_BOUNDING_BOX.topLeft.lat+AIRFIELD_BOUNDING_BOX.bottomRight.lat)/2+(AIRFIELD_BOUNDING_BOX.topLeft.lat-AIRFIELD_BOUNDING_BOX.bottomRight.lat)*1.5, 
	           lon = (AIRFIELD_BOUNDING_BOX.topLeft.lon+AIRFIELD_BOUNDING_BOX.bottomRight.lon)/2+(AIRFIELD_BOUNDING_BOX.topLeft.lon-AIRFIELD_BOUNDING_BOX.bottomRight.lon)/2},
    bottomRight = {lat = (AIRFIELD_BOUNDING_BOX.topLeft.lat+AIRFIELD_BOUNDING_BOX.bottomRight.lat)/2-(AIRFIELD_BOUNDING_BOX.topLeft.lat-AIRFIELD_BOUNDING_BOX.bottomRight.lat)*1.5, 
	               lon = (AIRFIELD_BOUNDING_BOX.topLeft.lon+AIRFIELD_BOUNDING_BOX.bottomRight.lon)/2-(AIRFIELD_BOUNDING_BOX.topLeft.lon-AIRFIELD_BOUNDING_BOX.bottomRight.lon)/2}
}

-- Calculate the center of the runway
local centerLat = (RUNWAY_START.lat + RUNWAY_END.lat)/2
local centerLon = (RUNWAY_START.lon + RUNWAY_END.lon)/2

-- Calculate the aspect ratio of the bounding box
local latRange = (AIRFIELD_BOUNDING_BOX.topLeft.lat - AIRFIELD_BOUNDING_BOX.bottomRight.lat)
local lonRange = (AIRFIELD_BOUNDING_BOX.bottomRight.lon - AIRFIELD_BOUNDING_BOX.topLeft.lon)
local aspectRatio = lonRange / latRange

-- Calculate the dimensions of the bounding box on the screen
local BOX_WIDTH = SCREEN_WIDTH / 2
local BOX_HEIGHT = BOX_WIDTH * aspectRatio

local function getTelemetryId(name)    
	field = getFieldInfo(name)
	if field then
		return field.id
	else
		return -1
	end
end

-- Get telemetry IDs
local gpsId = getTelemetryId("GPS")

local headingId = getTelemetryId("Hdg")


-- Function to calculate heading between two GPS coordinates
local function calculateHeading(lat1, lon1, lat2, lon2)
    local dLon = math.rad(lon2 - lon1)
    local y = math.sin(dLon) * math.cos(math.rad(lat2))
    local x = math.cos(math.rad(lat1)) * math.sin(math.rad(lat2)) - math.sin(math.rad(lat1)) * math.cos(math.rad(lat2)) * math.cos(dLon)
    local heading = math.deg(math.atan2(y, x))
    if heading < 0 then
        heading = heading + 360
    end
    return heading
end

-- Calculate the runway headings
local RUNWAY_HEADING_1 = calculateHeading(RUNWAY_START.lat, RUNWAY_START.lon, RUNWAY_END.lat, RUNWAY_END.lon)
local RUNWAY_HEADING_2 = (RUNWAY_HEADING_1 + 180) % 360
local HEADING_TOLERANCE = 5
local TRACK_ALIGNED = "aligned.wav"  -- The track to play when aligned
local TRACK_ONFIELD = "infield.wav"  -- The track to play when aligned


-- Function to get the current heading from telemetry
local function getCurrentHeading()
    local heading = getValue(headingId)
    if heading then
        return heading
    end
    return nil
end

-- Function to get the current GPS coordinates from telemetry
local function getCurrentGPS()
    local gpsLatLon  = getValue(gpsId)
	--print(gpsValue)
    if (type(gpsLatLon) == "table") then
        return {lat = gpsLatLon["lat"], lon = gpsLatLon["lon"]}
	else
        return {lat = centerLat, lon = centerLon}
    end
    return nil
end


-- Function to check if the current GPS coordinates are within the airfield bounding box
local function isWithinAirfieldBoundingBox(gps)
    if gps then
        return gps.lat <= AIRFIELD_BOUNDING_BOX.topLeft.lat and gps.lat >= AIRFIELD_BOUNDING_BOX.bottomRight.lat and
               gps.lon >= AIRFIELD_BOUNDING_BOX.topLeft.lon and gps.lon <= AIRFIELD_BOUNDING_BOX.bottomRight.lon
    end
    return false
end

local function isWithinAlignedBoundingBox(gps)
    if gps then
        return gps.lat <= ALIGNED_BOUNDING_BOX.topLeft.lat and gps.lat >= ALIGNED_BOUNDING_BOX.bottomRight.lat and
               gps.lon >= ALIGNED_BOUNDING_BOX.topLeft.lon and gps.lon <= ALIGNED_BOUNDING_BOX.bottomRight.lon
    end
    return false
end

function haversine_distance(lat1, lon1, lat2, lon2)
    -- Radius of the Earth in meters
    local R = 6371000
    
    -- Convert latitude and longitude from degrees to radians
    local function to_radians(degrees)
        return degrees * math.pi / 180
    end
    
    local phi1 = to_radians(lat1)
    local phi2 = to_radians(lat2)
    local delta_phi = to_radians(lat2 - lat1)
    local delta_lambda = to_radians(lon2 - lon1)
    
    -- Haversine formula
    local a = math.sin(delta_phi / 2.0) ^ 2 +
              math.cos(phi1) * math.cos(phi2) *
              math.sin(delta_lambda / 2.0) ^ 2
    local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    -- Distance in meters
    local distance = R * c
    
    return distance
end

function round(x, n)
    n = math.pow(10, n or 0)
    x = x * n
    if x >= 0 then x = math.floor(x + 0.5) else x = math.ceil(x - 0.5) end
    return x / n
end


-- Function to convert GPS coordinates to screen coordinates
local function gpsToScreen(lat, lon)
    -- Translate GPS coordinates to the center of the bounding box
    local translatedLat = lat - centerLat
    local translatedLon = lon - centerLon

    -- Rotate the coordinates to align the runway horizontally
    local angle = math.rad(RUNWAY_HEADING_1 + 90)
    local x = translatedLon * math.cos(angle) + translatedLat * math.sin(angle)
    local y = translatedLon * math.sin(angle) + translatedLat * math.cos(angle)

    -- Scale the coordinates to fit the screen
    x = x / (lonRange * math.cos(angle) + latRange * math.sin(angle)) * BOX_WIDTH / 2 + (SCREEN_WIDTH) / 2
    y = y / (latRange * math.cos(angle) + lonRange * math.sin(angle)) * BOX_HEIGHT / 2  + (SCREEN_HEIGHT) / 2
	
	x = round(x, 0)
	y = round(y, 0)

    return x, y
end

-- Function to draw the runway, airplane position, and bounding box on the screen
local function drawScreen(gps)
	local x, y = gpsToScreen(gps.lat, gps.lon)
    lcd.clear()
	local distance = haversine_distance(gps.lat, gps.lon, centerLat, centerLon)
    lcd.drawText(1, 1, "LFD v1.0 | D: " .. string.format("%.1f m",distance) , SMLSIZE)
	lcd.drawText(1, 8, "RW: " .. string.format("%.1f deg",RUNWAY_HEADING_1) , SMLSIZE)
    
    -- Draw the bounding box representing the airfield
    lcd.drawRectangle((SCREEN_WIDTH - BOX_WIDTH) / 2, (SCREEN_HEIGHT - BOX_HEIGHT) / 2, BOX_WIDTH, BOX_HEIGHT)
	lcd.drawRectangle((SCREEN_WIDTH - BOX_WIDTH * 1.5) / 2, (SCREEN_HEIGHT - BOX_HEIGHT / 2) / 2, BOX_WIDTH * 1.5, BOX_HEIGHT / 2)
    
    -- Convert runway GPS coordinates to screen coordinates
    local runwayStartX, runwayStartY = gpsToScreen(RUNWAY_START.lat, RUNWAY_START.lon)
    local runwayEndX, runwayEndY = gpsToScreen(RUNWAY_END.lat, RUNWAY_END.lon)

    -- Draw the runway as a line
    lcd.drawLine(runwayStartX, runwayStartY, runwayEndX, runwayEndY, SOLID, FORCE)
    
    -- Draw the airplane as 'o'
    --lcd.drawText(x-4, y-4, "o", SMLSIZE)
	lcd.drawFilledRectangle(x-2, y-2, 4, 4)
	local index = getSwitchIndex("L07")
	local queueLength = audio.getQueue()

	if queueLength == 0 and getSwitchValue(index) then
		if isWithinAlignedBoundingBox(gps) then
			playFile("/SOUNDS/en/aligned.wav")	
		end
		if isWithinAirfieldBoundingBox(gps) then
			playFile("/SOUNDS/en/infield.wav")
		end
	end
    
    lcd.refresh()
end

-- Main script loop
local function run(event)
    local gps = getCurrentGPS()
    if gps then
        drawScreen(gps)
    end
    return 0
end

return { run = run }
