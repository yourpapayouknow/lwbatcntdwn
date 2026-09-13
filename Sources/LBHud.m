#import "LBHead.h"

@implementation LBHudApp
@end

@implementation LBHudWin

// 将窗口标记为安全系统窗口。
+ (BOOL)_isSystemWindow { return YES; }

// 禁止窗口服务器接管托管策略。
- (BOOL)_isWindowServerHostingManaged { return NO; }

// 让提示层接收命中并阻断下层 App。
- (BOOL)_ignoresHitTest { return NO; }

// 将窗口内容标记为安全内容。
- (BOOL)_isSecure { return YES; }

// 创建安全的渲染上下文。
- (BOOL)_shouldCreateContextAsSecure { return YES; }

@end

// 检查设备是否支持震动。
static BOOL lb_canshake(void) {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) return NO;
    Class hapticClass = objc_getClass("CHHapticEngine");
    if (hapticClass) {
        id capabilities = [hapticClass valueForKey:@"capabilitiesForHardware"];
        if (capabilities && [capabilities respondsToSelector:NSSelectorFromString(@"supportsHaptics")]) {
            return [[capabilities valueForKey:@"supportsHaptics"] boolValue];
        }
    }
    return YES;
}

// 播放短促强震动与系统默认通知声音。
static void lb_playalert(BOOL shake, BOOL sound) {
    if (shake && lb_canshake()) {
        AudioServicesPlaySystemSound(1520);
        if (@available(iOS 13.0, *)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
                [generator prepare];
                [generator impactOccurred];
            });
        }
    }
    if (sound) {
        AudioServicesPlaySystemSound(1007);
    }
}

// 判断当前是否处于夜间锁定保护时段（23:30 - 07:00）。
static BOOL lb_isnight(void) {
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDateComponents *comps = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    NSInteger mins = comps.hour * 60 + comps.minute;
    return (mins >= (23 * 60 + 30)) || (mins < (7 * 60));
}

@interface LBHudCtl ()
@property(nonatomic, strong) UIImageView *iconView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *batteryLabel;
@property(nonatomic, strong) UILabel *countLabel;
@property(nonatomic, strong) UILabel *messageLabel;
@property(nonatomic, strong) UIProgressView *progressView;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, assign) LBState state;
@property(nonatomic, assign) BOOL forcedTest;
@property(nonatomic, assign) BOOL vibrateEnabled;
@property(nonatomic, assign) BOOL soundEnabled;
@property(nonatomic, assign) BOOL nightLocked;
@property(nonatomic, assign) BOOL alerted;
@end

@implementation LBHudCtl

// 创建警告图标。
- (UIImageView *)mkIcon {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:42.0 weight:UIImageSymbolWeightSemibold];
    UIImage *image = [UIImage systemImageNamed:@"battery.0" withConfiguration:config];
    UIImageView *view = [[UIImageView alloc] initWithImage:image];
    view.tintColor = UIColor.systemRedColor;
    view.contentMode = UIViewContentModeScaleAspectFit;
    [view.heightAnchor constraintEqualToConstant:48.0].active = YES;
    return view;
}

// 创建倒计时警告界面。
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.02 alpha:0.88];

    UIVisualEffectView *card = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark]];
    card.layer.cornerRadius = 20.0;
    card.layer.masksToBounds = YES;
    card.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    card.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.12].CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:card];

    self.iconView = [self mkIcon];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"电量过低";
    self.titleLabel.textColor = UIColor.whiteColor;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightSemibold];

    self.batteryLabel = [[UILabel alloc] init];
    self.batteryLabel.textColor = UIColor.secondaryLabelColor;
    self.batteryLabel.textAlignment = NSTextAlignmentCenter;
    self.batteryLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];

    self.countLabel = [[UILabel alloc] init];
    self.countLabel.textColor = UIColor.systemRedColor;
    self.countLabel.textAlignment = NSTextAlignmentCenter;
    self.countLabel.font = [UIFont monospacedDigitSystemFontOfSize:72.0 weight:UIFontWeightBold];
    self.countLabel.adjustsFontSizeToFitWidth = YES;
    self.countLabel.minimumScaleFactor = 0.7;

    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.progressTintColor = UIColor.systemRedColor;
    self.progressView.trackTintColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    self.progressView.layer.cornerRadius = 3.0;
    self.progressView.clipsToBounds = YES;
    [self.progressView.heightAnchor constraintEqualToConstant:6.0].active = YES;

    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.textColor = UIColor.secondaryLabelColor;
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    self.messageLabel.numberOfLines = 0;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.iconView, self.titleLabel, self.batteryLabel, self.countLabel, self.progressView, self.messageLabel,
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card.contentView addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [card.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:24.0],
        [card.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-24.0],
        [card.widthAnchor constraintLessThanOrEqualToConstant:380.0],
        [card.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.84],
        [stack.leadingAnchor constraintEqualToAnchor:card.contentView.leadingAnchor constant:24.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.contentView.trailingAnchor constant:-24.0],
        [stack.topAnchor constraintEqualToAnchor:card.contentView.topAnchor constant:24.0],
        [stack.bottomAnchor constraintEqualToAnchor:card.contentView.bottomAnchor constant:-24.0],
    ]];

    NSDictionary *config = lb_ldcfg();
    self.vibrateEnabled = [config[@"vibrate"] boolValue];
    self.soundEnabled = [config[@"sound"] boolValue];
    lb_init(&_state, [config[@"threshold"] intValue], [config[@"duration"] intValue]);
}

