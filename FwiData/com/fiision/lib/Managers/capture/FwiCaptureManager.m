#import "FwiCaptureManager.h"


@interface FwiCaptureManager () <FwiRecorderDelegate> {

    AVCaptureSession *_session;
    AVCaptureVideoPreviewLayer *_previewLayer;

    // Background task for record video
    UIBackgroundTaskIdentifier _backgroundTask;
}

@property (nonatomic, readonly) NSString *tempFile;


/** Retrieve capture device. */
- (AVCaptureDevice *)_captureBack;
- (AVCaptureDevice *)_captureFront;
- (AVCaptureDevice *)_captureMicro;
- (AVCaptureDevice *)_captureWithPosition:(AVCaptureDevicePosition)position;

/** Initialize camera manager. */
- (BOOL)_initializeSession;
/** Prepare before record, we must remove the previous file. */
- (void)_removeFile:(NSURL *)outputFile;

@end


@implementation FwiCaptureManager


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        [self _initializeSession];
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    if (_backgroundTask) [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_session stopRunning];
    _delegate = nil;

    FwiRelease(_session);
    FwiRelease(_recorder);
    FwiRelease(_audioInput);
    FwiRelease(_videoInput);
    FwiRelease(_captureOutput);
    FwiRelease(_previewLayer);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties
- (NSUInteger)cameraCount {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    return (devices ? [devices count] : 0);
}
- (NSUInteger)microCount {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    return (devices ? [devices count] : 0);
}
- (NSString *)tempFile {
    NSString *path = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"video.mp4"];
    return path;
}


#pragma mark - Class's public methods
- (BOOL)toggleCamera {
    /* Condition validation */
    if (self.cameraCount < 1) return NO;
    
    // Initialize new video input
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:(_videoInput.device.position == AVCaptureDevicePositionBack ? [self _captureFront] : [self _captureBack]) error:&error];
    
    // Notify error to delegate
    if (error && _delegate && [_delegate respondsToSelector:@selector(cameraManager:didFailWithError:)])
        [_delegate cameraManager:self didFailWithError:error];
    
    /* Condition validation: Validate error of initialize process */
    if (error) {
        FwiRelease(videoInput);
        return NO;
    }
    
    // Switch video input
    [_session beginConfiguration];
    [_session removeInput:_videoInput];

    if ([_session canAddInput:videoInput]) {
        [_session addInput:videoInput];
        FwiRelease(_videoInput);
        _videoInput = videoInput;
    }
    else {
        [_session addInput:_videoInput];
        FwiRelease(videoInput);
    }
    [_session commitConfiguration];
    
    return YES;
}

- (void)initializePreview:(UIView *)view {
    /* Condition validation */
    if (!view) return;
    _isInitialize = YES;
    
    CALayer *rootLayer = [view layer];
    [rootLayer setMasksToBounds:YES];

    CGRect frame = [view bounds];
    if (!_previewLayer) {
        // Initialize preview layer
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [_previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];

        [_previewLayer setFrame:frame];
        [rootLayer addSublayer:_previewLayer];
    }
}

- (void)autoFocusAtPoint:(CGPoint)point {
    /* Condition validation */
    AVCaptureDevice *device = _videoInput.device;
    if (!device.isFocusPointOfInterestSupported || ![device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) return;
    
    /* Condition validation: Do not process if could not lock device */
    if (![device lockForConfiguration:nil]) return;
    
    [device setFocusMode:AVCaptureFocusModeAutoFocus];
    [device setFocusPointOfInterest:point];
    
    // Unlock device
    [device unlockForConfiguration];
}
- (void)continuousFocusAtPoint:(CGPoint)point {
    /* Condition validation */
    AVCaptureDevice *device = _videoInput.device;
    if (!device.isFocusPointOfInterestSupported || ![device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) return;
    
    /* Condition validation: Do not process if could not lock device */
    if (![device lockForConfiguration:nil]) return;
    
    [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
    [device setFocusPointOfInterest:point];
    
    // Unlock device
    [device unlockForConfiguration];
}


#pragma mark - Class's private methods
- (BOOL)_initializeSession {
    /* Condition validation */
    if (self.cameraCount == 0 || self.microCount == 0) return NO;
    BOOL success   = NO;

    // Initialize inputs
    NSError *error = nil;
    _videoInput    = [[AVCaptureDeviceInput alloc] initWithDevice:[self _captureBack] error:&error];
    _audioInput    = [[AVCaptureDeviceInput alloc] initWithDevice:[self _captureMicro] error:&error];

    // Notify error to delegate
    if (error && _delegate && [_delegate respondsToSelector:@selector(cameraManager:didFailWithError:)])
        [_delegate cameraManager:self didFailWithError:error];

    /* Condition validation: Validate error of initialize process */
    if (error) return NO;

    // Initialize capture session & preset medium quality for video
    _session = [[AVCaptureSession alloc] init];
    if ([_session canSetSessionPreset:AVCaptureSessionPresetMedium]) [_session setSessionPreset:AVCaptureSessionPresetMedium];

    // Add video & audio inputs
    if ([_session canAddInput:_videoInput]) [_session addInput:_videoInput];
    if ([_session canAddInput:_audioInput]) [_session addInput:_audioInput];


	// Initialize video & audio output
    _recorder = [[FwiRecorder alloc] initWithSession:_session outputFile:[NSURL fileURLWithPath:[self tempFile]]];
    [_recorder setDelegate:self];

    // Setup the still image file output
    _captureOutput = [[AVCaptureStillImageOutput alloc] init];
    [_captureOutput setOutputSettings:@{AVVideoCodecKey:AVVideoCodecJPEG}];
    if ([_session canAddOutput:_captureOutput]) [_session addOutput:_captureOutput];

    success = YES;
    return success;
}

- (AVCaptureDevice *)_captureBack {
    return [self _captureWithPosition:AVCaptureDevicePositionBack];
}
- (AVCaptureDevice *)_captureFront {
    return [self _captureWithPosition:AVCaptureDevicePositionFront];
}
- (AVCaptureDevice *)_captureMicro {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0) return [devices objectAtIndex:0];
    else return nil;
}
- (AVCaptureDevice *)_captureWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void)_removeFile:(NSURL *)outputFile {
    NSString *filePath = [outputFile path];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error = nil;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            if (_delegate && [_delegate respondsToSelector:@selector(cameraManager:didFailWithError:)]) {
                [_delegate cameraManager:self didFailWithError:error];
            }
        }
    }
}


