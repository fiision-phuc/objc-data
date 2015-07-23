#import "FwiJson.h"
#import "FwiJson_Private.h"


static inline FwiJson* FwiJsonFromObject(id object) {
    /* Condition validation */
    if (!object) return [FwiJson null];

    if ([object isKindOfClass:[FwiJson class]]) {
        return object;
    }
    else if ([object isKindOfClass:[NSNull class]]) {
        return [FwiJson null];
    }
    else if ([object isKindOfClass:[NSData class]]) {
        return [FwiJson stringWithString:[(NSData *)object encodeBase64String]];
    }
    else if ([object isKindOfClass:[NSString class]]) {
        return [FwiJson stringWithString:(NSString *)object];
    }
    else if ([object isKindOfClass:[NSURL class]]) {
        return [FwiJson stringWithString:[(NSURL *)object absoluteString]];
    }
    else if ([object isKindOfClass:[NSDate class]]) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];

        [df setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [df setDateStyle:NSDateFormatterNoStyle];
        [df setTimeStyle:NSDateFormatterNoStyle];
        [df setDateFormat:@"yyyyMMddHHmmssSSS"];

        NSString *result = [df stringFromDate:(NSDate *)object];
        FwiRelease(df);

        return [FwiJson stringWithString:result];
    }
    else if ([object isKindOfClass:[NSNumber class]]) {
        if ([NSStringFromClass([object class]) isEqualToString:@"__NSCFBoolean"]) {
            return [FwiJson booleanWithBool:[(NSNumber *)object boolValue]];
        }
        else {
            return [FwiJson numberWithNumber:(NSNumber *)object];
        }
    }
    else if ([object isKindOfClass:[NSArray class]]) {
        return [FwiJson arrayWithArray:(NSArray *) object];
    }
    else if ([object isKindOfClass:[NSDictionary class]]) {
        return [FwiJson objectWithDictionary:(NSDictionary *)object];
    }
    else {
        NSLog(@"Could not find solution for class: %@", NSStringFromClass([object class]));
        return [FwiJson stringWithString:[object description]];
    }
}
static inline id FwiObjectFromJson(FwiJson *json) {
    switch ([json jsonType]) {
        case kJson_Boolean:
        case kJson_Number: {
            return [json getNumber];
        }
        case kJson_String: {
            return [json getString];
        }
        case kJson_Array: {
            __block NSMutableArray *a = FwiAutoRelease([[NSMutableArray alloc] initWithCapacity:[json count]]);
            [[json array] enumerateObjectsUsingBlock:^(FwiJson *item, NSUInteger idx, BOOL *stop) {
                [a addObject:FwiObjectFromJson(item)];
            }];
            return a;
        }
        case kJson_Object: {
            __block NSMutableDictionary *d = FwiAutoRelease([[NSMutableDictionary alloc] initWithCapacity:[json count]]);
            [[json dictionary] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
                d[key] = FwiObjectFromJson(value);
            }];
            return d;
        }
        case kJson_Null:
        default: {
            return [NSNull null];
        }
    }
}


@implementation FwiJson


@synthesize array=_array, dictionary=_objects;


+ (void)_array:(NSMutableArray *)array arg:(id)arg args:(va_list)args {
    if (!array || !arg || !args) return;
    
    [array addObject:FwiJsonFromObject(arg)];
    while ((arg = va_arg(args, id))) {
        [array addObject:FwiJsonFromObject(arg)];
    }
}
+ (void)_dictionary:(NSMutableDictionary *)dictionary arg:(id)arg args:(va_list)args {
	if (!dictionary || !arg || !args) return;
    
    __autoreleasing NSString *k = nil;
    if ([arg isKindOfClass:[NSString class]]) k = arg;
    else k = [arg description];
    
    BOOL isKey = YES;
    while ((arg = va_arg(args, id))) {
        if (isKey) {
            dictionary[k] = FwiJsonFromObject(arg);
            isKey = NO;
        }
        else {
            if ([arg isKindOfClass:[NSString class]]) k = arg;
            else k = [arg description];
            isKey = YES;
        }
    }
    
    if (isKey) dictionary[k] = [FwiJson null];
}


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _jsonType = kJson_Null;
		_number   = nil;
		_string   = nil;
		_array    = nil;
		_objects  = nil;
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    self.dictionary = nil;
    self.array = nil;

    FwiRelease(_number);
    FwiRelease(_string);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's override methods
