----------------------------------------------------------------------------------------
--Script start
----------------------------------------------------------------------------------

local sprite = app.activeSprite
-- Globals to be considered as constants
local TILE = 1
local MAP = 0
local tileSize = 32
local spriteFullPath
local spriteFileName

local repeatTile = 0x0000
local repeatHoriTile = 0x0200
local repeatVertTile = 0x0400
local repeatHVTile = 0x0600
local newTile = 0x0001


--Palette Constants
local currentPal = Palette(sprite.palettes[1])
local currentPalNumColors = #sprite.palettes[1]

--More colors than allowed by the hardware
if currentPalNumColors > 16 then
	local dlg = Dialog{title = "VDP color limit exceeded!"}
	dlg:label{ 	id    = "manyColors",
				label = "Warning!",
				text  = "Only the first 16 colors in the palette will be used!" }
	dlg:button{ id="continue", text="Continue" }
	dlg:button{ id="cancel", text="Cancel" }
	dlg:show()
	local data = dlg.data
	if data.cancel then
		return
	end
end

--Too few colors
if currentPalNumColors < 16 then
	currentPal:resize(16)
end


--Grab the title of our aseprite file
if sprite then
    spriteFullPath = sprite.filename
    spriteFilePath = spriteFullPath:match("(.+)%..+$")
    spriteFileName = spriteFullPath:match("([^/\\]+)$"):match("(.+)%..+$")
end


-- Get a copy of the current sprite as a single layer
local frame = app.activeFrame
local img = Image(sprite.width, sprite.height, sprite.colorMode)
img:drawSprite(sprite, frame)


----------------------------------------------------------------------------------------
--Helper Functions
----------------------------------------------------------------------------------
--Convert our 32-bit Aseprite color into SGB 15-bit color
local function convert32BitTo12BitColor(color)
	--Isolate the 32-bit components of the color
	local hexR = color.red
	local hexG = color.green
	local hexB = color.blue
	--Convert them into 12-bit color 
	local ggR = hexR & 0x00F0
	ggR = ggR >> 4
	local ggG = hexG & 0x00F0

	local ggB = hexB & 0x00F0
	ggB = ggB << 4
	--Put them into the 12-bit word in the form XXXXBBBB GGGGRRRR
	local gg12BitColor = 0x0000
	gg12BitColor = gg12BitColor | ggB
	gg12BitColor = gg12BitColor | ggG
	gg12BitColor = gg12BitColor | ggR

	return gg12BitColor
end

--Convert our 32-bit Aseprite color into SGB 6-bit color
local function convert32BitTo6BitColor(color)
	--Isolate the 32-bit components of the color
	local hexR = color.red
	local hexG = color.green
	local hexB = color.blue
	--Convert them into 6-bit color 
	local smsR = hexR & 0xC0
	smsR = smsR >> 6
	local smsG = hexG & 0xC0
	smsG = smsG >> 4
	local smsB = hexB & 0xC0
	smsB = smsB >> 2
	--Put them into the 15-bit word in the form XXBBGGRR
	local sms6BitColor = 0x00
	sms6BitColor = sms6BitColor | smsB 
	sms6BitColor = sms6BitColor | smsG 
	sms6BitColor = sms6BitColor | smsR

	return sms6BitColor
end


----------------------------------------------------------------------------------------
-- Background & Sprite Shared functions
----------------------------------------------------------------------------------


-- Write palette to a file
local function writePaletteToIncFile(file, systemType)
    local paletteFile = io.open(file, "w")
    local dataSize
    local writeSize
    paletteFile:write("; " .. systemType .. " Color Data\n")
    if systemType == "SMS" then
        dataSize = ".DB"
        writeSize = "%02X"
        for i = 0, 15, 1 do
            currentColor = convert32BitTo6BitColor(currentPal:getColor(i))
            paletteFile:write(dataSize .. " $" .. string.format(writeSize, currentColor) .. "\n")
        end
    else
        dataSize = ".DW"
        writeSize = "%04X"
        for i = 0, 15, 1 do
            currentColor = convert32BitTo12BitColor(currentPal:getColor(i))
            paletteFile:write(dataSize .. " $" .. string.format(writeSize, currentColor) .. "\n")
        end
    end
    paletteFile:write("; End of ".. systemType .. " Palette")
    paletteFile:close();
end


