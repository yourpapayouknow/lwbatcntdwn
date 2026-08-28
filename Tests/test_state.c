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

// 运行全部状态机测试。
int main(void) {
    tst_trigger();
    tst_hold();
    tst_charge();
    tst_bounds();
    puts("LBState tests passed");
    return 0;
}
