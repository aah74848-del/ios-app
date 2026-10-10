#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Result of a SA-MP server query.
typedef void (^SAMPQueryCompletion)(BOOL responded,
                                    NSString * _Nullable hostname,
                                    NSInteger players,
                                    NSInteger maxPlayers);

/// Sends a RakNet "unconnected ping" (the same query the SA-MP client uses) to a
/// server and parses the pong. This is a real network probe, not a simulation.
@interface SAMPQuery : NSObject

+ (void)queryHost:(NSString *)host
             port:(uint16_t)port
          timeout:(NSTimeInterval)timeout
       completion:(SAMPQueryCompletion)completion;

@end

NS_ASSUME_NONNULL_END
