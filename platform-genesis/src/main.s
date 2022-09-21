#include "hw.h"
#include "app.h"
#include "func.i"
#include "data/arid_badlands.h"
#include "data/borderlands-reduced.h"
#include "data/map_common.h"
#include "data/wasteland-tiles.h"
#include "data/WillowBody_CYR.h"

// Const
VersionLabel:
    .asciz  "Borderlands v0.00001"
    .align  2

 // Variables
.data

// Map


World:              .long   AridBadlandsGround   // address to tile map
WorldTilePosX:      .word   0   // x tile position within tile map
WorldTilePosY:      .word   0   // y tile position within tile map
WorldLastTilePosX:  .word   0   // last x tile position within tile map
WorldLastTilePosY:  .word   0   // last y tile position within tile map
WorldPosX:          .word   0   // x pixel pos
WorldPosY:          .word   0   // y pixel pos

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
    mov.l #WillowbodyCyrFont, %a0
    mov.w #FONT_VRAM, %d0         // vram offset to store tiles
    jsr VDPLoadTilePixelData
    rts

TestText:
    mov.l #WillowbodyCyrFont, %a0
    mov.l #VersionLabel, %a1
    mov.w #VDP_PLANEA, %d0
    mov.w #0, %d1  // x
    mov.w #0, %d2  // y
    mov.w #2, %d3  // palette
    jsr VDPDrawText
    
    rts

LoadOverlay:
    // load palette
    mov.l #borderlands_reduced_palette, %a0
    mov.w #1, %d0              // palette slot
    mov.w #1, %d1              // number of palettes
    jsr VDPLoadPalette

    // load tiles pixels
    mov.l #BorderlandsReduced, %a0
    mov.w #WASTELAND_TILES_TILE_COUNT, %d0     // load after our world map tiles
    mulu.w #32, %d0                             // 32 bytes per tile, d0 = vram offset
    jsr VDPLoadTilePixelData

    // set tile indexes
    mov.l #VDP_PLANEA, %d0                          // offset in vram
    add.l #5 * 2, %d0                               // x dest (x2 bytes)
    add.l #VDP_MAP_WIDTH_BYTES * 5, %d0             // y dest
    mov.l #WASTELAND_TILES_TILE_COUNT, %d1          // start tile index (after world tiles)
    mov.l #BORDERLANDS_REDUCED_WIDTH_TILES, %d2
    mov.l #BORDERLANDS_REDUCED_HEIGHT_TILES, %d3
    mov.l #1, %d4                                   // palette index to use
    jsr VDPFillTileMap
    rts

LoadWorldData:
    // load palette
    mov.l #wasteland_tiles_palette, %a0
    mov.w #0, %d0              // palette slot
    mov.w #1, %d1              // number of palettes
    jsr VDPLoadPalette

    // load tile pixels
    mov.l #WastelandTiles, %a0
    mov.w #0, %d0              // vram offset to store tiles
    jsr VDPLoadTilePixelData

    // draw initial screen
    mov.l (World), %a0              // map index structure
    mov.l MAP_OS_VRAM(%a0), %d0     // vram destination
    mov.w #0, %d1                   // d1, d2 = x source, y source
    mov.w #0, %d2
    mov.l #0, %d3                   // x dest
    mov.l #0, %d4                   // y dest
    mov.l #SCREEN_TILE_WIDTH + 1, %d5   // width
    mov.l #SCREEN_TILE_HEIGHT, %d6  // height
    jsr VDPLoadTileIndexData

    rts

ReadInput:
    jsr InputReadP1
    mov.l %d0, (ControllerStateP1)
    rts

DrawWorld:
    mov.l (World), %a0
    mov.l (ControllerStateP1), %d0 // d0 = 0000MXYZSACBRLDU

    // get world positions
    mov.w (WorldPosX), %d1        
    mov.w (WorldPosY), %d2         

    // move with joystick?
.DrawWorld_BtnRight:
    btst #IO_BTN_BIT_RIGHT, %d0     // check
    bne.s .DrawWorld_BtnLeft        // skip if button is not down
    addq.w #1, %d1                  // x++
