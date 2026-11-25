----------------------------------------------------------------------------------
-- Compares tile patterns for the map data
----------------------------------------------------------------------------------
local repeatTile = 0x0000
local repeatHoriTile = 0x0200
local repeatVertTile = 0x0400
local repeatHVTile = 0x0600
local newTile = 0x0001

----------------------------------------------------------------------------------
-- Function for getting our tile data etc
----------------------------------------------------------------------------------
function recordTileSetTiles(tileSet, tilePatternTable)
    -- We need to go through 256 tiles, 32 x 16
    local numTiles = #tileSet
    local tileWidth = 8
    local tileHeight = 8
    local currentX = 0
    local currentY = 0
    local origX = 0
    local origY = 0
    local pixelColor = 0
    local newRow = false
    local softwareBitAreas = {}
    
    -- Go through a screen one tile at a time
    for tilePattern = 1, numTiles - 1, 1 do
        -- Set our baseline X and Y
        origX = 0
        origY = 0
        local tileBuffer = {}
        local tileCount = 1
        -- Point tile pattern to next tile
        local tilePatternBuffer = {}
        
        -- Go down 8 pixels in a single tile
        for tilePatternRow = 1, tileHeight, 1 do
            local tilePatternRowColorData = {}
            local rowByte = 1
            -- The 32 bytes for our tile
            local rowDataByte0 = 0x00
            local rowDataByte1 = 0x00
            local rowDataByte2 = 0x00
            local rowDataByte3 = 0x00

            local shiftCounter = 4
            local shifSwap = 1
            local targetBit = 0x80
            -- Go across 8 pixels in a single tile
            for tilePatternPixel = 1, tileWidth, 1 do
                local bitCheck = 0x00
   
                --print(pixelIndexColor)
                -- First 4 bits
                -- Grab the index color of the first pixel in the byte
                local pixelIndexColor = tileSet:tile(tilePattern).image:getPixel(currentX, currentY)
                -- Move over to the target bit
                pixelIndexColor = pixelIndexColor << shiftCounter
                bitCheck = targetBit & pixelIndexColor
                -- Record bit into byte 3
                rowDataByte3 = rowDataByte3 | bitCheck
                --print(bitCheck)

                --Move next bit into target bit
                pixelIndexColor = tileSet:tile(tilePattern).image:getPixel(currentX, currentY)
                pixelIndexColor = pixelIndexColor << shiftCounter + 1
                bitCheck = targetBit & pixelIndexColor
                -- Record bit into byte 3
                rowDataByte2 = rowDataByte2 | bitCheck
                --print(bitCheck)

                --Move next bit into target bit
                pixelIndexColor = tileSet:tile(tilePattern).image:getPixel(currentX, currentY)
                pixelIndexColor = pixelIndexColor << shiftCounter + 2
                bitCheck = targetBit & pixelIndexColor
                -- Record bit into byte 3
                rowDataByte1 = rowDataByte1 | bitCheck
                --print(bitCheck)

                --Move next bit into target bit
                pixelIndexColor = tileSet:tile(tilePattern).image:getPixel(currentX, currentY)
                pixelIndexColor = pixelIndexColor << shiftCounter + 3
                bitCheck = targetBit & pixelIndexColor
                -- Record bit into byte 3
                rowDataByte0 = rowDataByte0 | bitCheck
                --print(bitCheck)
                
                -- Wow I hate doing bit manipulation in Lua

                -- Save our Two Pixel Bytes to the table
                tileBuffer[tileCount + 0] = rowDataByte0
                tileBuffer[tileCount + 1] = rowDataByte1
                tileBuffer[tileCount + 2] = rowDataByte2
                tileBuffer[tileCount + 3] = rowDataByte3

                -- Prepare to check next row
                currentX = currentX + 1
                shiftCounter = shiftCounter - 1
                if shiftCounter < 0 then
                    shiftSwap = -1
                end
                targetBit = targetBit / 2

            end
            -- Increament our tile count. Each tile uses 4 bytes, thus +4
            tileCount = tileCount + 4

            -- When we are out of the tile pattern pixel loop, then we've finished a row within a tile
            if tilePattern % 32 == 0 then
                currentX = origX
                newRow = true
            else
                currentX = origX
                newRow = false
            end
            -- Update our Y
            currentY = currentY + 1
        end
        -- When we finish the Tile Height loop, then we are finished with the tile
        -- Prepare for next tile
        -- If we are at the last tile in a row, then make sure to move to the next row
        if tilePattern % 32 == 0 then
                newRow = true
        end
        if newRow == true then
            currentY = origY + tileHeight
            currentX = 0 
            origX = currentX
            origY = currentY
            newRow = false                  -- Make sure to reset
        else
            currentY = origY
            currentX = origX + tileWidth
        end

        -- Save current tile
        tilePatternTable[#tilePatternTable + 1] = tileBuffer        
    end
end


----------------------------------------------------------------------------------
-- Function for exporting the Aseprite Tile Map into Map Data
----------------------------------------------------------------------------------
function recordTileMapData(tileOffset, tileMapTable, sprite, slices)
-- Find the tile map layer
    local tileMapIndex
    for i = 1, #sprite.layers, 1 do
        if sprite.layers[i].isTilemap then
            tileMapIndex = i
            break
        end
    end

-- No Tile map
    if tileMapIndex == nil then
        app.alert("No Tile Map Layer!")
        return
    end
-- Save Aseprite Tile Map
    local asepriteTileMap = sprite.layers[tileMapIndex].cels[1].image
    local mapWidthInTiles = asepriteTileMap.width
    local mapHeightInTiles = asepriteTileMap.height
    local blankMapWord      = 0x0000
    local tilePattern9Bit   = 0x01FF
    local horiWord          = 0x0200
    local vertWord          = 0x0400
    local saveMirrorBits    = 0xC0000000

-- Run through the entire map, and save each tile's Horizontal, and Vertical mirroring, and Pattern bytes
    for yPos = 0, mapHeightInTiles - 1, 1 do
        for xPos = 0, mapWidthInTiles - 1, 1 do
         -- Get the tile index from asepriteTileMap, AND with tilePattern9Bit
            local rawAsepriteTileID = asepriteTileMap:getPixel(xPos,yPos)
            local nineBitAseTileID = tilePattern9Bit & rawAsepriteTileID
        -- OR the first 9-bit into blankMapWord
            local currentMapWord = blankMapWord | nineBitAseTileID

        -- OR horiWord and VertWord based on MSb of asepriteTileID
            local mirrorBits = rawAsepriteTileID & saveMirrorBits
        -- Double mirror
            if mirrorBits == 0xC0000000 then
                currentMapWord = currentMapWord | horiWord | vertWord
        -- Horizontal Mirror
            elseif mirrorBits == 0x80000000 then
                currentMapWord = currentMapWord | horiWord
        -- Vertical Mirror
            elseif mirrorBits == 0x40000000 then
                currentMapWord = currentMapWord | vertWord
            end
        
        --Handle any slices we may have
            local softwareBitAreas =  calculateSliceAreas(slices)
        -- Check if the current tile is within one of the special softwareBit slices
            local softwareBitValue = 0x0000
            for currentSlice = 1, #softwareBitAreas, 1 do
            -- Check through each tile of the current slice
                for currentSliceTile = 1, #softwareBitAreas[currentSlice], 1 do
                    if softwareBitAreas[currentSlice][currentSliceTile] == ((yPos*mapWidthInTiles) + xPos) then
                    -- If the tile IS contained in a slice, update the softwareBitValue to reflect that value
                        for currentBit = 5, 1, -1 do
                            local checkBit = tonumber(string.sub(softwareBitAreas[currentSlice][0], currentBit, currentBit))
                            softwareBitValue = softwareBitValue >> 1
                            if checkBit == 1 then
                                softwareBitValue = softwareBitValue + 0x8000
                            end
                        end
                    end
                end
            end
        -- AND in the SSSBP bits from the slice if there was one

        -- Save word to the tileMapTable
            tileMapTable[#tileMapTable + 1] = currentMapWord | softwareBitValue
        end
    end
end




----------------------------------------------------------------------------------
-- Slice related code mess
----------------------------------------------------------------------------------
--------------------------
-- Create our big slice areas
--------------------------

function calculateSliceAreas(slices)
    local softwareBitAreas = {}
    -- User determines the palette used for each ATR, as well as the software bits that are to be turned on or off
    for i = 1, #slices, 1 do
        if slices[i] ~= nil then
        -- Adjust size of the slice in order to accomodate BG tiles
            local tiledRect = slices[i].bounds
        --X
            if tiledRect.x % 8 > 4 then
                tiledRect.width = tiledRect.width - (8 - tiledRect.x % 8)
                tiledRect.x = tiledRect.x + (8 - tiledRect.x % 8)
            else
                tiledRect.width = tiledRect.width + (tiledRect.x % 8)
                tiledRect.x = tiledRect.x - tiledRect.x % 8
            end
        --Y
            if tiledRect.y % 8 > 4 then
                tiledRect.height = tiledRect.height - (8 - tiledRect.y % 8)
                tiledRect.y = tiledRect.y + (8 - tiledRect.y % 8)
            else
                tiledRect.height = tiledRect.height + (tiledRect.y % 8)
                tiledRect.y = tiledRect.y - tiledRect.y % 8
            end
        --WIDTH
            if tiledRect.width % 8 > 4 then
                tiledRect.width = tiledRect.width + (8 - (tiledRect.width) % 8)
            else
                tiledRect.width = tiledRect.width - tiledRect.width % 8
            end
        --HEIGHT
            if tiledRect.height % 8 > 4 then
                tiledRect.height = tiledRect.height + (8 - (tiledRect.height) % 8)
            else
                tiledRect.height = tiledRect.height - tiledRect.height % 8
            end
            -- We've got our adjusted rectangle, so now we need to figure out which 
            -- tiles are within the rectangle. 
        -- First let's find out how many tiles there are in total.
            local numTilesInSlice = (tiledRect.width / 8) * (tiledRect.height / 8)

        -- Next we need to find the "tile number"... This will be the order in which tiles are
            -- written to the map. The formula is : tile# = (32Y + X)
            local originTile = (tiledRect.y / 8 * 32) + (tiledRect.x / 8)

         -- Create a for loop to add every single tile to the slice
            local containedTiles = {}
            local tileOffset = 0
            for currentTile = 1, numTilesInSlice + 1, 1 do

                containedTiles[currentTile] = originTile + tileOffset

                if currentTile % (tiledRect.width / 8) == 0 then
                    tileOffset = tileOffset + (32 - ((tiledRect.width / 8) - 1))
                else
                    tileOffset = tileOffset + 1
                end
                
            end

            -- Add the slice's data value to the 0-index of the array
            containedTiles[0] = slices[i].data
                
            -- Add an array to softwareBitAreas{}
            softwareBitAreas[#softwareBitAreas + 1] = containedTiles

            --print("Array= " .. softwareBitAreas[1][0])

        end
    end
    return softwareBitAreas
end