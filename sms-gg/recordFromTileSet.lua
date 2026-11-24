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
function recordTileSetTiles(tileSet, tilePatternTable, tileOffset, tileMapTable, slices)
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
                print(tilePattern)
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


