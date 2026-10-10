#import "SAMPQuery.h"

#import <arpa/inet.h>
#import <netdb.h>
#import <sys/socket.h>
#import <sys/time.h>
#import <unistd.h>

// OFFLINE_MESSAGE_DATA_ID used by RakNet / SA-MP.
static const uint8_t kRakNetMagic[16] = {
    0x00, 0xFF, 0xFF, 0x00, 0xFE, 0xFE, 0xFE, 0xFE,
    0xFD, 0xFD, 0xFD, 0xFD, 0x12, 0x34, 0x56, 0x78
};

@implementation SAMPQuery

+ (void)queryHost:(NSString *)host
             port:(uint16_t)port
          timeout:(NSTimeInterval)timeout
       completion:(SAMPQueryCompletion)completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        BOOL responded = NO;
        NSString *hostname = nil;
        NSInteger players = -1;
        NSInteger maxPlayers = -1;

        struct addrinfo hints;
        memset(&hints, 0, sizeof(hints));
        hints.ai_family = AF_INET;
        hints.ai_socktype = SOCK_DGRAM;

        NSString *portString = [NSString stringWithFormat:@"%u", (unsigned)port];
        struct addrinfo *res = NULL;
        int gai = getaddrinfo(host.UTF8String, portString.UTF8String, &hints, &res);
        if (gai == 0 && res != NULL) {
            int fd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
            if (fd >= 0) {
                struct timeval tv;
                tv.tv_sec = (time_t)timeout;
                tv.tv_usec = (suseconds_t)((timeout - (double)tv.tv_sec) * 1000000.0);
                setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

                uint8_t packet[33];
                packet[0] = 0x01;                 // ID_UNCONNECTED_PING
                memset(packet + 1, 0, 8);         // ping time (unused)
                memcpy(packet + 9, kRakNetMagic, 16);

                ssize_t sent = sendto(fd, packet, sizeof(packet), 0, res->ai_addr, res->ai_addrlen);
                if (sent > 0) {
                    uint8_t buf[2048];
                    ssize_t n = recvfrom(fd, buf, sizeof(buf), 0, NULL, NULL);
                    if (n > 20) {
                        for (ssize_t i = 0; i + 18 <= n; i++) {
                            if (memcmp(buf + i, kRakNetMagic, 16) == 0) {
                                uint16_t len = (uint16_t)((buf[i + 16] << 8) | buf[i + 17]);
                                ssize_t start = i + 18;
                                if (len > 0 && start + len <= n) {
                                    responded = YES;
                                    NSData *strData = [NSData dataWithBytes:(buf + start) length:len];
                                    NSString *info = [[NSString alloc] initWithData:strData
                                                                           encoding:NSISOLatin1StringEncoding];
                                    // SA-MP pong: password;players;maxplayers;hostname;gamemode;language
                                    NSArray<NSString *> *fields = [info componentsSeparatedByString:@";"];
                                    if (fields.count >= 6) {
                                        players = [fields[1] integerValue];
                                        maxPlayers = [fields[2] integerValue];
                                        hostname = fields[3];
                                    } else {
                                        hostname = info;
                                    }
                                }
                                break;
                            }
                        }
                    }
                }
                close(fd);
            }
            freeaddrinfo(res);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(responded, hostname, players, maxPlayers);
            }
        });
    });
}

@end
