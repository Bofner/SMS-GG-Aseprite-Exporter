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
require("exportBackground")
require("exportSprite")
require("bgTilesAndMaps")
require("recordFromTileSet")
require("tileCompressionPSRLE")
require("mapCompressionPSRLE")
require("mapCompressionPSRLERow")

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
    local tileSet = sprite.tilesets[1]
    local testTile = tileSet:tile(1)
    local asepriteTileMap = sprite.layers[2].cels[1].image
    print("$" .. string.format("%08X", asepriteTileMap:getPixel(19,8)))
    
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