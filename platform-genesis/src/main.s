#include "hw.h"
#include "func.i"
#include "data/claptrap-diffused-indexed.h"
#include "data/WillowBody_CYR.h"

// Some test data
TestPalette:
    dc.w    0x0333,0x0115,0x0356,0x0139,0x0031,0x0033,0x0785,0x05cd,0x0a9d,0x0eee,0x0154,0x04ee,0x098a,0x0743,0x0f95,0x079a

ClearPalette:
    dc.w    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

VersionLabel:
    .asciz  "Borderlands v0.00001"
    .align  2

.data // Variables

World:
    .long    0   // address to tile map
WorldTilePosX:
    .word    0   // x tile position within tile map
WorldTilePosY:
    .word    0   // y tile position within tile map

ControllerState:
    .long    0

.text // End Variables


// Main
func main
    jsr VDPInit
    //jsr PaletteTest
    //jsr TileDataTest
    jsr LoadWorldData
    jsr LoadFont
    jsr TestText
.mainLoop:
    jsr DrawWorld
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
    move.l #VersionLabel, %a1
    move.w #VDP_PLANEA, %d0
    move.w #0, %d1  // x
    move.w #0, %d2  // y
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

LoadWorldData:
    // load palette
    move.l #wasteland_tiles_palette, %a0
    move.w #0, %d0              // palette slot
    move.w #1, %d1              // number of palettes
    jsr VDPLoadPalette

    // load tile pixels
    move.l #WastelandTiles, %a0
    move.w #0, %d0              // vram offset to store tiles
    jsr VDPLoadTilePixelData

    rts

DrawWorld:
    jsr InputReadP1             // d0 = 0000MXYZSACBRLDU
    move.l %d0, (ControllerState)
    move.l %d0, %d5

    // get world tile positions
    move.w (WorldTilePosX), %d1 // x source -> VDPLoadTileIndexData
    move.w (WorldTilePosY), %d2 // y source -> VDPLoadTileIndexData

    // move with joystick?
.DrawWorld_BtnRight:
    btst #IO_BTN_BIT_RIGHT, %d0 // check
    bne.s .DrawWorld_BtnLeft    // skip?
    add.w #1, %d1               // action
.DrawWorld_BtnLeft:
    btst #IO_BTN_BIT_LEFT, %d0  // check
    bne.s .DrawWorld_BtnUp      // skip?
    sub.w #1, %d1               // action
.DrawWorld_BtnUp:
    btst #IO_BTN_BIT_UP, %d0    // check
    bne.s .DrawWorld_BtnDown    // skip?
    sub.w #1, %d2               // action
.DrawWorld_BtnDown:
    btst #IO_BTN_BIT_DOWN, %d0  // check
    bne.s .DrawWorld_BtnFinish  // skip?
    add.w #1, %d2               // action
.DrawWorld_BtnFinish:
    move.w %d1, (WorldTilePosX)
    move.w %d2, (WorldTilePosY)

    // load index data
    move.l #AridBadlandsPlaneB, %a0 // map index structure
    move.l #VDP_PLANEB, %d0         // vram destination
                                    // x source, y source = d1, d2
    move.l #0, %d3                  // x dest
    move.l #0, %d4                  // y dest
    move.l #40, %d5                 // width
    move.l #28, %d6                 // height
    jsr VDPLoadTileIndexData

    rts
