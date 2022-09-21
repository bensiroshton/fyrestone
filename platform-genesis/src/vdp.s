#include "hw.h"
#include "app.h"

.text
    .global VDPInit
    .global VDPClearCRAM
    .global VDPLoadPalette
    .global VDPLoadTileIndexData
    .global VDPLoadTilePixelData
    .global VDPFillTileMap
    .global VDPDrawText
    .global VDPSetVRAMAddressCommand

//----------------------------------------------------------------------
// Get a VDP command address with a given offset
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
// VDPLoadTilePixelData
// a0.l = address to tile data structure (source)
// d0.w = write offset (in vram)
// each tile is 8 x 8, each row is 4 bytes.
//----------------------------------------------------------------------
VDPLoadTilePixelData:
    jsr VDPSetVRAMAddressCommand
    
    movm.l %a1, -(%sp)      // save registers
    
    move.l (%a0), %a1       // set tile data
    move.w 4(%a0), %d0      // set tile count
    and.l   #0xffff, %d0

    subq.w #1, %d0
.VDPLoadTilePixelData_Loop:      // unrolled for each tile
    move.l (%a1)+, (VDP_DATA)
    move.l (%a1)+, (VDP_DATA)
    move.l (%a1)+, (VDP_DATA)
    move.l (%a1)+, (VDP_DATA)
    move.l (%a1)+, (VDP_DATA)
    move.l (%a1)+, (VDP_DATA)
    move.l (%a1)+, (VDP_DATA)
    move.l (%a1)+, (VDP_DATA)
    dbf %d0, .VDPLoadTilePixelData_Loop

    movm.l (%sp)+, %a1      // restore registers
    rts

//----------------------------------------------------------------------
// VDPFillTileMap
// fill a square of the tile map starting at X to (X + size)
// d0.w = map offset (in vram)
// d1.w = tile index start 
// d2.w = width (in tiles)
// d3.w = height (in tiles)
// d4.w = pallette index
//----------------------------------------------------------------------
VDPFillTileMap:
    movm.l %d5-%d6, -(%sp)      // save registers

    lsl.w #8, %d4               // shift palette index << 13 to blend with tile properties
    lsl.w #5, %d4

    // loop height in %d3
    subq.w #1, %d3
.VDPSetTileMapFillBlockLinear_LoopHeight:
    // set vram dest
    movm.l %d0, -(%sp)
    jsr VDPSetVRAMAddressCommand
    movm.l (%sp)+, %d0

    // loop width 
    move.w %d2, %d5             // use width as a temp var in d5
    subq.w #1, %d5
.VDPSetTileMapFillBlockLinear_LoopWidth:
    move.w %d1, %d6             // d6 = palette index << 13 | tile id
    or.w %d4, %d6
    move.w %d6, (VDP_DATA)      // send to vram
    add.w #1, %d1               // increment tile id
    dbf %d5, .VDPSetTileMapFillBlockLinear_LoopWidth

    add.l #VDP_MAP_WIDTH_BYTES, %d0 // go to next destination row
    dbf %d3, .VDPSetTileMapFillBlockLinear_LoopHeight

    movm.l (%sp)+, %d5-%d6      // restore registers
    rts



//----------------------------------------------------------------------
// 
//----------------------------------------------------------------------
VDPWrapMapPos:

//----------------------------------------------------------------------
// VDPLoadTileIndexData
// a0 = address to tile map structure
// d0.w = vram destination (VDP_PLANEA, VDP_PLANEB, VDP_WINDOW)
// d1.w = x source
// d2.w = y source
// d3.w = x destination
// d4.w = y destination
// d5.w = width
// d6.w = height
//----------------------------------------------------------------------
VDPLoadTileIndexData:
    // set %d0 to initial vram position
    add.w %d3, %d0                  // add x offset to vram dest
    add.w %d3, %d0                  // repeat (2 bytes)
    mulu.w #VDP_MAP_WIDTH_BYTES, %d4    // update y dest offset with map width
    add.w %d4, %d0                  // add y offset to vram dest
                                    // d3 and d4 are now free to use
    // d0 = vram offset

    // store source row stride in d4 (width * 2 bytes)
    move.w 4(%a0), %d4
    lsl.w #1, %d4
    // d4 = row stride

    // replace a0 with our source data pointer at initial xy source positions
    move.l %d4, %d3                 // row bytes
    mulu.w %d2, %d3                 // y offset
    add.w %d1, %d3                  // x offset
    add.w %d1, %d3                  // repeat (2 bytes)
    add.l (%a0), %d3                // add source data offset
    move.l %d3, %a0                 // store in a0
    // a0 = source data offset

    subq.w #1, %d6                  // loop while height counter
    // d6 = height counter
.VDPLoadTileIndexData_YLoop:
    move.w %d5, %d3                 // copy width
    subq.w #1, %d3                  // loop while width counter
    // d3 = width counter

    move.w %d0, -(%sp)
    jsr VDPSetVRAMAddressCommand    // set our VRAM destination to d0
    move.w (%sp)+, %d0

.VDPLoadTileIndexData_XLoop:
    move.w (%a0)+, (VDP_DATA)
    dbf %d3, .VDPLoadTileIndexData_XLoop

    // move our src data pointer to the next row
    add.l %d4, %a0                  // add row stride (sourc map)
    sub.l %d5, %a0                  // subtract x offset we added in XLoop
    sub.l %d5, %a0                  // repeat (2 bytes)

    // update %d0 to our new VRAM destination
    add.w #VDP_MAP_WIDTH_BYTES, %d0     // add row stride (vram)

    dbf %d6, .VDPLoadTileIndexData_YLoop
    rts

//----------------------------------------------------------------------
// VDPDrawText
// a0 = address to font
// a1 = address to null terminated string
// d0.w = vram destination (VDP_PLANEA, VDP_PLANEB, VDP_WINDOW)
// d1.w = x
// d2.w = y
// d3.w = palette index
//----------------------------------------------------------------------
VDPDrawText:
    // set vram offset where we are going to draw our text
    mulu.w #VDP_MAP_WIDTH_BYTES, %d2 // y offset = y * map width
    mulu.w #2, %d1          // x offset = x * 2 bytes
    add.w %d2, %d1          // d1 = x offset + y offset
    add.w %d1, %d0          // d0 (plane offset) += xy offsets
    jsr VDPSetVRAMAddressCommand

    move #FONT_VRAM, %d2    // set d2 to our tile offset in vram
    lsr.w #5, %d2           // divide by 32 (get tile index offset)

    lsl.w #8, %d3           // shift palette index << 13
    lsl.w #5, %d3           // .

    move.b #0, %d1          // move 0 into d1 for string null check
.VDPDrawText_Loop:
    cmp.b (%a1), %d1        // test current character for a null
    beq .VDPDrawText_Finish // quit if null

    move.w #0, %d0          // clear d0
    move.b (%a1)+, %d0      // copy character to d0, prepare next
    sub.w 6(%a0), %d0       // subtract character start from d0 (this is our offset into the character tiles 0=first tile)
    add.w %d2, %d0          // add tile offset
    or.w %d3, %d0           // set palette
    move.w %d0, (VDP_DATA)  // set map tile to our character index
    jmp .VDPDrawText_Loop
.VDPDrawText_Finish:
    rts
