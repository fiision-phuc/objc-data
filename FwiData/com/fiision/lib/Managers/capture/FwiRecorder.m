#import "FwiRecorder.h"


@interface FwiRecorder () <AVCaptureFileOutputRecordingDelegate> {

    NSURL *_outputFile;
    AVCaptureSession *_session;
    AVCaptureMovieFileOutput *_outputMovie;
}


- (AVCaptureConnection *)_connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;

@end


@implementation FwiRecorder


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _delegate    = nil;
        _session     = nil;
        _outputFile  = nil;
        _outputMovie = nil;
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    [_session removeOutput:_outputMovie];
    _delegate = nil;
    
    FwiRelease(_session);
	FwiRelease(_outputFile);
    FwiRelease(_outputMovie);
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties
- (BOOL)recording {
    BOOL isRecording = [_outputMovie isRecording];
    return isRecording;
}
- (BOOL)recordAudio {
	AVCaptureConnection *videoConnection = [self _connectionWithMediaType:AVMediaTypeVideo fromConnections:[_outputMovie connections]];
	return [videoConnection isActive];
}
- (BOOL)recordVideo {
	AVCaptureConnection *audioConnection = [self _connectionWithMediaType:AVMediaTypeAudio fromConnections:[_outputMovie connections]];
	return [audioConnection isActive];
}


#pragma mark - Class's public methods
- (void)startRecordingWithOrientation:(AVCaptureVideoOrientation)videoOrientation; {
    AVCaptureConnection *videoConnection = [self _connectionWithMediaType:AVMediaTypeVideo fromConnections:[_outputMovie connections]];
    if ([videoConnection isVideoOrientationSupported])
        [videoConnection setVideoOrientation:videoOrientation];

    [_outputMovie startRecordingToOutputFileURL:_outputFile recordingDelegate:self];
}
- (void)stopRecording {
    [_outputMovie stopRecording];
}


#pragma mark - Class's private methods
- (AVCaptureConnection *)_connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections {
	for (AVCaptureConnection *connection in connections) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:mediaType]) {
				return connection;
			}
		}
	}
	return nil;
}


#pragma mark - AVCaptureFileOutputRecordingDelegate's members
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    if ([[self delegate] respondsToSelector:@selector(recorderDidBegin:)]) {
        [[self delegate] recorderDidBegin:self];
    }
}
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFile fromConnections:(NSArray *)connections error:(NSError *)error {
    if ([[self delegate] respondsToSelector:@selector(recorder:writeToFile:error:)]) {
        [[self delegate] recorder:self writeToFile:outputFile error:error];
    }
}


@end


@implementation FwiRecorder (RecorderCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiRecorder *)recorderWithSession:(AVCaptureSession *)session outputFile:(NSURL *)outputFile {
    return FwiAutoRelease([[FwiRecorder alloc] initWithSession:session outputFile:outputFile]);
}


#pragma mark - Class's constructors
- (id)initWithSession:(AVCaptureSession *)session outputFile:(NSURL *)outputFile {
    self = [super init];
    if (self != nil) {
        _session     = FwiRetain(session);
        _outputFile  = FwiRetain(outputFile);
        _outputMovie = [[AVCaptureMovieFileOutput alloc] init];

        if ([_session canAddOutput:_outputMovie]) {
            [_session addOutput:_outputMovie];
        }
        else {
            FwiRelease(_outputMovie);
        }
    }
    
	return self;
}


@end