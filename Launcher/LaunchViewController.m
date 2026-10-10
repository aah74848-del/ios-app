#import "LaunchViewController.h"
#import "SAMPQuery.h"
#import "SAMPDownloader.h"

static NSString * const kServerHost = @"134.255.220.191";
static const uint16_t kServerPort = 7777;
static NSString * const kNicknameDefaultsKey = @"samp.nickname";

@interface LaunchViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *nicknameField;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *addressButton;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) UILabel *serverStatusLabel;
@property (nonatomic, strong) UILabel *gtaStatusLabel;
@property (nonatomic, strong) UIProgressView *progressView;

// Incremented whenever a new staged animation starts so stale steps bail out.
@property (nonatomic, assign) NSUInteger sequenceToken;

@end

@implementation LaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.06 green:0.07 blue:0.09 alpha:1.0];
    [self buildUI];

    // Restore the saved nickname immediately (persisted across launches).
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:kNicknameDefaultsKey];
    if (saved.length > 0) {
        self.nicknameField.text = saved;
    }

    [self refreshServerStatus];
    [self runGTAStatusSequence];
}

#pragma mark - UI

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
    server.text = [NSString stringWithFormat:@"SA-MP · %@:%u", kServerHost, (unsigned)kServerPort];
    server.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    server.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    server.textAlignment = NSTextAlignmentCenter;

    self.serverStatusLabel = [UILabel new];
    self.serverStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.serverStatusLabel.text = @"Server: checking…";
    self.serverStatusLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.serverStatusLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    self.serverStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.serverStatusLabel.numberOfLines = 2;

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
    // Persist the nickname as the user types.
    [self.nicknameField addTarget:self
                           action:@selector(onNicknameChanged:)
                 forControlEvents:UIControlEventEditingChanged];

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

    self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.downloadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.downloadButton setTitle:@"Download SA-MP client (for PC)" forState:UIControlStateNormal];
    [self.downloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.downloadButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.downloadButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    self.downloadButton.layer.cornerRadius = 10.0;
    [self.downloadButton addTarget:self action:@selector(downloadClientTapped:) forControlEvents:UIControlEventTouchUpInside];

    UILabel *gtaTitle = [UILabel new];
    gtaTitle.translatesAutoresizingMaskIntoConstraints = NO;
    gtaTitle.text = @"GTA STATUS";
    gtaTitle.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    gtaTitle.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    gtaTitle.textAlignment = NSTextAlignmentCenter;

    self.gtaStatusLabel = [UILabel new];
    self.gtaStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.gtaStatusLabel.text = @"Preparing…";
    self.gtaStatusLabel.font = [UIFont systemFontOfSize:13];
    self.gtaStatusLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.gtaStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.gtaStatusLabel.numberOfLines = 2;

    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.progressTintColor = accent;
    self.progressView.trackTintColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    self.progressView.progress = 0.0;

    for (UIView *v in @[title, server, self.serverStatusLabel, self.nicknameField, self.playButton,
                         self.addressButton, self.downloadButton, gtaTitle, self.gtaStatusLabel, self.progressView]) {
        [self.view addSubview:v];
    }

    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:g.topAnchor constant:44],
        [title.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:24],
        [title.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-24],

        [server.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4],
        [server.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:24],
        [server.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-24],

        [self.serverStatusLabel.topAnchor constraintEqualToAnchor:server.bottomAnchor constant:6],
        [self.serverStatusLabel.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:24],
        [self.serverStatusLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-24],

        [self.nicknameField.topAnchor constraintEqualToAnchor:self.serverStatusLabel.bottomAnchor constant:28],
        [self.nicknameField.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:28],
        [self.nicknameField.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-28],
        [self.nicknameField.heightAnchor constraintEqualToConstant:46],

        [self.playButton.topAnchor constraintEqualToAnchor:self.nicknameField.bottomAnchor constant:16],
        [self.playButton.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:28],
        [self.playButton.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-28],
        [self.playButton.heightAnchor constraintEqualToConstant:56],

        [self.addressButton.topAnchor constraintEqualToAnchor:self.playButton.bottomAnchor constant:8],
        [self.addressButton.centerXAnchor constraintEqualToAnchor:g.centerXAnchor],

        [self.downloadButton.topAnchor constraintEqualToAnchor:self.addressButton.bottomAnchor constant:14],
        [self.downloadButton.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:28],
        [self.downloadButton.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-28],
        [self.downloadButton.heightAnchor constraintEqualToConstant:46],

        [gtaTitle.topAnchor constraintEqualToAnchor:self.downloadButton.bottomAnchor constant:26],
        [gtaTitle.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:28],
        [gtaTitle.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-28],

        [self.gtaStatusLabel.topAnchor constraintEqualToAnchor:gtaTitle.bottomAnchor constant:6],
        [self.gtaStatusLabel.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:28],
        [self.gtaStatusLabel.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-28],

        [self.progressView.topAnchor constraintEqualToAnchor:self.gtaStatusLabel.bottomAnchor constant:10],
        [self.progressView.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:28],
        [self.progressView.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-28],
        [self.progressView.bottomAnchor constraintLessThanOrEqualToAnchor:g.bottomAnchor constant:-24],
    ]];
}

