#include "func.i"

TestPalette:
    dc.w    0x0F0F,0x0115,0x0356,0x0139,0x0031,0x0033,0x0785,0x05CD,0x0A9D,0x0EEE,0x0154,0x04EE,0x098A,0x0743,0x0F95,0x079A

ClearPalette:
    dc.w    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

func main
    jsr VDPInit
    jsr test
.mainLoop:
    add.l #1, %d0
    jmp .mainLoop

func test
    move.l #TestPalette, -(%sp)
    move.w #1, -(%sp)
    jsr VDPLoadPalette
    addq.l #6, %sp // pop arguments off stack

    rts
