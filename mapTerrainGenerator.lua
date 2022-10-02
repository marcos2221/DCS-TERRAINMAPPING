-- Created by Tupper / Rotorheads Server 09/2022

-- This Files requires LFS and IO not sanitized to save the data to a local file placed in SavedGames Folder.
-- Comment the lines mentioning LFS and IO in the missionscripting.lua in the installation folder/Scripts

--This Script is to be executed in Single Player to generate the areas
--Areas:
--      city
--      forest
--      clear (inside a forest)

if mist == nil then
  env.info("Terrain Mapping script needs MIST to work")
  trigger.action.outText( "Terrain Mapping script needs MIST to work" , 60)
end

--Config
tmap = {}
tmap.maxtries = 500;

-- Syria

local terrainByGrid = {}
local terrainMapping = { forest = {}, city = {}, clear = {}}

tmap.FileName = lfs.writedir().. "terrainData-" .. env.mission.theatre .. ".lua"

-- 
--local markerList = {}
local temppolyLinesId = {}
local lineId = 1000
local function getLineId()
  lineId = lineId + 1
  return lineId;
end

function mist.tostringMGRSgrid2(MGRS)
   return MGRS.MGRSDigraph ..  string.sub(string.format('%0' .. 5 .. 'd', mist.utils.round(MGRS.Easting/(10^(5-5)), 0)),1,1)
    ..  string.sub(string.format('%0' .. 5 .. 'd', mist.utils.round(MGRS.Northing/(10^(5-5)), 0)),1,1)
 
end
local function getGrid( _pos ) -- vec3

  local mgrs = coord.LLtoMGRS(coord.LOtoLL(_pos))
  local gridtxt = mist.tostringMGRSgrid2(mgrs)
  
  return gridtxt
  
end

local function drawTempPoligon(markerList)
   if #markerList < 3 then 
    return
   end
  
   temppolyLinesId = {}
   local firstLine 
   for key, val in ipairs( markerList ) do
    if firstLine == nil then
     firstLine = {x = val.x, y = 0, z = val.y}
    end
    local _nextLine = next(markerList, key) 
    local _lineId = getLineId()
    if _nextLine ~= nil then
    
      
      trigger.action.lineToAll(-1, _lineId  , {x = val.x, y = 0, z = val.y}, {x = markerList[_nextLine].x, y = 0, z = markerList[_nextLine].y}  , val.color, 1 , true)
    else
      trigger.action.lineToAll(-1, _lineId  , {x = val.x, y = 0, z = val.y} , firstLine , val.color , 1 , true)
    end
    table.insert(temppolyLinesId, { id = lineId})
    
   end  
   
end


local function getMappingAreas()
  local _groups = coalition.getGroups( coalition.side.BLUE , Group.Category.GROUND)
  local _affectedGrids = {}
  for key, _group in pairs (_groups) do
    local markerList = {}
    local groupName = _group:getName()
    if string.match(groupName,"FOREST-") then
      local route =  mist.getGroupRoute(groupName)
      if route ~= nil then
        table.insert(terrainMapping.forest, {})
        local index = #terrainMapping.forest
        for key2, val in pairs (route ) do
          table.insert(markerList, { x = val.x, y = val.y, color = {0,1,0,1} })
          local gridtxt = getGrid({ x = val.x, y = 0, z = val.y})
          table.insert(terrainMapping.forest[index], { x = val.x, y = val.y, grid = gridtxt })
        end
        drawTempPoligon(markerList)
      end 
    end
    if string.match(groupName,"CITY-") then
      local route =  mist.getGroupRoute(groupName)
      if route ~= nil then
        table.insert(terrainMapping.city, {})
        local index = #terrainMapping.city
        for key2, val in pairs (route ) do
          table.insert(markerList, { x = val.x, y = val.y, color = {1,0,0,1} })
          local gridtxt = getGrid({ x = val.x, y = 0, z = val.y})
          table.insert(terrainMapping.city[index], { x = val.x, y = val.y, grid = gridtxt })
        end
        drawTempPoligon(markerList)
      end 
    end
    if string.match(groupName,"CLEAR-") then
      local route =  mist.getGroupRoute(groupName)
      if route ~= nil then
        table.insert(terrainMapping.clear, {})
        local index = #terrainMapping.clear
        for key2, val in pairs (route ) do
          table.insert(markerList, { x = val.x, y = val.y, color = {1,1,0,1} })
          local gridtxt = getGrid({ x = val.x, y = 0, z = val.y})
          table.insert(terrainMapping.clear[index], { x = val.x, y = val.y, grid = gridtxt })
        end
        drawTempPoligon(markerList)
      end 
    end
  end
