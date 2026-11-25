-- Convert our 32-bit Aseprite color into GG 12-bit color
function convert32BitTo12BitColor(color)
	-- Isolate the 32-bit components of the color
	local hexR = color.red
	local hexG = color.green
	local hexB = color.blue
	-- Convert them into 12-bit color 
	local ggR = hexR & 0x00F0
	ggR = ggR >> 4
	local ggG = hexG & 0x00F0

	local ggB = hexB & 0x00F0
	ggB = ggB << 4
	--Put them into the 12-bit word in the form XXXXBBBB GGGGRRRR
	local gg12BitColor = 0x0000
	gg12BitColor = gg12BitColor | ggB
	gg12BitColor = gg12BitColor | ggG
	gg12BitColor = gg12BitColor | ggR

	return gg12BitColor
end

-- Convert our 32-bit Aseprite color into SMS 6-bit color
function convert32BitTo6BitColor(color)
	--Isolate the 32-bit components of the color
	local hexR = color.red
	local hexG = color.green
	local hexB = color.blue
	--Convert them into 6-bit color 
	local smsR = hexR & 0xC0
	smsR = smsR >> 6
	local smsG = hexG & 0xC0
	smsG = smsG >> 4
	local smsB = hexB & 0xC0
	smsB = smsB >> 2
	--Put them into the 6-bit byte in the form XXBBGGRR
	local sms6BitColor = 0x00
	sms6BitColor = sms6BitColor | smsB 
	sms6BitColor = sms6BitColor | smsG 
	sms6BitColor = sms6BitColor | smsR

	return sms6BitColor
end


----------------------------------------------------------------------------------------
-- Export Palette to INC file
----------------------------------------------------------------------------------
function writePaletteToIncFile(file, systemType, currentPal)
    local paletteFile = io.open(file, "w")
    local dataSize
    local writeSize
    paletteFile:write("; " .. systemType .. " Color Data\n")
    if systemType == "SMS" then
        dataSize = ".DB"
        writeSize = "%02X"
        for i = 0, 15, 1 do
            currentColor = convert32BitTo6BitColor(currentPal:getColor(i))
            paletteFile:write(dataSize .. " $" .. string.format(writeSize, currentColor) .. "\n")
        end
    else
        dataSize = ".DW"
        writeSize = "%04X"
        for i = 0, 15, 1 do
            currentColor = convert32BitTo12BitColor(currentPal:getColor(i))
            paletteFile:write(dataSize .. " $" .. string.format(writeSize, currentColor) .. "\n")
        end
    end
    paletteFile:write("; End of ".. systemType .. " Palette")
    paletteFile:close();
end


----------------------------------------------------------------------------------------
-- Export Palette to BIN file
----------------------------------------------------------------------------------
function writePaletteToBinFile(file, systemType, currentPal)
    local paletteFile = io.open(file, "w")
    local dataSize
    local writeSize
    if systemType == "SMS" then
        dataSize = ".DB"
        writeSize = "%02X"
        for i = 0, 15, 1 do
            currentColor = convert32BitTo6BitColor(currentPal:getColor(i))
            paletteFile:write(string.char(currentColor))
        end
    else
        dataSize = ".DW"
        writeSize = "%04X"
        for i = 0, 15, 1 do
            currentColor = convert32BitTo12BitColor(currentPal:getColor(i))
            paletteFile:write(string.pack(">I2", currentColor))
        end
    end
    paletteFile:close();
end