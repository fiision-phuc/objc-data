#import "FwiDataParameter.h"


@interface FwiDataParameter () {
}

@end


@implementation FwiDataParameter


@synthesize data=_data, contentType=_contentType;


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _data = nil;
        _contentType = nil;
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    FwiRelease(_data);
    FwiRelease(_contentType);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - NSCoding's members
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self && aDecoder) {
        _data = FwiRetain([aDecoder decodeObjectForKey:@"_data"]);
        _contentType = FwiRetain([aDecoder decodeObjectForKey:@"_contentType"]);
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (!aCoder) return;
    [aCoder encodeObject:_data forKey:@"_data"];
    [aCoder encodeObject:_contentType forKey:@"_contentType"];
}


@end


@implementation FwiDataParameter (FwiDataParameterCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiDataParameter *)parameterWithJson:(FwiJson *)json {
    /* Condition validation */
    if (!json) return nil;
    else return [FwiDataParameter parameterWithData:[json encode] contentType:@"application/json; charset=UTF-8"];
}
+ (__autoreleasing FwiDataParameter *)parameterWithString:(NSString *)string {
    /* Condition validation */
    if (!string || string.length == 0) return nil;
    else return [FwiDataParameter parameterWithData:[string toData] contentType:@"text/plain; charset=UTF-8"];
}
+ (__autoreleasing FwiDataParameter *)parameterWithData:(NSData *)data contentType:(NSString *)contentType {
    /* Condition validation */
    if (!data || data.length == 0 || !contentType || contentType.length == 0) return nil;
    return FwiAutoRelease([[FwiDataParameter alloc] initWithData:data contentType:contentType]);
}


#pragma mark - Class's constructors
- (id)initWithData:(NSData *)data contentType:(NSString *)contentType {
    self = [self init];
    if (self) {
        _data = FwiRetain(data);
        _contentType = FwiRetain(contentType);
    }
    return self;
}


@end