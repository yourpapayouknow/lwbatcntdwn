#include <assert.h>
#include <stdio.h>

#include "LBState.h"

// 验证默认阈值触发倒计时。
static void tst_trigger(void) {
    LBState state;
    lb_init(&state, 5, 60);
    assert(state.mode == LBModeHidden);
    assert(!lb_feed(&state, 6, false));
    assert(lb_feed(&state, 5, false));
    assert(state.mode == LBModeCount);
    assert(state.remaining == 60);
    lb_tick(&state);
    assert(!lb_feed(&state, 4, false));
    assert(state.remaining == 59);
}

// 验证倒计时归零后保持提示。
static void tst_hold(void) {
    LBState state;
    lb_init(&state, 5, 10);
    lb_feed(&state, 4, false);
    for (int index = 0; index < 10; index++) assert(lb_tick(&state));
    assert(state.mode == LBModeHold);
    assert(state.remaining == 0);
    assert(!lb_tick(&state));
    lb_feed(&state, 80, false);
    assert(state.mode == LBModeHold);
}

// 验证接通电源是唯一解除条件。
static void tst_charge(void) {
    LBState state;
    lb_init(&state, 10, 30);
    lb_feed(&state, 9, false);
    lb_tick(&state);
    assert(lb_feed(&state, 9, true));
    assert(state.mode == LBModeHidden);
    assert(state.remaining == 30);
}

// 验证非法配置和未知电量边界。
static void tst_bounds(void) {
    LBState state;
    lb_init(&state, -1, 999);
    assert(state.threshold == 1);
    assert(state.duration == 300);
    assert(!lb_feed(&state, -1, false));
    lb_cfg(&state, 99, 0);
    assert(state.threshold == 20);
    assert(state.duration == 10);
    assert(state.remaining == 10);
}

// 验证夜间暂缓时长递减与上限。
static void tst_snz(void) {
    assert(lb_snzdur(0) == 30 * 60);
    assert(lb_snzdur(1) == 10 * 60);
    assert(lb_snzdur(2) == 5 * 60);
    assert(lb_snzdur(3) == 0);
    assert(lb_snzdur(4) == 0);
    assert(lb_snzdur(-1) == 0);
}

// 验证夜间锁定时段判定。
static void tst_nght(void) {
    assert(!lb_chknght(-1, 0));
    assert(!lb_chknght(24, 0));
    assert(!lb_chknght(7, 60));
    assert(!lb_chknght(23, 29));
    assert(lb_chknght(23, 30));
    assert(lb_chknght(23, 59));
    assert(lb_chknght(0, 0));
    assert(lb_chknght(6, 59));
    assert(!lb_chknght(7, 0));
    assert(!lb_chknght(7, 1));
    assert(!lb_chknght(12, 0));
}

// 验证弹窗显示判定与早晨/暂缓边界条件。
static void tst_shw(void) {
    // 白天无论是否有暂缓时间均不弹窗。
    assert(!lb_shwnght(7, 0, 1000.0, 0.0));
    assert(!lb_shwnght(7, 0, 1000.0, 2000.0));
    assert(!lb_shwnght(12, 0, 1000.0, 0.0));
    assert(!lb_shwnght(23, 29, 1000.0, 0.0));

    // 刚刚跨过 07:00 晨间解除点。
    assert(!lb_shwnght(7, 0, 1000.0, 500.0));
    assert(!lb_shwnght(7, 0, 1000.0, 1500.0));

    // 06:59 临近早晨点：无暂缓应弹窗，暂缓未过期不弹窗，过期恢复弹窗。
    assert(lb_shwnght(6, 59, 1000.0, 0.0));
    assert(!lb_shwnght(6, 59, 1000.0, 1001.0));
    assert(lb_shwnght(6, 59, 1000.0, 999.0));

    // 23:30 刚进入夜间点：无暂缓应弹窗。
    assert(lb_shwnght(23, 30, 1000.0, 0.0));
    assert(!lb_shwnght(23, 30, 1000.0, 1001.0));
    assert(lb_shwnght(23, 30, 1000.0, 1000.0));
}

// 运行全部状态机测试。
int main(void) {
    tst_trigger();
    tst_hold();
    tst_charge();
    tst_bounds();
    tst_snz();
    tst_nght();
    tst_shw();
    puts("LBState tests passed");
    return 0;
}
