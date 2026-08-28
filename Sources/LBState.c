#include "LBState.h"

// 将整数限制到给定范围。
static int lb_clamp(int value, int minimum, int maximum) {
    if (value < minimum) return minimum;
    if (value > maximum) return maximum;
    return value;
}

// 初始化低电量状态。
void lb_init(LBState *state, int threshold, int duration) {
    state->threshold = lb_clamp(threshold, 1, 20);
    state->duration = lb_clamp(duration, 10, 300);
    state->remaining = state->duration;
    state->mode = LBModeHidden;
}

// 更新阈值和倒计时配置。
void lb_cfg(LBState *state, int threshold, int duration) {
    state->threshold = lb_clamp(threshold, 1, 20);
    state->duration = lb_clamp(duration, 10, 300);
    if (state->mode == LBModeHidden) state->remaining = state->duration;
}

// 根据电量和充电状态推进提示状态。
bool lb_feed(LBState *state, int percent, bool charging) {
    LBMode oldMode = state->mode;
    int oldRemaining = state->remaining;

    if (charging) {
        state->mode = LBModeHidden;
        state->remaining = state->duration;
    } else if (percent >= 0 && percent <= state->threshold && state->mode == LBModeHidden) {
        state->mode = LBModeCount;
        state->remaining = state->duration;
    }

    return oldMode != state->mode || oldRemaining != state->remaining;
}

// 推进一秒倒计时。
bool lb_tick(LBState *state) {
    if (state->mode != LBModeCount) return false;
    if (state->remaining > 0) state->remaining--;
    if (state->remaining == 0) state->mode = LBModeHold;
    return true;
}

