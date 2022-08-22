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
    move.w  #VDP_REG_MODE2|0x44, (VDP_CTRL)         // Mode register #2; 0x44 = enable display, NTSC mode
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
// VDPSetVRAMAddressCommand
// d0.w = offset (in vram)
//----------------------------------------------------------------------
VDPSetVRAMAddressCommand:
    and.l   #0xffff, %d0
    lsl.l   #2, %d0
    lsr.w   #2, %d0
    swap    %d0
    or.l    #VDP_VRAM_ADDR_CMD, %d0
    move.l   %d0, (VDP_CTRL)
    rts

//----------------------------------------------------------------------
// VDPSetCRAMAddressCommand
// d0.w = offset (in cram)
//----------------------------------------------------------------------
VDPSetCRAMAddressCommand:
    and.l   #0xffff, %d0
    lsl.l   #2, %d0
    lsr.w   #2, %d0
    swap    %d0
    or.l    #VDP_CRAM_ADDR_CMD,  %d0
    move.l   %d0, (VDP_CTRL)
    rts

//----------------------------------------------------------------------
// VDPSetVSRAMAddressCommand
// d0.w = offset (in vsram)
//----------------------------------------------------------------------
VDPSetVSRAMAddressCommand:
    and.l   #0xffff, %d0
    lsl.l   #2, %d0
    lsr.w   #2, %d0
    swap    %d0
    or.l    #VDP_VSRAM_ADDR_CMD,  %d0
    move.l   %d0, (VDP_CTRL)
    rts

//----------------------------------------------------------------------
// VDPClearCRAM
//----------------------------------------------------------------------
VDPClearCRAM:
    VDPSetFixedControlAddress VDP_CRAM_ADDR_CMD
    move.l #VDP_CRAM_SIZE, %d0  // d0 = VDP_CRAM_SIZE
    lsr.w #2, %d0               // d0 /= 4
    subq.w #1, %d0              // d0 -= 1
.VDPClearCRAM_Loop:
    move.l #0, (VDP_DATA)
    dbf %d0, .VDPClearCRAM_Loop  // Loop until d0 == -1
    rts


//----------------------------------------------------------------------
// VDPLoadPalette
// a0 = paletteAddress.l
// d0 = palette slot.w
// d1 = numberOfPalettes.w
// Each palette holds 16 colors, 2 bytes per color (BGR), total 32 bytes.
// Colors are 12 bits, using 4 bits per color component.
//----------------------------------------------------------------------
VDPLoadPalette:
    mulu.w #32, %d0
    jsr VDPSetCRAMAddressCommand

    and.l   #0xffff, %d1
    subq.w #1, %d1
.VDPLoadPalette_Loop: // unrolled for each palette
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    dbf %d1, .VDPLoadPalette_Loop
    rts

//----------------------------------------------------------------------
// VDPLoadTileMap
// a0 = map address
// d0 = plane selection (VDP_PLANEA, VDP_PLANEB, VDP_WINDOW)
// d1 = number of tiles
//----------------------------------------------------------------------
VDPLoadTileMap:    
    jsr VDPSetVRAMAddressCommand

    and.l   #0xffff, %d1
    subq.w #1, %d1
.VDPLoadTileMap_Loop:
    move.w (%a0)+, (VDP_DATA)
    dbf %d1, .VDPLoadTileMap_Loop
    rts

//----------------------------------------------------------------------
// VDPLoadTileData
// a0.l = data address (source)
// d0.w = offset (in vram)
// d1.w = number of tiles
// each tile is 8 x 8, each row is 4 bytes.
//----------------------------------------------------------------------
VDPLoadTileData:
    and.l   #0xffff, %d1
    jsr VDPSetVRAMAddressCommand

    subq.w #1, %d1
.VDPLoadTileData_Loop: // unrolled for each tile
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    dbf %d1, .VDPLoadTileData_Loop
    rts

//----------------------------------------------------------------------
// VDPSetTileMapFillBlockLinear
// fill the tile map starting at X to (X + size)
// d0.w = map offset (in vram)
// d1.w = tile index start 
// d2.w = width (in tiles)
// d3.w = height (in tiles)
//----------------------------------------------------------------------
VDPSetTileMapFillBlockLinear:
    movm.l %d4, -(%sp)  // save d4

    and.l   #0xffff, %d2
    and.l   #0xffff, %d3
    // loop height in %d3
    subq.w #1, %d3
.VDPSetTileMapFillBlockLinear_LoopHeight:
    movm.l %d0, -(%sp)
    jsr VDPSetVRAMAddressCommand
    movm.l (%sp)+, %d0

    // loop width in %d4
    move.w %d2, %d4 // use width as a temp var in d4
    subq.w #1, %d4
.VDPSetTileMapFillBlockLinear_LoopWidth:
    move.w %d1, (VDP_DATA)
    add.w #1, %d1
    dbf %d4, .VDPSetTileMapFillBlockLinear_LoopWidth
    add.l #128, %d0  // go to next destination row, add map width x 2 (bytes), TODO: use VDP_REG_PLANE_SIZE.
    dbf %d3, .VDPSetTileMapFillBlockLinear_LoopHeight

    movm.l (%sp)+, %d4 // restore d4
    rts