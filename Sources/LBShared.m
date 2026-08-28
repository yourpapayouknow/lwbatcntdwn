#import "LBHead.h"

#define LB_PERSONA_FLAGS 1
extern int posix_spawnattr_set_persona_np(const posix_spawnattr_t *attr, uid_t persona, uint32_t flags);
extern int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t *attr, uid_t uid);
extern int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t *attr, uid_t gid);

// 生成经过边界校验的配置。
static NSDictionary *lb_normcfg(NSDictionary *input) {
    NSInteger threshold = [input[@"threshold"] integerValue];
    NSInteger duration = [input[@"duration"] integerValue];
    if (threshold < 1 || threshold > 20) threshold = 5;
    if (duration < 10 || duration > 300) duration = 60;
    NSNumber *enabled = input[@"enabled"] ?: @YES;
    return @{
        @"threshold": @(threshold),
        @"duration": @(duration),
        @"enabled": @([enabled boolValue]),
    };
}

// 读取共享配置文件。
NSDictionary *lb_ldcfg(void) {
    NSDictionary *stored = [NSDictionary dictionaryWithContentsOfFile:LB_PREF_PATH];
    return lb_normcfg(stored ?: @{});
}

// 保存共享配置文件。
BOOL lb_svcfg(NSDictionary *config) {
    NSDictionary *normalized = lb_normcfg(config ?: @{});
    BOOL saved = [normalized writeToFile:LB_PREF_PATH atomically:YES];
    if (saved) notify_post(LB_CFG_NOTE);
    return saved;
}

// 返回当前可执行文件路径。
static const char *lb_exepath(void) {
    static char path[PATH_MAX];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uint32_t size = sizeof(path);
        if (_NSGetExecutablePath(path, &size) != 0) path[0] = '\0';
    });
    return path;
}

// 启动全局监控进程。
BOOL lb_spawn(void) {
    const char *path = lb_exepath();
    if (!path[0]) return NO;

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_set_persona_np(&attr, 99, LB_PERSONA_FLAGS);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);
    posix_spawnattr_setpgroup(&attr, 0);
    posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETPGROUP);

    pid_t pid = 0;
    char *const args[] = {(char *)path, "--hud", NULL};
    int result = posix_spawn(&pid, path, NULL, &attr, args, environ);
    posix_spawnattr_destroy(&attr);
    if (result == 0) {
        int status = 0;
        waitpid(pid, &status, WNOHANG);
    }
    return result == 0;
}

