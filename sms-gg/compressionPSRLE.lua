-- Algorithm: 
-- We can think of a tile as being made up of 8 rows of pixels
-- Each row is separated into 4 bitplanes
-- We will organize the tile data by bitplanes, so bitplane 0 of every row
-- will be grouped, bitplane 1 of every row will be grouped and so on
-- From there, we will count the number of identical or non-identical bytes
-- in a row, using bit 7 as: 0-Identical, 1-Non-identical, for a maximum of
-- 127 btyes in a row
-- Identical bytes will be stored as $NN $bitplaneValue
-- Non Identical bytes will be stored as $NN $bitplaneValue0 $bitplaneValue1 ... $bitplaneValueN-1
-- $00 in the place where a $NN value would be expected will be the terminator byte

----------------------------------------------------------------------------------
-- Applies Phantasy Star RLE Compression to tile data as a bin file
----------------------------------------------------------------------------------
function tileCompressionBinPSRLE(tileFile, tilePatternData)
    -- File
    local tileBinFile = io.open(tileFile, "w")
    local byteCount = 0
    -- Bitplanes
    local bitplanesPerRow = 4                       -- Distance between bitplaneN in 2 consecutive rows
    -- Tiles
    local tileSizeBytes = 32                        -- 32 bytes in a tile
    local tileSizeRows = 8                          -- 8 Rows per tile
    local bitplanesPerTile = tileSizeRows * bitplanesPerRow
    local totalNumTiles = 0
    -- Compression
    local runLength = nil
    local previousByteValue = nil                   -- Value of the previous byte
    local currentIdenticalByte = nil                  -- Value of the Current Identical Byte in the run
    local nonIdenticalBytes = nil                    -- Array to hold the list of Non-identical byte runs
    local nonIdenticalBytesFlag = 0x80              -- Flag for Non-identical bytes
    
    -- Don't write more tiles than will fit in VRAM proper
    if #tilePatternData > 448 then
       totalNumTiles = 448
    else
        totalNumTiles = #tilePatternData
    end

    -- Go through each bitplane, one tile at a time to compress a single bitplane at a time
    for bitplane = 1, bitplanesPerRow, 1 do
        -- Go through each tile once per bitplane
        for tile = 1, totalNumTiles, 1 do
            -- Go through each role of pixels, compressing just a single bitplane of the row
            for row = bitplane, bitplanesPerTile, bitplanesPerRow do
                -- Check if this is a new run
                if previousByte ~= nil then
                -- Check what stage we are at in the compression                
                -- IDENTICAL
                    if tilePatternData[tile][row] == previousByte and currentIdenticalByte == nil 
                    and nonIdenticalBytes == nil then
                    -- This is a NEW IDENTICAL run
                        runLength = runLength + 1
                        currentIdenticalByte = tilePatternData[tile][row]

                    elseif tilePatternData[tile][row] == previousByte and currentIdenticalByte ~= nil then
                    -- This is a CONTINUING IDENTICAL run
                        runLength = runLength + 1

                    elseif tilePatternData[tile][row] ~= previousByte and currentIdenticalByte ~= nil then
                    -- This is the END OF AN IDENTICAL run
                        -- Record the identical run
                        tileBinFile:write(string.char(runLength))
                        tileBinFile:write(string.char(previousByte))
                        -- Reset Variables
                        byteCount = byteCount + 2
                        currentIdenticalByte = nil
                        previousByte = tilePatternData[tile][row]
                        runLength = 1

                    -- NON-IDENTICAL
                    elseif tilePatternData[tile][row] ~= previousByte and nonIdenticalBytes == nil 
                    and previousByte ~= nil then
                    -- This is the start of a NEW NON-IDENTICAL run
                        runLength = runLength + 1
                        nonIdenticalBytes = {previousByte, tilePatternData[tile][row]}
                        previousByte = tilePatternData[tile][row]
                        
                    elseif tilePatternData[tile][row] ~= previousByte and nonIdenticalBytes ~= nil then
                    -- This is a CONTINUING NON-IDENTICAL run
                        runLength = runLength + 1
                        nonIdenticalBytes[#nonIdenticalBytes + 1] = tilePatternData[tile][row]
                        previousByte = tilePatternData[tile][row]

                    elseif tilePatternData[tile][row] == previousByte and nonIdenticalBytes ~= nil and runLength < 127 then
                    -- This is the END OF A NON-IDENTICAL run
                        -- Record the non-identical run
                        runLength = (runLength - 1) | nonIdenticalBytesFlag       -- Set the Non-identical flag
                        tileBinFile:write(string.char(runLength))
                        byteCount = byteCount + 1
                        for writes = 1, #nonIdenticalBytes - 1, 1 do
                        -- Don't include the previous byte, since it is identical to tilePatternData[tile][row]
                            tileBinFile:write(string.char(nonIdenticalBytes[writes]))
                            byteCount = byteCount + 1
                        end
                        -- Reset variables
                        nonIdenticalBytes = nil
                        previousByte = tilePatternData[tile][row]
                        runLength = 2       -- We have hit an identical couple
                    end
                
                else
                -- First loop, so set up variables
                    previousByte = tilePatternData[tile][row]
                    runLength = 1
                end
                -- Check if we are at compresion max
                if runLength == 127 and currentIdenticalByte ~= nil then
                -- End of a max-length identical run
                    -- Record the identical run
                    tileBinFile:write(string.char(runLength))
                    tileBinFile:write(string.char(previousByte))
                    -- Reset variables
                    nonIdenticalBytes = nil
                    currentIdenticalByte = nil
                    currentIdenticalByte = nil
                    previousByte = nil
                    runLength = 0
                elseif runLength == 127 and nonIdenticalBytes ~= nil then
                    runLength = (runLength) | nonIdenticalBytesFlag       -- Set the Non-identical flag
                    tileBinFile:write(string.char(runLength))
                    byteCount = byteCount + 1
                    for writes = 1, #nonIdenticalBytes, 1 do
                    -- Don't include the previous byte, since it is identical to tilePatternData[tile][row]
                        tileBinFile:write(string.char(nonIdenticalBytes[writes]))
                        byteCount = byteCount + 1
                    end
                    -- Reset variables
                    nonIdenticalBytes = nil
                    currentIdenticalByte = nil
                    currentIdenticalByte = nil
                    previousByte = nil
                    runLength = 0
                end
            end
        end
        -- Reached the end of a bitplane
        if currentIdenticalByte ~= nil then
            -- Record the identical run
            tileBinFile:write(string.char(runLength))
            tileBinFile:write(string.char(previousByte))
            byteCount = byteCount + 2
        elseif nonIdenticalBytes ~= nil then
            runLength = (runLength) | nonIdenticalBytesFlag       -- Set the Non-identical flag
            tileBinFile:write(string.char(runLength))
            byteCount = byteCount + 1
            for writes = 1, #nonIdenticalBytes, 1 do
            -- Don't include the previous byte, since it is identical to tilePatternData[tile][row]
                tileBinFile:write(string.char(nonIdenticalBytes[writes]))
                byteCount = byteCount + 1
            end
        elseif runLength == 1 then
            -- We reached the end of the bitplane with a runLength of only 1
            -- Treat this as non-identical
            runLength = (runLength) | nonIdenticalBytesFlag
            tileBinFile:write(string.char(runLength))
            tileBinFile:write(string.char(previousByte))
        end
        -- And the terminator byte
            tileBinFile:write(string.char(0))
            -- Reset variables
            nonIdenticalBytes = nil
            currentIdenticalByte = nil
            currentIdenticalByte = nil
            previousByte = nil
            runLength = 0
    end
    tileBinFile:close();
    byteCount = byteCount + 1
    if byteCount < totalNumTiles * 32 then
        print("Success!\n" .. "File size reduced from " .. totalNumTiles * 32 .. " bytes to " .. byteCount .. " bytes!")
    elseif byteCount == totalNumTiles * 32 then
        print("No change!\n" .. "Raw file size and compressed file size are " .. byteCount .. " bytes!")
    else
        print("Uh oh!\n" .. "File size increased from " .. totalNumTiles * 32 .. " bytes to " .. byteCount .. " bytes!\n Consider exporting as raw data.")
    end
end


----------------------------------------------------------------------------------
-- Applies Phantasy Star RLE Compression to tile data as a inc file
----------------------------------------------------------------------------------
function tileCompressionIncPSRLE(tileFile, tilePatternData, system)
    -- File
    local tileIncFile = io.open(tileFile, "w")
    local byteCount = 0
    -- Bitplanes
    local bitplanesPerRow = 4                       -- Distance between bitplaneN in 2 consecutive rows
    -- Tiles
    local tileSizeBytes = 32                        -- 32 bytes in a tile
    local tileSizeRows = 8                          -- 8 Rows per tile
    local bitplanesPerTile = tileSizeRows * bitplanesPerRow
    local totalNumTiles = 0
    -- Compression
    local runLength = 0
    local previousByteValue = nil                   -- Value of the previous byte
    local currentIdenticalByte = nil                  -- Value of the Current Identical Byte in the run
    local nonIdenticalBytes = nil                    -- Array to hold the list of Non-identical byte runs
    local nonIdenticalBytesFlag = 0x80              -- Flag for Non-identical bytes
    
    -- Don't write more tiles than will fit in VRAM proper
    if #tilePatternData > 448 then
       totalNumTiles = 448
    else
        totalNumTiles = #tilePatternData
    end

    -- Comments in INC file
    tileIncFile:write("; PSRLE Compressed Tiles for " .. system .. " Z80 Assembly programs\n")
    tileIncFile:write("; By Steelfinger Studios\n")

    -- Go through each bitplane, one tile at a time to compress a single bitplane at a time
    for bitplane = 1, bitplanesPerRow, 1 do
        -- Go through each tile once per bitplane
        tileIncFile:write("; --------------\n")
        tileIncFile:write("; Bitplane " .. bitplane -1 .. "\n")
        tileIncFile:write("; --------------\n")
        for tile = 1, totalNumTiles, 1 do
            -- Go through each role of pixels, compressing just a single bitplane of the row
            for row = bitplane, bitplanesPerTile, bitplanesPerRow do
                -- Check if this is a new run
                if previousByte ~= nil then
                -- Check what stage we are at in the compression                
                -- IDENTICAL
                    if tilePatternData[tile][row] == previousByte and currentIdenticalByte == nil 
                    and nonIdenticalBytes == nil then
                    -- This is a NEW IDENTICAL run
                        runLength = runLength + 1
                        currentIdenticalByte = tilePatternData[tile][row]

                    elseif tilePatternData[tile][row] == previousByte and currentIdenticalByte ~= nil then
                    -- This is a CONTINUING IDENTICAL run
                        runLength = runLength + 1

                    elseif tilePatternData[tile][row] ~= previousByte and currentIdenticalByte ~= nil then
                    -- This is the END OF AN IDENTICAL run
                        -- Record the identical run
                        tileIncFile:write("; Identical Run\n")
                        tileIncFile:write(".DB ")
                        tileIncFile:write("$" .. string.format("%02X",runLength) .. " ")
                        tileIncFile:write("$" .. string.format("%02X",previousByte) .. "\n")
                        -- Reset Variables
                        byteCount = byteCount + 2
                        currentIdenticalByte = nil
                        previousByte = tilePatternData[tile][row]
                        runLength = 1

                    -- NON-IDENTICAL
                    elseif tilePatternData[tile][row] ~= previousByte and nonIdenticalBytes == nil 
                    and previousByte ~= nil then
                    -- This is the start of a NEW NON-IDENTICAL run
                        runLength = runLength + 1
                        nonIdenticalBytes = {previousByte, tilePatternData[tile][row]}
                        previousByte = tilePatternData[tile][row]
                        
                    elseif tilePatternData[tile][row] ~= previousByte and nonIdenticalBytes ~= nil then
                    -- This is a CONTINUING NON-IDENTICAL run
                        runLength = runLength + 1
                        nonIdenticalBytes[#nonIdenticalBytes + 1] = tilePatternData[tile][row]
                        previousByte = tilePatternData[tile][row]

                    elseif tilePatternData[tile][row] == previousByte and nonIdenticalBytes ~= nil and runLength < 127 then
                    -- This is the END OF A NON-IDENTICAL run
                        -- Record the non-identical run
                        runLength = (runLength - 1) | nonIdenticalBytesFlag       -- Set the Non-identical flag
                        tileIncFile:write("; Non-identical Run\n")
                        tileIncFile:write(".DB ")
                        tileIncFile:write("$" .. string.format("%02X",runLength) .. " ")
                        byteCount = byteCount + 1
                        for writes = 1, #nonIdenticalBytes - 1, 1 do
                        -- Don't include the previous byte, since it is identical to tilePatternData[tile][row]
                            tileIncFile:write("$" .. string.format("%02X", nonIdenticalBytes[writes]) .. " ")
                            byteCount = byteCount + 1
                        end
                        tileIncFile:write("\n")
                        -- Reset variables
                        nonIdenticalBytes = nil
                        previousByte = tilePatternData[tile][row]
                        currentIdenticalByte = previousByte
                        runLength = 2       -- We have hit an identical couple
                    end
                
                else
                -- First loop, so set up variables
                    previousByte = tilePatternData[tile][row]
                    runLength = 1
                end
                -- Check if we are at compresion max
                if runLength == 127 and currentIdenticalByte ~= nil then
                -- End of a max-length identical run
                    -- Record the identical run
                    tileIncFile:write("; Identical Run\n")
                    tileIncFile:write(".DB ")
                    tileIncFile:write("$" .. string.format("%02X",runLength) .. " ")
                    tileIncFile:write("$" .. string.format("%02X",previousByte) .. "\n")
                    -- Reset variables
                    nonIdenticalBytes = nil
                    currentIdenticalByte = nil
                    currentIdenticalByte = nil
                    previousByte = nil
                    runLength = 0
                elseif runLength == 127 and nonIdenticalBytes ~= nil then
                    runLength = (runLength) | nonIdenticalBytesFlag       -- Set the Non-identical flag
                    tileIncFile:write("; Non-identical Run\n")
                    tileIncFile:write(".DB ")
                    tileIncFile:write("$" .. string.format("%02X",runLength) .. " ")
                    byteCount = byteCount + 1
                    for writes = 1, runLength, 1 do
                    -- Don't include the previous byte, since it is identical to tilePatternData[tile][row]
                        tileIncFile:write("$" .. string.format("%02X", nonIdenticalBytes[writes]) .. " ")
                        byteCount = byteCount + 1
                    end
                    tileIncFile:write("\n")
                    -- Reset variables
                    nonIdenticalBytes = nil
                    currentIdenticalByte = nil
                    currentIdenticalByte = nil
                    previousByte = nil
                    runLength = 0
                end
            end
        end
        -- Reached the end of a bitplane
        if currentIdenticalByte ~= nil then
            -- Record the identical run
            tileIncFile:write("; Identical Run\n")
            tileIncFile:write(".DB ")
            tileIncFile:write("$" .. string.format("%02X",runLength) .. " ")
            tileIncFile:write("$" .. string.format("%02X",previousByte) .. "\n")
            byteCount = byteCount + 2
        elseif nonIdenticalBytes ~= nil then
            runLength = (runLength) | nonIdenticalBytesFlag       -- Set the Non-identical flag
            tileIncFile:write("; Non-identical Run\n")
            tileIncFile:write(".DB ")
            tileIncFile:write("$" .. string.format("%02X",runLength) .. " ")
            byteCount = byteCount + 1
            for writes = 1, #nonIdenticalBytes, 1 do
            -- Don't include the previous byte, since it is identical to tilePatternData[tile][row]
                tileIncFile:write("$" .. string.format("%02X", nonIdenticalBytes[writes]) .. " ")
                byteCount = byteCount + 1
            end
            tileIncFile:write("\n")
        elseif runLength == 1 then
            -- We reached the end of the bitplane with a runLength of only 1
            -- Treat this as non-identical
            runLength = (runLength) | nonIdenticalBytesFlag
            tileIncFile:write("; Non-identical Run\n")
            tileIncFile:write(".DB ")
            tileIncFile:write("$" .. string.format("%02X",runLength) .. " ")
            tileIncFile:write("$" .. string.format("%02X", previousByte) .. "\n")
        end
        -- And the terminator byte
            tileIncFile:write("; Terminator Byte\n")
            tileIncFile:write(".DB ")
            tileIncFile:write("$" .. string.format("%02X",0) .. "\n")
            -- Reset variables
            nonIdenticalBytes = nil
            currentIdenticalByte = nil
            currentIdenticalByte = nil
            previousByte = nil
            runLength = 0
    end
    tileIncFile:close();
    byteCount = byteCount + 1
    if byteCount < totalNumTiles * 32 then
        print("Success!\n" .. "File size reduced from " .. totalNumTiles * 32 .. " bytes to " .. byteCount .. " bytes!")
    elseif byteCount == totalNumTiles * 32 then
        print("No change!\n" .. "Raw file size and compressed file size are " .. byteCount .. " bytes!")
    else
        print("Uh oh!\n" .. "File size increased from " .. totalNumTiles * 32 .. " bytes to " .. byteCount .. " bytes!\n Consider exporting as raw data.")
    end
end


----------------------------------------------------------------------------------
-- Applies Phantasy Star RLE Compression to map data as an inc file
----------------------------------------------------------------------------------
function mapCompressionIncPSRLE(mapFile, mapData, system)
    -- File
    local mapIncFile = io.open(mapFile, "w")
    local byteCount = 0
    -- Bitplanes
    local likeByteDistance = 2                       -- Distance between two Like-bytes in the map (ATRIB or INDEX)
    -- Tiles
    local totalNumTiles = 0
    -- Maps
    local attributeByte = 0xFF00                    -- Mask for Attribute byte
    local patternByte = 0x00FF                      -- Mask for Pattern byte
    local bitShift = 0                              -- How many bits to shift by
    -- Compression
    local runLength = 0
    local previousByteValue = nil                   -- Value of the previous byte
    local currentIdenticalByte = nil                  -- Value of the Current Identical Byte in the run
    local nonIdenticalBytes = nil                    -- Array to hold the list of Non-identical byte runs
    local nonIdenticalBytesFlag = 0x80              -- Flag for Non-identical bytes
    
    totalNumTiles = #mapData


    -- Comments in INC file
    mapIncFile:write("; PSRLE Compressed Map for " .. system .. " Z80 Assembly programs\n")
    mapIncFile:write("; By Steelfinger Studios\n")

    -- Go through the Attribute byte and then Index byte, one tile at a time to compress one Like-byte at a time
    for likeBytes = 1, likeByteDistance, 1 do
        -- Go through each tile once per bitplane
        if bitShift == 8 then
            mapIncFile:write("; -----------------\n")
            mapIncFile:write("; Attribute Bytes" .. "\n")
            mapIncFile:write("; -----------------\n")
        elseif bitShift == 0 then
            mapIncFile:write("; -----------------\n")
            mapIncFile:write("; Pattern Bytes" .. "\n")
            mapIncFile:write("; -----------------\n")
        end
        
        for tile = 1, totalNumTiles, 1 do
                -- Adjusts the Attribute byte, but keeps the Pattern byte the same
                local testByte 
                if bitShift == 8 then
                    testByte = mapData[tile] >> bitShift
                else
                    testByte = mapData[tile] & 0x00FF
                end
                
                -- Check if this is a new run
                if previousByte ~= nil then
                -- Check what stage we are at in the compression                
                -- IDENTICAL
                    if testByte == previousByte and currentIdenticalByte == nil 
                    and nonIdenticalBytes == nil then
                    -- This is a NEW IDENTICAL run
                        runLength = runLength + 1
                        currentIdenticalByte = testByte

                    elseif testByte == previousByte and currentIdenticalByte ~= nil then
                    -- This is a CONTINUING IDENTICAL run
                        runLength = runLength + 1

                    elseif testByte ~= previousByte and currentIdenticalByte ~= nil then
                    -- This is the END OF AN IDENTICAL run
                        -- Record the identical run
                        mapIncFile:write("; Identical Run\n")
                        mapIncFile:write(".DB ")
                        mapIncFile:write("$" .. string.format("%02X",runLength) .. " ")
                        mapIncFile:write("$" .. string.format("%02X",previousByte) .. "\n")
                        -- Reset Variables
                        byteCount = byteCount + 2
                        currentIdenticalByte = nil
                        previousByte = testByte
                        runLength = 1

                    -- NON-IDENTICAL
                    elseif testByte ~= previousByte and nonIdenticalBytes == nil 
                    and previousByte ~= nil then
                    -- This is the start of a NEW NON-IDENTICAL run
                        runLength = runLength + 1
                        nonIdenticalBytes = {previousByte, testByte}
                        previousByte = testByte
                        
                    elseif testByte ~= previousByte and nonIdenticalBytes ~= nil then
                    -- This is a CONTINUING NON-IDENTICAL run
                        runLength = runLength + 1
                        nonIdenticalBytes[#nonIdenticalBytes + 1] = testByte
                        previousByte = testByte

                    elseif testByte == previousByte and nonIdenticalBytes ~= nil and runLength < 127 then
                    -- This is the END OF A NON-IDENTICAL run
                        -- Record the non-identical run
                        runLength = (runLength - 1) | nonIdenticalBytesFlag       -- Set the Non-identical flag
                        mapIncFile:write("; Non-identical Run\n")
                        mapIncFile:write(".DB ")
                        mapIncFile:write("$" .. string.format("%02X",runLength) .. " ")
                        byteCount = byteCount + 1
                        for writes = 1, #nonIdenticalBytes - 1, 1 do
                        -- Don't include the previous byte, since it is identical to testByte
                            mapIncFile:write("$" .. string.format("%02X", nonIdenticalBytes[writes]) .. " ")
                            byteCount = byteCount + 1
                        end
                        mapIncFile:write("\n")
                        -- Reset variables
                        nonIdenticalBytes = nil
                        previousByte = testByte
                        runLength = 2       -- We have hit an identical couple
                    end
                
                else
                -- First loop, so set up variables
                    previousByte = testByte
                    runLength = 1
                end
                -- Check if we are at compresion max
                if runLength == 127 and currentIdenticalByte ~= nil then
                -- End of a max-length identical run
                    -- Record the identical run
                    mapIncFile:write("; Identical Run\n")
                    mapIncFile:write(".DB ")
                        mapIncFile:write("$" .. string.format("%02X",runLength) .. " ")
                        mapIncFile:write("$" .. string.format("%02X",previousByte) .. "\n")
                    -- Reset variables
                    nonIdenticalBytes = nil
                    currentIdenticalByte = nil
                    currentIdenticalByte = nil
                    previousByte = nil
                    runLength = 0
                elseif runLength == 127 and nonIdenticalBytes ~= nil then
                    runLength = (runLength) | nonIdenticalBytesFlag       -- Set the Non-identical flag
                    mapIncFile:write("; Non-identical Run\n")
                    mapIncFile:write(".DB ")
                    mapIncFile:write("$" .. string.format("%02X",runLength) .. " ")
                    byteCount = byteCount + 1
                    for writes = 1, #nonIdenticalBytes, 1 do
                    -- Don't include the previous byte, since it is identical to testByte
                        mapIncFile:write("$" .. string.format("%02X", nonIdenticalBytes[writes]) .. " ")
                        byteCount = byteCount + 1
                    end
                    mapIncFile:write("\n")
                    -- Reset variables
                    nonIdenticalBytes = nil
                    currentIdenticalByte = nil
                    currentIdenticalByte = nil
                    previousByte = nil
                    runLength = 0
                end
        end
        -- Reached the end of a bitplane
        if currentIdenticalByte ~= nil then
            -- Record the identical run
            mapIncFile:write("; Identical Run\n")
            mapIncFile:write(".DB ")
            mapIncFile:write("$" .. string.format("%02X",runLength) .. " ")
            mapIncFile:write("$" .. string.format("%02X",previousByte) .. "\n")
            byteCount = byteCount + 2
        elseif nonIdenticalBytes ~= nil then
            runLength = (runLength) | nonIdenticalBytesFlag       -- Set the Non-identical flag
            mapIncFile:write("; Non-identical Run\n")
            mapIncFile:write(".DB ")
            mapIncFile:write("$" .. string.format("%02X",runLength) .. " ")
            byteCount = byteCount + 1
            for writes = 1, #nonIdenticalBytes, 1 do
            -- Don't include the previous byte, since it is identical to testByte
                mapIncFile:write("$" .. string.format("%02X", nonIdenticalBytes[writes]) .. " ")
                byteCount = byteCount + 1
            end
            mapIncFile:write("\n")
        elseif runLength == 1 then
            -- We reached the end of the bitplane with a runLength of only 1
            -- Treat this as non-identical
            runLength = (runLength) | nonIdenticalBytesFlag
            mapIncFile:write("; Non-identical Run\n")
            mapIncFile:write(".DB ")
            mapIncFile:write("$" .. string.format("%02X",runLength) .. " ")
            mapIncFile:write("$" .. string.format("%02X", previousByte) .. "\n")
        end
        -- And the terminator byte
            mapIncFile:write("; Terminator Byte\n")
            mapIncFile:write(".DB ")
            mapIncFile:write("$" .. string.format("%02X",0) .. "\n")
            -- Reset variables
            nonIdenticalBytes = nil
            currentIdenticalByte = nil
            currentIdenticalByte = nil
            previousByte = nil
            runLength = 0
            bitShift = 8
    end
    mapIncFile:close();
    byteCount = byteCount + 1
    if byteCount < totalNumTiles * 32 then
        print("Success!\n" .. "File size reduced from " .. totalNumTiles * 32 .. " bytes to " .. byteCount .. " bytes!")
    elseif byteCount == totalNumTiles * 32 then
        print("No change!\n" .. "Raw file size and compressed file size are " .. byteCount .. " bytes!")
    else
        print("Uh oh!\n" .. "File size increased from " .. totalNumTiles * 32 .. " bytes to " .. byteCount .. " bytes!\n Consider exporting as raw data.")
    end
end