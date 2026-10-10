#import "LaunchViewController.h"

static NSString * const kServerHost = @"134.255.220.191";
static const NSInteger kServerPort = 7777;
static NSString * const kNicknameDefaultsKey = @"samp.nickname";

@interface LaunchViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *nicknameField;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *addressButton;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation LaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.06 green:0.07 blue:0.09 alpha:1.0];
    [self buildUI];
    self.nicknameField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kNicknameDefaultsKey];
}

- (void)buildUI {
    UIColor *accent = [UIColor colorWithRed:0.90 green:0.22 blue:0.27 alpha:1.0];

    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"KurdUnity";
    title.font = [UIFont systemFontOfSize:42 weight:UIFontWeightHeavy];
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;

    UILabel *server = [UILabel new];
    server.translatesAutoresizingMaskIntoConstraints = NO;
    server.text = [NSString stringWithFormat:@"SA-MP · %@:%ld", kServerHost, (long)kServerPort];
    server.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    server.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    server.textAlignment = NSTextAlignmentCenter;

    self.nicknameField = [UITextField new];
    self.nicknameField.translatesAutoresizingMaskIntoConstraints = NO;
    self.nicknameField.placeholder = @"Nickname";
    self.nicknameField.textColor = [UIColor whiteColor];
    self.nicknameField.tintColor = accent;
    self.nicknameField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.nicknameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.nicknameField.returnKeyType = UIReturnKeyDone;
    self.nicknameField.delegate = self;
    self.nicknameField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
    self.nicknameField.layer.cornerRadius = 10.0;
    self.nicknameField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 44)];
    self.nicknameField.leftViewMode = UITextFieldViewModeAlways;

    self.playButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.playButton setTitle:@"PLAY" forState:UIControlStateNormal];
    [self.playButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.playButton.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.playButton.backgroundColor = accent;
    self.playButton.layer.cornerRadius = 12.0;
    [self.playButton addTarget:self action:@selector(playTapped:) forControlEvents:UIControlEventTouchUpInside];

    self.addressButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.addressButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.addressButton setTitle:@"Copy server address" forState:UIControlStateNormal];
    [self.addressButton setTitleColor:[UIColor colorWithWhite:0.75 alpha:1.0] forState:UIControlStateNormal];
    [self.addressButton addTarget:self action:@selector(onCopyAddress:) forControlEvents:UIControlEventTouchUpInside];

    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.progressTintColor = accent;
    self.progressView.trackTintColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    self.progressView.progress = 0.0;

    self.statusLabel = [UILabel new];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"Ready";
    self.statusLabel.font = [UIFont systemFontOfSize:13];
    self.statusLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 2;

    for (UIView *v in @[title, server, self.nicknameField, self.playButton, self.addressButton, self.progressView, self.statusLabel]) {
        [self.view addSubview:v];
    }

    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:g.topAnchor constant:60],
        [title.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:24],
        [title.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-24],

        [server.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6],
        [server.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:24],
        [server.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-24],

        [self.nicknameField.topAnchor constraintEqualToAnchor:server.bottomAnchor constant:36],
        [self.nicknameField.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:28],
        [self.nicknameField.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-28],
        [self.nicknameField.heightAnchor constraintEqualToConstant:46],

        [self.playButton.topAnchor constraintEqualToAnchor:self.nicknameField.bottomAnchor constant:18],
        [self.playButton.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:28],
        [self.playButton.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-28],
        [self.playButton.heightAnchor constraintEqualToConstant:56],

        [self.addressButton.topAnchor constraintEqualToAnchor:self.playButton.bottomAnchor constant:10],
        [self.addressButton.centerXAnchor constraintEqualToAnchor:g.centerXAnchor],

        [self.statusLabel.bottomAnchor constraintEqualToAnchor:self.progressView.topAnchor constant:-10],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:28],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-28],

        [self.progressView.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-28],
        [self.progressView.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:28],
        [self.progressView.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-28],
    ]];
}

#pragma mark - Actions

- (void)playTapped:(UIButton *)sender {
    [self.nicknameField resignFirstResponder];

    NSString *name = [self.nicknameField.text stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (name.length == 0) {
        name = @"Player";
    }

    [[NSUserDefaults standardUserDefaults] setObject:name forKey:kNicknameDefaultsKey];

    NSString *iniPath = [self writeSettingsIniForNickname:name];
    self.statusLabel.text = [NSString stringWithFormat:@"Saved %@ · connecting…", iniPath.lastPathComponent];
    [self.progressView setProgress:0.35 animated:YES];

    [self attemptStreamingLaunch];
}

- (void)onCopyAddress:(UIButton *)sender {
    NSString *server = [NSString stringWithFormat:@"%@:%ld", kServerHost, (long)kServerPort];
    [UIPasteboard generalPasteboard].string = server;
    self.statusLabel.text = [NSString stringWithFormat:@"Copied %@", server];
}

#pragma mark - Config

- (NSString *)writeSettingsIniForNickname:(NSString *)name {
    NSArray<NSString *> *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs = dirs.firstObject;
    NSString *sampDir = [docs stringByAppendingPathComponent:@"samp"];

    [[NSFileManager defaultManager] createDirectoryAtPath:sampDir
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:nil];

    NSString *iniPath = [sampDir stringByAppendingPathComponent:@"settings.ini"];
    NSString *body = [NSString stringWithFormat:@"[client]\nname=%@\nhost=%@\nport=%ld\n",
                      name, kServerHost, (long)kServerPort];
    [body writeToFile:iniPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return iniPath;
}

#pragma mark - Streaming handoff

- (void)attemptStreamingLaunch {
    // Moonlight registers no URL scheme, so this is best-effort. If any candidate is
    // installed, jump to it; otherwise show the manual steps.
    NSArray<NSString *> *candidates = @[@"moonlight://", @"steamlink://"];
    for (NSString *scheme in candidates) {
        NSURL *url = [NSURL URLWithString:scheme];
        if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            [self.progressView setProgress:1.0 animated:YES];
            self.statusLabel.text = @"Opened streaming client";
            return;
        }
    }
    [self.progressView setProgress:1.0 animated:YES];
    self.statusLabel.text = @"Setup complete";
    [self showStreamingInstructions];
}

- (void)showStreamingInstructions {
    NSString *server = [NSString stringWithFormat:@"%@:%ld", kServerHost, (long)kServerPort];
    [UIPasteboard generalPasteboard].string = server;

    NSString *message = [NSString stringWithFormat:
        @"1. Open Moonlight and connect to your gaming PC.\n"
        @"2. Launch GTA: San Andreas on the PC.\n"
        @"3. In-game, join the server:\n%@\n\n"
        @"The address was copied to your clipboard.", server];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Ready to play"
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
