#import "FwiCacheHandler.h"


@interface FwiCacheHandler () {
    
    NSFileManager  *_manager;
    NSMutableArray *_placeHolder;
}

@end


@implementation FwiCacheHandler


@synthesize cacheFolder=_cacheFolder;


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _cacheFolder = nil;
        _manager     = [NSFileManager defaultManager];
        _placeHolder = [[NSMutableArray alloc] initWithCapacity:20];
    }
    return self;
}


#pragma mark - Cleanup memory
-(void)dealloc {
    FwiRelease(_cacheFolder);
    FwiRelease(_placeHolder);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (void)handleDelegate:(id<FwiCacheHandlerDelegate>)delegate {
//    NSURL    *imageUrl    = [delegate urlForHandler:self];
//    NSString *readyFile   = [_cacheFolder readyPathForFilename:[imageUrl description]];
//    NSString *loadingFile = [_cacheFolder loadingPathForFilename:[imageUrl description]];
//    
//    if ([_manager fileExistsAtPath:readyFile]) {
//        [_cacheFolder updateFile:readyFile];
//        
//        if (delegate && [delegate respondsToSelector:@selector(cacheHandler:didFinishDownloadingImage:atUrl:)]) {
//            UIImage *image = [UIImage imageWithContentsOfFile:readyFile];
//            [delegate cacheHandler:self didFinishDownloadingImage:image atUrl:imageUrl];
//        }
//    }
//    else {
//        // Add to place holder
//        @synchronized (_placeHolder) {
//            [_placeHolder addObject:@{@"url":imageUrl, @"delegate":delegate}];
//        }
//        
//        /* Condition validation: Validate if loading file is exited or not */
//        if (![_manager fileExistsAtPath:loadingFile]) {
//            [_manager createFileAtPath:loadingFile contents:nil attributes:nil];
//        }
//        
//        if (delegate && [delegate respondsToSelector:@selector(cacheHandlerWillStartDownloading:)]) {
//            [delegate cacheHandlerWillStartDownloading:self];
//        }
//    
//        // Perform download file from server
//        FwiRequest *request = [kNetController prepareRequestWithURL:imageUrl method:kMethodType_Get request:nil];
//        FwiService *service = [FwiService serviceWithRequest:request];
//        [service executeWithCompletion:^(NSURL *locationPath, NSError *error, NSInteger statusCode) {
//            if (200 <= statusCode && statusCode <= 299) {
//                NSData *responseData = [NSData dataWithContentsOfURL:locationPath];
//                NSString *readyFile1 = nil;
//                
//                if (responseData && responseData.length > 0) {
//                    NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:loadingFile];
//                    [output writeData:responseData];
//                    [output closeFile];
//                    
//                    // Move downloaded file from loading folder to ready folder
//                    readyFile1 = [_cacheFolder loadingFinishedForFilename:[imageUrl description]];
//                }
//                
//                @synchronized (_placeHolder) {
//                    // Notify all waiting delegates
//                    NSPredicate *p   = [NSPredicate predicateWithFormat:@"SELF.url == %@", imageUrl];
//                    NSArray *filters = [_placeHolder filteredArrayUsingPredicate:p];
//                    [filters enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop) {
//                        NSURL *u = [item objectForKey:@"url"];
//                        id<FwiCacheHandlerDelegate> d = [item objectForKey:@"delegate"];
//                        
//                        if (d && [d respondsToSelector:@selector(cacheHandler:didFinishDownloadingImage:atUrl:)]) {
//                            UIImage *image = [UIImage imageWithContentsOfFile:readyFile1];
//                            [d cacheHandler:self didFinishDownloadingImage:image atUrl:u];
//                        }
//                    }];
//                    
//                    // Update place holder
//                    [filters enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id item, NSUInteger idx, BOOL *stop) {
//                        [_placeHolder removeObject:item];
//                    }];
//                }
//            }
//            else {
//                NSError *fileError = nil;
//                [_manager removeItemAtPath:loadingFile error:&fileError];
//                
//                @synchronized (_placeHolder) {
//                    // Notify all waiting delegates
//                    NSPredicate *p   = [NSPredicate predicateWithFormat:@"SELF.url == %@", imageUrl];
//                    NSArray *filters = [_placeHolder filteredArrayUsingPredicate:p];
//                    [filters enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop) {
//                        NSURL *u = [item objectForKey:@"url"];
//                        id<FwiCacheHandlerDelegate> d = [item objectForKey:@"delegate"];
//                        
//                        if (d && [d respondsToSelector:@selector(cacheHandler:didFailDownloadingImage:atUrl:)]) {
//                            [d cacheHandler:self didFailDownloadingImage:nil atUrl:u];
//                        }
//                    }];
//                    
//                    // Update place holder
//                    [filters enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id item, NSUInteger idx, BOOL *stop) {
//                        [_placeHolder removeObject:item];
//                    }];
//                }
//            }
//        }];
//    }
}


#pragma mark - Class's private methods


@end


@implementation FwiCacheHandler (FwiCacheHandlerCreation)


#pragma mark - Class's static constructors
+ (FwiCacheHandler *)cacheHandlerWithCacheFolder:(FwiCacheFolder *)cacheFolder {
    return FwiAutoRelease([[FwiCacheHandler alloc] initWithCacheFolder:cacheFolder]);
}


#pragma mark - Class's constructors
- (id)initWithCacheFolder:(FwiCacheFolder *)cacheFolder {
    self = [self init];
    if (self) {
        _cacheFolder = FwiRetain(cacheFolder);
    }
    return self;
}


@end