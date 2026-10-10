#import "AppDelegate.h"
#import "LaunchViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[LaunchViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