// 开始监听电量、配置和测试事件。
- (void)startMon {
    UIDevice.currentDevice.batteryMonitoringEnabled = YES;
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(batChanged:) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    [center addObserver:self selector:@selector(batChanged:) name:UIDeviceBatteryStateDidChangeNotification object:nil];

    __weak typeof(self) weakSelf = self;
    int configToken = 0;
    notify_register_dispatch(LB_CFG_NOTE, &configToken, dispatch_get_main_queue(), ^(__unused int token) {
        [weakSelf loadCfg];
    });
    int testToken = 0;
    notify_register_dispatch(LB_TEST_NOTE, &testToken, dispatch_get_main_queue(), ^(__unused int token) {
        [weakSelf forceTest];
    });

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTick:) userInfo:nil repeats:YES];
    [self evalBat:NO];
}

// 重新载入共享配置。
- (void)loadCfg {
    NSDictionary *config = lb_ldcfg();
    if (![config[@"enabled"] boolValue]) {
        notify_post(LB_STOP_NOTE);
        return;
    }
    self.vibrateEnabled = [config[@"vibrate"] boolValue];
    self.soundEnabled = [config[@"sound"] boolValue];
    lb_cfg(&_state, [config[@"threshold"] intValue], [config[@"duration"] intValue]);
    [self evalBat:NO];
}

// 将测试事件转换为一次强制低电量状态。
- (void)forceTest {
    self.forcedTest = YES;
    self.alerted = NO;
    [self evalBat:NO];
}

// 处理系统电量变化通知。
- (void)batChanged:(NSNotification *)note {
    (void)note;
    [self evalBat:NO];
}

// 处理每秒倒计时。
- (void)onTick:(NSTimer *)timer {
    (void)timer;
    [self evalBat:YES];
}

// 读取设备电量并推进状态。
- (void)evalBat:(BOOL)tick {
    UIDevice *device = UIDevice.currentDevice;
    UIDeviceBatteryState batteryState = device.batteryState;
    BOOL charging = batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull;
    int percent = device.batteryLevel < 0.0 ? -1 : (int)lroundf(device.batteryLevel * 100.0f);

    if (charging) self.forcedTest = NO;
    lb_feed(&_state, self.forcedTest ? 0 : percent, charging);
    if (tick && !charging && _state.mode == LBModeCount) lb_tick(&_state);

    BOOL isNight = lb_isnight();
    if (_state.mode == LBModeCount || _state.mode == LBModeHold) {
        self.nightLocked = NO;
        if (!self.alerted) {
            lb_playalert(self.vibrateEnabled, self.soundEnabled);
            self.alerted = YES;
        }
    } else {
        self.alerted = NO;
        self.nightLocked = isNight;
    }

    [self drawState:percent];
}

// 将状态渲染到不可关闭窗口。
- (void)drawState:(int)percent {
    BOOL visible = self.nightLocked || (_state.mode != LBModeHidden);
    self.hudWindow.hidden = !visible;
    if (!visible) return;

    UIImageSymbolConfiguration *symCfg = [UIImageSymbolConfiguration configurationWithPointSize:42.0 weight:UIImageSymbolWeightSemibold];
    if (self.nightLocked) {
        self.iconView.image = [UIImage systemImageNamed:@"lock.fill" withConfiguration:symCfg];
        self.iconView.tintColor = UIColor.systemBlueColor;
        self.titleLabel.text = @"夜间锁定";
        self.batteryLabel.text = percent >= 0 ? [NSString stringWithFormat:@"当前电量 %d%%", percent] : @"当前电量未知";
        self.countLabel.hidden = YES;
        self.progressView.hidden = YES;
        self.messageLabel.text = @"23:30 - 07:00 时段锁定中\n仅在过 7 点或电量降至阈值时解除";
    } else {
        self.iconView.image = [UIImage systemImageNamed:@"battery.0" withConfiguration:symCfg];
        self.iconView.tintColor = UIColor.systemRedColor;
        self.titleLabel.text = @"电量过低";
        self.batteryLabel.text = percent >= 0 ? [NSString stringWithFormat:@"当前电量 %d%%", percent] : @"当前电量未知";
        self.countLabel.hidden = NO;
        self.progressView.hidden = NO;
        self.countLabel.text = [NSString stringWithFormat:@"%d", _state.remaining];
        float progress = _state.duration > 0 ? (float)_state.remaining / (float)_state.duration : 0.0f;
        [self.progressView setProgress:progress animated:YES];
        self.messageLabel.text = _state.mode == LBModeHold
            ? @"倒计时已结束，请接通电源后继续使用"
            : @"设备电量即将耗尽，请立即连接电源";
    }
}

