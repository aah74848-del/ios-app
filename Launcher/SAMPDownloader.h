#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Live progress: bytesWritten / totalBytes (totalBytes is -1 when unknown).
typedef void (^SAMPDownloadProgress)(int64_t bytesWritten, int64_t totalBytes);
typedef void (^SAMPDownloadCompletion)(NSURL * _Nullable fileURL, NSError * _Nullable error);

/// Downloads the free, official SA-MP client installer (sa-mp-0.3.7-R5-2-MP) to the
/// app's Documents folder, trying several public mirrors in turn.
///
/// NOTE: this is a Windows installer meant for the player's PC. iOS cannot run it;
/// the launcher only fetches it so the file can be moved to the PC.
@interface SAMPDownloader : NSObject

+ (instancetype)shared;

- (void)downloadWithProgress:(nullable SAMPDownloadProgress)progress
                  completion:(SAMPDownloadCompletion)completion;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
