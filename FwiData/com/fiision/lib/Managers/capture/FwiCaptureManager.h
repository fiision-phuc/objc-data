//  Project name: FwiData
//  File name   : FwiCaptureManager.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 8/31/15
//  Version     : 1.20
//  --------------------------------------------------------------
//  Copyright (C) 2012, 2015 Fiision Studio.
//  All Rights Reserved.
//  --------------------------------------------------------------
//
//  Permission is hereby granted, free of charge, to any person obtaining  a  copy
//  of this software and associated documentation files (the "Software"), to  deal
//  in the Software without restriction, including without limitation  the  rights
//  to use, copy, modify, merge,  publish,  distribute,  sublicense,  and/or  sell
//  copies of the Software,  and  to  permit  persons  to  whom  the  Software  is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF  ANY  KIND,  EXPRESS  OR
//  IMPLIED, INCLUDING BUT NOT  LIMITED  TO  THE  WARRANTIES  OF  MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO  EVENT  SHALL  THE
//  AUTHORS OR COPYRIGHT HOLDERS  BE  LIABLE  FOR  ANY  CLAIM,  DAMAGES  OR  OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING  FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN  THE
//  SOFTWARE.
//
//
//  Disclaimer
//  __________
//  Although reasonable care has been taken to  ensure  the  correctness  of  this
//  software, this software should never be used in any application without proper
//  testing. Fiision Studio disclaim  all  liability  and  responsibility  to  any
//  person or entity with respect to any loss or damage caused, or alleged  to  be
//  caused, directly or indirectly, by the use of this software.

#import <Foundation/Foundation.h>
#import "FwiRecorder.h"


@protocol FwiCaptureManagerDelegate;


@interface FwiCaptureManager : NSObject {
    
@private
    AVCaptureDeviceInput *_audioInput;
    AVCaptureDeviceInput *_videoInput;
    AVCaptureStillImageOutput *_captureOutput;
}

@property (nonatomic, assign) id<FwiCaptureManagerDelegate> delegate;

@property (nonatomic, readonly) FwiRecorder *recorder;
@property (nonatomic, readonly) AVCaptureSession *session;
@property (nonatomic, readonly) AVCaptureDeviceInput *audioInput;
@property (nonatomic, readonly) AVCaptureDeviceInput *videoInput;

@property (nonatomic, readonly) BOOL isInitialize;
@property (nonatomic, readonly) NSUInteger microCount;
@property (nonatomic, readonly) NSUInteger cameraCount;


/** Toggle between back and front camera. */
- (BOOL)toggleCamera;

/** Define preview layer. */
- (void)initializePreview:(UIView *)view;
/** Set auto focus. */
- (void)autoFocusAtPoint:(CGPoint)point;
/** Set continuous focus. */
- (void)continuousFocusAtPoint:(CGPoint)point;

@end


/** Flash mode for capturing static image. */
@interface FwiCaptureManager (ImageCapture)

/** Turn on flash. */
- (NSError *)flashOn;
/** Turn off flash. */
- (NSError *)flashOff;
/** Auto on/off flash. */
- (NSError *)flashAuto;

/** Capture still image */
- (void)captureImage;

@end


/** Torch mode for capturing video. */
@interface FwiCaptureManager (VideoRecorder)

/** Turn on torch. */
- (NSError *)torchOn;
/** Turn off torch. */
- (NSError *)torchOff;
/** Auto on/off torch. */
- (NSError *)torchAuto;

/** Stop recording video. */
- (void)stopRecording;
/** Start recording video. */
- (void)startRecording;

@end


@protocol FwiCaptureManagerDelegate <NSObject>

@optional
- (void)cameraManager:(FwiCaptureManager *)cameraManager didFailWithError:(NSError *)error;

- (void)cameraManagerDidBeginRecording:(FwiCaptureManager *)captureManager;
- (void)cameraManagerDidFinishRecording:(FwiCaptureManager *)captureManager outputFile:(NSString *)outputFile;


@end
