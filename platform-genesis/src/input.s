#include "hw.h"
#include "z80.h"

.text
    .global InputReadP1

//----------------------------------------------------------------------
// InputReadP1
// Read Controller Port 1
// https://plutiedev.com/controllers
// https://segaretro.org/Sega_Mega_Drive/Control_pad_inputs
//
// Return: d0 = 0000MXYZSACBRLDU
//----------------------------------------------------------------------
InputReadP1:
    move %d1, -(%sp)

    // TODO: go through this and better understand and tighten it up, its just copy/paste stuff right now.

    // read standard 3 button controller
    moveq   #0x40, %d0

    FastPauseZ80

    move.b  %d0, (IO_CTRL_1).l	    // TH pin to write, others to read
    nop
    nop
    nop
    nop
    
    move.b  %d0, (IO_DATA_1).l	    // TH to 1
    nop
    nop
    nop
    nop
    move.b  (IO_DATA_1).l, %d0

    ResumeZ80

    andi.b  #0x3f, %d0              // d0 = 00CBRLDU
    moveq   #0, %d1
    move.b  #0, (IO_DATA_1).l       // TH to 0
    nop
    nop
    nop
    nop
    move.b  (IO_DATA_1).l, %d1
    andi.b  #0x30, %d1              // d1 = 00SA
    lsl.b   #2, %d1                 // d1 = SA000000
    or.b    %d1, %d0                // d0 = SACBRLDU

    // now read extended buttons (6 button controller)
    moveq   #0, %d1
    move.b  #0x40, (IO_DATA_1).l    // TH to 1
    nop
    nop
    move.b	#0, (IO_DATA_1).l       // TH to 0
    nop
    nop
    move.b	#0x40, (IO_DATA_1).l    // TH to 1
    nop
    nop
    move.b  (IO_DATA_1).l, %d1
    move.b  #0, (IO_DATA_1).l       // TH to 0

    andi.w  #0xf, %d1               // d1 = 0000MXYZ
    lsl.w   #8, %d1                 // d1 = 0000MXYZ00000000
    or.w    %d1, %d0                // d0 = 0000MXYZSACBRLDU

    move (%sp)+, %d1
    rts
