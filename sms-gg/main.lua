----------------------------------------------------------------------------------
-- Script start
----------------------------------------------------------------------------------

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

-- Required files
require("palettes")
require("spriteTiles")
require("bgTilesAndMaps")
require("compressionPSRLE")



----------------------------------------------------------------------------------
-- Exports Sprite Data
----------------------------------------------------------------------------------
local function exportSprite(sprite, slices, currentPal, img)
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
            -- Choose compression type
            if data.compression == "Phantasy Star RLE" then
                tileCompressionIncPSRLE(data.tileFile, tilePatternTable, data.systemType, data.writeHeaderWord)
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
                tileCompressionBinPSRLE(data.tileFile, tilePatternTable, data.writeHeaderWord)
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


----------------------------------------------------------------------------------
-- Exports Background Data
----------------------------------------------------------------------------------
local function exportBackground(sprite, slices, currentPal, img)
    -- Check size of sprite
    if sprite.width ~= 256 or sprite.height ~= 192 then
        app.alert("Canvas needs to be 256x192")
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
            options={ "Phantasy Star RLE", "Raw" },
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
        dlg:check{ id="exportPalette",
            text="Export Palette",
            selected=false}
        dlg:check{ id="writeHeaderWord",
            text="Write Header Word For RAW Size",
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
        recordTiles(x, y, numTiles, tilePatternTable, tilePatternTableHori, tilePatternTableVert, tilePatternTableHV, data.tileOffsetValue, tileMapTable, slices, img)
        -- Save the tiles to a file
        -- Write to file
        local tileFileSize = 0
        local mapFileSize = 0
        -- INC file
        if data.fileType == "inc" then
            -- COMPRESSION
            if data.compression == "Phantasy Star RLE" then
                tileFileSize = tileCompressionIncPSRLE(data.tileFile, tilePatternTable, data.systemType, data.writeHeaderWord)
                mapFileSize = mapCompressionIncPSRLE(data.mapFile, tileMapTable, data.systemType, data.writeHeaderWord)
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
                writeRawTilePatternToIncFile(data.tileFile, tilePatternTable, data.systemType)
                writeRawTileMapToIncFile(data.mapFile, tileMapTable, data.systemType)
            end
            -- Save the palette file
            if data.exportPalette then
                writePaletteToIncFile(data.paletteFile, data.systemType, currentPal)
            end
            


        -- BIN file
        elseif data.fileType == "bin" then
            writeRawTilePatternToBinFile(data.tileFile, tilePatternTable, data.systemType, data.writeHeaderWord)
            writeRawTileMapToBinFile(data.mapFile, tileMapTable, data.systemType, data.writeHeaderWord)
            -- Save the palette file
            if data.exportPalette then
                writePaletteToBinFile(data.paletteFile, data.systemType, currentPal)
            end
        end
    end
end


----------------------------------------------------------------------------------
-- Exports Palette Data
----------------------------------------------------------------------------------
local function exportPalette(sprite, currentPal, img)
    --Menu that pops up in Aseprite
    local dlg = Dialog("Palette Export")
        local function updateFilePath()
            local data = dlg.data
            local base = app.fs.filePathAndTitle(data.paletteFile)
            dlg:modify{ id="paletteFile", filename = base .. "." .. data.fileType }
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
        dlg:file{ id= "paletteFile",
            title= "SMS-GG Export",
            filename=spriteFilePath .. "Pal",
            open=false,
            save=true,
            filetypes={ "inc", "bin"},
        }
        
        dlg:button{ id="ok", text="OK", focus = true}
        dlg:button{ id="cancel", text="Cancel"}
        dlg:show()
    local data = dlg.data

    if data.ok then
        local paletteFilePath = data.paletteFile --.. data.fileType
        if data.fileType == "inc" then
            writePaletteToIncFile(paletteFilePath, data.systemType, currentPal)
        elseif data.fileType == "bin" then
            writePaletteToBinFile(paletteFilePath, data.systemType, currentPal)
        end
        
    end
end


----------------------------------------------------------------------------------
-- Plugin entrance
----------------------------------------------------------------------------------
local function graphicsExport()
    local sprite = app.activeSprite

    -- Slices to be used for software bits
    local slices = sprite.slices
    for currentSlice = 1, #slices, 1 do
            if #slices[currentSlice].data < 5 then
            local dlg = Dialog{title = "Slice data formatting incorrect!"}
            dlg:label{  id    = "sliceError",
                        label = "Warning!",
                        text  = " Please set first five characters of the slice at (" .. slices[currentSlice].bounds.x .. "," .. slices[currentSlice].bounds.y .. ")" .. " to the desired bits (i.e. 10010)" }
            dlg:button{ id="cancel", text="Okay" }
            dlg:show()
            local data = dlg.data
            return

        end
    end


    -- Palette Constants
    local currentPal = Palette(sprite.palettes[1])
    local currentPalNumColors = #sprite.palettes[1]

    -- More colors than allowed by the hardware is a No-no
    if currentPalNumColors > 16 then
        local dlg = Dialog{title = "VDP color limit exceeded!"}
        dlg:label{  id    = "manyColors",
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

    -- Too few colors
    if currentPalNumColors < 16 then
        currentPal:resize(16)
    end


    -- Grab the title of our aseprite file
    if sprite then
        spriteFullPath = sprite.filename
        spriteFilePath = spriteFullPath:match("(.+)%..+$")
        spriteFileName = spriteFullPath:match("([^/\\]+)$"):match("(.+)%..+$")
    end


    -- Get a copy of the current sprite as a single layer
    local frame = app.activeFrame
    local img = Image(sprite.width, sprite.height, sprite.colorMode)
    img:drawSprite(sprite, frame)

        ----------------------------------------------------------------------------------
        -- Main Menu
        ----------------------------------------------------------------------------------
        -- Check constrains
        if sprite == nil then
        app.alert("No Sprite...")
        return
        end
        if sprite.colorMode ~= ColorMode.INDEXED then
        app.alert("Sprite needs to be indexed")
        return
        end


        local dlg = Dialog("SMS-GG Graphics Export")

        dlg:button{ id="background", text="Export Background", focus = false }
        dlg:button{ id="sprite", text="Export Sprite", focus = false  }
        dlg:newrow()
        dlg:button{ id="palette", text="Export Palette", focus = false  }
        dlg:button{ id="cancel", text="Cancel", focus = true }
        dlg:show()
        local data = dlg.data
        if data.background then
            exportBackground(sprite, slices, currentPal, img)
        elseif data.sprite then
            exportSprite(sprite, slices, currentPal, img)
        elseif data.palette then
            exportPalette(sprite, currentPal, img)
        else
            return
        end

end

----------------------------------------------------------------------------------
-- Plugin initialization
----------------------------------------------------------------------------------
function init(plugin)
  plugin:newCommand{
    id="sms_export_id",
    title="SMS-GG Export",
    group="file_export_2",
    onenabled = function() return app.activeSprite ~= nil end,
    onclick = graphicsExport
  }
end