end

local function createFile()

  local strOutput = [[tmap = {}
  tmap.maxtries = 500
  local terrainByGrid = {}
if mist == nil then
  env.info("Terrain Mapping script needs MIST to work")
  trigger.action.outText( "Terrain Mapping script needs MIST to work" , 60)
end
  ]]
  strOutput = strOutput .. "local terrainMapping = {\n"
  
  for key, val in pairs (terrainMapping) do
    strOutput = strOutput .. [[  ["]] .. key .. [["] = {]] .. "\n"
      for key2, val2 in pairs(val) do
        strOutput = strOutput .. [[    []] .. key2 .. [[] = {]] .. "\n" -- Polygon
        for key3, val3 in pairs(val2) do

            strOutput = strOutput .. [[      []] .. key3 .. [[] = ]]  -- Polygon line

            strOutput = strOutput .. [[{["x"] = ]] .. val3.x .. [[, ["y"] = ]] .. val3.y ..[[, ["grid"] = "]] .. tostring(val3.grid) .. [["}]]
            strOutput = strOutput .. ",\n"
        end
        strOutput = strOutput .. "    },\n"
      end   
    strOutput = strOutput .. "  },\n"
  end
   
  strOutput = strOutput .. "}\n"
  
  strOutput =  strOutput .. [[function mist.tostringMGRSgrid2(MGRS)
return MGRS.MGRSDigraph ..  string.sub(string.format('%0' .. 5 .. 'd', mist.utils.round(MGRS.Easting/(10^(5-5)), 0)),1,1)
..  string.sub(string.format('%0' .. 5 .. 'd', mist.utils.round(MGRS.Northing/(10^(5-5)), 0)),1,1)
end
   
local function getGrid( _pos ) -- vec3
  local mgrs = coord.LLtoMGRS(coord.LOtoLL(_pos))
  local gridtxt = mist.tostringMGRSgrid2(mgrs)
  return gridtxt
end

function tmap.createGridIndex()
  for key, table1 in pairs (terrainMapping) do  -- Table contains City, forest
    for key2, polyTable in pairs (table1) do
      local affectedGrids = {}
      for key3, polyline in pairs (polyTable) do
        affectedGrids[polyline.grid]    = true   
      end
      for grid, _ in pairs(affectedGrids) do
        if terrainByGrid[grid] == nil then 
          terrainByGrid[grid] = { forest = {}, city = {}, clear = {}}
        end
        table.insert( terrainByGrid[grid][key], polyTable )
      end
    end    
  end
end

function tmap.getRandomPointInArea( pos, radius)
  local randomPos = mist.getRandPointInCircle(pos, radius)
  local allowed = false
  local maxTries = tmap.maxtries
  local gridtxt = getGrid(pos)
  while allowed == false do
    if land.getSurfaceType(randomPos) ~= land.SurfaceType.WATER then
      allowed = true
      if terrainByGrid[gridtxt] == nil then
        allowed = true
        break
      end
      local onroad = false
      for key, val in pairs (terrainByGrid[gridtxt].city) do
        if  mist.pointInPolygon(randomPos,val) then
          if land.getSurfaceType(randomPos) ~= land.SurfaceType.ROAD then
            local roadPointx, roadPointy = land.getClosestPointOnRoads( "roads" , randomPos.x , randomPos.y )
            local dist = mist.utils.get2DDist(pos, {x = roadPointx, y = 0, z = roadPointy})
            if dist > radius then
              allowed = false
              break;
            else
              randomPos = { x = roadPointx, y = roadPointy}
              onroad = true
              break;
            end
          else
            onroad = true
            break;
          end
        end
      end
      if allowed == true and onroad == false then
        -- check if Its a city -- Only place units on roads
        for key, val in pairs (terrainByGrid[gridtxt].forest) do
          if  mist.pointInPolygon(randomPos,val) then
            -- Check if theres a clear in this forest area
            local clearFound = false
            for key2, val2 in pairs (terrainByGrid[gridtxt].clear) do
              if  mist.pointInPolygon(randomPos,val2) then
                clearFound = true
                break;
              end
            end
            if clearFound == false then
              allowed = false
              break;
            end
          end
        end  
      end
    end
    if allowed == false then
      randomPos = mist.getRandPointInCircle(pos,radius)
      maxTries = maxTries - 1
      if maxTries < 1 then
        break;
      end
    end
  end
  if allowed == true then
    return randomPos
  else
    return false
  end
end

]]
  
 
  strOutput = strOutput .. [[tmap.createGridIndex()]]
    
  local _file = io.open(tmap.FileName, 'w')
  _file:write(strOutput)
  _file:close()  
  
  trigger.action.outText( "File " .. tmap.FileName .. " Generated successfully" , 60)
    
end
function tmap.createGridIndex()
  for key, table1 in pairs (terrainMapping) do  -- Table contains City, forest
    for key2, polyTable in pairs (table1) do
      local affectedGrids = {}
      for key3, polyline in pairs (polyTable) do
        affectedGrids[polyline.grid]    = true   
      end
      for grid, _ in pairs(affectedGrids) do
        if terrainByGrid[grid] == nil then 
          terrainByGrid[grid] = { forest = {}, city = {}, clear = {}}
        end
        table.insert( terrainByGrid[grid][key], polyTable )
      end
    end    
  end
end

function tmap.getRandomPointInArea( pos, radius)
  local randomPos = mist.getRandPointInCircle(pos, radius)
  local allowed = false
  local maxTries = tmap.maxtries
  local gridtxt = getGrid(pos)
  while allowed == false do
    if land.getSurfaceType(randomPos) ~= land.SurfaceType.WATER then
      allowed = true
      if terrainByGrid[gridtxt] == nil then
        allowed = true
        break
      end
      local onroad = false
      for key, val in pairs (terrainByGrid[gridtxt].city) do
        if  mist.pointInPolygon(randomPos,val) then
          if land.getSurfaceType(randomPos) ~= land.SurfaceType.ROAD then
            local roadPointx, roadPointy = land.getClosestPointOnRoads( "roads" , randomPos.x , randomPos.y )
            local dist = mist.utils.get2DDist(pos, {x = roadPointx, y = 0, z = roadPointy})
            if dist > radius then
              allowed = false
              break;
            else
              randomPos = { x = roadPointx, y = roadPointy}
              onroad = true
              break;
            end
          else
            onroad = true
            break;
          end
        end
      end
      if allowed == true and onroad == false then
        -- check if Its a city -- Only place units on roads
        for key, val in pairs (terrainByGrid[gridtxt].forest) do
          if  mist.pointInPolygon(randomPos,val) then
            -- Check if theres a clear in this forest area
            local clearFound = false
            
            for key2, val2 in pairs (terrainByGrid[gridtxt].clear) do
              if  mist.pointInPolygon(randomPos,val2) then
                clearFound = true
                break;
              end
            end
            if clearFound == false then
              allowed = false
              break;
            end
          end
        end  
      end
    end
    if allowed == false then
      randomPos = mist.getRandPointInCircle(pos,radius)
      maxTries = maxTries - 1
      if maxTries < 1 then
        break;
      end
    end
  end
  if allowed == true then
    return randomPos
  else
    return false
  end
end

getMappingAreas()
createFile()

tmap.createGridIndex()
