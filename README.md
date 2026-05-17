# A graphics exporter for Sega Master System and Game Gear on Aseprite

Convert your Aseprite drawings to data that a real Sega Master System or Sega Game Gear can read and display!

Supports background and sprite graphics with any custom 16-color SMS or GG palettes. Colors that fall outside of the range of the SMS or GG will be cut to fit the bit-depth of the target system. 

Exports 3 file types:

### Tile Pattern Data

### Tile Map Data

### Color Palette Data

## How to Use

Make sure your drawing is set to index color mode, and doesn't exceed 16 colors. 

![](https://github.com/Bofner/SMS-GG-Aseprite-Exporter/blob/main/img/1.png)

Select the SMS-GG Exporter from the scripts drop-down

![](https://github.com/Bofner/SMS-GG-Aseprite-Exporter/blob/main/img/2.png)

Select the type of data you want to export 

![](https://github.com/Bofner/SMS-GG-Aseprite-Exporter/blob/main/img/3.png)

Select a target system (SMS or GG), an offset for where in VRAM your tile will be stored (default is 0), and where you want your files to be exported

![](https://github.com/Bofner/SMS-GG-Aseprite-Exporter/blob/main/img/4.png)

Then just implement the data into your source code and you're good to go!

## Updates
2026/05/15
- Added support for 8x8 and 8x16 sprites!
- Adjusted the default keyboard focus on the menus to make reading a little easier

### Planned:
- ~~Sprite support~~
  - ~~8x8~~
  - ~~8x16~~
- RLE compression option
- Support for backgrounds that are smaller than 256x192 (Like for cinematic cutscenes)


