#import "FwiNetworkManager.h"


@interface FwiNetworkManager () <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate/*, NSURLSessionDownloadDelegate (Should be implemented by receiver)*/> {
}


/** Handle network error status. */
//- (void)_handleError:(NSError *)error errorMessage:(FwiJson *)errorMessage statusCode:(FwiNetworkStatus)statusCode;

@end


@implementation FwiNetworkManager


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _configuration = FwiRetain([NSURLSessionConfiguration defaultSessionConfiguration]);
        _configuration.allowsCellularAccess = YES;
        _configuration.timeoutIntervalForRequest  = 30.0f;
        _configuration.timeoutIntervalForResource = 60.0f;
        _configuration.networkServiceType = NSURLNetworkServiceTypeBackground;
        _configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
        
        _session = [NSURLSession sessionWithConfiguration:_configuration delegate:self delegateQueue:[FwiOperation operationQueue]];
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    FwiRelease(_configuration);
    FwiRelease(_session);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (__autoreleasing NSURLRequest *)prepareRequestWithURL:(NSURL *)url method:(FwiHttpMethod)method {
    return [FwiRequest requestWithURL:url methodType:method];
}
- (__autoreleasing NSURLRequest *)prepareRequestWithURL:(NSURL *)url method:(FwiHttpMethod)method params:(NSDictionary *)params {
    __unsafe_unretained __block FwiRequest *request = [FwiRequest requestWithURL:url methodType:method];

    // Insert data parameters if available
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [request addFormParam:[FwiFormParam paramWithKey:key andValue:value]];
    }];
    return request;
}

- (void)sendRequest:(NSURLRequest *)request completion:(void(^)(NSData *data, NSError *error, NSInteger statusCode))completion {
    if ([request isKindOfClass:[FwiRequest class]]) {
        _weak FwiRequest *customRequest = (FwiRequest *)request;
        [customRequest prepare];
    }
    
    __autoreleasing NSURLSessionDataTask *task = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completion) completion(data, error, 200);
    }];
    [task resume];
}
- (void)downloadResource:(NSURLRequest *)request completion:(void(^)(NSURL *location, NSError *error, NSInteger statusCode))completion {
    if ([request isKindOfClass:[FwiRequest class]]) {
        _weak FwiRequest *customRequest = (FwiRequest *)request;
        [customRequest prepare];
    }
    
    __autoreleasing NSURLSessionDownloadTask *task = [_session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (completion) completion(location, error, 200);
    }];
    [task resume];
}


