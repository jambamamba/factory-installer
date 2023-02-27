#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*KeypressCallback)(uint32_t key, uint32_t btn_id);
typedef void (*WindowEventCallback)(struct SDL_WindowEvent *e);
void initRenderingEngineSDL(KeypressCallback keypress_cb, WindowEventCallback window_event_cb);

#ifdef __cplusplus
}
#endif
