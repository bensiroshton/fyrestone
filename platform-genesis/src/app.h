#if !defined(_app_h_)
#define _app_h_

#define SCREEN_WIDTH            320
#define SCREEN_HEIGHT           224
#define SCREEN_TILE_WIDTH       SCREEN_WIDTH / 8    // 40 
#define SCREEN_TILE_HEIGHT      SCREEN_HEIGHT / 8   // 28
#define FONT_VRAM               0xb400
#define VDP_MAP_WIDTH           64
#define VDP_MAP_HEIGHT          28
#define VDP_MAP_WIDTH_BYTES     VDP_MAP_WIDTH * 2

#endif