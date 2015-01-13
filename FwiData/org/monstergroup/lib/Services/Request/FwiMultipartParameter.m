#import "FwiMultipartParameter.h"


@interface FwiMultipartParameter () {
}

@end


@implementation FwiMultipartParameter


@synthesize name=_name, filename=_filename, data=_data, contentType=_contentType;


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _name = nil;
        _filename = nil;

        _data = nil;
        _contentType = nil;
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    FwiRelease(_name);
    FwiRelease(_filename);
    FwiRelease(_data);
    FwiRelease(_contentType);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's public methods
- (NSUInteger)hash {
    NSUInteger hash = 0;

    hash += [_name hash];
    hash += [_filename hash];
    hash += [_data hash];
    hash += [_contentType hash];

    return hash;
}

- (NSComparisonResult)compare:(FwiMultipartParameter *)parameter {
    /* Condition validation */
    if (!parameter) return NSOrderedDescending;

    __autoreleasing NSNumber *a = @([self hash]);
    __autoreleasing NSNumber *b = @([parameter hash]);
    return [a compare:b];
}


#pragma mark - NSCoding's members
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self && aDecoder) {
        _name        = FwiRetain([aDecoder decodeObjectForKey:@"_name"]);
        _filename    = FwiRetain([aDecoder decodeObjectForKey:@"_filename"]);
        _data        = FwiRetain([aDecoder decodeObjectForKey:@"_data"]);
        _contentType = FwiRetain([aDecoder decodeObjectForKey:@"_contentType"]);
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (!aCoder) return;
    [aCoder encodeObject:_name forKey:@"_name"];
    [aCoder encodeObject:_filename forKey:@"_filename"];
    [aCoder encodeObject:_data forKey:@"_data"];
    [aCoder encodeObject:_contentType forKey:@"_contentType"];
}


@end


@implementation FwiMultipartParameter (FwiMultipartParameterCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiMultipartParameter*)parameterWithName:(NSString *)name filename:(NSString *)filename data:(NSData *)data contentType:(NSString *)contentType {
    return FwiAutoRelease([[FwiMultipartParameter alloc] initWithName:name filename:filename data:data contentType:contentType]);
}


#pragma mark - Class's constructors
- (id)initWithName:(NSString *)name filename:(NSString *)filename data:(NSData *)data contentType:(NSString *)contentType {
    self = [self init];
    if (self) {
        _name = FwiRetain(name);
        _filename = FwiRetain(filename);
        _data = FwiRetain(data);
        _contentType = FwiRetain(contentType);
    }
    return self;
}


@end