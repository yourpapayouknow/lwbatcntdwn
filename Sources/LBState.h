#ifndef LBSTATE_H
#define LBSTATE_H

#include <stdbool.h>

typedef enum {
    LBModeHidden = 0,
    LBModeCount = 1,
    LBModeHold = 2,
} LBMode;

typedef struct {
    int threshold;
    int duration;
    int remaining;
    LBMode mode;
} LBState;

// 初始化低电量状态。
void lb_init(LBState *state, int threshold, int duration);

// 更新阈值和倒计时配置。
void lb_cfg(LBState *state, int threshold, int duration);

// 根据电量和充电状态推进提示状态。
bool lb_feed(LBState *state, int percent, bool charging);

// 推进一秒倒计时。
bool lb_tick(LBState *state);

#endif

