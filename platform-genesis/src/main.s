#include "hw.h"
#include "func.i"

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
    jsr PaletteTest
    jsr TileTest
.mainLoop:
    add.l #1, %d0 // debug ticker
    jmp .mainLoop

PaletteTest:
    move.l #TestPalette, %a0    // palette address
    move.w #1, %d0              // number of palettes
    move.w #0, %d1              // palette slot
    jsr VDPLoadPalette
    rts

TileTest:
    move.l #TestMap, %a0        // map address
    move.l #VDP_REG_PLANEA, %d0 // plane selection
    move.w #4, %d1              // number of tiles
    jsr VDPLoadTileMap
    rts
