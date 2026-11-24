----------------------------------------------------------------------------------
-- Exports Sprite Data
----------------------------------------------------------------------------------
function exportSprite(sprite, slices, currentPal, img)
    -- Check size of sprite
    if sprite.width % 8 ~= 0 or sprite.height % 8 ~= 0 then
        app.alert("Sprite dimensions must be a multiple of 8!")
        return
    end

    local numTiles = (sprite.width / 8) * (sprite.height / 8)
 
    --Menu that pops up in Aseprite
    local dlg = Dialog("Sprite Export")
        local function updateFilePath()
            local data = dlg.data
            local tileBase = app.fs.filePathAndTitle(data.tileFile)
            dlg:modify{ id="tileFile", filename = tileBase .. "." .. data.fileType }
            local paletteBase = app.fs.filePathAndTitle(data.paletteFile)
            dlg:modify{ id="paletteFile", filename = paletteBase .. "." .. data.fileType }
        end
        -- Enables the Header Word option only when PSRLE is selected
        local function updateHeaderWord()
            local data = dlg.data
            local compression = app.fs.filePathAndTitle(data.compression)
            if dlg.compression == "Phantasy Star RLE" then
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
            options={ "Raw", "Phantasy Star RLE" },
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
            filename= spriteFilePath .. "SpriteTiles.inc",
            filetypes={"inc","bin"}
        }
        dlg:file{ id="paletteFile",
            label="Palette-File",
            title="SMS-GG Export",
            open=false,
            save=true,
            filename= spriteFilePath .. "SpritePal.inc",
            filetypes={"inc","bin"}
        }
        dlg:check{ id="exportPalette",
            text="Export Palette",
            selected=false
        }
        dlg:check{ id="writeHeaderWord",
            text="Write Header Word For RAW Size",
            enabled=false,
            selected=false}
        dlg:button{ id="ok", text="OK", focus = true}
        dlg:button{ id="cancel", text="Cancel"}
        dlg:show()
    local data = dlg.data

    if data.ok then
        -- Tile patterns 
        local tilePatternTable = {}
        -- Begin our conversion
        local x = 0
        local y = 0
        recordSpriteTiles(x, y, numTiles, tilePatternTable, data.spriteSize, sprite, img)
        -- Save the tiles to a file
        -- Write to file as inc
        if data.fileType == "inc" then
            -- Write to file
            local tileFileSize = 0
            -- Choose compression type
            if data.compression == "Phantasy Star RLE" then
                tileFileSize = tileCompressionIncPSRLE(data.tileFile, tilePatternTable, data.systemType, data.writeHeaderWord)
                -- Tile File Size
                local tileMessage
                if tileFileSize < #tilePatternTable * 32 then
                    tileMessage = "Success! " .. "Tile File size reduced from " .. #tilePatternTable * 32 .. " bytes to " .. tileFileSize .. " bytes!"
                elseif tileFileSize == #tilePatternTable * 32 then
                    tileMessage = "No change! " .. "Raw file size and compressed file size are " .. tileFileSize .. " bytes!"
                else
                    tileMessage = "Uh oh! " .. "File size increased from " .. #tilePatternTable * 32 .. " bytes to " .. tileFileSize .. " bytes! Consider exporting as raw data."
                end
                app.alert{title="Compression Result", text={tileMessage}}
            else
                writeRawSpriteTilePatternToIncFile(data.tileFile, tilePatternTable, data.systemType)
            end
            
            -- Save the palette file
            if data.exportPalette then
                writePaletteToIncFile(data.paletteFile, data.systemType, currentPal)
            end
        -- Write to file as bin
        elseif data.fileType == "bin" then
            -- Choose compression type
            if data.compression == "Phantasy Star RLE" then
                tileFileSize =tileCompressionBinPSRLE(data.tileFile, tilePatternTable, data.writeHeaderWord)
                -- Tile File Size
                local tileMessage
                if tileFileSize < #tilePatternTable * 32 then
                    tileMessage = "Success! " .. "Tile File size reduced from " .. #tilePatternTable * 32 .. " bytes to " .. tileFileSize .. " bytes!"
                elseif tileFileSize == #tilePatternTable * 32 then
                    tileMessage = "No change! " .. "Raw file size and compressed file size are " .. tileFileSize .. " bytes!"
                else
                    tileMessage = "Uh oh! " .. "File size increased from " .. #tilePatternTable * 32 .. " bytes to " .. tileFileSize .. " bytes! Consider exporting as raw data."
                end
                app.alert{title="Compression Result", text={tileMessage}}
            else
                writeRawSpriteTilePatternToBinFile(data.tileFile, tilePatternTable, data.systemType)
            end
            -- Save the palette file
            if data.exportPalette then
                writePaletteToBinFile(data.paletteFile, data.systemType, currentPal)
            end
        end
    end
end