- (NSString *)description {
    switch (_jsonType) {
        case kJson_String: {
            return _string;
        }
        case kJson_Boolean: {
            return [_number boolValue] == NO ? @"False" : @"True";
        }
        case kJson_Number: {
            return [_number description];
        }
		case kJson_Array:
		case kJson_Object: {
            __autoreleasing id object = FwiObjectFromJson(self);
            
            __autoreleasing NSError *error = nil;
            __autoreleasing NSData *data = [NSJSONSerialization dataWithJSONObject:object
                                                                           options:NSJSONWritingPrettyPrinted
                                                                             error:&error];
            
			if (!error) {
                __autoreleasing NSString *result = [data toString];
                return result;
            }
			else return @"";
		}
		case kJson_Null:
        default: {
            return @"Null";
        }
	}
}


#pragma mark - Class's properties
- (NSUInteger)count {
	switch (_jsonType) {
		case kJson_Array : {
            return [_array count];
        }
		case kJson_Object: {
            return [_objects count];
        }
		default: {
            return 0;
        }
	}
}


#pragma mark - Class's public methods
- (BOOL)isLike:(FwiJson *)json {
	if (!json) return NO;
    
	BOOL isLike = YES;
    switch ([json jsonType]) {
        case kJson_Array : {
            NSMutableArray *a = [json array];
            if (!a) isLike = NO;
            else {
                if ([a count] > 0) {
                    if ([_array count] == [a count]) {
                        __block BOOL like = YES;
                        [a enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                            __autoreleasing FwiJson *o = self->_array[idx];
                            if (o) {
                                if ([o jsonType] == [(FwiJson *)obj jsonType]) {
                                    if ([o jsonType] == kJson_Object || [o jsonType] == kJson_Array) {
                                        like &= [o isLike:obj];
                                        *stop = !like;
                                    }
                                }
                                else {
                                    *stop = YES;
                                    like = NO;
                                }
                            }
                            else {
                                *stop = YES;
                                like = NO;
                            }
                        }];
                        isLike = like;
                    }
                    else isLike = NO;
                }
            }
            break;
        }
        case kJson_Object: {
            NSDictionary *d = [json dictionary];
            if (!d) isLike = NO;
            else {
                if ([d count] > 0) {
                    if ([_objects count] == [d count]) {
                        __block BOOL like = YES;
                        [d enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                            __autoreleasing FwiJson *o = self->_objects[key];
                            if (o) {
                                if ([o jsonType] == [(FwiJson *)obj jsonType]) {
                                    if ([o jsonType] == kJson_Object || [o jsonType] == kJson_Array) {
                                        like &= [o isLike:obj];
                                        *stop = !like;
                                    }
                                }
                                else {
                                    *stop = YES;
                                    like = NO;
                                }
                            }
                            else {
                                *stop = YES;
                                like = NO;
                            }
                        }];
                        isLike = like;
                    }
                    else isLike = NO;
                }
            }
            break;
        }
            
        default:
            isLike = ([json jsonType] == _jsonType);
            break;
    }
	
    return isLike;
}


#pragma mark - NSCoding's members
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self && aDecoder) {
        _jsonType = [aDecoder decodeIntegerForKey:@"_jsonType"];
        
        __autoreleasing NSNumber *numberValue = [aDecoder decodeObjectForKey:@"_numberValue"];
        if (numberValue) _number = FwiRetain(numberValue);

        __autoreleasing NSString *stringValue = FwiRetain([aDecoder decodeObjectForKey:@"_stringValue"]);
        if (stringValue) _string = FwiRetain(stringValue);

        __autoreleasing NSArray *array = [aDecoder decodeObjectForKey:@"_array"];
        if (array) _array = FwiRetain([array toMutableArray]);

        __autoreleasing NSDictionary *objects = [aDecoder decodeObjectForKey:@"_objects"];
        if (objects) _objects = FwiRetain([objects toMutableDictionary]);
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (!aCoder) return;
    
    [aCoder encodeInteger:_jsonType forKey:@"_jsonType"];
    
    [aCoder encodeObject:_number forKey:@"_numberValue"];
    [aCoder encodeObject:_string forKey:@"_stringValue"];
    
    [aCoder encodeObject:_array forKey:@"_array"];
    [aCoder encodeObject:_objects forKey:@"_objects"];
}


@end


@implementation FwiJson (FwiJsonCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiJson *)null {
    __autoreleasing FwiJson *o = FwiAutoRelease([[FwiJson alloc] initWithJsonType:kJson_Null]);
	return o;
}

+ (__autoreleasing FwiJson *)boolean {
	return [FwiJson booleanWithBool:NO];
}
+ (__autoreleasing FwiJson *)booleanWithBool:(BOOL)value {
    __autoreleasing FwiJson * o = FwiAutoRelease([[FwiJson alloc] initWithJsonType:kJson_Boolean]);
	[o setNumber:@(value)];
	return o;
}

