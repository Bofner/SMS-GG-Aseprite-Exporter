----------------------------------------------------------------------------------
-- Export Sprite data
----------------------------------------------------------------------------------
function recordSpriteTiles(currentX, currentY, numTiles, tilePatternTable, spriteSize, sprite, img)
    -- We need to go through However many tiles
    local tileCount = numTiles
    local tileWidth = 8
    local tileHeight = 8
    if spriteSize == "8x16 Pixels" then
        tileHeight = 16
        tileCount = numTiles / 2
    end
    local spriteWidth = sprite.width / 8
    
    local origX = currentX
    local origY = currentY
    local pixelColor = 0
    local newRow = false
    
    -- Go through all tiles
    for tilePattern = 1, tileCount, 1 do
        -- Set our baseline X and Y
        origX = currentX
        origY = currentY
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
                local pixelIndexColor = img:getPixel(currentX, currentY)
                -- Move over to the target bit
                pixelIndexColor = pixelIndexColor << shiftCounter
                bitCheck = targetBit & pixelIndexColor
                -- Record bit into byte 3
                rowDataByte3 = rowDataByte3 | bitCheck
                --print(bitCheck)

                --Move next bit into target bit
                pixelIndexColor = img:getPixel(currentX, currentY)
                pixelIndexColor = pixelIndexColor << shiftCounter + 1
                bitCheck = targetBit & pixelIndexColor
                -- Record bit into byte 3
                rowDataByte2 = rowDataByte2 | bitCheck
                --print(bitCheck)

                --Move next bit into target bit
                pixelIndexColor = img:getPixel(currentX, currentY)
                pixelIndexColor = pixelIndexColor << shiftCounter + 2
                bitCheck = targetBit & pixelIndexColor
                -- Record bit into byte 3
                rowDataByte1 = rowDataByte1 | bitCheck
                --print(bitCheck)

                --Move next bit into target bit
                pixelIndexColor = img:getPixel(currentX, currentY)
                pixelIndexColor = pixelIndexColor << shiftCounter + 3
                bitCheck = targetBit & pixelIndexColor
                -- Record bit into byte 3
                rowDataByte0 = rowDataByte0 | bitCheck
                --print(bitCheck)
                
                -- Wow I hate doing bit manipulation in Lua

                -- Save our Two Pixel Bytes to the table
                tileBuffer[tileCount + 0] = ("$" .. string.format("%02X", rowDataByte0) )
                tileBuffer[tileCount + 1] = ("$" .. string.format("%02X", rowDataByte1) )
                tileBuffer[tileCount + 2] = ("$" .. string.format("%02X", rowDataByte2) )
                tileBuffer[tileCount + 3] = ("$" .. string.format("%02X", rowDataByte3) )

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
        
        if tilePattern % spriteWidth == 0 then
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
            
        tilePatternTable[#tilePatternTable + 1] = tileBuffer                   
             
            
    end
end

----------------------------------------------------------------------------------
-- write the Tile Pattern Data to inc files
----------------------------------------------------------------------------------
function writeSpriteTilePatternToIncFile(file, tilePatternData, system, spriteSize)
    
    local tileIncFile = io.open(file, "w")  
    local byteCount = 1
    local tileSize = 32
    
    -- Header comment message
    tileIncFile:write("; Tile Pattern file for use with " .. system .. " Z80 Assembly programs\n; By Steelfinger Studios\n")
    -- Write the pattern data
    local totalNumTiles = 0
    if #tilePatternData > 448 then
       totalNumTiles = 448
    else
        totalNumTiles = #tilePatternData
    end

    local spriteSizeBytes = tileSize
    if spriteSize == "8x16 Pixels" then
        spriteSizeBytes = 64
    end

    local tileNum = 0

    for tile = 1, totalNumTiles, 1 do
        -- Beginning of the first row of tiles
        tileIncFile:write("; Sprite Tile Pattern #" .. tileNum)
        tileIncFile:write("\n")
        tileIncFile:write(".DB ")
        tileNum = tileNum + 1
        
        -- Each tile is made of 32 bytes
        for tileBytes = 1, spriteSizeBytes, 1 do
            --print(tilePatternData[byteCount])
            tileIncFile:write(tilePatternData[tile][tileBytes].." ")
            byteCount = byteCount + 1
            
            if tileBytes % 4 == 0 and tileBytes == spriteSizeBytes / 2 and spriteSizeBytes == 64 then
                tileIncFile:write("\n")
                tileIncFile:write("; Sprite Tile Pattern #" .. tileNum)
                tileIncFile:write("\n")
                tileIncFile:write(".DB ")
                tileNum = tileNum + 1
            elseif tileBytes % 4 == 0 and tileBytes ~= spriteSizeBytes then
                tileIncFile:write("\n")
                tileIncFile:write(".DB ")
            end
            

        end
        tileIncFile:write(" \n")
    end
    
    tileIncFile:write("; End of file\n")
    tileIncFile:close();

end