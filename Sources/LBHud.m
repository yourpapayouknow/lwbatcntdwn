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

// 检查设备是否支持触觉震动。
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

// 触发系统默认预设短促强劲触觉反馈（基于 Apple UIImpactFeedbackGenerator rigid 预设）。
static void lb_dovibrate(UIImpactFeedbackGenerator *generator) {
    if (!lb_canshake() || !generator) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [generator prepare];
        if (@available(iOS 13.0, *)) {
            [generator impactOccurredWithIntensity:1.0];
        } else {
            [generator impactOccurred];
        }
    });
}

// 播放系统预设提示音与震动联动。
static void lb_playalert(UIImpactFeedbackGenerator *generator, BOOL shake, BOOL sound) {
    if (shake) {
        lb_dovibrate(generator);
    }
    if (sound) {
        AudioServicesPlaySystemSound(1007);
    }
}

static BOOL lb_lowpoweractive = NO;

// 设置或解除低电量弹窗启用的系统省电模式。
static void lb_setlowpower(BOOL enable) {
    if (enable == lb_lowpoweractive) return;

    static Class saverClass = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dlopen("/System/Library/PrivateFrameworks/CoreDuet.framework/CoreDuet", RTLD_NOW | RTLD_GLOBAL);
        saverClass = objc_getClass("_CDBatterySaver");
    });
    if (!saverClass) return;
    id saver = nil;
    SEL batSaverSel = NSSelectorFromString(@"batterySaver");
    SEL sharedInstSel = NSSelectorFromString(@"sharedInstance");
    if ([saverClass respondsToSelector:batSaverSel]) {
        saver = ((id (*)(id, SEL))objc_msgSend)(saverClass, batSaverSel);
    } else if ([saverClass respondsToSelector:sharedInstSel]) {
        saver = ((id (*)(id, SEL))objc_msgSend)(saverClass, sharedInstSel);
    }
    if (!saver) return;

    long long mode = enable ? 1 : 0;
    SEL setModeSel = NSSelectorFromString(@"setMode:");
    SEL setPowerModeSel = NSSelectorFromString(@"setPowerMode:error:");
    if ([saver respondsToSelector:setModeSel]) {
        NSMethodSignature *sig = [saver methodSignatureForSelector:setModeSel];
        if (sig) {
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
            [inv setTarget:saver];
            [inv setSelector:setModeSel];
            [inv setArgument:&mode atIndex:2];
            [inv invoke];
            lb_lowpoweractive = enable;
        }
    } else if ([saver respondsToSelector:setPowerModeSel]) {
        NSMethodSignature *sig = [saver methodSignatureForSelector:setPowerModeSel];
        if (sig) {
            NSError *__autoreleasing err = nil;
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
            [inv setTarget:saver];
            [inv setSelector:setPowerModeSel];
            [inv setArgument:&mode atIndex:2];
            [inv setArgument:&err atIndex:3];
            [inv invoke];
            if (!err) lb_lowpoweractive = enable;
        }
    }
}

// 判断当前是否处于夜间锁定保护时段。
static BOOL lb_isnight(void) {
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDateComponents *comps = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    return lb_chknght((int)comps.hour, (int)comps.minute);
}

