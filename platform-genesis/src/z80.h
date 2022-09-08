#include "hw.h"

.macro PauseZ80
    move.w  #0x100, (Z80_BUS_REQ)
.PauseZ80_Wait\@:
    btst    #0, (Z80_BUS_REQ)
    bne.s   .PauseZ80_Wait
.endm

.macro FastPauseZ80
    move.w  #0x100, (Z80_BUS_REQ)
.endm

.macro ResumeZ80
    move.w  #0x000, (Z80_BUS_REQ)
.endm