.DrawWorld_BtnLeft:
    btst #IO_BTN_BIT_LEFT, %d0      // check
    bne.s .DrawWorld_BtnUp          // skip if button is not down
    subq.w #1, %d1                  // x--
.DrawWorld_BtnUp:
    btst #IO_BTN_BIT_UP, %d0        // check
    bne.s .DrawWorld_BtnDown        // skip if button is not down
    subq.w #1, %d2                  // y--
.DrawWorld_BtnDown:
    btst #IO_BTN_BIT_DOWN, %d0      // check
    bne.s .DrawWorld_BtnFinish      // skip if button is not down
    addq.w #1, %d2                  // y++
.DrawWorld_BtnFinish:

    // check and fix our tile bounds if needed
.DrawWorld_CheckXLow:
    cmpi #0, %d1
    bge .DrawWorld_CheckXHigh
    mov.w #0, %d1
.DrawWorld_CheckXHigh:
    cmp.w MAP_OS_MAX_PIXEL_X(%a0), %d1
    ble .DrawWorld_CheckYLow
    mov.w MAP_OS_MAX_PIXEL_X(%a0), %d1
.DrawWorld_CheckYLow:
    cmpi #0, %d2
    bge .DrawWorld_CheckYHigh
    mov.w #0, %d2
.DrawWorld_CheckYHigh:
    cmp.w MAP_OS_MAX_PIXEL_Y(%a0), %d2
    ble .DrawWorld_FinishCheckXY
    mov.w MAP_OS_MAX_PIXEL_Y(%a0), %d2
.DrawWorld_FinishCheckXY:
    // store our position
    mov.w %d1, (WorldPosX)
    mov.w %d2, (WorldPosY)
    //mov.w %d1, %d3  // prepare plane x scroll
    //mov.w %d2, %d4  // prepare plane y scroll
 
    // convert to tile positions
    lsr.w #3, %d1   // x pixel pos / 8
    lsr.w #3, %d2   // y pixel pos / 8

    // set initial xy dest to top/left of view plane
    mov.w %d1, %d3  // d3 = tile x
    mov.w %d2, %d4  // d4 = tile y
 
    // compare our current and last tile pos to see which  
    // side(s) we might need to draw new tiles.
    mov.w (WorldLastTilePosX), %d5
    mov.w (WorldLastTilePosY), %d6
    // store our current tile positions for next time
    mov.w %d1, (WorldLastTilePosX)
    mov.w %d2, (WorldLastTilePosY)

    cmp.w %d5, %d1
    beq .DrawWorld_DrawLeftRightTilesDone
    bgt .DrawWorld_DrawTilesRight
.DrawWorld_DrawTilesLeft:
    // draw left side
    // todo ...
    jmp .DrawWorld_DrawLeftRightTilesDone
.DrawWorld_DrawTilesRight:
    // draw right side
    // todo ...
    add.w #SCREEN_TILE_WIDTH, %d1
    add.w #SCREEN_TILE_WIDTH, %d3
.DrawWorld_DrawLeftRightTilesDone:

    // todo, if map did not move then dont draw

   // wrap d3 by vdp map width
 .DrawWorld_WrapVDPMapX:
    cmp.w #VDP_MAP_WIDTH, %d3
    blt .DrawWorld_WrapVDPMapY
    sub #VDP_MAP_WIDTH, %d3
    jmp .DrawWorld_WrapVDPMapX
.DrawWorld_WrapVDPMapY:
    // TODO: wrap Y


    // load index data
    //mov.l (World), %a0            // map index structure
    mov.l MAP_OS_VRAM(%a0), %d0     // vram destination
                                    // d1, d2 = x source, y source
    //mov.l #0, %d3                   // x dest
    //mov.l #0, %d4                   // y dest
    mov.l #1, %d5                  // width
    mov.l #28, %d6                  // height
    jsr VDPLoadTileIndexData

    // scroll view window
    mov.w #VDP_HSCROLL, %d0
    jsr VDPSetVRAMAddressCommand
    // upper word = h scroll plane A, lower word = plane B
    mov.w #0, %d0 // temp: were just moving 0 to plane A for now
    lsl.l #8, %d0 
    lsl.l #8, %d0
    mov.w (WorldPosX), %d0
    neg.w %d0
    mov.l %d0, (VDP_DATA)
 
    rts


