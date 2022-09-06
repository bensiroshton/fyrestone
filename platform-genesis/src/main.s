#include "hw.h"
#include "func.i"
#include "data/claptrap-diffused-indexed.h"
#include "data/WillowBody_CYR.h"

// Some test data
TestPalette:
    dc.w    0x0333,0x0115,0x0356,0x0139,0x0031,0x0033,0x0785,0x05cd,0x0a9d,0x0eee,0x0154,0x04ee,0x098a,0x0743,0x0f95,0x079a

ClearPalette:
    dc.w    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

TestString:
    .asciz  "Hello World! This is a test string..."
    .align  2

TestString2:
    .asciz  "0123456789"
    .align  2

World:
    ds.l    1   // address to tile map
WorldTilePosX:
    ds.w    1   // x tile position within tile map
WorldTilePosY:
    ds.w    1   // y tile position within tile map


// Main
func main
    jsr VDPInit
    //jsr PaletteTest
    //jsr TileDataTest
    jsr DrawWorld
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

LoadFont:
    move.l #WillowbodyCyrFont, %a0
    move.w #0xb400, %d0         // vram offset to store tiles
    jsr VDPLoadTilePixelData
    rts

TestText:
    move.l #WillowbodyCyrFont, %a0
    move.l #TestString2, %a1
    move.w #VDP_PLANEA, %d0
    move.w #0, %d1  // x
    move.w #0, %d2  // y
    move.w #1, %d3  // palette
    jsr VDPDrawText
    
    move.l #WillowbodyCyrFont, %a0
    move.l #TestString, %a1
    move.w #VDP_PLANEA, %d0
    move.w #1, %d1  // x
    move.w #1, %d2  // y
    move.w #2, %d3  // palette
    jsr VDPDrawText

    move.l #WillowbodyCyrFont, %a0
    move.l #TestString, %a1
    move.w #VDP_PLANEA, %d0
    move.w #2, %d1  // x
    move.w #2, %d2  // y
    move.w #3, %d3  // palette
    jsr VDPDrawText

    move.l #WillowbodyCyrFont, %a0
    move.l #TestString, %a1
    move.w #VDP_PLANEA, %d0
    move.w #3, %d1  // x
    move.w #3, %d2  // y
    move.w #1, %d3  // palette
    jsr VDPDrawText

    rts

TileDataTest:
    // load palette
    move.l #claptrap_diffused_indexed_palette, %a0
    move.w #0, %d0              // palette slot
    move.w #1, %d1              // number of palettes
    jsr VDPLoadPalette

    // load tiles pixels
    move.l #ClaptrapIndexed, %a0
    move.w #32, %d0             // vram offset to store tiles (32 = skip first tile)
    jsr VDPLoadTilePixelData

    // set tile indexes
    move.l #VDP_PLANEB, %d0     // offset in vram
    move.w #1, %d1              // start tile index
    move.w #CLAPTRAP_DIFFUSED_INDEXED_WIDTH_TILES, %d2
    move.w #CLAPTRAP_DIFFUSED_INDEXED_HEIGHT_TILES, %d3
    jsr VDPFillTileMap
    rts

DrawWorld:
    // TODO: we don't want to load the palette and tile pixels here.

    // load palette
    move.l #wasteland_tiles_palette, %a0
    move.w #0, %d0              // palette slot
    move.w #1, %d1              // number of palettes
    jsr VDPLoadPalette

    // load tile pixels
    move.l #WastelandTiles, %a0
    move.w #0, %d0             // vram offset to store tiles
    jsr VDPLoadTilePixelData

    // load index data
    move.l #AridBadlandsPlaneB, %a0 // map index structure
    move.l #VDP_PLANEB, %d0         // vram destination
    move.l #10, %d1                  // x source
    move.l #10, %d2                 // y source
    move.l #0, %d3                  // x dest
    move.l #0, %d4                  // y dest
    move.l #40, %d5                 // width
    move.l #28, %d6                 // height
    jsr VDPLoadTileIndexData
