#import "FwiFormParameter.h"


@interface FwiFormParameter () {
}

@end


@implementation FwiFormParameter


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        self.key   = nil;
        self.value = nil;
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    self.key   = nil;
    self.value = nil;

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's override methods
- (BOOL)isEqual:(id)object {
	if (object && [object isKindOfClass:[FwiFormParameter class]]) {
        FwiFormParameter *other = (FwiFormParameter *)object;
        return ([_key isEqualToString:other.key] && [_value isEqualToString:other.value]);
	}
	return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@=%@", _key, [_value encodeHTML]];
}


#pragma mark - Class's public methods
- (NSComparisonResult)compare:(FwiFormParameter *)parameter {
    /* Condition validation */
    if (!parameter) return NSOrderedDescending;
    else return [_key compare:parameter.key];
}


#pragma mark - NSCoding's members
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self && aDecoder) {
        _key   = FwiRetain([aDecoder decodeObjectForKey:@"_key"]);
        _value = FwiRetain([aDecoder decodeObjectForKey:@"_value"]);
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (!aCoder) return;
    [aCoder encodeObject:_key forKey:@"_key"];
    [aCoder encodeObject:_value forKey:@"_value"];
}


@end


@implementation FwiFormParameter (FwiRequestParameterCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiFormParameter *)decode:(NSString *)info {
    /* Condition validation */
    if (!info || info.length == 0) return nil;

    /* Condition validation: Invalid format */
    NSRange range = [info rangeOfString:@"="];
    if (range.location == NSNotFound) return nil;

    __autoreleasing NSArray *tokens = [[info trim] componentsSeparatedByString:@"="];
    return [FwiFormParameter parameterWithKey:tokens[0] andValue:[tokens[1] decodeHTML]];
}
+ (__autoreleasing FwiFormParameter *)parameterWithKey:(NSString *)key andValue:(NSString *)value {
    /* Condition validation */
    if (!key || key.length == 0 || !value || value.length == 0) return nil;
    else return FwiAutoRelease([[FwiFormParameter alloc] initWithKey:key andValue:value]);
}


#pragma mark - Class's constructors
- (id)initWithKey:(NSString *)key andValue:(NSString *)value {
    self = [self init];
    if (self) {
        self.key = key;
        self.value = value;
    }
    return self;
}


@end