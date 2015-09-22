//  Project name: FwiData
//  File name   : FwiRecorder.h
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


@protocol FwiRecorderDelegate;


@interface FwiRecorder : NSObject {
}

@property (nonatomic, assign) id<FwiRecorderDelegate> delegate;

@property (nonatomic, readonly) BOOL recording;
@property (nonatomic, readonly) BOOL recordAudio;
@property (nonatomic, readonly) BOOL recordVideo;
@property (nonatomic, readonly) NSURL *outputFile;
@property (nonatomic, readonly) AVCaptureMovieFileOutput *outputMovie;


- (void)startRecordingWithOrientation:(AVCaptureVideoOrientation)videoOrientation;
- (void)stopRecording;

@end


@interface FwiRecorder (RecorderCreation)

// Class's static constructors
+ (__autoreleasing FwiRecorder *)recorderWithSession:(AVCaptureSession *)session outputFile:(NSURL *)outputFile;

// Class's constructors
- (id)initWithSession:(AVCaptureSession *)session outputFile:(NSURL *)outputFile;

@end


@protocol FwiRecorderDelegate <NSObject>

@required
- (void)recorderDidBegin:(FwiRecorder *)recorder;
- (void)recorder:(FwiRecorder *)recorder writeToFile:(NSURL *)outputFile error:(NSError *)error;

@end