#import <UIKit/UIKit.h>
#import "PlayerView.h"


@interface StreamingMovieController : UIViewController {

@private
    IBOutlet PlayerView *_vwPlayer;
    
    IBOutlet UINavigationBar  *_navBar;
    IBOutlet UINavigationItem *_itmTitle;
    IBOutlet UIBarButtonItem  *_itmPlay;
    IBOutlet UIBarButtonItem  *_itmPause;
    IBOutlet UISlider         *_vwSlider;
    
    IBOutlet UIView           *_vwBusy;
}

@property (nonatomic, retain) NSURL *url;


- (IBAction)keyPressed:(id)sender;

// Handle slider
- (IBAction)scrub:(id)sender;
- (IBAction)endScrubbing:(id)sender;
- (IBAction)beginScrubbing:(id)sender;

@end
