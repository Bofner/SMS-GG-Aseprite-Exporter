----------------------------------------------------------------------------------
-- write the Map Data to inc files 
----------------------------------------------------------------------------------
function writeRawTileMapToIncFile(file, tileMapTable, system)

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
        mapIncFile:write("$" .. string.format("%04X", tileMapTable[mapWord]) .. " ")
        
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


----------------------------------------------------------------------------------
-- write the Map Data to bin files 
----------------------------------------------------------------------------------
function writeRawTileMapToBinFile(file, tileMapTable, system)

    local mapIncFile = io.open(file, "w")
    local rowCount = 1
    -- Write the pattern data
    local totalMapTiles
    if #tileMapTable > 768 then
       totalMapTiles = 768
    else
        totalMapTiles = #tileMapTable
    end
    for mapWord = 1, totalMapTiles, 1 do
        --print(tilePatternData[byteCount])
        mapIncFile:write(string.pack(">I2", tileMapTable[mapWord]))
    end
    mapIncFile:close();
end