+ (__autoreleasing FwiJson *)number {
	return [FwiJson numberWithNumber:@0];
}
+ (__autoreleasing FwiJson *)numberWithInteger:(NSInteger)value {
	return [FwiJson numberWithNumber:@(value)];
}
+ (__autoreleasing FwiJson *)numberWithUnsignedInteger:(NSUInteger)value {
	return [FwiJson numberWithNumber:@(value)];
}
+ (__autoreleasing FwiJson *)numberWithLongLong:(long long)value {
	return [FwiJson numberWithNumber:@(value)];
}
+ (__autoreleasing FwiJson *)numberWithUnsignedLongLong:(unsigned long long)value {
	return [FwiJson numberWithNumber:@(value)];
}
+ (__autoreleasing FwiJson *)numberWithDouble:(double)value {
	return [FwiJson numberWithNumber:@(value)];
}
+ (__autoreleasing FwiJson *)numberWithDecimal:(NSDecimal)value {
	return [FwiJson numberWithDecimalNumber:[NSDecimalNumber decimalNumberWithDecimal:value]];
}
+ (__autoreleasing FwiJson *)numberWithNumber:(NSNumber *)value {
    __autoreleasing FwiJson *o = FwiAutoRelease([[FwiJson alloc] initWithJsonType:kJson_Number]);
	[o setNumber:value];
	return o;
}
+ (__autoreleasing FwiJson *)numberWithDecimalNumber:(NSDecimalNumber *)value {
    return [FwiJson numberWithNumber:value];
}

+ (__autoreleasing FwiJson *)string {
	return [FwiJson stringWithString:@""];
}
+ (__autoreleasing FwiJson *)stringWithData:(NSData *)data {
    return [FwiJson stringWithString:[data toString]];
}
+ (__autoreleasing FwiJson *)stringWithString:(NSString *)string {
    __autoreleasing FwiJson *o = FwiAutoRelease([[FwiJson alloc] initWithJsonType:kJson_String]);
	[o setString:string];
	return o;
}

+ (__autoreleasing FwiJson *)array {
    __autoreleasing FwiJson *o = FwiAutoRelease([[FwiJson alloc] initWithJsonType:kJson_Array]);
	return o;
}
+ (__autoreleasing FwiJson *)arrayWithArray:(NSArray *)array {
    __block FwiJson *o = [FwiJson array];

    [array enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL *stop) {
        [o addJson:FwiJsonFromObject(value)];
    }];
	return o;
}

+ (__autoreleasing FwiJson *)object {
    __autoreleasing FwiJson *o = FwiAutoRelease([[FwiJson alloc] initWithJsonType:kJson_Object]);
	return o;
}
+ (__autoreleasing FwiJson *)objectWithDictionary:(NSDictionary *)dictionary {
    __block FwiJson *o = [FwiJson object];

    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        [o addKey:key andJson:FwiJsonFromObject(value)];
    }];
	return o;
}


@end


@implementation FwiJson (FwiJsonCreation_Private)


#pragma mark - Class's constructors
- (id)initWithJsonType:(FwiJsonValue)jsonType {
	self = [self init];
	if (self) {
		switch (jsonType) {
			case kJson_Boolean: {
				_number = FwiRetain(@NO);
                _jsonType = jsonType;
				break;
			}
			case kJson_Number: {
				_number = FwiRetain(@0);
                _jsonType = jsonType;
				break;
			}
			case kJson_String: {
				_string = @"";
                _jsonType = jsonType;
				break;
			}
			case kJson_Array: {
				_array = [[NSMutableArray alloc] init];
                _jsonType = jsonType;
				break;
			}
			case kJson_Object: {
				_objects = [[NSMutableDictionary alloc] init];
                _jsonType = jsonType;
				break;
			}
			default:
				// Do nothing
				break;
		}
	}
	return self;
}


@end


@implementation FwiJson (FwiJsonCollection)


- (__autoreleasing FwiJson *)jsonAtIndex:(NSUInteger)index {
	switch (_jsonType) {
		case kJson_Array: {
			if (index < [_array count]) return _array[index];
			else return nil;
		}
		case kJson_Object: {
			if (index < [_objects count]) {
                __autoreleasing NSArray *jsons = [_objects allValues];
                return jsons[index];
			}
			else return nil;
		}
		default: {
            return nil;
        }
	}
}
- (__autoreleasing FwiJson *)jsonWithPath:(NSString *)path {
    /* Condition validation */
    if (!path || [path length] <= 0) return nil;
    
    __autoreleasing FwiJson *o = nil;
	switch (_jsonType) {
		case kJson_Array: {
			o = [_array _objectWithPath:path];
			break;
		}
		case kJson_Object: {
			o = [_objects _objectWithPath:path];
			break;
		}
		default:
			break;
	}
	return o;
}

