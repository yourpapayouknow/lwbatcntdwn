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

// 获取夜间暂缓时长秒数。
int lb_snzdur(int count);

// 检查给定时间是否属于夜间锁定区间。
bool lb_chknght(int hour, int minute);

// 判定是否应显示夜间锁定弹窗。
bool lb_shwnght(int hour, int minute, double now, double expire);

#endif

