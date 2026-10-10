#import "HostProbe.h"

#import <errno.h>
#import <fcntl.h>
#import <netdb.h>
#import <sys/select.h>
#import <sys/socket.h>
#import <sys/time.h>
#import <unistd.h>

@implementation HostProbe

+ (void)probeHost:(NSString *)host
             port:(uint16_t)port
          timeout:(NSTimeInterval)timeout
       completion:(void (^)(BOOL))completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        BOOL reachable = NO;

        struct addrinfo hints;
        memset(&hints, 0, sizeof(hints));
        hints.ai_family = AF_INET;
        hints.ai_socktype = SOCK_STREAM;

        NSString *portString = [NSString stringWithFormat:@"%u", (unsigned)port];
        struct addrinfo *res = NULL;
        if (getaddrinfo(host.UTF8String, portString.UTF8String, &hints, &res) == 0 && res != NULL) {
            int fd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
            if (fd >= 0) {
                int flags = fcntl(fd, F_GETFL, 0);
                fcntl(fd, F_SETFL, flags | O_NONBLOCK);

                int result = connect(fd, res->ai_addr, res->ai_addrlen);
                if (result == 0) {
                    reachable = YES;
                } else if (errno == EINPROGRESS) {
                    fd_set writeSet;
                    FD_ZERO(&writeSet);
                    FD_SET(fd, &writeSet);

                    struct timeval tv;
                    tv.tv_sec = (time_t)timeout;
                    tv.tv_usec = (suseconds_t)((timeout - (double)tv.tv_sec) * 1000000.0);

                    int selected = select(fd + 1, NULL, &writeSet, NULL, &tv);
                    if (selected > 0) {
                        int socketError = 0;
                        socklen_t length = sizeof(socketError);
                        if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &socketError, &length) == 0 && socketError == 0) {
                            reachable = YES;
                        }
                    }
                }
                close(fd);
            }
            freeaddrinfo(res);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(reachable);
            }
        });
    });
}

@end
