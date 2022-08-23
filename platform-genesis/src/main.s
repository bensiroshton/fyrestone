#include "hw.h"
#include "func.i"
#include "data/claptrap-diffused-indexed.h"
#include "data/WillowBody_CYR.h"

TestPalette:
    dc.w    0x0333,0x0115,0x0356,0x0139,0x0031,0x0033,0x0785,0x05cd,0x0a9d,0x0eee,0x0154,0x04ee,0x098a,0x0743,0x0f95,0x079a

ClearPalette:
    dc.w    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

TestMap:
    dc.w    0x05c1
    dc.w    0x05c2
    dc.w    0x05c3
    dc.w    0x05c4

MainFont:
MainFontVRAM:
    dc.w    0xb400
MainFontCharStart:
    dc.w    WILLOWBODY_CYR_CHAR_START
MainFontCharCount:
    dc.w    WILLOWBODY_CYR_CHAR_COUNT

TestString:
    .asciz  "Hello World! This is a test string..."
    .align  2

func main
    jsr VDPInit
    //jsr PaletteTest
    //jsr TileMapTest
    jsr TileDataTest
    jsr LoadFont
    jsr TestText
.mainLoop:
    add.l #1, %d7 // debug ticker
    jmp .mainLoop

PaletteTest:
    move.l #TestPalette, %a0    // palette address
    move.w #0, %d0              // palette slot
    move.w #1, %d1              // number of palettes
    jsr VDPLoadPalette
    rts

TileMapTest:
    move.l #TestMap, %a0        // map address
    move.w #VDP_PLANEA, %d0     // plane selection
    move.w #4, %d1              // number of tiles
    jsr VDPLoadTileMap
    rts

LoadFont:
    move.l #willowbody_cyr_data, %a0
    move.w MainFontVRAM, %d0        // vram offset to store tiles
    move.w MainFontCharCount, %d1   // number of tiles
    jsr VDPLoadTileData
    rts

TestText:
    move.l #MainFont, %a0
    move.l #TestString, %a1
    move.w #VDP_PLANEA, %d0
    // TODO: figure out why we can't write to xy = 1,1.. something to do with odd addresses??
    move.w #2, %d1  // x
    move.w #0, %d2  // y
    move.w #0, %d3  // palette
    jsr VDPDrawText
    rts

TileDataTest:
    // load palette
    move.l #claptrap_diffused_indexed_palette, %a0
    move.w #0, %d0              // palette slot
    move.w #1, %d1              // number of palettes
    jsr VDPLoadPalette

    // load tiles
    move.l #claptrap_diffused_indexed_data, %a0
    move.w #32, %d0                                     // vram offset to store tiles (32 = skip first tile)
    move.w #CLAPTRAP_DIFFUSED_INDEXED_TILE_COUNT, %d1   // number of tiles
    jsr VDPLoadTileData

    // set tile indexes
    move.l #VDP_PLANEB, %d0     // offset in vram
    move.w #1, %d1              // start tile index
    move.w #CLAPTRAP_DIFFUSED_INDEXED_WIDTH_TILES, %d2
    move.w #CLAPTRAP_DIFFUSED_INDEXED_HEIGHT_TILES, %d3
    jsr VDPSetTileMapFillBlockLinear
    rts