#pragma mark - RecorderDelegate's members
- (void)recorderDidBegin:(FwiRecorder *)recorder {
    if (_delegate && [_delegate respondsToSelector:@selector(cameraManagerDidBeginRecording:)]) {
        [_delegate cameraManagerDidBeginRecording:self];
    }
}
- (void)recorder:(FwiRecorder *)recorder writeToFile:(NSURL *)outputFile error:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(cameraManagerDidFinishRecording:outputFile:)]) {
        [_delegate cameraManagerDidFinishRecording:self outputFile:self.tempFile];
    }
}


@end


@implementation FwiCaptureManager (ImageCapture)


- (NSError *)flashOn {
    NSError *error = nil;
    
    if ([[self _captureBack] hasFlash]) {
		if ([[self _captureBack] lockForConfiguration:&error]) {
			if ([[self _captureBack] isFlashModeSupported:AVCaptureFlashModeOn]) {
				[[self _captureBack] setFlashMode:AVCaptureFlashModeOn];
			}
			[[self _captureBack] unlockForConfiguration];
		}
	}
    return error;
}
- (NSError *)flashOff {
    NSError *error = nil;
    
    if ([[self _captureBack] hasFlash]) {
		if ([[self _captureBack] lockForConfiguration:&error]) {
			if ([[self _captureBack] isFlashModeSupported:AVCaptureFlashModeOff]) {
				[[self _captureBack] setFlashMode:AVCaptureFlashModeOff];
			}
			[[self _captureBack] unlockForConfiguration];
		}
	}
    return error;
}
- (NSError *)flashAuto {
    NSError *error = nil;
    
    if ([[self _captureBack] hasFlash]) {
		if ([[self _captureBack] lockForConfiguration:&error]) {
			if ([[self _captureBack] isFlashModeSupported:AVCaptureFlashModeAuto]) {
				[[self _captureBack] setFlashMode:AVCaptureFlashModeAuto];
			}
			[[self _captureBack] unlockForConfiguration];
		}
	}
    return error;
}

- (void)captureImage {
    /* Condition validation */
    if (!_captureOutput) return;
    AVCaptureConnection *captureConnection = nil;

    // Lookup video connection
    NSArray *connections = [_captureOutput connections];
    for (AVCaptureConnection *connection in connections) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				captureConnection = connection;
                break;
			}
		}
	}

    /* Condition validation: Stop process if could not find capture connection */
    if (!captureConnection) return;

    // Capture image
    [_captureOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        // Process image here
    }];
}


@end


@implementation FwiCaptureManager (VideoRecorder)


- (NSError *)torchOn {
    NSError *error = nil;
    
    if ([[self _captureBack] hasTorch]) {
		if ([[self _captureBack] lockForConfiguration:&error]) {
			if ([[self _captureBack] isTorchModeSupported:AVCaptureTorchModeOn]) {
				[[self _captureBack] setTorchMode:AVCaptureTorchModeOn];
			}
			[[self _captureBack] unlockForConfiguration];
		}
	}
    return error;
}
- (NSError *)torchOff {
    NSError *error = nil;
    
    if ([[self _captureBack] hasTorch]) {
		if ([[self _captureBack] lockForConfiguration:&error]) {
			if ([[self _captureBack] isTorchModeSupported:AVCaptureTorchModeOff]) {
				[[self _captureBack] setTorchMode:AVCaptureTorchModeOff];
			}
			[[self _captureBack] unlockForConfiguration];
		}
	}
    return error;
}
- (NSError *)torchAuto {
    NSError *error = nil;
    
    if ([[self _captureBack] hasTorch]) {
		if ([[self _captureBack] lockForConfiguration:&error]) {
			if ([[self _captureBack] isTorchModeSupported:AVCaptureTorchModeAuto]) {
				[[self _captureBack] setTorchMode:AVCaptureTorchModeAuto];
			}
			[[self _captureBack] unlockForConfiguration];
		}
	}
    return error;
}

- (void)stopRecording {
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
        _backgroundTask = UIBackgroundTaskInvalid;

        [[self recorder] stopRecording];
    });
}
- (void)startRecording {
    /* Condition validation */
    if ([[self recorder] recording]) return;
    
    NSInteger osVersion = [[[UIDevice currentDevice] systemVersion] integerValue];
    if (osVersion >= 7) {
        // Initialize audio recorder session
        NSError *error = nil;

        // Initialize audio session
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    }
    
    // Start camera
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            _backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
        }
        
        [self _removeFile:[[self recorder] outputFile]];
        [[self recorder] startRecordingWithOrientation:AVCaptureVideoOrientationPortrait];
    });
}


@end