- (void)setJson:(id)json {
    if (_jsonType != kJson_Array || !json) return;
	[_array removeAllObjects];
    
    [_array addObject:FwiJsonFromObject(json)];
}
- (void)addJson:(id)json {
    if (_jsonType != kJson_Array || !json) return;
    [_array addObject:FwiJsonFromObject(json)];
}
- (void)setJsons:(id)arg, ... NS_REQUIRES_NIL_TERMINATION {
	if (_jsonType != kJson_Array || !arg) return;
	[_array removeAllObjects];
	va_list args;
    
	va_start(args, arg);
    [FwiJson _array:_array arg:arg args:args];
	va_end(args);
}
- (void)addJsons:(id)arg, ... NS_REQUIRES_NIL_TERMINATION {
	if (_jsonType != kJson_Array || !arg) return;
	va_list args;
    
	va_start(args, arg);
    [FwiJson _array:_array arg:arg args:args];
	va_end(args);
}
- (void)replaceJson:(FwiJson *)json atIndex:(NSUInteger)index {
    if (_jsonType != kJson_Array || !json || index >= _array.count) return;
    _array[index] = json;
}
- (void)removeJsons:(id)arg, ... NS_REQUIRES_NIL_TERMINATION {
	if (_jsonType != kJson_Array || !arg) return;
    [_array removeObject:arg];
    va_list args;
    
    va_start(args, arg);
    while ((arg = va_arg(args, id))) {
        [_array removeObject:arg];
    }
    va_end(args);
}
- (void)jsonWithPath:(NSString *)path setJsons:(id)arg, ... NS_REQUIRES_NIL_TERMINATION {
	if (_jsonType != kJson_Array || !path || [path length] <= 0 || !arg) return;
    
    __autoreleasing FwiJson *o = [self jsonWithPath:path];
    if ([o jsonType] != kJson_Array) return;
    
    [[o array] removeAllObjects];
    va_list args;
    
    va_start(args, arg);
    [FwiJson _array:[o array] arg:arg args:args];
    va_end(args);
}
- (void)jsonWithPath:(NSString *)path addJsons:(id)arg, ... NS_REQUIRES_NIL_TERMINATION {
	if (!path || [path length] <= 0 || !arg) return;
    
    __autoreleasing FwiJson *o = [self jsonWithPath:path];
    if ([o jsonType] != kJson_Array) return;
    
    va_list args;
    
    va_start(args, arg);
    [FwiJson _array:[o array] arg:arg args:args];
    va_end(args);
}
- (void)jsonWithPath:(NSString *)path removeJsons:(id)arg, ... NS_REQUIRES_NIL_TERMINATION {
	if (!path || [path length] <= 0 || !arg) return;
    
    __autoreleasing FwiJson *o = [self jsonWithPath:path];
    if ([o jsonType] != kJson_Array) return;
    
    [[o array] removeObject:arg];
    va_list args;
    
    va_start(args, arg);
    while ((arg = va_arg(args, id))) {
        [[o array] removeObject:arg];
    }
    va_end(args);
}

