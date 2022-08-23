#include "hw.h"
#include "func.i"
#include "data/claptrap-diffused-indexed.h"

TestPalette:
    dc.w    0x0333,0x0115,0x0356,0x0139,0x0031,0x0033,0x0785,0x05cd,0x0a9d,0x0eee,0x0154,0x04ee,0x098a,0x0743,0x0f95,0x079a

ClearPalette:
    dc.w    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

TestMap:
    dc.w    0x05c1
    dc.w    0x05c2
    dc.w    0x05c3
    dc.w    0x05c4

func main
    jsr VDPInit
    //jsr PaletteTest
    //jsr TileMapTest
    jsr TileDataTest
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

TileDataTest:
    // load palette
    move.l #claptrap_diffused_indexed_palette, %a0
    move.w #0, %d0              // palette slot
    move.w #1, %d1              // number of palettes
    jsr VDPLoadPalette

    // load tiles
    move.l #claptrap_diffused_indexed_data, %a0
    move.w #32, %d0 // vram offset to store tiles (32 = skip first tile)
    move.w #CLAPTRAP_DIFFUSED_INDEXED_TILE_COUNT, %d1
    jsr VDPLoadTileData

    // set tile indexes
    move.l #VDP_PLANEB, %d0     // offset in vram
    move.w #1, %d1              // start tile index
    move.w #CLAPTRAP_DIFFUSED_INDEXED_WIDTH_TILES, %d2
    move.w #CLAPTRAP_DIFFUSED_INDEXED_HEIGHT_TILES, %d3
    jsr VDPSetTileMapFillBlockLinear
    rts
