#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#include <CoreFoundation/CoreFoundation.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <math.h>
#include <notify.h>
#include <objc/message.h>
#include <objc/runtime.h>
#include <signal.h>
#include <spawn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include "LBState.h"

#define LB_PREF_PATH @"/var/mobile/Library/Preferences/com.iwmeiagent.lowbatcntdwn.plist"
#define LB_CFG_NOTE "com.iwmeiagent.lowbatcntdwn.config"
#define LB_STOP_NOTE "com.iwmeiagent.lowbatcntdwn.stop"
#define LB_TEST_NOTE "com.iwmeiagent.lowbatcntdwn.test"
#define LB_LOCK_PATH "/var/tmp/com.iwmeiagent.lowbatcntdwn.hud.lock"

extern char **environ;

@interface UIApplication (LBPrivate)
- (void)_accessibilityInit;
- (void)__completeAndRunAsPlugin;
@end

@interface UIWindow (LBPrivate)
- (unsigned int)_contextId;
- (id)_boundContext;
@end

@interface NSObject (LBContext)
- (void)setSecure:(BOOL)secure;
@end

@interface LBApp : UIApplication
@end

@interface LBAppDel : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end

@interface LBSetCtl : UIViewController
@end

@interface LBHudApp : UIApplication
@end

@interface LBHudDel : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end

@interface LBHudWin : UIWindow
@end

@interface LBHudCtl : UIViewController
@property(nonatomic, weak) LBHudWin *hudWindow;
- (void)startMon;
@end

// 读取共享配置文件。
NSDictionary *lb_ldcfg(void);

// 保存共享配置文件。
BOOL lb_svcfg(NSDictionary *config);

// 启动全局监控进程。
BOOL lb_spawn(void);

// 运行全局 HUD 进程。
int lb_hudmain(void);