// 生成带月亮睡眠镂空的大锁图标。
static UIImage *lb_mklockimg(CGFloat pt) {
    static UIImage *cached = nil;
    if (cached) return cached;

    UIImageSymbolConfiguration *lockCfg = [UIImageSymbolConfiguration configurationWithPointSize:pt weight:UIImageSymbolWeightBold];
    UIImage *lock = [[UIImage systemImageNamed:@"lock.fill" withConfiguration:lockCfg] imageWithTintColor:UIColor.systemBlueColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    if (!lock) return nil;

    CGSize size = lock.size;
    UIGraphicsImageRendererFormat *fmt = [UIGraphicsImageRendererFormat defaultFormat];
    fmt.opaque = NO;
    fmt.scale = UIScreen.mainScreen.scale;
    UIGraphicsImageRenderer *rndr = [[UIGraphicsImageRenderer alloc] initWithSize:size format:fmt];

    UIImage *outImg = [rndr imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [lock drawInRect:CGRectMake(0, 0, size.width, size.height)];

        CGFloat moonPt = pt * 0.38;
        UIImageSymbolConfiguration *moonCfg = [UIImageSymbolConfiguration configurationWithPointSize:moonPt weight:UIImageSymbolWeightBold];
        UIImage *moon = [UIImage systemImageNamed:@"moon.zzz.fill" withConfiguration:moonCfg];
        if (!moon) moon = [UIImage systemImageNamed:@"moon.fill" withConfiguration:moonCfg];
        if (moon) {
            CGSize mSize = moon.size;
            CGFloat bodyTop = size.height * 0.36;
            CGFloat bodyH = size.height - bodyTop;
            CGFloat mX = (size.width - mSize.width) / 2.0;
            CGFloat mY = bodyTop + (bodyH - mSize.height) / 2.0;
            CGRect mRect = CGRectMake(mX, mY, mSize.width, mSize.height);

            CGContextSetBlendMode(ctx.CGContext, kCGBlendModeDestinationOut);
            [moon drawInRect:mRect];
        }
    }];
    cached = [outImg imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    return cached;
}

@interface LBHudCtl ()
@property(nonatomic, strong) UIView *iconContainer;
@property(nonatomic, strong) UIImageView *iconView;
@property(nonatomic, strong) NSLayoutConstraint *iconHeight;
@property(nonatomic, strong) UILabel *countLabel;
@property(nonatomic, strong) UILabel *batteryLabel;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, assign) LBState state;
@property(nonatomic, assign) BOOL forcedTest;
@property(nonatomic, assign) BOOL vibrateEnabled;
@property(nonatomic, assign) BOOL soundEnabled;
@property(nonatomic, assign) BOOL nightLocked;
@property(nonatomic, assign) int nightSnoozeCount;
@property(nonatomic, assign) NSTimeInterval nightSnoozeExpire;
@property(nonatomic, assign) BOOL alerted;
@property(nonatomic, assign) int holdTicks;
@property(nonatomic, strong) UIImpactFeedbackGenerator *rigidImpact;
@property(nonatomic, strong) NSTimer *vibrateTimer;
@end

@implementation LBHudCtl

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

    self.iconContainer = [[UIView alloc] init];
    self.iconContainer.translatesAutoresizingMaskIntoConstraints = NO;

    self.iconView = [[UIImageView alloc] init];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.iconContainer addSubview:self.iconView];

    self.countLabel = [[UILabel alloc] init];
    self.countLabel.textColor = UIColor.systemRedColor;
    self.countLabel.textAlignment = NSTextAlignmentCenter;
    self.countLabel.font = [UIFont monospacedDigitSystemFontOfSize:54.0 weight:UIFontWeightBold];
    self.countLabel.adjustsFontSizeToFitWidth = YES;
    self.countLabel.minimumScaleFactor = 0.5;
    self.countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.iconContainer addSubview:self.countLabel];

    self.iconHeight = [self.iconView.heightAnchor constraintEqualToConstant:130.0];
    self.iconHeight.active = YES;

    [NSLayoutConstraint activateConstraints:@[
        [self.iconView.topAnchor constraintEqualToAnchor:self.iconContainer.topAnchor],
        [self.iconView.bottomAnchor constraintEqualToAnchor:self.iconContainer.bottomAnchor],
        [self.iconView.centerXAnchor constraintEqualToAnchor:self.iconContainer.centerXAnchor],
        [self.iconView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.iconContainer.leadingAnchor],
        [self.iconView.trailingAnchor constraintLessThanOrEqualToAnchor:self.iconContainer.trailingAnchor],

        [self.countLabel.centerXAnchor constraintEqualToAnchor:self.iconView.centerXAnchor constant:-7.5],
        [self.countLabel.centerYAnchor constraintEqualToAnchor:self.iconView.centerYAnchor],
        [self.countLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.iconView.widthAnchor multiplier:0.65],
        [self.countLabel.heightAnchor constraintLessThanOrEqualToAnchor:self.iconView.heightAnchor multiplier:0.60],
    ]];

    self.batteryLabel = [[UILabel alloc] init];
    self.batteryLabel.textColor = UIColor.secondaryLabelColor;
    self.batteryLabel.textAlignment = NSTextAlignmentCenter;
    self.batteryLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.iconContainer, self.batteryLabel,
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16.0;
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

    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(lngprs:)];
    press.minimumPressDuration = 5.0;
    press.allowableMovement = 30.0;
    [self.view addGestureRecognizer:press];

    NSDictionary *config = lb_ldcfg();
    self.vibrateEnabled = [config[@"vibrate"] boolValue];
    self.soundEnabled = [config[@"sound"] boolValue];
    lb_init(&_state, [config[@"threshold"] intValue], [config[@"duration"] intValue]);

    if (lb_canshake()) {
        self.rigidImpact = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
        [self.rigidImpact prepare];
    }
}

