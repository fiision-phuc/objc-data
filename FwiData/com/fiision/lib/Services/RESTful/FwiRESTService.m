#import "FwiRESTService.h"


@interface FwiRESTService () {
}

@end


@implementation FwiRESTService


#pragma mark - Cleanup memory
- (void)dealloc {
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's public methods
- (void)executeWithCompletion:(void(^)(FwiJson *responseMessage, NSError *error, NSInteger statusCode))completion {
    [super executeWithCompletion:^(NSURL *locationPath, NSError *error, FwiNetworkStatus statusCode) {
        __autoreleasing NSData *data = [NSData dataWithContentsOfURL:locationPath];
        __autoreleasing FwiJson *responseMessage = [data decodeJson];

        if (completion) completion(responseMessage, error, statusCode);
    }];
}


@end


@implementation FwiRESTService (FwiRESTServiceCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiRESTService *)serviceWithRequest:(FwiRequest *)request {
    return FwiAutoRelease([[FwiRESTService alloc] initWithRequest:request]);
}

+ (__autoreleasing FwiRESTService *)serviceWithURL:(NSURL *)url {
    return [FwiRESTService serviceWithRequest:[FwiRequest requestWithURL:url methodType:kMethodType_Get]];
}
+ (__autoreleasing FwiRESTService *)serviceWithURL:(NSURL *)url method:(FwiMethodType)method {
    return [FwiRESTService serviceWithRequest:[FwiRequest requestWithURL:url methodType:method]];
}
+ (__autoreleasing FwiRESTService *)serviceWithURL:(NSURL *)url method:(FwiMethodType)method requestMessage:(FwiJson *)requestMessage {
    __autoreleasing FwiRequest *request = [FwiRequest requestWithURL:url methodType:method];
    [request setDataParameter:[FwiDataParam parameterWithJson:requestMessage]];
    return [FwiRESTService serviceWithRequest:request];
}
+ (__autoreleasing FwiRESTService *)serviceWithURL:(NSURL *)url method:(FwiMethodType)method requestDictionary:(NSDictionary *)requestDictionary {
    __unsafe_unretained __block FwiRequest *request = [FwiRequest requestWithURL:url methodType:method];
    
    [requestDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        __autoreleasing FwiFormParam *parameter = [FwiFormParam paramWithKey:key andValue:value];
        [request addFormParameters:parameter, nil];
    }];
    return [FwiRESTService serviceWithRequest:request];
}


@end