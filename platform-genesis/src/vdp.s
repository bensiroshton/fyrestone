#include "hw.h"

.text
    .global VDPInit
    .global VDPClearCRAM
    .global VDPLoadPalette
    .global VDPLoadTileMap
    .global VDPLoadTileData
    .global VDPSetTileMapFillBlockLinear

//----------------------------------------------------------------------
// get a VDP command address with a given offset
// since this is a macro it only works with fixed values, ie., you can't pass in a register for example.
// command:
//  VDP_VRAM_ADDR_CMD
//  VDP_CRAM_ADDR_CMD
//  VDP_VSRAM_ADDR_CMD
//----------------------------------------------------------------------
.macro VDPSetFixedControlAddress command, offset=0x0
move.l #((\offset & 0x3FFF) << 16) | ((\offset & 0xC000) >> 14) | \command, (VDP_CTRL)
.endm

//----------------------------------------------------------------------
// VDPInit
// 
//----------------------------------------------------------------------
VDPInit:
    tst.w   (VDP_CTRL)                              // put the VDP into a known state, by reading the ctrl port.
    move.w  #VDP_REG_MODE1|0x04, (VDP_CTRL)         // Mode register #1
    move.w  #VDP_REG_MODE2|0x40, (VDP_CTRL)         // Mode register #2; 0x40 = enable display, NTSC mode
    move.w  #VDP_REG_MODE3|0x00, (VDP_CTRL)         // Mode register #3
    move.w  #VDP_REG_MODE4|0x81, (VDP_CTRL)         // Mode register #4
    
    move.w  #VDP_REG_PLANEA|0x30, (VDP_CTRL)        // Plane A address
    move.w  #VDP_REG_PLANEB|0x07, (VDP_CTRL)        // Plane B address
    move.w  #VDP_REG_SPRITE|0x78, (VDP_CTRL)        // Sprite address
    move.w  #VDP_REG_WINDOW|0x34, (VDP_CTRL)        // Window address
    move.w  #VDP_REG_HSCROLL|0x3d, (VDP_CTRL)       // HScroll address
    
    move.w  #VDP_REG_PLANE_SIZE|0x01, (VDP_CTRL)    // Tilemap size;  0x01 = 512x256 pixels (64x32 cells), https://segaretro.org/Sega_Mega_Drive/Planes
    move.w  #VDP_REG_WINX|0x00, (VDP_CTRL)          // Window X split
    move.w  #VDP_REG_WINY|0x00, (VDP_CTRL)          // Window Y split
    move.w  #VDP_REG_INCR|0x02, (VDP_CTRL)          // Autoincrement
    move.w  #VDP_REG_BGCOL|0x00, (VDP_CTRL)         // Background color
    move.w  #VDP_REG_HRATE|0xff, (VDP_CTRL)         // HBlank IRQ rate
    rts

//----------------------------------------------------------------------
// VDPSetAddressCommand
// d0 = commandAddress.l
// d1 = offset.l
//----------------------------------------------------------------------
VDPSetAddressCommand:
    //move.l #((\offset & 0x3FFF) << 16) | ((\offset & 0xC000) >> 14) | \command, (VDP_CTRL)
    movm.l %d2, -(%sp)  // store registers
    move.l %d1, %d2

    and.l #0x3fff, %d1
    lsl.l #8, %d1
    lsl.l #8, %d1
    and.l #0xC000, %d2
    lsr.l #8, %d2
    lsr.l #6, %d2
    or.l %d2, %d1
    or.l %d1, %d0
    move.l %d0, (VDP_CTRL)

    movm.l (%sp)+, %d2 // restore registers
    rts

//----------------------------------------------------------------------
// VDPClearCRAM
//----------------------------------------------------------------------
VDPClearCRAM:
    VDPSetFixedControlAddress VDP_CRAM_ADDR_CMD
    move.w #VDP_CRAM_SIZE, %d0  // d0 = VDP_CRAM_SIZE
    lsr.w #2, %d0               // d0 /= 4
    subq.w #1, %d0              // d0 -= 1