// 清理系统通知监听。
- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self.timer invalidate];
}

@end

@implementation LBHudDel {
    LBHudCtl *_controller;
    id _hostingController;
}

// 创建并注册系统级全屏窗口。
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    (void)application;
    (void)options;
    _controller = [[LBHudCtl alloc] init];
    (void)_controller.view;

    LBHudWin *window = [[LBHudWin alloc] initWithFrame:UIScreen.mainScreen.bounds];
    window.rootViewController = _controller;
    window.windowLevel = 10000010.0;
    window.alpha = 0.0;
    window.hidden = NO;
    [window makeKeyAndVisible];
    [[window _boundContext] setSecure:YES];

    Class hostClass = objc_getClass("SBSAccessibilityWindowHostingController");
    if (!hostClass) return NO;
    _hostingController = [[hostClass alloc] init];
    SEL registerSelector = NSSelectorFromString(@"registerWindowWithContextID:atLevel:");
    if (![_hostingController respondsToSelector:registerSelector]) return NO;
    unsigned int contextId = [window _contextId];
    double level = window.windowLevel;
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:Id"];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:_hostingController];
    [invocation setSelector:registerSelector];
    [invocation setArgument:&contextId atIndex:2];
    [invocation setArgument:&level atIndex:3];
    [invocation invoke];

    window.alpha = 1.0;
    self.window = window;
    _controller.hudWindow = window;
    [_controller startMon];
    return YES;
}

@end

// 打开运行 HUD 所需的私有框架。
static BOOL lb_ldfw(void) {
    const char *frameworks[] = {
        "/System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices",
        "/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices",
        "/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices",
    };
    for (size_t index = 0; index < sizeof(frameworks) / sizeof(frameworks[0]); index++) {
        if (!dlopen(frameworks[index], RTLD_NOW | RTLD_GLOBAL)) return NO;
    }
    return YES;
}

// 获取无参数私有函数。
static void (*lb_fn0(const char *name))(void) {
    return (void (*)(void))dlsym(RTLD_DEFAULT, name);
}

static int lb_lockfd = -1;
static dispatch_source_t lb_exesrc;

// 在 App 可执行文件被删除时退出 HUD。
static void lb_monexe(void) {
    char path[PATH_MAX];
    uint32_t size = sizeof(path);
    if (_NSGetExecutablePath(path, &size) != 0) return;
    int handle = open(path, O_EVTONLY);
    if (handle < 0) return;

    lb_exesrc = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, handle, DISPATCH_VNODE_DELETE, dispatch_get_main_queue());
    dispatch_source_set_event_handler(lb_exesrc, ^{
        close(handle);
        exit(EXIT_SUCCESS);
    });
    dispatch_resume(lb_exesrc);
}

// 运行全局 HUD 进程。
int lb_hudmain(void) {
    lb_lockfd = open(LB_LOCK_PATH, O_RDWR | O_CREAT, 0644);
    if (lb_lockfd < 0 || flock(lb_lockfd, LOCK_EX | LOCK_NB) != 0) return EXIT_FAILURE;
    ftruncate(lb_lockfd, 0);
    dprintf(lb_lockfd, "%d\n", getpid());
    lb_monexe();

    int stopToken = 0;
    notify_register_dispatch(LB_STOP_NOTE, &stopToken, dispatch_get_main_queue(), ^(__unused int token) {
        exit(EXIT_SUCCESS);
    });
    int springBoardToken = 0;
    notify_register_dispatch("SBSpringBoardDidLaunchNotification", &springBoardToken, dispatch_get_main_queue(), ^(__unused int token) {
        flock(lb_lockfd, LOCK_UN);
        close(lb_lockfd);
        lb_lockfd = -1;
        lb_spawn();
        exit(EXIT_SUCCESS);
    });

    if (!lb_ldfw()) return EXIT_FAILURE;
    void (*gsInit)(void) = lb_fn0("GSInitialize");
    void (*bksStart)(void) = lb_fn0("BKSDisplayServicesStart");
    void (*uiInit)(void) = lb_fn0("UIApplicationInitialize");
    void (*uiSingle)(Class) = (void (*)(Class))dlsym(RTLD_DEFAULT, "UIApplicationInstantiateSingleton");
    if (!gsInit || !bksStart || !uiInit || !uiSingle) return EXIT_FAILURE;

    [UIScreen initialize];
    CFRunLoopGetCurrent();
    gsInit();
    bksStart();
    uiInit();
    uiSingle([LBHudApp class]);

    LBHudDel *delegate = [[LBHudDel alloc] init];
    UIApplication *app = UIApplication.sharedApplication;
    app.delegate = delegate;
    [app _accessibilityInit];
    [app __completeAndRunAsPlugin];
    CFRunLoopRun();
    return EXIT_SUCCESS;
}
