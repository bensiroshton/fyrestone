#if !defined(_hw_h_)
#define _hw_h_

// Control
#define VDP_CTRL            0xc00004   // VDP control port
#define VDP_DATA            0xc00000   // VDP data port
#define HV_COUNTER          0xc00008   // H/V counter

// Registers: https://segaretro.org/Sega_Mega_Drive/VDP_registers
#define VDP_REG_MODE1       0x8000     // Mode register #1
#define VDP_REG_MODE2       0x8100     // Mode register #2
#define VDP_REG_MODE3       0x8B00     // Mode register #3
#define VDP_REG_MODE4       0x8c00     // Mode register #4

#define VDP_REG_PLANEA      0x8200     // Register: Plane A table address
#define VDP_REG_PLANEB      0x8400     // Register: Plane B table address
#define VDP_REG_SPRITE      0x8500     // Register: Sprite table address
#define VDP_REG_WINDOW      0x8300     // Register: Window table address
#define VDP_REG_HSCROLL     0x8d00     // Register: HScroll table address

#define VDP_REG_PLANE_SIZE  0x9000     // Register: Plane A and B size
#define VDP_REG_WINX        0x9100     // Register: Window X position/split
#define VDP_REG_WINY        0x9200     // Register: Window Y position/split
#define VDP_REG_INCR        0x8f00     // Register: Autoincrement
#define VDP_REG_BGCOL       0x8700     // Register: Background color
#define VDP_REG_HRATE       0x8a00     // Register: HBlank interrupt rate

#define VDP_REG_DMALEN_L    0x9300     // DMA length (low)
#define VDP_REG_DMALEN_H    0x9400     // DMA length (high)
#define VDP_REG_DMASRC_L    0x9500     // DMA source (low)
#define VDP_REG_DMASRC_M    0x9600     // DMA source (mid)
#define VDP_REG_DMASRC_H    0x9700     // DMA source (high)

// table addresses, technically these are dynamic and set using the registers above but unless we change these we can use these defines.
#define VDP_PLANEA          0xc000      // Plane A Table address
#define VDP_PLANEB          0xe000      // Plane B Table address
#define VDP_SPRITES         0xf000      // Sprites Table address
#define VDP_WINDOW          0xd000      // Window Table address

// VDP Memory
#define VDP_VRAM_ADDR_CMD   0x40000000 // Video RAM Address
#define VDP_CRAM_ADDR_CMD   0xc0000000 // Color RAM Address (Palettes)
#define VDP_VSRAM_ADDR_CMD  0x40000010 // Vertical Scroll RAM

#define VDP_VRAM_SIZE       65536
#define VDP_CRAM_SIZE       128
#define VDP_VSRAM_SIZE      80

// Tile Attributes
// 2 Bytes Per Tile
// 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01
// PR P1 P0 VF HF T9 T8 T7 T6 T5 T4 T3 T2 T1 T0 
//  T0 - T9 : Tile Number
//       HF : Horizontal Flip
//       VF : Vertical Flip
//  P0 - P1 : Palette Number
//       PR : Prioirty
#define TILE_NOFLIP         0x0000      // Don't flip (default)
#define TILE_HFLIP          0x0800      // Flip horizontally
#define TILE_VFLIP          0x1000      // Flip vertically
#define TILE_HVFLIP         0x1800      // Flip both ways (180° flip)

#define TILE_PAL0           0x0000      // Use palette 0 (default)
#define TILE_PAL1           0x2000      // Use palette 1
#define TILE_PAL2           0x4000      // Use palette 2
#define TILE_PAL3           0x6000      // Use palette 3

#define TILE_LOPRI          0x0000      // Low priority (default)
#define TILE_HIPRI          0x8000      // High priority

#endif