.VDPClearCRAM_Loop:
    move.l #0, (VDP_DATA)
    dbf %d0, .VDPClearCRAM_Loop  // Loop until d0 == -1
    rts


//----------------------------------------------------------------------
// VDPLoadPalette
// a0 = paletteAddress.l
// d0 = numberOfPalettes.w
// d1 = palette slot.w
// Each palette holds 16 colors, 2 bytes per color (BGR), total 32 bytes.
// Colors are 12 bits, using 4 bits per color component.
//----------------------------------------------------------------------
VDPLoadPalette:
    movm.l %d0-%d1, -(%sp)
    move.l #VDP_CRAM_ADDR_CMD, %d0
    mulu.w #32, %d1
    jsr VDPSetAddressCommand
    movm.l (%sp)+, %d0-%d1

    subq.w #1, %d0
.VDPLoadPalette_Loop: // unrolled for each palette
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    dbf %d0, .VDPLoadPalette_Loop
    rts

//----------------------------------------------------------------------
// VDPLoadTileMap
// a0 = map address
// d0 = plane selection (VDP_PLANEA, VDP_PLANEB, VDP_WINDOW)
// d1 = number of tiles
//----------------------------------------------------------------------
VDPLoadTileMap:
    // TODO: support %d0 instead of hard coding VDP_PLANEA
    VDPSetFixedControlAddress VDP_VRAM_ADDR_CMD, VDP_PLANEA
    subq.w #1, %d1
.VDPLoadTileMap_Loop:
    move.w (%a0)+, (VDP_DATA)
    dbf %d1, .VDPLoadTileMap_Loop
    rts

//----------------------------------------------------------------------
// VDPLoadTileData
// a0 = data address
// d0 = number of tiles
// each tile is 8 x 8, each row is 4 bytes.
//----------------------------------------------------------------------
VDPLoadTileData:
    //movm.l %d0-%d1, -(%sp)
    //move.l #VDP_VRAM_ADDR_CMD, %d0
    //mulu.w #32, %d1
    //jsr VDPSetAddressCommand
    //movm.l (%sp)+, %d0-%d1
    VDPSetFixedControlAddress VDP_VRAM_ADDR_CMD, 0x20 // offset by 32 bytes for testing (leave background tile 0 empty)

    subq.w #1, %d0
.VDPLoadTileData_Loop: // unrolled for each tile
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    dbf %d0, .VDPLoadTileData_Loop
    rts

//----------------------------------------------------------------------
// VDPSetTileMapFillBlockLinear
// fill the tile map starting at X to (X + size)
// d0 = tile index start 
// d1 = map offset
// d2 = width (in tiles)
// d3 = height (in tiles)
//----------------------------------------------------------------------
VDPSetTileMapFillBlockLinear:
    movm.l %d4, -(%sp)  // save d4

    // loop height in %d3
    subq.w #1, %d3
.VDPSetTileMapFillBlockLinear_LoopHeight:
    // set vram offset
    movm.l %d0-%d1, -(%sp)
    move.l #VDP_VRAM_ADDR_CMD, %d0
    jsr VDPSetAddressCommand
    movm.l (%sp)+, %d0-%d1

    // loop width in %d4
    move.w %d2, %d4 // use width as a temp var in d4
    subq.w #1, %d4
.VDPSetTileMapFillBlockLinear_LoopWidth:
    move.w %d0, (VDP_DATA)
    add.w #1, %d0
    dbf %d4, .VDPSetTileMapFillBlockLinear_LoopWidth
    add.l #128, %d1  // go to next destination row, add map width x 2 (bytes), TODO: use VDP_REG_PLANE_SIZE.
    dbf %d3, .VDPSetTileMapFillBlockLinear_LoopHeight

    movm.l (%sp)+, %d4 // restore d4
    rts