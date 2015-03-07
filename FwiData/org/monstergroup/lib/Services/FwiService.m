#import "FwiService.h"


@interface FwiService () {
    
    // Network
    NSError *_error;
    NSTimer *_timer;
    FwiNetworkStatus _statusCode;
    
    // File Handler
    NSString *_path;
    NSFileHandle *_output;
}


/** Close connection. */
- (void)_shutdownConnection;

@end


@implementation FwiService


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _con = nil;
        _req = nil;
        _res = nil;
        
        _path   = nil;
        _output = nil;
        
        _error = nil;
        _timer = nil;
        _statusCode = kNetworkStatus_None;
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    FwiRelease(_con);
    FwiRelease(_req);
    FwiRelease(_res);
    
    FwiRelease(_path);
    FwiRelease(_output);
    
    FwiRelease(_error);
    _timer = nil;
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's public methods
- (void)businessLogic {
    // Prepare data buffer
    __autoreleasing NSString *path = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString randomIdentifier]];
    _path = FwiRetain(path);
    
    // Prepare request if neccessary
    if ([_req respondsToSelector:@selector(prepare)]) [_req performSelector:@selector(prepare)];

    __autoreleasing NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    @try {
        // Initialize connection
        _con = [[NSURLConnection alloc] initWithRequest:_req delegate:self startImmediately:NO];
        [_con scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];

        // Initialize timer
        if (!self.isLongOperation) {
            _timer = [NSTimer timerWithTimeInterval:_req.timeoutInterval target:self selector:@selector(_shutdownConnection) userInfo:nil repeats:NO];
            [runLoop addTimer:_timer forMode:NSDefaultRunLoopMode];
        }
        
        // Open network connection
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [_con  start];
        [runLoop run];
    }
    @catch(NSException *ex) {
        _state      = kOPState_Error;
        _statusCode = NSURLErrorUnknown;
        _error      = FwiRetain([NSError errorWithDomain:ex.name code:_statusCode userInfo:ex.userInfo]);
    }
    @finally {
        if (_state == kOPState_Error) {
            __autoreleasing NSMutableString *errorMessage = [NSMutableString stringWithCapacity:1000];
            [errorMessage appendFormat:@"HTTP Url   : %@\n", _req.URL];
            [errorMessage appendFormat:@"HTTP Method: %@\n", _req.HTTPMethod];
            [errorMessage appendFormat:@"HTTP Status: %li (%@)\n", (unsigned long) _statusCode, _error.localizedDescription];
            [errorMessage appendFormat:@"%@", [NSString stringWithContentsOfFile:_path encoding:NSUTF8StringEncoding error:nil]];

            NSLog(@"\n\n%@\n\n", errorMessage);
        }
    }
}


#pragma mark - Class's private methods
- (void)_shutdownConnection {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (_output) [_output closeFile];
    if (_timer) [_timer invalidate];
    if (_con) [_con cancel];
}


#pragma mark - Class's notification handlers


#pragma mark - NSOperation's members
- (void)cancel {
    [self _shutdownConnection];

    // Define error
    _state = kOPState_Error;
    _statusCode = kNetworkStatus_Cancelled;
    
    __autoreleasing NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:_statusCode userInfo:@{NSURLErrorFailingURLErrorKey:[_req.URL description], NSURLErrorFailingURLStringErrorKey:[_req.URL description], NSLocalizedDescriptionKey:[NSHTTPURLResponse localizedStringForStatusCode:_statusCode]}];
    _error = FwiRetain(error);

    // Perform cancel
    [super cancel];
}


#pragma mark - NSURLConnectionDelegate's members
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self _shutdownConnection];

    _state = kOPState_Error;
    _statusCode = [error code];
    
    _error = FwiRetain(error);
}
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef       serverTrust = challenge.protectionSpace.serverTrust;
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
        
        // Verify certificate
        __autoreleasing NSData   *crtData = (NSData *)CFBridgingRelease(SecCertificateCopyData(certificate));
        __autoreleasing NSBundle *bundle  = [NSBundle bundleForClass:[self class]];
        __autoreleasing NSArray  *paths   = [bundle pathsForResourcesOfType:@"cer" inDirectory:@"."];

        // Load all accepted certificates
        __autoreleasing NSMutableArray *crts = [NSMutableArray arrayWithCapacity:paths.count];
        for (NSString *path in paths) {
            __autoreleasing NSData *data = [NSData dataWithContentsOfFile:path];
            [crts addObject:data];
        }

        // Validate the received certificate
        if ([crts containsObject:crtData]) {
            __autoreleasing NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        }
        else {
            __autoreleasing FwiDer *cert  = [crtData decodeDer];
            __autoreleasing NSDate *today = [NSDate date];

            FwiDer *issuer     = [cert derWithPath:@"0/3"];
            FwiDer *subject    = [cert derWithPath:@"0/5"];
            NSUInteger version = [[cert derWithPath:@"0/0/0"] getInt];
            NSDate *notBefor   = [[cert derWithPath:@"0/4/0"] getTime];
            NSDate *notAfter   = [[cert derWithPath:@"0/4/1"] getTime];

            /* Condition validation */
            if (version != 2) {
                [[challenge sender] cancelAuthenticationChallenge:challenge];
                return;
            }
            if (!issuer || !subject) {
                [[challenge sender] cancelAuthenticationChallenge:challenge];
                return;
            }
            if (!notBefor || !notAfter || !(([today compare:notBefor] >= 0 && [today compare:notAfter] < 0))) {
                [[challenge sender] cancelAuthenticationChallenge:challenge];
                return;
            }

            BOOL shouldAllow = NO;
            if (self.delegate && [self.delegate respondsToSelector:@selector(service:authenticationChallenge:)])
                shouldAllow = [(id<FwiServiceDelegate>)self.delegate service:self authenticationChallenge:certificate];

            if (!shouldAllow) {
                [[challenge sender] cancelAuthenticationChallenge:challenge];
            }
            else {
                __autoreleasing NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
            }
        }
    }
    else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}


