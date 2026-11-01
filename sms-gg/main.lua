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
            filename= spriteFilePath .. "SpriteTiles.inc",
            filetypes={"inc"}}
    dlg:file{ id="paletteFile",
            label="Palette-File",
            title="SMS-GG Export",
            open=false,
            save=true,
            filename= spriteFilePath .. "SpritePal.inc",
            filetypes={"inc"}}
    dlg:check{ id="exportPalette",
        text="Export Palette",
        selected=false}
    
    dlg:button{ id="ok", text="OK", focus = true   }
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
        -- Write to file
        writeSpriteTilePatternToIncFile(data.tileFile, tilePatternTable, data.systemType, data.spriteSize)

        --Save the palette file
        if data.exportPalette then
            writePaletteToIncFile(data.paletteFile, data.systemType, currentPal)
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
        dlg:check{ id="exportPalette",
            text="Export Palette",
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
        writeTilePatternToIncFile(data.tileFile, tilePatternTable, data.systemType)
        writeTileMapToIncFile(data.mapFile, tileMapTable, data.systemType)

        -- Save the palette file
        if data.exportPalette then
            writePaletteToIncFile(data.paletteFile, data.systemType, currentPal)
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
            dlg:label{ 	id    = "sliceError",
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


        local dlg = Dialog()

        dlg:button{ id="background", text="Export Background", focus = false }
        dlg:button{ id="sprite", text="Export Sprite", focus = false  }
        dlg:button{ id="cancel", text="Cancel", focus = true }
        dlg:show()
        local data = dlg.data
        if data.background then
            exportBackground(sprite, slices, currentPal, img)
        elseif data.sprite then
            exportSprite(sprite, slices, currentPal, img)
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

