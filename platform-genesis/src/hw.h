#if !defined(_HW_H_)
#define _HW_H_

#define VDP_CTRL            0xC00004   // VDP control port
#define VDP_DATA            0xC00000   // VDP data port
#define HV_COUNTER          0xC00008   // H/V counter

#define VDP_REG_MODE1       0x8000     // Mode register #1
#define VDP_REG_MODE2       0x8100     // Mode register #2
#define VDP_REG_MODE3       0x8B00     // Mode register #3
#define VDP_REG_MODE4       0x8C00     // Mode register #4

#define VDP_REG_PLANEA      0x8200     // Plane A table address
#define VDP_REG_PLANEB      0x8400     // Plane B table address
#define VDP_REG_SPRITE      0x8500     // Sprite table address
#define VDP_REG_WINDOW      0x8300     // Window table address
#define VDP_REG_HSCROLL     0x8D00     // HScroll table address

#define VDP_REG_SIZE        0x9000     // Plane A and B size
#define VDP_REG_WINX        0x9100     // Window X split position
#define VDP_REG_WINY        0x9200     // Window Y split position
#define VDP_REG_INCR        0x8F00     // Autoincrement
#define VDP_REG_BGCOL       0x8700     // Background color
#define VDP_REG_HRATE       0x8A00     // HBlank interrupt rate

#define VDP_REG_DMALEN_L    0x9300     // DMA length (low)
#define VDP_REG_DMALEN_H    0x9400     // DMA length (high)
#define VDP_REG_DMASRC_L    0x9500     // DMA source (low)
#define VDP_REG_DMASRC_M    0x9600     // DMA source (mid)
#define VDP_REG_DMASRC_H    0x9700     // DMA source (high)

#define VRAM_ADDR_CMD       0x40000000 // Video RAM Address
#define CRAM_ADDR_CMD       0xC0000000 // Color RAM Address (Palettes)
#define VSRAM_ADDR_CMD      0x40000010 // Vertical Scroll RAM

#define VRAM_SIZE           65536
#define CRAM_SIZE           128
#define VSRAM_SIZE          80

/*
.equ VDP_CTRL, 0xC00004
*/

#endif