----------------------------------------------------------------------------------------
-- Background                                
----------------------------------------------------------------------------------

function compareTilePattern(checkTile, tilePatternTable, tilePatternTableHori, tilePatternTableVert, tilePatternTableHV) 
    local sameTilePattern = true
    if #tilePatternTable < 1 then
        return {newTile, 0}
    end
    -- Check if we are looking at a repeated tile by checking each pixel of the current tile
    -- against each pixel of the tiles we have previously recorded
    for tile = 1, #tilePatternTable, 1 do
        sameTilePattern = true
        for pixel = 1,  #tilePatternTable[tile], 1 do
            if checkTile[pixel] ~= tilePatternTable[tile][pixel] then
                -- Skip to next tile
                sameTilePattern = false
                break
            end
        end
        -- If we make it through and the tile was the same, then it's a duplicate
        if sameTilePattern == true then
            return {repeatTile, tile - 1}
        end
     
    end

    -- if not, let's check the horizontal flipped versions
    for tile = 1, #tilePatternTableHori, 1 do
        sameTilePattern = true
        for pixel = 1,  #tilePatternTableHori[tile], 1 do
            if checkTile[pixel] ~= tilePatternTableHori[tile][pixel] then
                -- Skip to next tile
                sameTilePattern = false
                break
            end
        end
        -- If we make it through and the tile was the same, then it's a duplicate
        if sameTilePattern == true then
            return {repeatHoriTile, tile - 1}
        end
    end

    -- Next, let's the vertical flipped versions
        for tile = 1, #tilePatternTableVert, 1 do
        sameTilePattern = true
        for pixel = 1,  #tilePatternTableVert[tile], 1 do
            if checkTile[pixel] ~= tilePatternTableVert[tile][pixel] then
                -- Skip to next tile
                sameTilePattern = false
                break
            end
        end
        -- If we make it through and the tile was the same, then it's a duplicate
        if sameTilePattern == true then
            return {repeatVertTile, tile - 1}
        end
    end

    -- Lastly, check the Horizontal and Vertical flipped versions
    
    for tile = 1, #tilePatternTableHV, 1 do
        sameTilePattern = true
        for pixel = 1,  #tilePatternTableHV[tile], 1 do
            if checkTile[pixel] ~= tilePatternTableHV[tile][pixel] then
                -- Skip to next tile
                sameTilePattern = false
                break
            end
        end
        -- If we make it through and the tile was the same, then it's a duplicate
        if sameTilePattern == true then
            return {repeatHVTile, tile - 1}
        end
    end

    return {newTile, #tilePatternTable}

end

function makeHorizontalTile(tileBuffer)
    local horizontalTileBuffer = {}
    local bitSetter = 0x00
    local tileSize = 32
    -- Horizontally mirror all bits in each byte
    for byte = 1, tileSize, 1 do
        
        -- Convert byte to a number
        local currentByte = tonumber(tileBuffer[byte]:match("^$(.*)"), 16)
        horizontalTileBuffer[byte] = 0x00
        -- Bit 0 goes to bit 7
        bitSetter = (currentByte << 7) & 0x80
        horizontalTileBuffer[byte] = horizontalTileBuffer[byte] | bitSetter
        -- Bit 1 goes to bit 6
        bitSetter = (currentByte << 5) & 0x40
        horizontalTileBuffer[byte] = horizontalTileBuffer[byte] | bitSetter
        -- Bit 2 goes to bit 5
        bitSetter = (currentByte << 3) & 0x20
        horizontalTileBuffer[byte] = horizontalTileBuffer[byte] | bitSetter
        -- Bit 3 goes to bit 4
        bitSetter = (currentByte << 1) & 0x10
        horizontalTileBuffer[byte] = horizontalTileBuffer[byte] | bitSetter
        -- Bit 4 goes to bit 3
        bitSetter = (currentByte >> 1) & 0x08
        horizontalTileBuffer[byte] = horizontalTileBuffer[byte] | bitSetter
        -- Bit 5 goes to bit 2
        bitSetter = (currentByte >> 3) & 0x04
        horizontalTileBuffer[byte] = horizontalTileBuffer[byte] | bitSetter
        -- Bit 6 goes to bit 1
        bitSetter = (currentByte >> 5) & 0x02
        horizontalTileBuffer[byte] = horizontalTileBuffer[byte] | bitSetter
        -- Bit 7 goes to bit 0
        bitSetter = (currentByte >> 7) & 0x01
        horizontalTileBuffer[byte] = horizontalTileBuffer[byte] | bitSetter

        horizontalTileBuffer[byte] = ("$" .. string.format("%02X", horizontalTileBuffer[byte]))
        if byte == 1 then
            --print("Normal Byte: " .. tileBuffer[byte] .. " Mirrored Byte: " .. horizontalTileBuffer[byte])
        end
        
    end
    return horizontalTileBuffer
end


function makerVerticalTile(tileBuffer)
    local verticalTileBuffer = {}
    local byteBuffer0 = 0x00
    local byteBuffer1 = 0x00
    local byteBuffer2 = 0x00
    local byteBuffer3 = 0x00
    local tileSize = 32
    -- Horizontally mirror all bits in each byte
    for byte = 1, tileSize, 4 do
        -- Copy one row of the tile, starting from the bottom
        byteBuffer0 = tileBuffer[tileSize - (byte + 2)]
        byteBuffer1 = tileBuffer[tileSize - (byte + 1)]
        byteBuffer2 = tileBuffer[tileSize - (byte + 0)]
        byteBuffer3 = tileBuffer[tileSize - (byte - 1)]     -- I REALLY hate index by 1

        -- Paste that row into the vertically opposite row of the new tile buffer
        verticalTileBuffer[byte + 0] = byteBuffer0
        verticalTileBuffer[byte + 1] = byteBuffer1
        verticalTileBuffer[byte + 2] = byteBuffer2
        verticalTileBuffer[byte + 3] = byteBuffer3

        if byte == 1 then
            --print("Normal Byte: " .. tileBuffer[byte] .. " Mirrored Byte: " .. horizontalTileBuffer[byte])
        end
        
    end

    return verticalTileBuffer
end


-- Function for getting our tile data etc
local function recordTiles(currentX, currentY, numTiles, tilePatternTable, tilePatternTableHori, tilePatternTableVert, tilePatternTableHV, tileOffset, tileMapTable)
    -- We need to go through 256 tiles, 32 x 16
    local tileCount = numTiles
    local tileWidth = 8
    local tileHeight = 8
    local origX = currentX
    local origY = currentY
    local pixelColor = 0
    local newRow = false
    
    

    -- Go through a third of the screen
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
            
            -- Check if this is a new Tile Pattern, or a duplicate
            local tileStatus = 1
            local tileIndex = 2
            currentTile = compareTilePattern(tileBuffer, tilePatternTable, tilePatternTableHori, tilePatternTableVert, tilePatternTableHV)
            -- If it's a new pattern, then save the Tile Pattern and the associated color pattern
            if currentTile[tileStatus] == newTile then
                -- Save current tile
                tilePatternTable[#tilePatternTable + 1] = tileBuffer   
                -- Keep a record of its horizontal pattern
                tilePatternTableHori[#tilePatternTableHori + 1] = makeHorizontalTile(tileBuffer)
                -- Keep a record of its vertical pattern
                local verticalTile = makerVerticalTile(tileBuffer)
                tilePatternTableVert[#tilePatternTableVert + 1] = verticalTile
                -- Keep a record of its HV pattern
                tilePatternTableHV[#tilePatternTableHV + 1] = makeHorizontalTile(verticalTile)
                
                -- And save the Tile Pattern to the map
                tileMapTable[#tileMapTable + 1] = ("$" .. string.format("%04X", (tileOffset + currentTile[tileIndex])))
            else
                -- And save the Tile Pattern to the map
                tileMapTable[#tileMapTable + 1] = ("$" .. string.format("%04X", (tileOffset + currentTile[tileIndex]) | currentTile[tileStatus]))

            end                  
            
            --tileMapTable[tilePattern] = ("$" .. string.format("%02X", #tilePatternTable - 1) )
            --[[         else
            -- And save the Tile Pattern to the map
            tileMapTable[tilePattern] = ("$" .. string.format("%02X", tileMapNumber) )
        end ]]
    end
end


-- Function to write the Tile Pattern Data to inc files for use in SG-100/MSX projects
local function writeTilePatternToIncFile(file, tilePatternData, system)

    local tileIncFile = io.open(file, "w")
    local byteCount = 1
    -- Header comment message
    tileIncFile:write("; Tile Pattern file for use with " .. system .. " Z80 Assembly programs\n; By Steelfinger Studios\n")
    -- Write the pattern data
    local totalNumTiles
    if #tilePatternData > 448 then
       totalNumTiles = 448
    else
        totalNumTiles = #tilePatternData
    end
    for tile = 1, totalNumTiles, 1 do
        -- Beginning of the first row of tiles
        tileIncFile:write("; Tile Pattern #" .. tile - 1)
        tileIncFile:write("\n")
        tileIncFile:write(".DB ")
        -- Each tile is made of 32 bytes
        for tileBytes = 1, tileSize, 1 do
            --print(tilePatternData[byteCount])
            tileIncFile:write(tilePatternData[tile][tileBytes].." ")
            byteCount = byteCount + 1
            if tileBytes % 4 == 0 and tileBytes ~= 32 then
                tileIncFile:write("\n")
                tileIncFile:write(".DB ")
            end
            

        end
        tileIncFile:write(" \n")
    end
    
    tileIncFile:write("; End of file\n")
    tileIncFile:close();

end


-- Function to write the Tile Pattern Data to inc files for use in SG-100/MSX projects
local function writeTileMapToIncFile(file, tileMapTable, system)

    local mapIncFile = io.open(file, "w")
    local rowCount = 1
    -- Header comment message
    mapIncFile:write("; Tile Map file for use with " .. system .. " Z80 Assembly programs\n; By Steelfinger Studios\n")
    -- Write the pattern data
    local totalMapTiles
    if #tileMapTable > 768 then
       totalMapTiles = 768
    else
        totalMapTiles = #tileMapTable
    end
    -- Beginning of the first row of tiles
    mapIncFile:write("\n")
    mapIncFile:write("; Map Row #" .. rowCount - 1)
    mapIncFile:write("\n")
    mapIncFile:write(".DW ")
    for mapWord = 1, totalMapTiles, 1 do
        --print(tilePatternData[byteCount])
        mapIncFile:write(tileMapTable[mapWord].." ")
        
        if mapWord % 32 == 0 and mapWord ~= totalMapTiles then
            mapIncFile:write("\n")
            mapIncFile:write("; Map Row #" .. rowCount - 1)
            mapIncFile:write("\n")
            mapIncFile:write(".DW ")
            rowCount = rowCount + 1
        end
        

    end
    mapIncFile:write(" \n")
    mapIncFile:write("; End of file\n")
    mapIncFile:close();

end


-- Export drawing as a background
local function exportBackground()
    -- Check size of sprite
    if sprite.width ~= 256 or sprite.height ~= 192 then
        app.alert("Canvas needs to be 256x192")
        return
    end

    local numTiles = (sprite.width / 8) * (sprite.height / 8) 

    --Menu that pops up in Aseprite
    local dlg = Dialog()
    
    dlg:combobox{ id="systemType",
        label="System Type",
        option="SMS",
        options={ "SMS","GG" },
        }
    dlg:number{ id="tileOffsetValue", label="Tile Offset (Decimal)", text="0", value=0, min = 0, max=255}
    dlg:file{ id="tileFile",
            label="Tile-Pattern-File",
            title="SMS-GG Export",
            open=false,
            save=true,
            filename= spriteFilePath .. "Tiles.inc",
            filetypes={"inc"}}
    dlg:file{ id="mapFile",
            label="Tile-Map-File",
            title="SMS-GG Export",
            open=false,
            save=true,
            filename= spriteFilePath .. "Map.inc",
            filetypes={"inc"}}
    dlg:file{ id="paletteFile",
            label="Palette-File",
            title="SMS-GG Export",
            open=false,
            save=true,
            filename= spriteFilePath .. "Pal.inc",
            filetypes={"inc"}}
    

    dlg:button{ id="ok", text="OK" }
    dlg:button{ id="cancel", text="Cancel" }
    dlg:show()
    local data = dlg.data
    --local notPointer = {aBinaryValue}
    local tileBinary
    local mapBinary
    local paletteBinary

    if data.ok then
        -- Tile patterns f
        local tilePatternTable = {}
        local tilePatternTableHori = {}
        local tilePatternTableVert = {}
        local tilePatternTableHV = {}
        -- Tile Map
        local tileMapTable = {}

        -- Begin our conversion
        local x = 0
        local y = 0
        recordTiles(x, y, numTiles, tilePatternTable, tilePatternTableHori, tilePatternTableVert, tilePatternTableHV, data.tileOffsetValue, tileMapTable)
        -- Save the tiles to a file
        -- Write to file
        writeTilePatternToIncFile(data.tileFile, tilePatternTable, data.systemType)
        writeTileMapToIncFile(data.mapFile, tileMapTable, data.systemType)

        --Save the palette file
        writePaletteToIncFile(data.paletteFile, data.systemType)

        -- Write to file
        --writeTilePatternToIncFile(data.tileFile, tilePatternTable0, tilePatternTable1, tilePatternTable2)
        --writeTileMapToIncFile(data.mapFile, tileMapTable0, tileMapTable1, tileMapTable2)
        --writeColorMapToIncFile(data.colorFile, colorMapTable0, colorMapTable1, colorMapTable2)
    end
end



----------------------------------------------------------------------------------------
--Sprite
----------------------------------------------------------------------------------


-- Write sprite tiles to a file
local function writeSpriteTiles(tileFile, tilePatternData)
     local tilePatternIncFile = io.open(tileFile, "w")
    -- Header comment message
    tilePatternIncFile:write("; Tile Pattern file for use with sprites on SMS Z80 Assembly programs\n; By Steelfinger Studios\n \n")
    -- Write the Tile Patterns
    for tile = 1, #tilePatternData, 1 do
        -- Beginning of the first row of tiles
        tilePatternIncFile:write("; Sprite Pattern #" .. tile - 1)
        tilePatternIncFile:write("\n")
        tilePatternIncFile:write(".DB ")
        -- Each tile is made of 8 bytes
        for rowByte = 1, #tilePatternData[tile], 1 do
            tilePatternIncFile:write(tilePatternData[tile][rowByte].." ")
        end
        tilePatternIncFile:write("\n")
    end
    tilePatternIncFile:close();
end


local function exportSprite()
    -- Check size of sprite
    if sprite.width % 8 ~= 0 or sprite.height % 8 ~= 0 then
        app.alert("Sprite dimensions must be a multiple of 8!")
        return
    end

    local numTiles = (sprite.width / 8) * (sprite.height / 8)

    --Menu that pops up in Aseprite
    local dlg = Dialog()

    dlg:combobox{ id="systemType",
        label="System Type",
        option="SMS",
        options={ "SMS","GG" },
        }
    dlg:combobox{ id="spriteSize",
		  	  label="Sprite Size",
		  	  option="8x8 Pixels",
		  	  options={ "8x8 Pixels","8x16 Pixels" },
			}
    dlg:file{ id="tileFile",
            label="Tile-Pattern-File",
            title="SMS-GG Export",
            open=false,
            save=true,
            filename= spriteFilePath .. "Tiles.inc",
            filetypes={"inc"}}
    dlg:file{ id="paletteFile",
            label="Palette-File",
            title="SMS-GG Export",
            open=false,
            save=true,
            filename= spriteFilePath .. "Pal.inc",
            filetypes={"inc"}}
    
    dlg:button{ id="ok", text="OK" }
    dlg:button{ id="cancel", text="Cancel" }
    dlg:show()
    local data = dlg.data

    if data.ok then
         -- Tile patterns 
        local tilePatternTable = {}
        -- Begin our conversion
        local x = 0
        local y = 0

        --Save the palette file
        writePaletteToIncFile(data.paletteFile, data.systemType)
        
        -- First 256 tiles
        --recordSpriteTiles(x, y, numTiles, tilePatternTable, data.bigSprites )

        --writeSpriteTiles(data.tileFile, tilePatternTable)
    end
end

-- Start user interaction

-- Check constrains
if sprite == nil then
  app.alert("No Sprite...")
  return
end
if sprite.colorMode ~= ColorMode.INDEXED then
  app.alert("Sprite needs to be indexed")
  return
end


----------------------------------------------------------------------------------------
--Main Dialog of the script
----------------------------------------------------------------------------------

local dlg = Dialog()
dlg:button{ id="background", text="Export Background" }
dlg:button{ id="sprite", text="Export Sprite" }
dlg:button{ id="cancel", text="Cancel" }
dlg:show()
local data = dlg.data
if data.background then
    exportBackground()
elseif data.sprite then
    exportSprite()
else
    return
end



