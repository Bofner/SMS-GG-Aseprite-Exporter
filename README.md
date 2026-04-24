# A graphics exporter for Sega Master System and Game Gear on Aseprite

Convert your Aseprite drawings to data that a real Sega Master System or Sega Game Gear can read and display!

Supports background (and sprites in the future) graphics with any custom 16-color SMS or GG palettes. Colors that fall outside of the range of the SMS or GG will be cut to fit the bit-depth of the target system. 

Exports 3 file types:

### Tile Pattern Data

### Tile Map Data

### Color Palette Data

## How to Use

Make sure your drawing is set to index color mode, and doesn't exceed 16 colors. 

Select the SMS-GG Exporter from the scripts drop-down

Select the type of data you want to export (sprite support will be added in a future update)

Select a target system (SMS or GG), an offset for where in VRAM your tile will be stored (default is 0), and where you want your files to be exported

Then just implement the data into your source code and you're good to go!

## Updates

### Planned:
- Sprite support
  - 8x8
  - 8x16
- RLE compression option
- Backgrounds that are smaller than 256x192 (Like for cinematic cutscenes)


