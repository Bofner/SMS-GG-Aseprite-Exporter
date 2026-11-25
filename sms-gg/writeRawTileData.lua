----------------------------------------------------------------------------------
-- write the Tile Pattern Data to inc files
----------------------------------------------------------------------------------
function writeRawTilePatternToIncFile(file, tilePatternData, system)
    local tileIncFile = io.open(file, "w")
    local byteCount = 1
    local tileSize = 32
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
            tileIncFile:write("$" .. string.format("%02X",tilePatternData[tile][tileBytes]) .." ")
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


----------------------------------------------------------------------------------
-- write the Tile Pattern Data to bin files
----------------------------------------------------------------------------------
function writeRawTilePatternToBinFile(file, tilePatternData, system)
    local rawTileBin = io.open(file, "w")
    local byteCount = 1
    local tileSize = 32
    -- Write the pattern data
    local totalNumTiles
    if #tilePatternData > 448 then
       totalNumTiles = 448
    else
        totalNumTiles = #tilePatternData
    end
    for tile = 1, totalNumTiles, 1 do
        for tileBytes = 1, tileSize, 1 do
            --print(tilePatternData[byteCount])
            rawTileBin:write(string.char(tilePatternData[tile][tileBytes]))
            byteCount = byteCount + 1
        end
    end
    rawTileBin:close();
end


