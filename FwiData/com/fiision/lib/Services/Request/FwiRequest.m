#import "FwiRequest.h"
#import "FwiDataParam.h"
#import "FwiFormParam.h"
#import "FwiMultipartParam.h"


#define kHTTP_Copy      @"COPY";
#define kHTTP_Delete    @"DELETE";
#define kHTTP_Get       @"GET";
#define kHTTP_Link      @"LINK";
#define kHTTP_Head      @"HEAD";
#define kHTTP_Options   @"OPTIONS";
#define kHTTP_Patch     @"PATCH";
#define kHTTP_Post      @"POST";
#define kHTTP_Purge     @"PURGE";
#define kHTTP_Put       @"PUT";
#define kHTTP_Unlink    @"UNLINK";


@interface FwiRequest () {

    // Request type
    FwiMethodType    _type;

    // Raw request
    FwiDataParam *_raw;
    // Form request
    NSMutableArray   *_form;
    NSMutableArray   *_upload;
}

@property (nonatomic, strong) FwiDataParam *raw;
@property (nonatomic, strong) NSMutableArray *form;
@property (nonatomic, strong) NSMutableArray *upload;


/** Initialize form & upload. */
- (void)_initializeForm;
- (void)_initializeUpload;

/** Add form parameter. */
- (void)_addFormParameter:(FwiDataParam *)parameter;

/** Add multipart parameter. */
- (void)_addMultipartParameter:(FwiMultipartParam *)parameter;

@end


@implementation FwiRequest


