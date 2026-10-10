#import "SAMPDownloader.h"

static NSString * const kClientFileName = @"sa-mp-0.3.7-R5-2-MP-install.exe";

@interface SAMPDownloader () <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy, nullable) SAMPDownloadProgress progressBlock;
@property (nonatomic, copy, nullable) SAMPDownloadCompletion completionBlock;
@property (nonatomic, assign) NSUInteger urlIndex;
@property (nonatomic, strong, nullable) NSURLSessionDownloadTask *task;
@property (nonatomic, strong, nullable) NSURL *downloadedFileURL;

@end

@implementation SAMPDownloader

+ (instancetype)shared {
    static SAMPDownloader *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[SAMPDownloader alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30.0;
        config.timeoutIntervalForResource = 900.0;
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return self;
}

- (NSArray<NSString *> *)mirrorURLs {
    // Mirror list curated by the SA-MP / open.mp project (see sa-mp.mp/downloads).
    return @[
        @"https://gta-multiplayer.cz/downloads/sa-mp-0.3.7-R5-2-MP-install.exe",
        @"https://hzgaming.net/downloads/sa-mp-0.3.7-R5-2-MP-install.exe",
        @"https://uifserver.net/download/sa-mp-0.3.7-R5-2-MP-install.exe",
    ];
}

- (void)downloadWithProgress:(SAMPDownloadProgress)progress completion:(SAMPDownloadCompletion)completion {
    self.progressBlock = progress;
    self.completionBlock = completion;
    self.urlIndex = 0;
    self.downloadedFileURL = nil;
    [self startCurrentMirror];
}

- (void)startCurrentMirror {
    NSArray<NSString *> *urls = [self mirrorURLs];
    if (self.urlIndex >= urls.count) {
        NSError *error = [NSError errorWithDomain:@"SAMPDownloader"
                                             code:1
                                         userInfo:@{NSLocalizedDescriptionKey: @"All download mirrors failed."}];
        [self finishWithURL:nil error:error];
        return;
    }
    NSURL *url = [NSURL URLWithString:urls[self.urlIndex]];
    self.downloadedFileURL = nil;
    self.task = [self.session downloadTaskWithURL:url];
    [self.task resume];
}

- (void)cancel {
    [self.task cancel];
    self.task = nil;
}

#pragma mark - Helpers

- (void)finishWithURL:(NSURL *)fileURL error:(NSError *)error {
    SAMPDownloadCompletion completion = self.completionBlock;
    self.progressBlock = nil;
    self.completionBlock = nil;
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(fileURL, error);
        });
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    SAMPDownloadProgress progress = self.progressBlock;
    if (progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progress(totalBytesWritten, totalBytesExpectedToWrite);
        });
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    // Ignore non-2xx responses (e.g. a mirror serving an error page).
    NSHTTPURLResponse *http = [downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]
        ? (NSHTTPURLResponse *)downloadTask.response : nil;
    if (http != nil && http.statusCode >= 400) {
        return; // leave downloadedFileURL nil so didCompleteWithError retries the next mirror
    }

    // Move synchronously: the temporary file is deleted when this method returns.
    NSArray<NSString *> *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *destDir = [dirs.firstObject stringByAppendingPathComponent:@"KurdUnity"];
    [[NSFileManager defaultManager] createDirectoryAtPath:destDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    NSURL *destURL = [NSURL fileURLWithPath:[destDir stringByAppendingPathComponent:kClientFileName]];

    NSError *moveError = nil;
    [[NSFileManager defaultManager] removeItemAtURL:destURL error:nil];
    if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:destURL error:&moveError]) {
        return; // leave downloadedFileURL nil; didCompleteWithError reports the failure
    }
    self.downloadedFileURL = destURL;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error == nil && self.downloadedFileURL != nil) {
        NSURL *fileURL = self.downloadedFileURL;
        self.downloadedFileURL = nil;
        [self finishWithURL:fileURL error:nil];
        return;
    }

    // User cancelled: stop, don't fall through to another mirror.
    if (error != nil && error.code == NSURLErrorCancelled) {
        [self finishWithURL:nil error:error];
        return;
    }

    NSError *finalError = error;
    if (finalError == nil) {
        NSHTTPURLResponse *http = [task.response isKindOfClass:[NSHTTPURLResponse class]]
            ? (NSHTTPURLResponse *)task.response : nil;
        NSString *reason = http != nil
            ? [NSString stringWithFormat:@"Mirror returned HTTP %ld.", (long)http.statusCode]
            : @"Mirror did not return a usable file.";
        finalError = [NSError errorWithDomain:@"SAMPDownloader"
                                         code:2
                                     userInfo:@{NSLocalizedDescriptionKey: reason}];
    }

    self.urlIndex += 1;
    if (self.urlIndex < [self mirrorURLs].count && self.completionBlock != nil) {
        [self startCurrentMirror];
    } else {
        [self finishWithURL:nil error:finalError];
    }
}

@end