// 处理长按解除夜间弹窗手势。
- (void)lngprs:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    if (!lb_isnight() || !self.nightLocked || _state.mode != LBModeHidden) return;
    int duration = lb_snzdur(self.nightSnoozeCount);
    if (duration <= 0) return;

    self.nightSnoozeCount++;
    self.nightSnoozeExpire = [NSDate date].timeIntervalSinceReferenceDate + (NSTimeInterval)duration;
    lb_dovibrate(self.rigidImpact);
    [self evalBat:NO];
}

// 开始监听电量、配置和测试事件。
- (void)startMon {
    UIDevice.currentDevice.batteryMonitoringEnabled = YES;
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(batChanged:) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    [center addObserver:self selector:@selector(batChanged:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [center addObserver:self selector:@selector(tmchg:) name:UIApplicationSignificantTimeChangeNotification object:nil];

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
    [NSRunLoop.currentRunLoop addTimer:self.timer forMode:NSRunLoopCommonModes];
    [self evalBat:NO];
}

// 处理系统时间跳变通知。
- (void)tmchg:(NSNotification *)note {
    (void)note;
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
    if (!self.vibrateEnabled) {
        [self stopVibrateTimer];
    }
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

    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDateComponents *comps = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    BOOL isNight = lb_chknght((int)comps.hour, (int)comps.minute);
    BOOL isLowBat = (_state.mode == LBModeCount || _state.mode == LBModeHold);
    if (isLowBat) {
        self.nightLocked = NO;
        if (!self.alerted) {
            lb_playalert(self.rigidImpact, self.vibrateEnabled, self.soundEnabled);
            self.alerted = YES;
            self.holdTicks = 0;
            [self startVibrateTimer];
        } else if (self.vibrateEnabled && !self.vibrateTimer) {
            [self startVibrateTimer];
        }
        lb_setlowpower(YES);
    } else {
        self.alerted = NO;
        self.holdTicks = 0;
        [self stopVibrateTimer];
        lb_setlowpower(NO);

        if (!isNight) {
            self.nightLocked = NO;
            self.nightSnoozeCount = 0;
            self.nightSnoozeExpire = 0;
        } else {
            NSTimeInterval now = [NSDate date].timeIntervalSinceReferenceDate;
            self.nightLocked = lb_shwnght((int)comps.hour, (int)comps.minute, now, self.nightSnoozeExpire);
        }
    }

    [self drawState:percent];
}

// 将状态渲染到不可关闭窗口。
- (void)drawState:(int)percent {
    BOOL visible = self.nightLocked || (_state.mode != LBModeHidden);
    self.hudWindow.hidden = !visible;
    if (!visible) return;

    if (self.nightLocked) {
        self.iconHeight.constant = 130.0;
        self.iconView.image = lb_mklockimg(110.0);
        self.countLabel.hidden = YES;
        self.batteryLabel.text = percent >= 0 ? [NSString stringWithFormat:@"当前电量 %d%%", percent] : @"当前电量未知";
    } else {
        self.iconHeight.constant = 130.0;
        UIImageSymbolConfiguration *symCfg = [UIImageSymbolConfiguration configurationWithPointSize:125.0 weight:UIImageSymbolWeightSemibold];
        self.iconView.image = [UIImage systemImageNamed:@"battery.0" withConfiguration:symCfg];
        self.iconView.tintColor = UIColor.systemRedColor;
        self.countLabel.hidden = NO;
        self.countLabel.text = [NSString stringWithFormat:@"%d", _state.remaining];
        self.batteryLabel.text = percent >= 0 ? [NSString stringWithFormat:@"当前电量 %d%%", percent] : @"当前电量未知";
    }
}

// 启动高频震动定时器（每秒触发 4 次：0.25s 间隔）。
- (void)startVibrateTimer {
    if (self.vibrateTimer || !self.vibrateEnabled || !lb_canshake()) return;
    __weak typeof(self) weakSelf = self;
    self.vibrateTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(__unused NSTimer *timer) {
        typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.vibrateEnabled) return;
        lb_dovibrate(strongSelf.rigidImpact);
    }];
}

// 停止高频震动定时器。
- (void)stopVibrateTimer {
    if (self.vibrateTimer) {
        [self.vibrateTimer invalidate];
        self.vibrateTimer = nil;
    }
}

// 清理系统通知监听。
- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self.timer invalidate];
    [self stopVibrateTimer];
    lb_setlowpower(NO);
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
        lb_setlowpower(NO);
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
        lb_setlowpower(NO);
        exit(EXIT_SUCCESS);
    });
    int springBoardToken = 0;
    notify_register_dispatch("SBSpringBoardDidLaunchNotification", &springBoardToken, dispatch_get_main_queue(), ^(__unused int token) {
        lb_setlowpower(NO);
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