#pragma mark - NSURLConnectionDataDelegate's members
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if (totalBytesWritten == totalBytesExpectedToWrite) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
    else {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    
    // FIX FIX FIX: Should return delegate here to implement upload progress bar
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    _res = FwiRetain((NSHTTPURLResponse *)response);
    _statusCode = _res.statusCode;
    
	if (!FwiNetworkStatusIsSuccces(_statusCode)) {
        __autoreleasing NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:_statusCode userInfo:@{NSURLErrorFailingURLErrorKey:[_req.URL description], NSURLErrorFailingURLStringErrorKey:[_req.URL description], NSLocalizedDescriptionKey:[NSHTTPURLResponse localizedStringForStatusCode:_statusCode]}];
        _error = FwiRetain(error);
        _state = kOPState_Error;
	}

    _weak NSString *contentLength = [_res allHeaderFields][@"Content-Length"];
    NSUInteger contentSize = contentLength ? (NSUInteger)roundf([contentLength integerValue]) : 4096;

    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createFileAtPath:_path contents:nil attributes:nil];
    _output = FwiRetain([NSFileHandle fileHandleForWritingAtPath:_path]);

    // Notify delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(service:totalBytesWillReceive:)])
        [(id<FwiServiceDelegate>)self.delegate service:self totalBytesWillReceive:contentSize];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    /* Condition validation */
    if (!data || data.length == 0) return;
    if (_output) [_output writeData:data];

    if (self.delegate && [self.delegate respondsToSelector:@selector(service:bytesReceived:)])
        [(id<FwiServiceDelegate>)self.delegate service:self bytesReceived:[data length]];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self _shutdownConnection];
}


@end


@implementation FwiService (FwiServiceCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiService *)serviceWithRequest:(FwiRequest *)request {
    return FwiAutoRelease([[FwiService alloc] initWithRequest:request]);
}

+ (__autoreleasing FwiService *)serviceWithURL:(NSURL *)url {
    return [FwiService serviceWithRequest:[FwiRequest requestWithURL:url methodType:kMethodType_Get]];
}
+ (__autoreleasing FwiService *)serviceWithURL:(NSURL *)url method:(FwiMethodType)method {
    return [FwiService serviceWithRequest:[FwiRequest requestWithURL:url methodType:method]];
}
+ (__autoreleasing FwiService *)serviceWithURL:(NSURL *)url method:(FwiMethodType)method requestMessage:(FwiJson *)requestMessage {
    __autoreleasing FwiRequest *request = [FwiRequest requestWithURL:url methodType:method];
    [request setDataParameter:[FwiDataParam parameterWithJson:requestMessage]];
    return [FwiService serviceWithRequest:request];
}
+ (__autoreleasing FwiService *)serviceWithURL:(NSURL *)url method:(FwiMethodType)method requestDictionary:(NSDictionary *)requestDictionary {
    __unsafe_unretained __block FwiRequest *request = [FwiRequest requestWithURL:url methodType:method];
    
    // Insert parameters
    [requestDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        __autoreleasing FwiFormParam *parameter = [FwiFormParam paramWithKey:key andValue:value];
        [request addFormParameters:parameter, nil];
    }];
    return [FwiService serviceWithRequest:request];
}


#pragma mark - Class's constructors
- (id)initWithRequest:(FwiRequest *)request {
    self = [self init];
    if (self) {
        _req = FwiRetain(request);
    }
    return self;
}


@end


@implementation FwiService (FwiExtension)


- (void)executeWithCompletion:(void(^)(NSURL *locationPath, NSError *error, NSInteger statusCode))completion {
    [super executeWithCompletion:^{
        __autoreleasing NSURL *locationPath = [NSURL fileURLWithPath:_path];
        if (completion) completion(locationPath, _error, _statusCode);

        // Delete buffer data
        NSFileManager *manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:_path]) {
            [manager removeItemAtPath:_path error:nil];
        }
    }];
}


@end