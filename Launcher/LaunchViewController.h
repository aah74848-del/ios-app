#import <UIKit/UIKit.h>

/**
 * Programmatic launcher UI:
 *  - nickname field (persisted on every keystroke; written to Documents/samp/settings.ini)
 *  - SERVER status line (real RakNet query to 134.255.220.191:7777)
 *  - GTA STATUS: download-style progress bar
 *  - PLAY runs a SA-MP-style join sequence, then hands off to a streaming client
 */
@interface LaunchViewController : UIViewController

@end
