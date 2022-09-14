#include "hw.h"
#include "app.h"
#include "func.i"
#include "data/arid_badlands.h"
#include "data/borderlands-reduced.h"
#include "data/wasteland-tiles.h"
#include "data/WillowBody_CYR.h"

// Const
VersionLabel:
    .asciz  "Borderlands v0.00001"
    .align  2

 // Variables
.data

// Map


Test:           .long   0xf0f0f0f0
World:          .long   0   // address to tile map
WorldLayer:     .long   VDP_PLANEB
WorldTilePosX:  .word   0   // x tile position within tile map
WorldTilePosY:  .word   0   // y tile position within tile map
WorldTileMaxX:  .word   ARID_BADLANDS_PLANE_B_MAP_WIDTH - SCREEN_TILE_WIDTH
WorldTileMaxY:  .word   ARID_BADLANDS_PLANE_B_MAP_HEIGHT - SCREEN_TILE_HEIGHT
WorldPosX:      .long   0   // x pixel pos
WorldPosY:      .long   0   // y pixel pos
Test2:          .long   0xf1f1f1f1

// Controller Status
ControllerStateP1:  .long    0


// Code
.text 

// Main
func main
    jsr VDPInit
    jsr LoadWorldData
    jsr LoadOverlay
    jsr LoadFont
    jsr TestText
.mainLoop:
    jsr ReadInput
    jsr DrawWorld
    jmp .mainLoop

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

LoadOverlay:
    // load palette
    move.l #borderlands_reduced_palette, %a0
    move.w #1, %d0              // palette slot
    move.w #1, %d1              // number of palettes
    jsr VDPLoadPalette

    // load tiles pixels
    move.l #BorderlandsReduced, %a0
    move.w #WASTELAND_TILES_TILE_COUNT, %d0     // load after our world map tiles
    mulu.w #32, %d0                             // 32 bytes per tile, d0 = vram offset
    jsr VDPLoadTilePixelData

    // set tile indexes
    move.l #VDP_PLANEA, %d0                             // offset in vram
    add.l #5 * 2, %d0                                   // x dest (x2 bytes)
    add.l #MAP_WIDTH_BYTES * 5, %d0                     // y dest
    move.l #WASTELAND_TILES_TILE_COUNT, %d1             // start tile index (after world tiles)
    move.l #BORDERLANDS_REDUCED_WIDTH_TILES, %d2
    move.l #BORDERLANDS_REDUCED_HEIGHT_TILES, %d3
    move.l #1, %d4                                      // palette index to use
    jsr VDPFillTileMap
    rts

LoadWorldData:
    move.l  #AridBadlandsPlaneB, (World)

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

ReadInput:
    jsr InputReadP1             // d0 = 0000MXYZSACBRLDU
    move.l %d0, (ControllerStateP1)
    rts

DrawWorld:
    move.l (ControllerStateP1), %d0 // d0 = 0000MXYZSACBRLDU

    // get world tile positions
    move.w (WorldTilePosX), %d1 // x source -> VDPLoadTileIndexData
    move.w (WorldTilePosY), %d2 // y source -> VDPLoadTileIndexData
 
    // move with joystick?
.DrawWorld_BtnRight:
    btst #IO_BTN_BIT_RIGHT, %d0 // check
    bne.s .DrawWorld_BtnLeft    // skip?
    cmp.w (WorldTileMaxX), %d1  // skip if we can't go any further
    beq .DrawWorld_BtnLeft      // ..

    add.w #1, %d1               // tile x pos ++
.DrawWorld_BtnLeft:
    btst #IO_BTN_BIT_LEFT, %d0  // check
    bne.s .DrawWorld_BtnUp      // skip?
    cmpi #0, %d1                // skip if we can't go any further
    beq .DrawWorld_BtnUp        // ..

    sub.w #1, %d1               // tile x pos --
.DrawWorld_BtnUp:
    btst #IO_BTN_BIT_UP, %d0    // check
    bne.s .DrawWorld_BtnDown    // skip?
    cmpi #0, %d2                // skip if we can't go any further
    beq .DrawWorld_BtnDown      // ..

    sub.w #1, %d2               // action
.DrawWorld_BtnDown:
    btst #IO_BTN_BIT_DOWN, %d0  // check
    bne.s .DrawWorld_BtnFinish  // skip?
    cmp.w (WorldTileMaxY), %d2  // skip if we can't go any further
    beq .DrawWorld_BtnFinish      // ..

    add.w #1, %d2               // action
.DrawWorld_BtnFinish:
    move.w %d1, (WorldTilePosX)
    move.w %d2, (WorldTilePosY)

    // load index data
    move.l (World), %a0             // map index structure
    move.l (WorldLayer), %d0        // vram destination
                                    // x source, y source = d1, d2
    move.l #0, %d3                  // x dest
    move.l #0, %d4                  // y dest
    move.l #40, %d5                 // width
    move.l #28, %d6                 // height
    jsr VDPLoadTileIndexData

    rts


