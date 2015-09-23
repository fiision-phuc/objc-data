#import "StreamingMovieController.h"


@interface StreamingMovieController () {
    
    BOOL _isCancel;
    BOOL _shouldReset;
}

@property (nonatomic, retain) id timeObserver;
@property (nonatomic, assign) float_t playSpeed;

@property (nonatomic, retain) AVURLAsset   *asset;
@property (nonatomic, retain) AVPlayer     *player;
@property (nonatomic, retain) AVPlayerItem *playerItem;


/** Initialize class's private variables. */
- (void)_init;
/** Localize UI components. */
- (void)_localize;
/** Visualize all view's components. */
- (void)_visualize;

/** Check if player is playing or not. */
- (BOOL)_isPlaying;
/** Return player item's duration. */
- (CMTime)_playerItemDuration;

/** Remove time observer. */
- (void)_removeTimeObserver;

/** Control scrubber. */
- (void)_initScrubber;
- (void)_syncScrubber;

/** Control star/pause. */
- (void)_showItemStop;
- (void)_showItemPlay;
- (void)_syncControls;
    
- (void)_assetDidFailWithError:(NSError *)error;
- (void)_prepareToPlayAssetWithKeys:(NSArray *)keys;

@end


@implementation StreamingMovieController


static void *PlayerItemStatusContext = &PlayerItemStatusContext;
static void *PlayerRateContext       = &PlayerRateContext;

static NSString *kTracksKey	  = @"tracks";
static NSString *kStatusKey	  = @"status";
static NSString *kRateKey     = @"rate";
static NSString *kPlayableKey = @"playable";


#pragma mark - Class's constructors
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }
    return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _init];
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.asset) {
        [self.asset cancelLoading];
        self.asset = nil;
    }
    
    [self.player removeObserver:self forKeyPath:kRateKey];
    self.url = nil;

#if !__has_feature(objc_arc)
    [_vwSlider release];
    [_vwPlayer release];
    [_navBar release];
    [_itmPlay release];
    [_itmPause release];
    [_itmTitle release];
    [_vwBusy release];
    [super dealloc];
#endif
}


#pragma mark - View's lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    
    // Metadata that need to be loaded
    NSArray *keys = @[kTracksKey, kPlayableKey];
    
    // Inject authorization header
    NSMutableDictionary * headers = [NSMutableDictionary dictionary];
    [headers setObject:[NSString stringWithFormat:@"%@ %@", [kUserPreferences tokenType], [kUserPreferences accessToken]] forKey:@"Authorization"];
    
    // Initialize url asset
    self.asset = [AVURLAsset URLAssetWithURL:self.url options:nil];
    [self.asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
         dispatch_async( dispatch_get_main_queue(), ^{
             /* Condition validation */
             if (_isCancel) return;
            
             /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
             [self _prepareToPlayAssetWithKeys:keys];
         });
    }];
}
- (void)viewWillDisappear:(BOOL)animated {
    _isCancel = YES;
    
    if ([self player]) {
        [self.player pause];
        self.player = nil;
    }
    
    [super viewWillDisappear:animated];
}
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}


