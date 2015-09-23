#import <UIKit/UIKit.h>

@class AVPlayerLayer;


@interface PlayerView : UIView {
}

@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

- (void)setVideoFillMode:(NSString *)fillMode;

@end
