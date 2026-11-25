----------------------------------------------------------------------------------
-- Exports Background Data
----------------------------------------------------------------------------------
function exportBackground(sprite, slices, currentPal, img)
    -- Check size of sprite
    if sprite.width % 8 ~= 0 or sprite.height % 8 ~= 0 then
        app.alert("Canvas dimensions must be a multiple of 8!")
        return
    end

    local numTiles = (sprite.width / 8) * (sprite.height / 8) 

    -- Menu that pops up in Aseprite
    local dlg = Dialog("Background Export")
        -- Update the export file type
        local function updateFilePath()
            local data = dlg.data
            local tileBase = app.fs.filePathAndTitle(data.tileFile)
            dlg:modify{ id="tileFile", filename = tileBase .. "." .. data.fileType }
            local mapBase = app.fs.filePathAndTitle(data.mapFile)
            dlg:modify{ id="mapFile", filename = mapBase .. "." .. data.fileType }
            local paletteBase = app.fs.filePathAndTitle(data.paletteFile)
            dlg:modify{ id="paletteFile", filename = paletteBase .. "." .. data.fileType }
        end
        -- Enables the Header Word option only when PSRLE is selected
        local function updateHeaderWord()
            local data = dlg.data
            local compression = app.fs.filePathAndTitle(data.compression)
            if data.compression == "Phantasy Star RLE" then
                dlg:modify{ id="writeHeaderWord", enabled = true }
            else
                dlg:modify{ id="writeHeaderWord", enabled = false }
            end
        end
        dlg:combobox{ id="systemType",
            label="System Type",
            option="SMS",
            options={ "SMS","GG" },
            }
        dlg:combobox{ id="fileType",
            label="File Type",
            option="inc",
            options={ "inc","bin" },
            onchange= updateFilePath
            }
        dlg:combobox{ id="compression",
            label="Compression Algorithm",
            option="Phantasy Star RLE",
            options={ "Phantasy Star RLE", "Phantasy Star RLE Row",  "Raw" },
            onchange= updateHeaderWord
            }
        dlg:number{ id="tileOffsetValue", label="Tile Offset (Decimal)", text="0", value=0, min = 0, max=255}
        dlg:file{ id="tileFile",
                label="Tile-Pattern-File",
                title="SMS-GG Export",
                open=false,
                save=true,
                filename= spriteFilePath .. "Tiles",
                filetypes={"inc","bin"}}
        dlg:file{ id="mapFile",
                label="Tile-Map-File",
                title="SMS-GG Export",
                open=false,
                save=true,
                filename= spriteFilePath .. "Map",
                filetypes={"inc","bin"}}
        dlg:file{ id="paletteFile",
                label="Palette-File",
                title="SMS-GG Export",
                open=false,
                save=true,
                filename= spriteFilePath .. "Pal",
                filetypes={"inc","bin"}}

        dlg:check{ id="exportTiles",
            text="Export Tile Data",
            selected=true}

        dlg:check{ id="exportMap",
            text="Export Map Data",
            selected=true}

        dlg:check{ id="exportPalette",
            text="Export Palette",
            selected=false}

        dlg:newrow()
        
        if #sprite.tilesets == 1 then
            dlg:check{id="tileSetCheck",
                text="Use Tile Set for export data",
                selected=true}
        end

        dlg:check{ id="writeHeaderWord",
            text="Write RAW Tile Size Header",
            enabled=true,
            selected=false}
        
        dlg:button{ id="ok", text="OK", focus = true  }
        dlg:button{ id="cancel", text="Cancel" }
        dlg:show()
    local data = dlg.data
    -- local notPointer = {aBinaryValue}
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
        if data.tileSetCheck then
            recordTileSetTiles(sprite.tilesets[1], tilePatternTable, tileOffset, tileMapTable, slices)
            recordTileMapData(data.tileOffsetValue, tileMapTable, sprite, slices)
        else
            recordTiles(x, y, numTiles, tilePatternTable, tilePatternTableHori, tilePatternTableVert, tilePatternTableHV, data.tileOffsetValue, tileMapTable, slices, img)
        end
        -- Save the tiles to a file
        -- Write to file
        local tileFileSize = 0
        local mapFileSize = 0
        -- INC file
        if data.fileType == "inc" then
            -- COMPRESSION
            if data.compression == "Phantasy Star RLE" or data.compression == "Phantasy Star RLE Row" then
                if data.exportTiles then
                    tileFileSize = tileCompressionIncPSRLE(data.tileFile, tilePatternTable, data.systemType, data.writeHeaderWord)
                end
                if data.compression == "Phantasy Star RLE Row" and data.exportMap then
                    mapFileSize = mapCompressionIncPSRLERow(data.mapFile, tileMapTable, data.systemType, sprite)
                else
                    mapFileSize = mapCompressionIncPSRLE(data.mapFile, tileMapTable, data.systemType, data.writeHeaderWord)
                end
                
                -- Tile File Size
                local tileMessage
                if tileFileSize < #tilePatternTable * 32 then
                    tileMessage = "Success! " .. "Tile File size reduced from " .. #tilePatternTable * 32 .. " bytes to " .. tileFileSize .. " bytes!"
                elseif tileFileSize == #tilePatternTable * 32 then
                    tileMessage = "No change! " .. "Raw file size and compressed file size are " .. tileFileSize .. " bytes!"
                else
                    tileMessage = "Uh oh! " .. "File size increased from " .. #tilePatternTable * 32 .. " bytes to " .. tileFileSize .. " bytes! Consider exporting as raw data."
                end
                -- Map File Size
                local mapMessage
                if mapFileSize < #tileMapTable * 2 then
                    mapMessage = "Success! " .. "Tile File size reduced from " .. #tileMapTable * 2 .. " bytes to " .. mapFileSize .. " bytes!"
                elseif mapFileSize == #tileMapTable * 2 then
                    mapMessage = "No change! " .. "Raw file size and compressed file size are " .. mapFileSize .. " bytes!"
                else
                    mapMessage = "Uh oh! " .. "File size increased from " .. #tileMapTable * 2 .. " bytes to " .. mapFileSize .. " bytes! Consider exporting as raw data."
                end
                app.alert{title="Compression Result", text={tileMessage, mapMessage}}
            else
                if data.exportTiles then
                    writeRawTilePatternToIncFile(data.tileFile, tilePatternTable, data.systemType)
                end
                if data.exportMap then
                    writeRawTileMapToIncFile(data.mapFile, tileMapTable, data.systemType)
                end
            end
            -- Save the palette file
            if data.exportPalette then
                writePaletteToIncFile(data.paletteFile, data.systemType, currentPal)
            end

        -- BIN file
        elseif data.fileType == "bin" then
            if data.compression == "Phantasy Star RLE" or data.compression == "Phantasy Star RLE Row" then
                if data.exportTiles then
                    tileFileSize = tileCompressionBinPSRLE(data.tileFile, tilePatternTable, data.systemType, data.writeHeaderWord)
                end
                if data.exportMap then
                    if data.compression == "Phantasy Star RLE Row" then
                        app.alert("Binary Row PSRLE not yet implemented! Sorry!")
                    end
                    mapFileSize = mapCompressionBinPSRLE(data.mapFile, tileMapTable, data.systemType, data.writeHeaderWord)
                end
                -- Tile File Size
                local tileMessage
                if tileFileSize < #tilePatternTable * 32 then
                    tileMessage = "Success! " .. "Tile File size reduced from " .. #tilePatternTable * 32 .. " bytes to " .. tileFileSize .. " bytes!"
                elseif tileFileSize == #tilePatternTable * 32 then
                    tileMessage = "No change! " .. "Raw file size and compressed file size are " .. tileFileSize .. " bytes!"
                else
                    tileMessage = "Uh oh! " .. "File size increased from " .. #tilePatternTable * 32 .. " bytes to " .. tileFileSize .. " bytes! Consider exporting as raw data."
                end
                -- Map File Size
                local mapMessage
                if mapFileSize < #tileMapTable * 2 then
                    mapMessage = "Success! " .. "Tile File size reduced from " .. #tileMapTable * 2 .. " bytes to " .. mapFileSize .. " bytes!"
                elseif mapFileSize == #tileMapTable * 2 then
                    mapMessage = "No change! " .. "Raw file size and compressed file size are " .. mapFileSize .. " bytes!"
                else
                    mapMessage = "Uh oh! " .. "File size increased from " .. #tileMapTable * 2 .. " bytes to " .. mapFileSize .. " bytes! Consider exporting as raw data."
                end
                app.alert{title="Compression Result", text={tileMessage, mapMessage}}
            else
                writeRawTilePatternToBinFile(data.tileFile, tilePatternTable, data.systemType)
                writeRawTileMapToBinFile(data.mapFile, tileMapTable, data.systemType)
            end
            -- Save the palette file
            if data.exportPalette then
                writePaletteToBinFile(data.paletteFile, data.systemType, currentPal)
            end
        end
    end
end