-- Algorithm: 
-- We can think of a tile as being made up of 8 rows of pixels
-- Each row is separated into 4 bitplanes
-- We will organize the tile data by bitplanes, so bitplane 0 of every row
-- will be grouped, bitplane 1 of every row will be grouped and so on
-- From there, we will count the number of identical or non-identical bytes
-- in a row, using bit 7 as: 1-Identical, 0-Non-identical, for a maximum of
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
                    if tilePatternData[tile][row] == previousByte and currentIdenticalByte == nil then
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
                        currentIdenticalByte = nil
                        previousByte = tilePatternData[tile][row]
                        runLength = 1

                    -- NON-IDENTICAL
                    elseif tilePatternData[tile][row] ~= previousByte and nonIdenticalBytes == nil then
                    -- This is a NEW NON-IDENTICAL run
                        runLength = runLength + 1
                        nonIdenticalBytes = {tilePatternData[tile][row]}
                        previousByte = tilePatternData[tile][row]

                    elseif tilePatternData[tile][row] ~= previousByte and nonIdenticalBytes ~= nil then
                    -- This is a CONTINUING NON-IDENTICAL run
                        runLength = runLength + 1
                        nonIdenticalBytes[#nonIdenticalBytes + 1] = tilePatternData[tile][row]
                        previousByte = tilePatternData[tile][row]

                    elseif tilePatternData[tile][row] == previousByte and nonIdenticalBytes ~= nil and runLength < 127 then
                    -- This is the END OF A NON-IDENTICAL run
                        -- Record the non-identical run
                        runLength = runLength | nonIdenticalBytesFlag       -- Set the Non-identical flag
                        tileBinFile:write(string.char(runLength))
                        for writes = 1, #nonIdenticalBytes - 1, 1 do
                        -- Don't include the previous byte, since it is identical to tilePatternData[tile][row]
                            tileFile:write(string.char(nonIdenticalBytes[writes]))
                        end
                        -- Reset variables
                        nonIdenticalBytes = nil
                        currentIdenticalByte = previousByte
                        runLength = 2
                    end
                
                else
                -- First loop, so set up variables
                    previousByte = tilePatternData[tile][row]
                    runLength = 1
                end
            end
        end
        -- Reached the end of a bitplane
        if currentIdenticalByte ~= nil then
            -- Record the identical run
            tileBinFile:write(string.char(runLength))
            tileBinFile:write(string.char(previousByte))
            -- Reset Variables
            currentIdenticalByte = nil
            previousByte = nil
            runLength = 1
        else
            runLength = runLength | nonIdenticalBytesFlag       -- Set the Non-identical flag
            tileBinFile:write(string.char(runLength))
            for writes = 1, #nonIdenticalBytes - 1, 1 do
            -- Don't include the previous byte, since it is identical to tilePatternData[tile][row]
                tileFile:write(string.char(nonIdenticalBytes[writes]))
            end
            -- Reset variables
            nonIdenticalBytes = nil
            currentIdenticalByte = nil
            runLength = 2
        end
    end
    -- And the terminator byte
    tileBinFile:write(string.char(0))
    tileBinFile:close();
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
                        tileIncFile:write(".DW ")
                        tileIncFile:write("$" .. string.format("%02X",runLength))
                        tileIncFile:write(string.format("%02X",previousByte) .. "\n")
                        -- Reset Variables
                        byteCount = byteCount + 2
                        currentIdenticalByte = nil
                        previousByte = tilePatternData[tile][row]
                        runLength = 1

                    -- NON-IDENTICAL
                    elseif tilePatternData[tile][row] ~= previousByte and nonIdenticalBytes == nil then
                    -- This is a NEW NON-IDENTICAL run
                        runLength = runLength + 1
                        nonIdenticalBytes = {tilePatternData[tile][row]}
                        nonIdenticalBytes = {previousByte}
                        previousByte = tilePatternData[tile][row]
                        
                    elseif tilePatternData[tile][row] ~= previousByte and nonIdenticalBytes ~= nil then
                    -- This is a CONTINUING NON-IDENTICAL run
                        runLength = runLength + 1
                        nonIdenticalBytes[#nonIdenticalBytes + 1] = tilePatternData[tile][row]
                        previousByte = tilePatternData[tile][row]

                    elseif tilePatternData[tile][row] == previousByte and nonIdenticalBytes ~= nil and runLength < 127 then
                    -- This is the END OF A NON-IDENTICAL run
                        -- Record the non-identical run
                        runLength = runLength | nonIdenticalBytesFlag       -- Set the Non-identical flag
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
                        -- Reset variables
                        nonIdenticalBytes = nil
                        previousByte = tilePatternData[tile][row]
                        runLength = 1
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
                    tileIncFile:write(".DW ")
                    tileIncFile:write("$" .. string.format("%02X",runLength))
                    tileIncFile:write(string.format("%02X",previousByte) .. "\n")
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
                    for writes = 1, #nonIdenticalBytes, 1 do
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
            tileIncFile:write(".DW ")
            tileIncFile:write("$" .. string.format("%02X",runLength))
            tileIncFile:write(string.format("%02X",previousByte) .. "\n")
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
        print("Success!\n File size reduced from " .. totalNumTiles * 32 .. " bytes to " .. byteCount .. " bytes!")
    else
        print("Uh oh!\n File size increased from " .. totalNumTiles * 32 .. " bytes to " .. byteCount .. " bytes!\n Consider exporting as raw data.")
    end
end