#pragma mark - View's memory handler
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - View's orientation handler
- (BOOL)shouldAutorotate {
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations {
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


#pragma mark - View's transition event handler
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}


#pragma mark - View's key pressed event handlers
- (IBAction)keyPressed:(id)sender {
    if (sender == _itmPlay) {
        if (YES == _shouldReset) {
            _shouldReset = NO;
            [self.player seekToTime:kCMTimeZero];
        }
        
        [self.player play];
        [self _showItemStop];
    }
    else if (sender == _itmPause) {
        [self.player pause];
        [self _showItemPlay];
    }
}

- (IBAction)scrub:(id)sender {
    CMTime playerDuration = [self _playerItemDuration];
    
    /* Condition validation: Stop if player duration is invalid */
    if (CMTIME_IS_INVALID(playerDuration)) return;
    
    // Calculate time
    NSTimeInterval duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float_t minValue = [_vwSlider minimumValue];
        float_t maxValue = [_vwSlider maximumValue];
        float_t value    = [_vwSlider value];
        
        NSTimeInterval time = duration * (value - minValue) / (maxValue - minValue);
        [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
    }
}
- (IBAction)endScrubbing:(id)sender {
    [self _initScrubber];

    // Restore previous play speed
	[self.player setRate:_playSpeed];
    self.playSpeed = 0.0f;
}
- (IBAction)beginScrubbing:(id)sender {
    // Backup play speed
	self.playSpeed = [self.player rate];
	[self.player setRate:0.0f];

    // Stop time observer for a while
	[self _removeTimeObserver];
}


#pragma mark - Class's properties


#pragma mark - Class's public methods


#pragma mark - Class's private methods
- (void)_init {
}
- (void)_localize {
}
- (void)_visualize {
    self.view.backgroundColor = kColor_Texture1;
}

- (BOOL)_isPlaying {
	return ([self.player rate] != 0.0f);
}
- (CMTime)_playerItemDuration {
	AVPlayerItem *item = [self.player currentItem];
    
    if (item.status == AVPlayerItemStatusReadyToPlay) {
        return [item duration];
    }
    else {
        return kCMTimeInvalid;
    }
}

- (void)_removeTimeObserver {
	if (self.timeObserver) {
		[self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
	}
}

- (void)_initScrubber {
	/* Condition validation: Stop if player duration is invalid */
    CMTime playerDuration = [self _playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) return;
    
    /* Condition validation: Stop if timer duration is invalid */
    NSTimeInterval duration = CMTimeGetSeconds(playerDuration);
    if (!isfinite(duration)) return;
    
    // Enable time observer
	if (!self.timeObserver) {
        CGFloat width = CGRectGetWidth([_vwSlider bounds]);
        double_t interval = 0.5f * duration / width;
        
        self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                      queue:dispatch_get_main_queue()
                                                                 usingBlock:^(CMTime time) {
                                                                     [self _syncScrubber];
                                                                 }];
	}
}
- (void)_syncScrubber {
    _vwSlider.minimumValue = 0.0f;
    
    /* Condition validation: Stop if player duration is invalid */
    CMTime playerDuration = [self _playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) return;
    
    /* Condition validation: Stop if timer duration is invalid */
    NSTimeInterval duration = CMTimeGetSeconds(playerDuration);
    if (!isfinite(duration)) return;
	
    float_t minValue = [_vwSlider minimumValue];
    float_t maxValue = [_vwSlider maximumValue];
    NSTimeInterval time = CMTimeGetSeconds([self.player currentTime]);
    [_vwSlider setValue:((maxValue - minValue) * time / duration + minValue)];
}

- (void)_showItemStop {
    _itmTitle.leftBarButtonItem = _itmPause;
}
- (void)_showItemPlay {
    _itmTitle.leftBarButtonItem = _itmPlay;
}
- (void)_syncControls {
	if ([self _isPlaying]) {
        [self _showItemStop];
	}
	else {
        [self _showItemPlay];
	}
}

- (void)_assetDidFailWithError:(NSError *)error {
    if (self.asset) {
        [self.asset cancelLoading];
        self.asset = nil;
    }
    [kAppDelegate presentAlertWithTitle:[error localizedDescription] message:[error localizedFailureReason]];
}
- (void)_prepareToPlayAssetWithKeys:(NSArray *)keys {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.15f
                         animations:^{
                             _vwBusy.alpha = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             _vwBusy.hidden = YES;
                         }];
    });
    
    /* Condition validation: Make sure that the value of each key has loaded successfully */
	for (NSString *key in keys) {
        
        NSError *error = nil;
		AVKeyValueStatus status = [self.asset statusOfValueForKey:key error:&error];
        
		if (status == AVKeyValueStatusFailed) {
			[self _assetDidFailWithError:error];
			return;
		}
	}
    
    /* Condition validation: Detect whether the asset can be played */
    if (!self.asset.playable) {
		NSString *reason = NSLocalizedString(@"The asset were loaded, but could not be played.", @"The asset were loaded, but could not be played.");
		NSString *description = NSLocalizedString(@"Item cannot be played.", @"Item cannot be played.");
        
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey:description, NSLocalizedFailureReasonErrorKey:reason};
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"AVPlayer" code:0 userInfo:errorInfo];
        
        [self _assetDidFailWithError:assetCannotBePlayedError];
        return;
    }
    
    // Initialize AVPlayerItem
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset];
    
    // Initialize AVPlayer
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    _shouldReset = NO;
    // Reset slider
    [_vwSlider setValue:0.0f];
    
    // Observe change
    [self.playerItem addObserver:self
                      forKeyPath:kStatusKey
                         options:(NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew)
                         context:PlayerItemStatusContext];
    
    [self.player addObserver:self
                  forKeyPath:kRateKey
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:PlayerRateContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handlePlayerItemDidFinishNotification:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
}


#pragma mark - Class's notification handlers
- (void)observeValueForKeyPath:(NSString *)path ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == PlayerItemStatusContext) {
		[self _syncControls];
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerStatusUnknown: {
                [self _removeTimeObserver];
                [self _syncScrubber];
                break;
            }
            case AVPlayerStatusReadyToPlay: {
                _vwPlayer.playerLayer.hidden = NO;
                _vwSlider.hidden = NO;
                
                
                _vwPlayer.playerLayer.backgroundColor = [[UIColor blackColor] CGColor];
                
                /* Set the AVPlayerLayer on the view to allow the AVPlayer object to display
                 its content. */
                [_vwPlayer.playerLayer setPlayer:self.player];
                
                [self _initScrubber];
                break;
            }
            case AVPlayerStatusFailed: {
                [self _assetDidFailWithError:self.playerItem.error];
                break;
            }
        }
	}
	else if (context == PlayerRateContext) {
        [self _syncControls];
	}
	else {
		[super observeValueForKeyPath:path ofObject:object change:change context:context];
	}
}

- (void)_handlePlayerItemDidFinishNotification:(NSNotification *)aNotification {
    [self _showItemPlay];
	_shouldReset = YES;
}


@end