#pragma mark - Class's private methods
//- (void)_handleError:(NSError *)error errorMessage:(FwiJson *)errorMessage statusCode:(FwiNetworkStatus)statusCode {
//    
//    
//    switch ((NSUInteger) statusCode) {
//        case 400:
//        case 401: {
////            if (errorMessage && ![[errorMessage jsonWithPath:@"title"] isLike:[FwiJson null]] && [[[errorMessage jsonWithPath:@"title"] getString] isEqualToString:kText_Expired] ) {
////                NSString *title = [[errorMessage jsonWithPath:@"title"] getString];
////                if ([title isEqualToString:kText_Expired]) {
////                    [kAppDelegate presentAlertWithTitle:kText_Info message:kText_RenewSubscription delegate:self tag:ALERT_TAG btnCancel:kText_No btnConfirm:kText_Yes];
////                    [kAppController dismissBusyWithCompletion:nil];
////                }
////            }
////            else {
////                if (errorMessage && ![[errorMessage jsonWithPath:@"detail"] isLike:[FwiJson null]]) {
////                    [kAppDelegate presentAlertWithTitle:kText_Warning message:[[errorMessage jsonWithPath:@"detail"] getString]];
////                }
////                else {
////                    [kAppDelegate presentAlertWithTitle:kText_Warning message:@"Unauthorized access."];
////                }
////            }
//            break;
//        }
//        case 402: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Payment Required: %@", detail]];
//            break;
//        }
//        case 403: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Forbidden: %@", detail]];
//            break;
//        }
//        case 404: {
////            NSString *title  = kText_Warning;
////            NSString *detail = @"Resource is not available.";
////            
////            if (errorMessage && ![[errorMessage jsonWithPath:@"detail"] isLike:[FwiJson null]]) {
////                detail = [[errorMessage jsonWithPath:@"detail"] getString];
////            }
////            if (errorMessage && ![[errorMessage jsonWithPath:@"title"] isLike:[FwiJson null]]) {
////                title = [[errorMessage jsonWithPath:@"title"] getString];
////            }
////            [kAppDelegate presentAlertWithTitle:title message:detail];
//            //                    [kAppDelegate presentAlertWithTitle:kText_Warning message:@"Resource is not available."];
//            break;
//        }
//        case 405: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Method Not Allowed: %@", detail]];
//            break;
//        }
//        case 406: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Not Acceptable: %@", detail]];
//            break;
//        }
//        case 407: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Proxy Authentication Required: %@", detail]];
//            break;
//        }
//        case 408: {
////            [kAppDelegate presentAlertWithTitle:kText_Warning message:@"Server is busy at the moment."];
//            break;
//        }
//        case 409: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Conflict: %@", detail]];
//            break;
//        }
//        case 410: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Gone: %@", detail]];
//            break;
//        }
//        case 411: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Length Required: %@", detail]];
//            break;
//        }
//        case 412: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Precondition Failed: %@", detail]];
//            break;
//        }
//        case 413: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Request Entity Too Large: %@", detail]];
//            break;
//        }
//        case 414: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Request-URI Too Large: %@", detail]];
//            break;
//        }
//        case 415: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Unsupported Media Type: %@", detail]];
//            break;
//        }
//        case 416: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Requested range not satisfiable: %@", detail]];
//            break;
//        }
//        case 417: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Expectation Failed: %@", detail]];
//            break;
//        }
//        case 418: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"I'm a teapot: %@", detail]];
//            break;
//        }
//        case 422: {
////            __block NSString *title  = nil;
////            __block NSString *detail = nil;
////            
////            if (![[errorMessage jsonWithPath:@"validation_messages"] isLike:[FwiJson null]]) {
////                FwiJson *validation = [errorMessage jsonWithPath:@"validation_messages"];
////                title = [[errorMessage jsonWithPath:@"detail"] getString];
////                
////                [validation enumerateKeysAndObjectsUsingBlock:^(NSString *key, FwiJson *json, BOOL *stop) {
////                    *stop  = YES;
////                    detail = ([json isLike:[FwiJson object]] ? [[json jsonAtIndex:0] getString] : [json getString]);
////                }];
////            }
////            else {
////                title  = [[errorMessage jsonWithPath:@"title"] getString];
////                detail = [[errorMessage jsonWithPath:@"detail"] getString];
////            }
////            
////            [kAppDelegate presentAlertWithTitle:title message:detail];
//            break;
//        }
//        case 423: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Locked: %@", detail]];
//            break;
//        }
//        case 424: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Failed Dependency: %@", detail]];
//            break;
//        }
//        case 425: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Unordered Collection: %@", detail]];
//            break;
//        }
//        case 426: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Upgrade Required: %@", detail]];
//            break;
//        }
//        case 428: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Precondition Required: %@", detail]];
//            break;
//        }
//        case 429: {
////            [kAppDelegate presentAlertWithTitle:kText_Warning message:@"Server is busy at the moment."];
//            break;
//        }
//        case 431: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Request Header Fields Too Large: %@", detail]];
//            break;
//        }
//        case 500: {
////            [kAppDelegate presentAlertWithTitle:kText_Warning message:@"Server is busy at the moment."];
//            break;
//        }
//        case 501: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Not Implemented: %@", detail]];
//            break;
//        }
//        case 502: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Bad Gateway: %@", detail]];
//            break;
//        }
//        case 503: {
////            [kAppDelegate presentAlertWithTitle:kText_Warning message:@"This service is not available at the moment."];
//            break;
//        }
//        case 504: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Gateway Time-out: %@", detail]];
//            break;
//        }
//        case 505: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"HTTP Version not supported: %@", detail]];
//            break;
//        }
//        case 506: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Variant Also Negotiates: %@", detail]];
//            break;
//        }
//        case 507: {
////            [kAppDelegate presentAlertWithTitle:kText_Warning message:@"Uploaded file had been rejected by server."];
//            break;
//        }
//        case 508: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Loop Detected: %@", detail]];
//            break;
//        }
//        case 511: {
//            //                    [kAppDelegate presentAlertWithTitle:title message:[NSString stringWithFormat:@"Network Authentication Required: %@", detail]];
//            break;
//        }
////        case kNetworkStatus_CannotConnectToHost:
//        default:
////            [kAppDelegate presentAlertWithTitle:kText_Warning message:@"Could not connect to server at the moment."];
//            break;
//    }
//}


#pragma mark - NSURLSessionDelegate's members
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    DLog(@"");
}
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    DLog(@"");
}


#pragma mark - NSURLSessionTaskDelegate's members
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    DLog(@"");
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    DLog(@"");
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler {
    DLog(@"");
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    DLog(@"");
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    DLog(@"");
}


#pragma mark - NSURLSessionDataDelegate's members
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    DLog(@"");
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    DLog(@"");
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    DLog(@"");
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
    DLog(@"");
}


@end


@implementation FwiNetworkManager (FwiNetworkManagerSingleton)


static FwiNetworkManager *_NetworkManager;


#pragma mark - Environment initialize
+ (void)initialize {
    _NetworkManager = nil;
}


#pragma mark - Class's static constructors
+ (_weak FwiNetworkManager *)sharedInstance {
    if (_NetworkManager) return _NetworkManager;
    
    @synchronized (self) {
        if (!_NetworkManager) _NetworkManager = [[FwiNetworkManager alloc] init];
    }
    return _NetworkManager;
}


@end