#pragma mark - Cleanup memory
- (void)dealloc {
    self.raw    = nil;
    self.form   = nil;
    self.upload = nil;

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (size_t)prepare {
    __autoreleasing NSDictionary *allHeaders = [self allHTTPHeaderFields];

    if (!allHeaders[@"Accept"]) [self setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    if (!allHeaders[@"Accept-Charset"]) [self setValue:@"UTF-8" forHTTPHeaderField:@"Accept-Charset"];
    if (!allHeaders[@"Accept-Encoding"]) [self setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    if (!allHeaders[@"Connection"]) [self setValue:@"close" forHTTPHeaderField:@"Connection"];
    if (!allHeaders[@"User-Agent"]) [self setValue:FwiGenerateUserAgent() forHTTPHeaderField:@"User-Agent"];

    /* Condition validation */
    if (!_raw && _form.count == 0 && _upload.count == 0) return 0;
    size_t length = 0;

    if (_raw) {
        // Define content type header
        if (!allHeaders[@"Content-Type"]) [self setValue:_raw.contentType forHTTPHeaderField:@"Content-Type"];

        // Compress data
        NSData *compressedData = (_enableGZip ? [_raw.data zip] : _raw.data);
        if (_enableGZip) [self setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];

        // Define content length header
        length = [compressedData length];
        [self setHTTPBody:compressedData];
        [self setValue:[NSString stringWithFormat:@"%zu",(unsigned long)[compressedData length]] forHTTPHeaderField:@"Content-Length"];
    }
    else {
        switch (_type) {
            case kMethodType_Delete: {
                // ???
                break;
            }
            case kMethodType_Patch:
            case kMethodType_Post:
            case kMethodType_Put: {
                if (_form && !_upload) {
                    // Define content type header
                    if (!allHeaders[@"Content-Type"]) [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

                    // Compress data
                    __autoreleasing NSData *compressedData = (_enableGZip ? [[[_form componentsJoinedByString:@"&"] toData] zip] : [[_form componentsJoinedByString:@"&"] toData]);
                    if (_enableGZip) [self setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];

                    // Define content length header
                    length = [compressedData length];
                    [self setHTTPBody:compressedData];
                    [self setValue:[NSString stringWithFormat:@"%li", (long)length] forHTTPHeaderField:@"Content-Length"];
                }
                else {
                    // Define boundary
                    __autoreleasing NSString *boundary    = [NSString stringWithFormat:@"--------%li", (unsigned long) [[NSDate date] timeIntervalSince1970]];
                    __autoreleasing NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];

                    // Define content type header
                    [self setValue:contentType forHTTPHeaderField:@"Content-Type"];

                    // Define body
                    __unsafe_unretained __block NSString *weakBoundary = boundary;
                    __unsafe_unretained __block NSMutableData *body    = [NSMutableData data];

                    [_upload enumerateObjectsUsingBlock:^(FwiMultipartParam *part, NSUInteger idx, BOOL *stop) {
                        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", weakBoundary] toData]];
                        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", part.name, part.fileName] toData]];
                        [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", part.contentType] toData]];
                        [body appendData:part.data];
                    }];

                    [_form enumerateObjectsUsingBlock:^(FwiFormParam *pair, NSUInteger idx, BOOL *stop) {
                        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", weakBoundary] toData]];
                        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", pair.key] toData]];
                        [body appendData:[pair.value toData]];
                    }];
                    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] toData]];

                    // Prepare body
                    [self setHTTPBody:body];
                    length = [body length];
                    
                    // Define content length header
                    [self setValue:[NSString stringWithFormat:@"%zu",(unsigned long)length] forHTTPHeaderField:@"Content-Length"];
                }
                break;
            }
            case kMethodType_Get:
            default: {
                __autoreleasing NSString *finalURL = [NSString stringWithFormat:@"%@?%@", self.URL.absoluteString, [_form componentsJoinedByString:@"&"]];
                self.URL = [NSURL URLWithString:finalURL];
                break;
            }
        }
    }
    return length;
}


#pragma mark - Class's private methods
- (void)_initializeForm {
    /* Condition validation */
    if (_form) return;
    _form = [[NSMutableArray alloc] initWithCapacity:9];
}
- (void)_initializeUpload {
    /* Condition validation */
    if (_upload) return;
    _upload = [[NSMutableArray alloc] initWithCapacity:1];
}

- (void)_addFormParameter:(FwiDataParam *)parameter {
    /* Condition validation */
    if (![parameter isMemberOfClass:[FwiFormParam class]] || [_form containsObject:parameter]) return;
    [_form addObject:parameter];
}

- (void)_addMultipartParameter:(FwiMultipartParam *)parameter {
    /* Condition validation */
    if (![parameter isMemberOfClass:[FwiMultipartParam class]] || [_upload containsObject:parameter]) return;
    [_upload addObject:parameter];
}


@end


@implementation FwiRequest (FwiRequestCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiRequest *)requestWithURL:(NSURL *)url methodType:(FwiMethodType)type {
    return FwiAutoRelease([[FwiRequest alloc] initWithURL:url methodType:type]);
}


#pragma mark - Class's constructors
- (id)initWithURL:(NSURL *)url methodType:(FwiMethodType)type {
    self = [super initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    if (self) {
        _enableGZip = NO;
        _raw        = nil;
        _form       = nil;
        _upload     = nil;

        // Assign HTTP Method
        _type = type;
        switch (_type) {
            case kMethodType_Copy: {
                self.HTTPMethod = kHTTP_Copy;
                break;
            }
            case kMethodType_Delete: {
                self.HTTPMethod = kHTTP_Delete;
                break;
            }
            case kMethodType_Head: {
                self.HTTPMethod = kHTTP_Head;
                break;
            }
            case kMethodType_Link: {
                self.HTTPMethod = kHTTP_Link;
                break;
            }
            case kMethodType_Options: {
                self.HTTPMethod = kHTTP_Options;
                break;
            }
            case kMethodType_Patch: {
                self.HTTPMethod = kHTTP_Patch;
                break;
            }
            case kMethodType_Post: {
                self.HTTPMethod = kHTTP_Post;
                break;
            }
            case kMethodType_Purge: {
                self.HTTPMethod = kHTTP_Purge;
                break;
            }
            case kMethodType_Put: {
                self.HTTPMethod = kHTTP_Put;
                break;
            }
            case kMethodType_Unlink: {
                self.HTTPMethod = kHTTP_Unlink;
                break;
            }
            case kMethodType_Get:
            default: {
                self.HTTPMethod = kHTTP_Get;
                break;
            }
        }
    }
    return self;
}


@end


@implementation FwiRequest (FwiForm)


- (void)addFormParameter:(id)parameter {
    if (!_form) [self _initializeForm];
    FwiRelease(_raw);
    
    [self _addFormParameter:parameter];
}
- (void)addFormParameters:(id)parameter, ... NS_REQUIRES_NIL_TERMINATION {
    if (!_form) [self _initializeForm];
    FwiRelease(_raw);

    va_list parameters;
	va_start(parameters, parameter);
    [self _addFormParameter:parameter];

    while ((parameter = va_arg(parameters, id))) {
        [self _addFormParameter:parameter];
    }
	va_end(parameters);
}
- (void)setFormParameter:(id)parameter {
    if (!_form) [self _initializeForm];
    else [_form removeAllObjects];
    FwiRelease(_raw);
    
    [self _addFormParameter:parameter];
}
- (void)setFormParameters:(id)parameter, ... NS_REQUIRES_NIL_TERMINATION {
    if (!_form) [self _initializeForm];
    else [_form removeAllObjects];
    FwiRelease(_raw);

    va_list parameters;
	va_start(parameters, parameter);
    [self _addFormParameter:parameter];

    while ((parameter = va_arg(parameters, id))) {
        [self _addFormParameter:parameter];
    }
	va_end(parameters);
}

- (void)addMultipartParameter:(id)parameter {
    if (!_upload) [self _initializeUpload];
    FwiRelease(_raw);
    
    [self _addMultipartParameter:parameter];
}
- (void)addMultipartParameters:(id)parameter, ... NS_REQUIRES_NIL_TERMINATION {
    if (!_upload) [self _initializeUpload];
    FwiRelease(_raw);

    va_list parameters;
	va_start(parameters, parameter);
    [self _addMultipartParameter:parameter];

    while ((parameter = va_arg(parameters, id))) {
        [self _addMultipartParameter:parameter];
    }
	va_end(parameters);
}
- (void)setMultipartParameter:(id)parameter {
    if (!_upload) [self _initializeUpload];
    else [_upload removeAllObjects];
    FwiRelease(_raw);
    
    [self _addMultipartParameter:parameter];
}
- (void)setMultipartParameters:(id)parameter, ... NS_REQUIRES_NIL_TERMINATION {
    if (!_upload) [self _initializeUpload];
    else [_upload removeAllObjects];
    FwiRelease(_raw);

    va_list parameters;
	va_start(parameters, parameter);
    [self _addMultipartParameter:parameter];

    while ((parameter = va_arg(parameters, id))) {
        [self _addMultipartParameter:parameter];
    }
	va_end(parameters);
}


@end


@implementation FwiRequest (FwiRaw)


- (void)setDataParameter:(id)parameter {
    /* Condition validation: Validate method type */
    if (!(_type == kMethodType_Post || _type == kMethodType_Patch || _type == kMethodType_Put)) return;

    /* Condition validation: Validate parameter type */
    if (!parameter || ![parameter isMemberOfClass:[FwiDataParam class]]) return;

    // Release form
    FwiRelease(_form);
    FwiRelease(_upload);

    // Keep new raw
    FwiRelease(_raw);
    _raw = FwiRetain(parameter);
}


@end