#include "hw.h"

.text
    .global VDPInit
    .global VDPClearCRAM
    .global VDPLoadPalette

// get a VDP command address with a given offset
// since this is a macro it only works with fixed values, ie., you can't pass in a register for example.
.macro VDPSetFixedControlAddress command, offset=0x0
move.l #((\offset & 0x3FFF) << 16) | ((\offset & 0xC000) >> 14) | \command, (VDP_CTRL)
.endm

//----------------------------------------------------------------------
// VDPInit
// 
//----------------------------------------------------------------------
VDPInit:
    tst.w   (VDP_CTRL)                      // put the VDP into a known state, by reading the ctrl port.
    lea     (VDP_CTRL), %a0   
    move.w  #VDP_REG_MODE1|0x04, (%a0)      // Mode register #1
    move.w  #VDP_REG_MODE2|0x04, (%a0)      // Mode register #2
    move.w  #VDP_REG_MODE3|0x00, (%a0)      // Mode register #3
    move.w  #VDP_REG_MODE4|0x81, (%a0)      // Mode register #4
    
    move.w  #VDP_REG_PLANEA|0x30, (%a0)     // Plane A address
    move.w  #VDP_REG_PLANEB|0x07, (%a0)     // Plane B address
    move.w  #VDP_REG_SPRITE|0x78, (%a0)     // Sprite address
    move.w  #VDP_REG_WINDOW|0x34, (%a0)     // Window address
    move.w  #VDP_REG_HSCROLL|0x3D, (%a0)    // HScroll address
    
    move.w  #VDP_REG_SIZE|0x01, (%a0)       // Tilemap size
    move.w  #VDP_REG_WINX|0x00, (%a0)       // Window X split
    move.w  #VDP_REG_WINY|0x00, (%a0)       // Window Y split
    move.w  #VDP_REG_INCR|0x02, (%a0)       // Autoincrement
    move.w  #VDP_REG_BGCOL|0x00, (%a0)      // Background color
    move.w  #VDP_REG_HRATE|0xFF, (%a0)      // HBlank IRQ rate
    rts

//----------------------------------------------------------------------
// VDPSetAddressCommand
// d0 = commandAddress.l
// d1 = offset.w
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
    VDPSetFixedControlAddress CRAM_ADDR_CMD
    move.w #CRAM_SIZE, %d0      // d0 = CRAM_SIZE
    lsr.w #2, %d0               // d0 /= 4
    subq.w #1, %d0              // d0 -= 1
.VDPClearCRAMLoop:
    move.l #0, (VDP_DATA)
    dbf %d0, .VDPClearCRAMLoop  // Loop until d0 == -1
    rts


//----------------------------------------------------------------------
// VDPLoadPalette
// a0 = paletteAddress.l
// d0 = numberOfPalettes.w
// d1 = palette slot.w
// Each palette holds 16 colors, 2 bytes per color (BGR), total 32 bytes.
//----------------------------------------------------------------------
VDPLoadPalette:
    movm.l %d0-%d1, -(%sp)
    move.l #CRAM_ADDR_CMD, %d0
    mulu.w #32, %d1
    jsr VDPSetAddressCommand
    movm.l (%SP)+, %d0-%d1

    subq.w #1, %d0
.VDPLoadPaletteLoop:
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    move.l (%a0)+, (VDP_DATA)
    dbf %d0, .VDPLoadPaletteLoop
    rts