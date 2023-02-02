#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*KeypressCallback)(uint32_t key, uint32_t btn_id);
void init_rendering_engine_sdl(KeypressCallback keypress_callback);

#ifdef __cplusplus
}
#endif
