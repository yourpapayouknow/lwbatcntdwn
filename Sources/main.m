#import "LBHead.h"

// 根据启动参数选择配置 App 或全局 HUD 模式。
int main(int argc, char *argv[]) {
    @autoreleasepool {
        if (argc > 1 && strcmp(argv[1], "--hud") == 0) return lb_hudmain();
        return UIApplicationMain(argc, argv, NSStringFromClass([LBApp class]), NSStringFromClass([LBAppDel class]));
    }
}