- (void)setKey:(id)key andJson:(id)json {
    if (_jsonType != kJson_Object) return;
    [_objects removeAllObjects];
    
    _objects[key] = FwiJsonFromObject(json);
}
- (void)addKey:(id)key andJson:(id)json {
    if (_jsonType != kJson_Object) return;
    _objects[key] = FwiJsonFromObject(json);
}
- (void)setKeysAndJsons:(id)arg, ... NS_REQUIRES_NIL_TERMINATION {
	if (_jsonType != kJson_Object) return;
	[_objects removeAllObjects];
	va_list args;
    
	va_start(args, arg);
    [FwiJson _dictionary:_objects arg:arg args:args];
	va_end(args);
}
- (void)addKeysAndJsons:(id)arg, ... NS_REQUIRES_NIL_TERMINATION {
	if (_jsonType != kJson_Object) return;
	va_list args;
    
	va_start(args, arg);
    [FwiJson _dictionary:_objects arg:arg args:args];
	va_end(args);
}
- (void)removeJsonsForKeys:(id)arg, ... NS_REQUIRES_NIL_TERMINATION {
	if (_jsonType != kJson_Object) return;
    [_objects removeObjectForKey:arg];
    va_list args;
    
    va_start(args, arg);
    while ((arg = va_arg(args, id))) {
        [_objects removeObjectForKey:arg];
    }
    va_end(args);
}
- (void)jsonWithPath:(NSString *)path setKeysAndJsons:(id)arg, ... NS_REQUIRES_NIL_TERMINATION {
    if (_jsonType != kJson_Object || !path || [path length] <= 0 || !arg) return;
    
    __autoreleasing FwiJson *o = [self jsonWithPath:path];
    if ([o jsonType] != kJson_Object) return;
    
    [[o dictionary] removeAllObjects];
    va_list args;
    
    va_start(args, arg);
    [FwiJson _dictionary:[o dictionary] arg:arg args:args];
    va_end(args);
}
- (void)jsonWithPath:(NSString *)path addKeysAndJsons:(id)arg, ... NS_REQUIRES_NIL_TERMINATION {
	if (_jsonType != kJson_Object || !path || [path length] <= 0 || !arg) return;
    
    __autoreleasing FwiJson *o = [self jsonWithPath:path];
    if ([o jsonType] != kJson_Object) return;
    
    va_list args;
    
    va_start(args, arg);
    [FwiJson _dictionary:[o dictionary] arg:arg args:args];
    va_end(args);
}
- (void)jsonWithPath:(NSString *)path removeJsonsForKeys:(id)arg, ... NS_REQUIRES_NIL_TERMINATION {
	if (_jsonType != kJson_Object || !path || [path length] <= 0 || !arg) return;
    
    __autoreleasing FwiJson *o = [self jsonWithPath:path];
    if ([o jsonType] != kJson_Object) return;
    
    __autoreleasing NSMutableDictionary *d = [o dictionary];
    [d removeObjectForKey:arg];
    va_list args;
    
    va_start(args, arg);
    while ((arg = va_arg(args, id))) {
        [d removeObjectForKey:arg];
    }
    va_end(args);
}


@end


@implementation FwiJson (FwiJsonPrimitive)


- (BOOL)getBoolean {
    /* Condition validation */
	if (!(_jsonType == kJson_Boolean || _jsonType == kJson_Number)) return NO;
	return [_number boolValue];
}
- (void)setBoolean:(BOOL)value {
    /* Condition validation */
	if (!(_jsonType != kJson_Boolean || _jsonType == kJson_Number)) return;
    FwiRelease(_number);
	_number = FwiRetain(@(value));
}

- (__autoreleasing NSNumber *)getNumber {
    /* Condition validation */
    if (!(_jsonType == kJson_Boolean || _jsonType == kJson_Number)) return nil;
    else return _number;
}
- (void)setNumber:(NSNumber *)value {
    /* Condition validation */
	if (!(_jsonType == kJson_Boolean || _jsonType == kJson_Number)) return;
	if (value) {
        FwiRelease(_number);
        _number = FwiRetain(value);
    }
}

- (__autoreleasing NSString *)getString {
	/* Condition validation */
    if (_jsonType != kJson_String) return nil;
	return _string;
}
- (void)setString:(NSString *)value {
    /* Condition validation */
	if (_jsonType != kJson_String || !value || value.length == 0) return;
    FwiRelease(_string);
    _string = FwiRetain([value trim]);
}


@end


@implementation FwiJson (FwiJsonEncode)


- (__autoreleasing NSData *)encode {
    __autoreleasing id object = FwiObjectFromJson(self);

    __autoreleasing NSError *error = nil;
    __autoreleasing NSData *data = [NSJSONSerialization dataWithJSONObject:object
                                                                   options:kNilOptions
                                                                     error:&error];

    if (!error) {
        return data;
    }
    else {
        return nil;
    }
}
- (__autoreleasing NSString *)encodeJson {
    return [[self encode] toString];
}

- (__autoreleasing NSData *)encodeBase64Data {
    return [[self encode] encodeBase64Data];
}
- (__autoreleasing NSString *)encodeBase64String {
	return [[[self encode] encodeBase64Data] toString];
}


@end


@implementation FwiJson (FwiJsonEnumeration)


- (void)enumerateObjectsUsingBlock:(void (^)(FwiJson *json, NSUInteger, BOOL *))block {
    /* Condition validation */
    if (_jsonType != kJson_Array) return;
    [_array enumerateObjectsUsingBlock:block];
}

- (void)enumerateKeysAndObjectsUsingBlock:(void(^)(NSString *key, FwiJson *json, BOOL *stop))block {
    /* Condition validation */
    if (_jsonType != kJson_Object) return;
    [_objects enumerateKeysAndObjectsUsingBlock:block];
}


@end