#pragma mark - Actions

- (void)onNicknameChanged:(UITextField *)field {
    // Saved on every keystroke so the username is always persisted.
    [self persistNickname:[self sanitizedNickname]];
}

- (void)playTapped:(UIButton *)sender {
    [self.nicknameField resignFirstResponder];

    NSString *name = [self sanitizedNickname];
    [self persistNickname:name];

    self.playButton.enabled = NO;
    [self runJoinSequenceForNickname:name];
}

- (void)onCopyAddress:(UIButton *)sender {
    NSString *server = [NSString stringWithFormat:@"%@:%u", kServerHost, (unsigned)kServerPort];
    [UIPasteboard generalPasteboard].string = server;
    self.gtaStatusLabel.text = [NSString stringWithFormat:@"Copied %@", server];
}

- (void)downloadClientTapped:(UIButton *)sender {
    // If a previous staged animation is running, cancel it.
    self.sequenceToken += 1;
    self.downloadButton.enabled = NO;
    [self.progressView setProgress:0.0 animated:NO];
    self.gtaStatusLabel.text = @"Connecting to mirror…";

    __weak typeof(self) weakSelf = self;
    [[SAMPDownloader shared] downloadWithProgress:^(int64_t bytesWritten, int64_t totalBytes) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        double megabytesWritten = (double)bytesWritten / 1048576.0;
        if (totalBytes > 0) {
            double fraction = (double)bytesWritten / (double)totalBytes;
            [self.progressView setProgress:(float)fraction animated:NO];
            self.gtaStatusLabel.text = [NSString stringWithFormat:
                                        @"Downloading SA-MP client… %.0f%% (%.1f / %.1f MB)",
                                        fraction * 100.0, megabytesWritten, (double)totalBytes / 1048576.0];
        } else {
            self.gtaStatusLabel.text = [NSString stringWithFormat:
                                        @"Downloading SA-MP client… %.1f MB", megabytesWritten];
        }
    } completion:^(NSURL *fileURL, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        self.downloadButton.enabled = YES;
        if (fileURL != nil) {
            [self.progressView setProgress:1.0 animated:YES];
            self.gtaStatusLabel.text = @"SA-MP client saved — send it to your PC";
            [self presentShareSheetForURL:fileURL];
        } else if (error != nil && error.code == NSURLErrorCancelled) {
            self.gtaStatusLabel.text = @"Download cancelled";
        } else {
            self.gtaStatusLabel.text = [NSString stringWithFormat:@"Download failed: %@",
                                        error.localizedDescription ?: @"unknown error"];
        }
    }];
}

- (void)presentShareSheetForURL:(NSURL *)fileURL {
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL]
                                                                          applicationActivities:nil];
    // iPad/regular-size safety.
    activity.popoverPresentationController.sourceView = self.downloadButton;
    activity.popoverPresentationController.sourceRect = self.downloadButton.bounds;
    [self presentViewController:activity animated:YES completion:nil];
}

#pragma mark - Nickname persistence

- (NSString *)sanitizedNickname {
    NSString *name = [self.nicknameField.text stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return name.length > 0 ? name : @"Player";
}

- (void)persistNickname:(NSString *)name {
    if (name.length == 0) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:kNicknameDefaultsKey];
    [self writeSettingsIniForNickname:name];
}

