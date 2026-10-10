#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Probes whether a TCP port on a host accepts connections (real `connect()`),
/// e.g. Sunshine/GameStream on port 47989. Runs off the main thread.
@interface HostProbe : NSObject

+ (void)probeHost:(NSString *)host
             port:(uint16_t)port
          timeout:(NSTimeInterval)timeout
       completion:(void (^)(BOOL reachable))completion;

@end

NS_ASSUME_NONNULL_END
