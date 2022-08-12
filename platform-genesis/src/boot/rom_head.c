#include "genesis.h"

__attribute__((externally_visible))
const ROMHeader rom_header = {
#if (ENABLE_BANK_SWITCH != 0)
    "SEGA SSF        ", // console name
#elif (ENABLE_MEGAWIFI != 0)
    "SEGA MEGAWIFI   ", // console name
#else
    "SEGA MEGA DRIVE ", // console name
#endif
//  |----------------| 
    "(c)-=ben        ", // copyright information
//  |------------------------------------------------|
    "Borderlands                                     ", // domestic name
    "                                                ", // international name
//  |--------------|
    "GM 00000000-00", // serial number
    0x000, // checksum
//  |----------------|
    "JD              ", // I/O Support
    0x00000000, // ROM start address
#if (ENABLE_BANK_SWITCH != 0)
    0x003FFFFF, // ROM end address
#else
    0x000FFFFF, // ROM end address
#endif
    0xE0FF0000, // RAM backup start
    0xE0FFFFFF, // RAM backup end
    "RA", // RA = Save Ram
    0xF820, // SRAM type
    0x00200000, // SRAM Start
    0x0020FFFF, // SRAM end
//  |------------|
    "            ", // Modem Support
//  |----------------------------------------|
    "gotta start somewhere                   ", // notes
//  |----------------|
    "U               " // country support
};
