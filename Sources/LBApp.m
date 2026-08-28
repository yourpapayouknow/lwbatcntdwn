#import "LBHead.h"

@implementation LBApp
@end

@interface LBSetCtl ()
@property(nonatomic, strong) UILabel *thresholdLabel;
@property(nonatomic, strong) UILabel *durationLabel;
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) UISlider *thresholdSlider;
@property(nonatomic, strong) UISlider *durationSlider;
@property(nonatomic, strong) UISwitch *monitorSwitch;
@property(nonatomic, strong) UIButton *testButton;
@end

@implementation LBSetCtl

// 创建带标题的纵向设置组。
- (UIStackView *)mkGroup:(NSString *)title control:(UIView *)control {
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    label.textColor = UIColor.labelColor;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[label, control]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8.0;
    stack.layoutMargins = UIEdgeInsetsMake(16.0, 16.0, 16.0, 16.0);
    stack.layoutMarginsRelativeArrangement = YES;
    stack.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    stack.layer.cornerRadius = 16.0;
    return stack;
}

// 创建数值与滑杆组合。
- (UIStackView *)mkSlider:(UISlider *)slider value:(UILabel *)value {
    UIStackView *line = [[UIStackView alloc] initWithArrangedSubviews:@[slider, value]];
    line.axis = UILayoutConstraintAxisHorizontal;
    line.spacing = 12.0;
    line.alignment = UIStackViewAlignmentCenter;
    [value.widthAnchor constraintEqualToConstant:72.0].active = YES;
    return line;
}

// 创建监控开关组合。
- (UIStackView *)mkSwitch {
    UILabel *label = [[UILabel alloc] init];
    label.text = @"开机后首次打开本 App 会自动恢复监控";
    label.numberOfLines = 0;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    label.textColor = UIColor.secondaryLabelColor;
    [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.monitorSwitch setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.monitorSwitch setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    UIStackView *line = [[UIStackView alloc] initWithArrangedSubviews:@[label, self.monitorSwitch]];
    line.axis = UILayoutConstraintAxisHorizontal;
    line.spacing = 12.0;
    line.alignment = UIStackViewAlignmentCenter;
    line.distribution = UIStackViewDistributionFill;
    return line;
}

// 构建配置界面。
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"低电量倒计时";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    self.thresholdLabel = [[UILabel alloc] init];
    self.durationLabel = [[UILabel alloc] init];
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.statusLabel.textColor = UIColor.secondaryLabelColor;
    self.statusLabel.numberOfLines = 0;

    self.thresholdSlider = [[UISlider alloc] init];
    self.thresholdSlider.minimumValue = 1.0;
    self.thresholdSlider.maximumValue = 20.0;
    self.thresholdSlider.tintColor = UIColor.systemRedColor;
    [self.thresholdSlider addTarget:self action:@selector(valChanged:) forControlEvents:UIControlEventValueChanged];

    self.durationSlider = [[UISlider alloc] init];
    self.durationSlider.minimumValue = 10.0;
    self.durationSlider.maximumValue = 300.0;
    self.durationSlider.tintColor = UIColor.systemRedColor;
    [self.durationSlider addTarget:self action:@selector(valChanged:) forControlEvents:UIControlEventValueChanged];

    self.monitorSwitch = [[UISwitch alloc] init];
    self.monitorSwitch.onTintColor = UIColor.systemRedColor;
    [self.monitorSwitch addTarget:self action:@selector(monChanged:) forControlEvents:UIControlEventValueChanged];

    UIButtonConfiguration *buttonConfig = [UIButtonConfiguration filledButtonConfiguration];
    buttonConfig.title = @"测试不可关闭弹窗";
    buttonConfig.baseBackgroundColor = UIColor.systemRedColor;
    buttonConfig.baseForegroundColor = UIColor.whiteColor;
    buttonConfig.cornerStyle = UIButtonConfigurationCornerStyleLarge;
    buttonConfig.contentInsets = NSDirectionalEdgeInsetsMake(14.0, 18.0, 14.0, 18.0);
    self.testButton = [UIButton buttonWithConfiguration:buttonConfig primaryAction:nil];
    self.testButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [self.testButton addTarget:self action:@selector(testTapped) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *content = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self mkGroup:@"监控服务" control:[self mkSwitch]],
        [self mkGroup:@"触发电量" control:[self mkSlider:self.thresholdSlider value:self.thresholdLabel]],
        [self mkGroup:@"倒计时" control:[self mkSlider:self.durationSlider value:self.durationLabel]],
        self.testButton,
        self.statusLabel,
    ]];
    content.axis = UILayoutConstraintAxisVertical;
    content.spacing = 16.0;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20.0],
        [content.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20.0],
        [content.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24.0],
    ]];
    [self loadCfg];
}

// 将共享配置载入控件。
- (void)loadCfg {
    NSDictionary *config = lb_ldcfg();
    self.thresholdSlider.value = [config[@"threshold"] floatValue];
    self.durationSlider.value = [config[@"duration"] floatValue];
    self.monitorSwitch.on = [config[@"enabled"] boolValue];
    [self syncUI];
}

// 同步显示文本与控件状态。
- (void)syncUI {
    NSInteger threshold = lroundf(self.thresholdSlider.value);
    NSInteger duration = lroundf(self.durationSlider.value / 10.0f) * 10;
    self.thresholdLabel.text = [NSString stringWithFormat:@"%ld%%", (long)threshold];
    self.thresholdLabel.textAlignment = NSTextAlignmentRight;
    self.durationLabel.text = [NSString stringWithFormat:@"%ld 秒", (long)duration];
    self.durationLabel.textAlignment = NSTextAlignmentRight;
    self.testButton.enabled = self.monitorSwitch.on;
    self.testButton.alpha = self.monitorSwitch.on ? 1.0 : 0.45;
}

// 保存当前控件配置。
- (void)saveCfg {
    NSInteger threshold = lroundf(self.thresholdSlider.value);
    NSInteger duration = lroundf(self.durationSlider.value / 10.0f) * 10;
    NSDictionary *config = @{
        @"threshold": @(threshold),
        @"duration": @(duration),
        @"enabled": @(self.monitorSwitch.on),
    };
    self.statusLabel.text = lb_svcfg(config) ? @"配置已保存" : @"配置保存失败，请重新安装并检查权限";
}

// 处理滑杆数值变化。
- (void)valChanged:(UISlider *)sender {
    if (sender == self.thresholdSlider) sender.value = lroundf(sender.value);
    if (sender == self.durationSlider) sender.value = lroundf(sender.value / 10.0f) * 10;
    [self syncUI];
    [self saveCfg];
}

// 处理监控开关变化。
- (void)monChanged:(UISwitch *)sender {
    [self syncUI];
    [self saveCfg];
    if (sender.on) {
        self.statusLabel.text = lb_spawn() ? @"监控进程已启动" : @"启动失败：请确认使用 TrollStore 安装";
    } else {
        notify_post(LB_STOP_NOTE);
        self.statusLabel.text = @"监控进程已停止";
    }
}

// 显示测试风险确认。
- (void)testTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"测试后只能接电解除"
                                                                   message:@"弹窗会立即覆盖全屏，并保持到设备接通电源。若异常，可重启设备恢复。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"开始测试" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        notify_post(LB_TEST_NOTE);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

@implementation LBAppDel

// 创建配置 App 主窗口并恢复监控。
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    (void)application;
    (void)options;
    LBSetCtl *settings = [[LBSetCtl alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:settings];
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];

    NSDictionary *config = lb_ldcfg();
    if ([config[@"enabled"] boolValue]) lb_spawn();
    return YES;
}

@end