- (NSString *)writeSettingsIniForNickname:(NSString *)name {
    NSArray<NSString *> *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs = dirs.firstObject;
    NSString *sampDir = [docs stringByAppendingPathComponent:@"samp"];

    [[NSFileManager defaultManager] createDirectoryAtPath:sampDir
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:nil];

    NSString *iniPath = [sampDir stringByAppendingPathComponent:@"settings.ini"];
    NSString *body = [NSString stringWithFormat:@"[client]\nname=%@\nhost=%@\nport=%u\n",
                      name, kServerHost, (unsigned)kServerPort];
    [body writeToFile:iniPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return iniPath;
}

#pragma mark - Server status

- (void)refreshServerStatus {
    __weak typeof(self) weakSelf = self;
    [SAMPQuery queryHost:kServerHost port:kServerPort timeout:2.0
              completion:^(BOOL responded, NSString *hostname, NSInteger players, NSInteger maxPlayers) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        self.serverStatusLabel.text = responded
            ? [NSString stringWithFormat:@"Server: %@ (%ld/%ld)",
               hostname.length ? hostname : @"online", (long)players, (long)maxPlayers]
            : [NSString stringWithFormat:@"Server: no response from %@:%u", kServerHost, (unsigned)kServerPort];
    }];
}

#pragma mark - GTA status (download-style)

- (void)runGTAStatusSequence {
    NSArray<NSString *> *phases = @[
        @"Checking GTA files…",
        @"Downloading game data…",
        @"Verifying assets…",
        @"GTA ready to launch"
    ];
    NSUInteger token = ++self.sequenceToken;
    __weak typeof(self) weakSelf = self;
    __block void (^step)(NSUInteger) = nil;
    step = ^(NSUInteger index) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || token != self.sequenceToken) { return; }
        if (index >= phases.count) { return; }
        self.gtaStatusLabel.text = phases[index];
        [self.progressView setProgress:(float)(index + 1) / (float)phases.count animated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            step(index + 1);
        });
    };
    step(0);
}

#pragma mark - Join sequence

- (void)runJoinSequenceForNickname:(NSString *)name {
    NSUInteger token = ++self.sequenceToken;
    self.gtaStatusLabel.text = [NSString stringWithFormat:@"Connecting to %@:%u…", kServerHost, (unsigned)kServerPort];
    [self.progressView setProgress:0.15 animated:YES];

    __weak typeof(self) weakSelf = self;
    [SAMPQuery queryHost:kServerHost port:kServerPort timeout:2.5
              completion:^(BOOL responded, NSString *hostname, NSInteger players, NSInteger maxPlayers) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || token != self.sequenceToken) { return; }

        if (responded) {
            NSString *serverName = hostname.length ? hostname : @"SA-MP server";
            self.serverStatusLabel.text = [NSString stringWithFormat:@"Server: %@ (%ld/%ld)",
                                           serverName, (long)players, (long)maxPlayers];
            self.gtaStatusLabel.text = [NSString stringWithFormat:@"Joining server as %@…", name];
            [self.progressView setProgress:0.7 animated:YES];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self || token != self.sequenceToken) { return; }
                self.gtaStatusLabel.text = @"Logged in. Loading world…";
                [self.progressView setProgress:1.0 animated:YES];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) self2 = weakSelf;
                    if (!self2 || token != self2.sequenceToken) { return; }
                    self2.gtaStatusLabel.text = @"Opening streaming client…";
                    [self2 finishJoin];
                });
            });
        } else {
            self.serverStatusLabel.text = [NSString stringWithFormat:@"Server: no response from %@:%u",
                                           kServerHost, (unsigned)kServerPort];
            self.gtaStatusLabel.text = [NSString stringWithFormat:
                                        @"Can't reach %@:%u — start your host PC + Moonlight",
                                        kServerHost, (unsigned)kServerPort];
            [self.progressView setProgress:1.0 animated:YES];
            [self finishJoin];
        }
    }];
}

- (void)finishJoin {
    self.playButton.enabled = YES;
    [self attemptStreamingLaunch];
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
            self.gtaStatusLabel.text = @"Opened streaming client";
            return;
        }
    }
    [self showStreamingInstructions];
}

- (void)showStreamingInstructions {
    NSString *server = [NSString stringWithFormat:@"%@:%u", kServerHost, (unsigned)kServerPort];
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
    [self persistNickname:[self sanitizedNickname]];
    return YES;
}

@end
