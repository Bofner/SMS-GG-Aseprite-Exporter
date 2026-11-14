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
-- Applies Phantasy Star RLE Compression to map data as an inc file
----------------------------------------------------------------------------------
function mapCompressionIncPSRLE(mapFile, mapData, system, writeHeader)
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
    local headerSize = 0
    
    totalNumTiles = #mapData


    -- Comments in INC file
    mapIncFile:write("; PSRLE Compressed Map for " .. system .. " Z80 Assembly programs\n")
    mapIncFile:write("; By Steelfinger Studios\n")
    if writeHeader == true then
        mapIncFile:write("; -----------------\n")
        mapIncFile:write("; Raw Size Header" .. "\n")
        mapIncFile:write("; -----------------\n")
        mapIncFile:write(".DW $" .. string.format("%04X", totalNumTiles * 2) .. "\n")
        headerSize = 2
    end

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
    byteCount = byteCount + 1 + headerSize
    return byteCount

end


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
-- Applies Phantasy Star RLE Compression to map data as an bin file
----------------------------------------------------------------------------------
function mapCompressionBinPSRLE(mapFile, mapData, system, writeHeader)
    -- File
    local mapBinFile = io.open(mapFile, "w")
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
    local headerSize = 0
    
    totalNumTiles = #mapData


    -- Comments in INC file
    if writeHeader == true then
        mapBinFile:write(string.pack("<I2", totalNumTiles * 2))
        headerSize = 2
    end

    -- Go through the Attribute byte and then Index byte, one tile at a time to compress one Like-byte at a time
    for likeBytes = 1, likeByteDistance, 1 do
        -- Go through each tile once per bitplane
        if bitShift == 8 then

        elseif bitShift == 0 then

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
                        mapBinFile:write(string.char(runLength))
                        mapBinFile:write(string.char(previousByte))
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
                        mapBinFile:write(string.char(runLength))
                        byteCount = byteCount + 1
                        for writes = 1, #nonIdenticalBytes - 1, 1 do
                        -- Don't include the previous byte, since it is identical to testByte
                            mapBinFile:write(string.char( nonIdenticalBytes[writes]))
                            byteCount = byteCount + 1
                        end
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
                        mapBinFile:write(string.char(runLength))
                        mapBinFile:write(string.char(previousByte))
                    -- Reset variables
                    nonIdenticalBytes = nil
                    currentIdenticalByte = nil
                    currentIdenticalByte = nil
                    previousByte = nil
                    runLength = 0
                elseif runLength == 127 and nonIdenticalBytes ~= nil then
                    runLength = (runLength) | nonIdenticalBytesFlag       -- Set the Non-identical flag
                    mapBinFile:write(string.char(runLength))
                    byteCount = byteCount + 1
                    for writes = 1, #nonIdenticalBytes, 1 do
                    -- Don't include the previous byte, since it is identical to testByte
                        mapBinFile:write(string.char( nonIdenticalBytes[writes]))
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
        -- Reached the end of a bitplane
        if currentIdenticalByte ~= nil then
            -- Record the identical run
            mapBinFile:write(string.char(runLength))
            mapBinFile:write(string.char(previousByte))
            byteCount = byteCount + 2
        elseif nonIdenticalBytes ~= nil then
            runLength = (runLength) | nonIdenticalBytesFlag       -- Set the Non-identical flag
            mapBinFile:write(string.char(runLength))
            byteCount = byteCount + 1
            for writes = 1, #nonIdenticalBytes, 1 do
            -- Don't include the previous byte, since it is identical to testByte
                mapBinFile:write(string.char( nonIdenticalBytes[writes]))
                byteCount = byteCount + 1
            end
        elseif runLength == 1 then
            -- We reached the end of the bitplane with a runLength of only 1
            -- Treat this as non-identical
            runLength = (runLength) | nonIdenticalBytesFlag
            mapBinFile:write(string.char(runLength))
            mapBinFile:write(string.char( previousByte))
        end
        -- And the terminator byte
            mapBinFile:write(string.char(0))
            -- Reset variables
            nonIdenticalBytes = nil
            currentIdenticalByte = nil
            currentIdenticalByte = nil
            previousByte = nil
            runLength = 0
            bitShift = 8
    end
    mapBinFile:close();
    byteCount = byteCount + 1 + headerSize
    return byteCount

end