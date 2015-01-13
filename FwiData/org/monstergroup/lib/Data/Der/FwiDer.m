#import <math.h>
#import "FwiDer.h"
#import "FwiDer_Private.h"


@implementation FwiDer


@synthesize identifier=_identifier, derClass=_derClass, derValue=_derValue;
@synthesize internalContent=_content;


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _identifier = 0x00;
        _derClass   = 0x00;
        _derValue   = 0x00;
        _content    = nil;
        _children   = nil;
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    FwiRelease(_content);
    FwiRelease(_children);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's override methods
- (NSString *)description {
    return [self _objectDescription:self spaceIndent:@""];
}

- (BOOL)isEqual:(id)object {
    /* Condition validation */
    if (!object || ![object isMemberOfClass:[FwiDer class]]) return NO;
    
    __autoreleasing NSData *d1 = [(FwiDer *)object encode];
    __autoreleasing NSData *d2 = [self encode];
    
    if (!d1 || !d2) return NO;
    else return [d1 isEqualToData:d2];
}


#pragma mark - Class's properties
- (BOOL)isStructure {
    return (((_identifier & 0x20) >> 5) == 1);
}
- (NSUInteger)count {
    if (![self isStructure]) return 0;
    return (_children ? [_children count] : 0);
}
- (NSUInteger)length {
    if ([self isStructure]) {
        NSUInteger total = 0;
        
        if (_children && _children.count > 0) {
            for (NSUInteger i = 0; i < _children.count; i++) {
                NSUInteger length = [(FwiDer *)_children[i] length];
                if (length > 0x7f) {
                    if (length < 0x100) {
                        total += 3;
                    }
                    else if (length < 0x10000) {
                        total += 4;
                    }
                    else if (length < 0x1000000) {
                        total += 5;
                    }
                    else {
                        total += 6;
                    }
                }
                else {
                    total += 2;
                }
                total += length;
            }
        }
        return total;
    }
    else {
        return _content ? _content.length : 0;
    }
}


#pragma mark - Class's public methods
- (BOOL)isLike:(FwiDer *)der {
    /* Condition validation */
    if (!der) return NO;
    
    // First validator run
    BOOL isLike = (_identifier == [der identifier]);
    if (!isLike) return NO;
    
    if ([der isStructure] && [der count] > 0) {
        if ([self count] == [der count]) {
            for (NSUInteger i = 0; i < [der count]; i++) {
                _weak FwiDer *o1 = [self derAtIndex:i];
                _weak FwiDer *o2 = [der derAtIndex:i];
                
                isLike &= [o1 isLike:o2];
                if (!isLike) break;
            }
        }
        else {
            isLike = NO;
        }
    }
    return isLike;
}

- (__autoreleasing NSData *)getContent {
    if ([self isStructure]) {
        if (_children) {
            __autoreleasing NSMutableData *content = [NSMutableData dataWithCapacity:self.length];
            for (FwiDer *der in _children) [content appendData:[der encode]];
            
            return content;
        }
    }
    else if (_content) {
        if (self.derValue != kFwiDerValue_BitString) {
            return _content;
        }
        else {
            const uint8_t *current = _content.bytes;
            return [NSData dataWithBytes:&current[1] length:(_content.length - 1)];
        }
    }
    return nil;
}
- (void)setContent:(NSData *)content {
    /* Condition validation */
    if (_derValue == kFwiDerValue_Null) return;
    
    /* Condition validation: Validate content */
    if (!content || content.length == 0) return;
    
    /* Condition validation */
    if ([self isStructure])  return;
    
    // Sepecial case for boolean as it is only accept 1 byte length
    if (_derValue == kFwiDerValue_Boolean) {
        const uint8_t *bytes = content.bytes;
        
        if (!_content) {
            uint8_t b = (bytes[0] == 0x00 ? 0x00 : 0xff);
            _content  = [[NSData alloc] initWithBytes:&b length:1];
        }
        else {
            uint8_t *current = (void *)_content.bytes;
            current[0] = (bytes[0] == 0x00 ? 0x00 : 0xff);
        }
    }
    else {
        _content = FwiRetain(content);
    }
}


#pragma mark - Class's private methods
- (__autoreleasing NSString *)_objectDescription:(FwiDer *)der spaceIndent:(NSString *)spaceIndent {
    if (der.derClass == kFwiDerClass_Universal) {
        if ([der isStructure]) {
            __autoreleasing NSMutableString *string = [NSMutableString stringWithCapacity:100];
            [string appendFormat:@"%@%@->%@[%zi] ::= Body {\n", spaceIndent, FwiGetDerClassDescription(der.derClass), FwiGetDerValueDescription(der.derValue), der.length];
            
            for (NSUInteger i = 0; i < der.count; i++) {
                __autoreleasing FwiDer *record = [der derAtIndex:i];
                
                [string appendString:[der _objectDescription:record spaceIndent:[NSString stringWithFormat:@"%@| ", spaceIndent]]];
                [string appendString:@"\n"];
            }
            [string appendString:spaceIndent];
            [string appendString:@"}"];
            return string;
        }
        else {
            __autoreleasing NSString *text = ([der derValue] == kFwiDerValue_ObjectIdentifier ? [der getObjectIdentifier] : [der getString]);
            __autoreleasing NSString *description = nil;
            if (text && text.length > 0) {
                if ([der derValue] != kFwiDerValue_BitString) {
                    description = [NSString stringWithFormat:@"%@%@->%@[%zi] ", spaceIndent, FwiGetDerClassDescription(der.derClass), FwiGetDerValueDescription(der.derValue), der.length];
                }
                else {
                    const uint8_t *bytes = [[der internalContent] bytes];
                    description = [NSString stringWithFormat:@"%@%@->%@[%zi, %zi] ", spaceIndent, FwiGetDerClassDescription(der.derClass), FwiGetDerValueDescription(der.derValue), der.length, bytes[0]];
                }
                description = [NSString stringWithFormat:@"%@%@", description, text];
            }
            else {
                if ([der derValue] != kFwiDerValue_BitString) {
                    description = [NSString stringWithFormat:@"%@%@->%@[%zi] ", spaceIndent, FwiGetDerClassDescription(der.derClass), FwiGetDerValueDescription(der.derValue), der.length];
                }
                else {
                    description = [NSString stringWithFormat:@"%@%@->%@[%zi, 0] ", spaceIndent, FwiGetDerClassDescription(der.derClass), FwiGetDerValueDescription(der.derValue), der.length];
                }
            }
            return description;
        }
    }
    else {
        if ([der isStructure]) {
            __autoreleasing NSMutableString *string = [NSMutableString stringWithCapacity:[der length]];
            [string appendFormat:@"%@%@->Tagged(%zi)[%zi] ::= Body {\n", spaceIndent, FwiGetDerClassDescription(der.derClass), (der.identifier & 0x1f), der.length];
            
            for (NSUInteger i = 0; i < der.count; i++) {
                __autoreleasing FwiDer *record = [der derAtIndex:i];
                [string appendString:[der _objectDescription:record spaceIndent:[NSString stringWithFormat:@"%@| ", spaceIndent]]];
                [string appendString:@"\n"];
            }
            [string appendString:spaceIndent];
            [string appendString:@"}"];
            return string;
        }
        else {
            return [NSString stringWithFormat:@"%@%@->Tagged[%zi][%zi] %@", spaceIndent, FwiGetDerClassDescription(der.derClass), (der.identifier & 0x1f), der.length, [der getString]];
        }
    }
    return nil;
}


#pragma mark - Class's notification handlers


#pragma mark - NSCoding's members
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self && aDecoder) {
        _identifier = [[aDecoder decodeObjectForKey:@"_identifier"] unsignedIntegerValue];
        _derClass   = [[aDecoder decodeObjectForKey:@"_derClass"] unsignedIntegerValue];
        _derValue   = [[aDecoder decodeObjectForKey:@"_derValue"] unsignedIntegerValue];
        _content    = [aDecoder decodeObjectForKey:@"_content"];

        NSArray *children = [aDecoder decodeObjectForKey:@"_children"];
        if (children) _children = FwiRetain([children toMutableArray]);
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (!aCoder) return;

    [aCoder encodeObject:@(_identifier) forKey:@"_identifier"];
    [aCoder encodeObject:@(_derClass) forKey:@"_derClass"];
    [aCoder encodeObject:@(_derValue) forKey:@"_derValue"];
    if (_children) [aCoder encodeObject:_children forKey:@"_children"];
    if (_content) [aCoder encodeObject:_content forKey:@"_content"];
}


@end




@implementation FwiDer (FwiDerCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiDer *)null {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_Null)];
    return o;
}

+ (__autoreleasing FwiDer *)boolean {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_Boolean)];
    return o;
}
+ (__autoreleasing FwiDer *)booleanWithValue:(BOOL)value {
    __autoreleasing FwiDer *o = [FwiDer boolean];
    [o setBoolean:value];
    return o;
}

+ (__autoreleasing FwiDer *)integer {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_Integer)];
    return o;
}
+ (__autoreleasing FwiDer *)integerWithInt:(NSInteger)value {
    __autoreleasing FwiDer *o = [FwiDer integer];
    [o setInt:value];
    return o;
}
+ (__autoreleasing FwiDer *)integerWithData:(NSData *)value {
    __autoreleasing FwiDer *o = [FwiDer integer];
    
    if (value && value.length > 0) {
        [o setBigInt:[FwiBigInt bigIntWithData:value shouldReverse:YES]];
    }
    return o;
}
+ (__autoreleasing FwiDer *)integerWithBigInt:(FwiBigInt *)value {
    __autoreleasing FwiDer *o = [FwiDer integer];
    [o setBigInt:value];
    return o;
}

+ (__autoreleasing FwiDer *)bitString {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_BitString)];
    return o;
}
+ (__autoreleasing FwiDer *)bitStringWithData:(NSData *)input {
    __autoreleasing FwiDer *o = [FwiDer bitString];
    [o setBitStringWithData:input];
    return o;
}
+ (__autoreleasing FwiDer *)bitStringWithData:(NSData *)input padding:(NSUInteger)padding {
    __autoreleasing FwiDer *o = [FwiDer bitString];
    [o setBitStringWithData:input padding:padding];
    return o;
}

+ (__autoreleasing FwiDer *)octetString {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_OctetString)];
    return o;
}
+ (__autoreleasing FwiDer *)octetStringWithData:(NSData *)input {
    __autoreleasing FwiDer *o = [FwiDer octetString];
    [o setOctetStringWithData:input];
    return o;
}

+ (__autoreleasing FwiDer *)enumerated {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_Enumerated)];
    return o;
}
+ (__autoreleasing FwiDer *)enumeratedWithInt:(NSInteger)value {
    __autoreleasing FwiDer *o = [FwiDer enumerated];
    [o setInt:value];
    return o;
}
+ (__autoreleasing FwiDer *)enumeratedWithData:(NSData *)value {
    __autoreleasing FwiDer *o = [FwiDer enumerated];
    
    if (value && value.length > 0) {
        [o setBigInt:[FwiBigInt bigIntWithData:value shouldReverse:YES]];
    }
    return o;
}
+ (__autoreleasing FwiDer *)enumeratedWithBigInt:(FwiBigInt *)value {
    __autoreleasing FwiDer *o = [FwiDer enumerated];
    [o setBigInt:value];
    return o;
}

+ (__autoreleasing FwiDer *)utf8String {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_Utf8String)];
    return o;
}
+ (__autoreleasing FwiDer *)utf8StringWithData:(NSData *)input {
    __autoreleasing FwiDer *o = [FwiDer utf8String];
    [o setStringWithData:input];
    return o;
}
+ (__autoreleasing FwiDer *)utf8StringWithString:(NSString *)input {
    __autoreleasing FwiDer *o = [FwiDer utf8String];
    [o setStringWithString:input];
    return o;
}

+ (__autoreleasing FwiDer *)numericString {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_NumericString)];
    return o;
}
+ (__autoreleasing FwiDer *)numericStringWithData:(NSData *)input {
    __autoreleasing FwiDer *o = [FwiDer numericString];
    [o setStringWithData:input];
    return o;
}
+ (__autoreleasing FwiDer *)numericStringWithString:(NSString *)input {
    __autoreleasing FwiDer *o = [FwiDer numericString];
    [o setStringWithString:input];
    return o;
}

+ (__autoreleasing FwiDer *)printableString {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_PrintableString)];
    return o;
}
+ (__autoreleasing FwiDer *)printableStringWithData:(NSData *)input {
    __autoreleasing FwiDer *o = [FwiDer printableString];
    [o setStringWithData:input];
    return o;
}
+ (__autoreleasing FwiDer *)printableStringWithString:(NSString *)input {
    __autoreleasing FwiDer *o = [FwiDer printableString];
    [o setStringWithString:input];
    return o;
}

+ (__autoreleasing FwiDer *)t61String {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_T61String)];
    return o;
}
+ (__autoreleasing FwiDer *)t61StringWithData:(NSData *)input {
    __autoreleasing FwiDer *o = [FwiDer t61String];
    [o setStringWithData:input];
    return o;
}
+ (__autoreleasing FwiDer *)t61StringWithString:(NSString *)input {
    __autoreleasing FwiDer *o = [FwiDer t61String];
    [o setStringWithString:input];
    return o;
}

+ (__autoreleasing FwiDer *)ia5String {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_Ia5String)];
    return o;
}
+ (__autoreleasing FwiDer *)ia5StringWithData:(NSData *)input {
    __autoreleasing FwiDer *o = [FwiDer ia5String];
    [o setStringWithData:input];
    return o;
}
+ (__autoreleasing FwiDer *)ia5StringWithString:(NSString *)input {
    __autoreleasing FwiDer *o = [FwiDer ia5String];
    [o setStringWithString:input];
    return o;
}

+ (__autoreleasing FwiDer *)graphicString {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_GraphicString)];
    return o;
}
+ (__autoreleasing FwiDer *)graphicStringWithData:(NSData *)input {
    __autoreleasing FwiDer *o = [FwiDer graphicString];
    [o setStringWithData:input];
    return o;
}
+ (__autoreleasing FwiDer *)graphicStringWithString:(NSString *)input {
    __autoreleasing FwiDer *o = [FwiDer graphicString];
    [o setStringWithString:input];
    return o;
}

+ (__autoreleasing FwiDer *)visibleString {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_VisibleString)];
    return o;
}
+ (__autoreleasing FwiDer *)visibleStringWithData:(NSData *)input {
    __autoreleasing FwiDer *o = [FwiDer visibleString];
    [o setStringWithData:input];
    return o;
}
+ (__autoreleasing FwiDer *)visibleStringWithString:(NSString *)input {
    __autoreleasing FwiDer *o = [FwiDer visibleString];
    [o setStringWithString:input];
    return o;
}

+ (__autoreleasing FwiDer *)generalString {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_GeneralString)];
    return o;
}
+ (__autoreleasing FwiDer *)generalStringWithData:(NSData *)input {
    __autoreleasing FwiDer *o = [FwiDer generalString];
    [o setStringWithData:input];
    return o;
}
+ (__autoreleasing FwiDer *)generalStringWithString:(NSString *)input {
    __autoreleasing FwiDer *o = [FwiDer generalString];
    [o setStringWithString:input];
    return o;
}

+ (__autoreleasing FwiDer *)universalString {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_UniversalString)];
    return o;
}
+ (__autoreleasing FwiDer *)universalStringWithData:(NSData *)input {
    __autoreleasing FwiDer *o = [FwiDer universalString];
    [o setStringWithData:input];
    return o;
}
+ (__autoreleasing FwiDer *)universalStringWithString:(NSString *)input {
    __autoreleasing FwiDer *o = [FwiDer universalString];
    [o setStringWithString:input];
    return o;
}

+ (__autoreleasing FwiDer *)bmpString {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_BmpString)];
    return o;
}
+ (__autoreleasing FwiDer *)bmpStringWithData:(NSData *)input {
    __autoreleasing FwiDer *o = [FwiDer bmpString];
    [o setStringWithData:input];
    return o;
}
+ (__autoreleasing FwiDer *)bmpStringWithString:(NSString *)input {
    __autoreleasing FwiDer *o = [FwiDer bmpString];
    [o setStringWithString:input];
    return o;
}

+ (__autoreleasing FwiDer *)objectIdentifier {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_ObjectIdentifier)];
    return o;
}
+ (__autoreleasing FwiDer *)objectIdentifierWithOIDString:(NSString *)oidString {
    __autoreleasing FwiDer *o = [FwiDer objectIdentifier];
    [o setObjectIdentifier:oidString];
    return o;
}

+ (__autoreleasing FwiDer *)utcTime {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_UtcTime)];
    [o setTime:[NSDate date]];
    return o;
}
+ (__autoreleasing FwiDer *)utcTimeWithDate:(NSDate *)time {
    __autoreleasing FwiDer *o = [FwiDer utcTime];
    [o setTime:time];
    return o;
}

+ (__autoreleasing FwiDer *)generalizedTime {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | kFwiDerValue_GeneralizedTime)];
    [o setTime:[NSDate date]];
    return o;
}
+ (__autoreleasing FwiDer *)generalizedTimeWithDate:(NSDate *)time {
    __autoreleasing FwiDer *o = [FwiDer generalString];
    [o setTime:time];
    return o;
}


+ (__autoreleasing FwiDer *)bitStringWithDer:(FwiDer *)der {
    __autoreleasing FwiDer *o = [FwiDer bitString];
    [o setBitStringWithDer:der];
    return o;
}
+ (__autoreleasing FwiDer *)bitStringWithDers:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION {
    __autoreleasing FwiDer *o = [FwiDer bitString];
    
    if (der) {
        __autoreleasing NSMutableArray *array = [NSMutableArray arrayWithObjects:der, nil];
        
        va_list args;
        va_start(args, der);
        while ((der = va_arg(args, id))) {
            if ([der isMemberOfClass:[FwiDer class]]) [array addObject:der];
        }
        va_end(args);
        [o setBitStringWithDer:[FwiDer sequenceWithArray:array]];
    }
    return o;
}
+ (__autoreleasing FwiDer *)bitStringWithArray:(NSArray *)array {
    __autoreleasing FwiDer *o = [FwiDer bitString];
    
    [o setBitStringWithDer:[FwiDer sequenceWithArray:array]];
    return o;
}

+ (__autoreleasing FwiDer *)octetStringWithDer:(FwiDer *)der {
    __autoreleasing FwiDer *o = [FwiDer octetString];
    [o setOctetStringWithDer:der];
    return o;
}
+ (__autoreleasing FwiDer *)octetStringWithDers:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION {
    __autoreleasing FwiDer *o = [FwiDer octetString];
    
    if (der) {
        __autoreleasing NSMutableArray *array = [NSMutableArray arrayWithObjects:der, nil];
        
        va_list args;
        va_start(args, der);
        while ((der = va_arg(args, id))) {
            if ([der isMemberOfClass:[FwiDer class]]) [array addObject:der];
        }
        va_end(args);
        [o setOctetStringWithDer:[FwiDer sequenceWithArray:array]];
    }
    return o;
}
+ (__autoreleasing FwiDer *)octetStringWithArray:(NSArray *)array {
    __autoreleasing FwiDer *o = [FwiDer octetString];
    
    [o setOctetStringWithDer:[FwiDer sequenceWithArray:array]];
    return o;
}

+ (__autoreleasing FwiDer *)sequence {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | 0x20 | kFwiDerValue_Sequence)];
    return o;
}
+ (__autoreleasing FwiDer *)sequence:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION {
    __autoreleasing FwiDer *o = [FwiDer sequence];
    
    if (der) {
        __autoreleasing NSMutableArray *array = [NSMutableArray arrayWithObjects:der, nil];
        
        va_list args;
        va_start(args, der);
        while ((der = va_arg(args, id))) {
            if ([der isMemberOfClass:[FwiDer class]]) [array addObject:der];
        }
        va_end(args);
        [o setDersWithArray:array];
    }
    return o;
}
+ (__autoreleasing FwiDer *)sequenceWithArray:(NSArray *)array {
    __autoreleasing FwiDer *o = [FwiDer sequence];
    [o setDersWithArray:array];
    return o;
}

+ (__autoreleasing FwiDer *)set {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:(kFwiDerClass_Universal | 0x20 | kFwiDerValue_Set)];
    return o;
}
+ (__autoreleasing FwiDer *)set:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION {
    __autoreleasing FwiDer *o = [FwiDer set];
    
    if (der) {
        __autoreleasing NSMutableArray *array = [NSMutableArray arrayWithObjects:der, nil];
        
        va_list args;
        va_start(args, der);
        while ((der = va_arg(args, id))) {
            if ([der isMemberOfClass:[FwiDer class]]) [array addObject:der];
        }
        va_end(args);
        [o setDersWithArray:array];
    }
    return o;
}
+ (__autoreleasing FwiDer *)setWithArray:(NSArray *)array {
    __autoreleasing FwiDer *o = [FwiDer set];
    [o setDersWithArray:array];
    return o;
}

+ (__autoreleasing FwiDer *)derWithIdentifier:(uint8_t)identifier {
    return FwiAutoRelease([[FwiDer alloc] initWithIdentifier:identifier]);
}
+ (__autoreleasing FwiDer *)derWithIdentifier:(uint8_t)identifier content:(NSData *)content {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:identifier];
    [o setContent:content];
    return o;
}
+ (__autoreleasing FwiDer *)derWithIdentifier:(uint8_t)identifier Ders:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:identifier];

    if (der) {
        __autoreleasing NSMutableArray *array = [NSMutableArray arrayWithObjects:der, nil];
        
        va_list args;
        va_start(args, der);
        while ((der = va_arg(args, id))) {
            if ([der isMemberOfClass:[FwiDer class]]) [array addObject:der];
        }
        va_end(args);
        [o setDersWithArray:array];
    }
    return o;
}
+ (__autoreleasing FwiDer *)derWithIdentifier:(uint8_t)identifier array:(NSArray *)array {
    __autoreleasing FwiDer *o = [FwiDer derWithIdentifier:identifier];
    [o setDersWithArray:array];
    return o;
}


@end


@implementation FwiDer (FwiDerCreation_Private)


#pragma mark - Class's constructors
- (id)initWithIdentifier:(uint8_t)identifier {
    self = [self init];
    if (self) {
        _identifier = identifier;
        _derClass   = FwiGetDerClass(_identifier);
        _derValue   = FwiGetDerValue(_identifier);
        
		if (_derClass == kFwiDerClass_Universal) {
			if (_derValue == kFwiDerValue_BitString       || _derValue == kFwiDerValue_OctetString      ||
				_derValue == kFwiDerValue_Null            || _derValue == kFwiDerValue_ObjectIdentifier ||
				_derValue == kFwiDerValue_NumericString   || _derValue == kFwiDerValue_PrintableString  ||
				_derValue == kFwiDerValue_T61String       || _derValue == kFwiDerValue_Utf8String       ||
				_derValue == kFwiDerValue_Ia5String       || _derValue == kFwiDerValue_UtcTime          ||
				_derValue == kFwiDerValue_GeneralizedTime || _derValue == kFwiDerValue_GraphicString    ||
				_derValue == kFwiDerValue_VisibleString   || _derValue == kFwiDerValue_GeneralString    ||
				_derValue == kFwiDerValue_UniversalString || _derValue == kFwiDerValue_BmpString)
                {
                // Do nothing
                }
            else if (_derValue == kFwiDerValue_Integer  || _derValue == kFwiDerValue_Enumerated) {
                [self setInt:0];
            }
			else if (_derValue == kFwiDerValue_Sequence || _derValue == kFwiDerValue_Set) {
                _children = [[NSMutableArray alloc] init];
			}
			else if (_derValue == kFwiDerValue_Boolean) {
                [self setBoolean:NO];
            }
		}
		else {
			if ([self isStructure]) _children = [[NSMutableArray alloc] init];
		}
    }
    return self;
}


@end


@implementation FwiDer (FwiDerCollection)


- (__autoreleasing FwiDer *)derAtIndex:(NSUInteger)index {
    /* Condition validation */
    if (![self isStructure] || !_children || [_children count] == 0 || index >= [_children count]) return nil;
    return _children[index];
}
- (__autoreleasing FwiDer *)derWithPath:(NSString *)path {
    /* Condition validation */
    if (![self isStructure] || !_children || [_children count] == 0 || !path || path.length == 0 || ![path matchPattern:@"^\\d+(/\\d+)*$"]) return nil;
    return [_children _objectWithPath:path];
}

- (void)setDers:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION {
    /* Condition validation */
    if (![self isStructure] || !der) return;
    NSMutableArray *array = [[NSMutableArray alloc] initWithObjects:der, nil];
    
    va_list args;
    va_start(args, der);
    while ((der = va_arg(args, id))) {
        if ([der isMemberOfClass:[FwiDer class]]) [array addObject:der];
    }
    va_end(args);
    
    [self setDersWithArray:array];
    FwiRelease(array);
}
- (void)setDersWithArray:(NSArray *)array {
    /* Condition validation */
    if (![self isStructure] || !array || [array count] == 0) return;
    
    FwiRelease(_children);
    _children = [[NSMutableArray alloc] initWithArray:array];
}

- (void)addDers:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION {
    /* Condition validation */
    if (![self isStructure] || !der) return;
    
    if (!_children) _children = [[NSMutableArray alloc] initWithCapacity:1];
    [_children addObject:der];
    
    va_list args;
    va_start(args, der);
    while ((der = va_arg(args, id))) {
        if ([der isMemberOfClass:[FwiDer class]]) [_children addObject:der];
    }
    va_end(args);
}
- (void)addDersWithArray:(NSArray *)array {
    /* Condition validation */
    if (![self isStructure] || !array || [array count] == 0) return;
    
    if (!_children) _children = [[NSMutableArray alloc] initWithCapacity:array.count];
    [_children addObjectsFromArray:array];
}

- (void)insertDer:(FwiDer *)der atIndex:(NSUInteger)index {
    /* Condition validation */
    if (![self isStructure] || !der) return;
    if (!_children) _children = [[NSMutableArray alloc] initWithCapacity:1];
    
    if (index >= [_children count]) {
        [_children addObject:der];
    }
    else {
        [_children insertObject:der atIndex:index];
    }
}
- (void)replaceDer:(FwiDer *)der atIndex:(NSUInteger)index {
    /* Condition validation */
    if (![self isStructure] || !der) return;
    
    if (!_children || index >= [_children count]) {
        [_children addObject:der];
    }
    else {
        _children[index] = der;
    }
}

- (void)removeLastDer {
    /* Condition validation */
    if (![self isStructure] || !_children || [_children count] == 0) return;
    [_children removeObjectAtIndex:(_children.count - 1)];
}
- (void)removeDerAtIndex:(NSUInteger)index {
    /* Condition validation */
    if (![self isStructure] || !_children || [_children count] == 0 || index >= [_children count]) return;
    [_children removeObjectAtIndex:index];
}


@end


@implementation FwiDer (FwiDerPrimitive)


- (BOOL)getBoolean {
    /* Condition validation */
    if (!_content || [_content length] == 0) return NO;
    
    const uint8_t *bytes = [_content bytes];
    return (bytes[0] == 0xff);
}
- (void)setBoolean:(BOOL)value {
    /* Condition validation */
    if (_derValue != kFwiDerValue_Boolean) return;
    
    uint8_t byte  = (value) ? 0xff : 0x00;
    [self setContent:FwiAutoRelease([[NSData alloc] initWithBytes:&byte length:1])];
}

- (NSInteger)getInt {
    /* Condition validation */
    if (!_content || [_content length] == 0) return 0;
    
    NSUInteger length = ([_content length] < 4) ? [_content length] : sizeof(NSInteger);
    const uint8_t *bytes = [_content bytes];
    
    NSInteger value = bytes[0];
    for (NSUInteger i = 1; i < length; i++) {
        value <<= 8;
        value |= bytes[i];
    }
    return value;
}
- (void)setInt:(NSInteger)value {
    /* Condition validation */
    if (!(_derValue == kFwiDerValue_Integer || _derValue == kFwiDerValue_Enumerated)) return;
    [self setBigInt:[FwiBigInt bigIntWithInteger:value]];
}

- (__autoreleasing FwiBigInt *)getBigInt {
    /* Condition validation */
    if (!_content || [_content length] == 0) return nil;
    return [FwiBigInt bigIntWithData:_content shouldReverse:YES];
}
- (void)setBigInt:(FwiBigInt *)value {
    /* Condition validation */
    if (!(_derValue == kFwiDerValue_Integer || _derValue == kFwiDerValue_Enumerated) || !value) return;
    [self setContent:[value encode]];
}

- (__autoreleasing NSDate *)getTime {
    __autoreleasing NSDateFormatter *dateFormat = FwiAutoRelease([[NSDateFormatter alloc] init]);
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormat setDateStyle:NSDateFormatterNoStyle];
    [dateFormat setTimeStyle:NSDateFormatterNoStyle];
    [dateFormat setDateFormat:nil];
    
    __autoreleasing NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"Z"];
    __autoreleasing NSString *sc  = [[self getString] uppercaseString];
    
    NSRange range = [sc rangeOfCharacterFromSet:charSet];
    if (range.location != NSNotFound) sc = [sc substringWithRange:NSMakeRange(0, range.location)];
    
    if (_derValue == kFwiDerValue_GeneralizedTime) {
        __autoreleasing NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"."];
        range = [sc rangeOfCharacterFromSet:charSet];
        if (range.location != NSNotFound) {
            if (range.location == 14) {
                if (sc.length == 16) {
                    [dateFormat setDateFormat:@"yyyyMMddHHmmss.S"];
                }
                else if (sc.length == 17) {
                    [dateFormat setDateFormat:@"yyyyMMddHHmmss.SS"];
                }
                else if (sc.length == 18) {
                    [dateFormat setDateFormat:@"yyyyMMddHHmmss.SSS"];
                }
            }
        }
        else {
            if (sc.length == 8) {
                [dateFormat setDateFormat:@"yyyyMMdd"];
            }
            else if (sc.length == 12) {
                [dateFormat setDateFormat:@"yyyyMMddHHmm"];
            }
            else if (sc.length == 14) {
                [dateFormat setDateFormat:@"yyyyMMddHHmmss"];
            }
        }
    }
    else if (_derValue == kFwiDerValue_UtcTime) {
        if (sc.length == 6) {
            [dateFormat setDateFormat:@"yyMMdd"];
        }
        else if (sc.length == 10) {
            [dateFormat setDateFormat:@"yyMMddHHmm"];
        }
        else if (sc.length == 12) {
            [dateFormat setDateFormat:@"yyMMddHHmmss"];
        }
    }
    
    if (dateFormat.dateFormat || dateFormat.dateFormat.length > 0) return [dateFormat dateFromString:sc];
    else return nil;
}
- (void)setTime:(NSDate *)date {
    /* Condition validation */
    if (!(_derValue == kFwiDerValue_UtcTime || _derValue == kFwiDerValue_GeneralizedTime) || !date) return;
    
    __autoreleasing NSDateFormatter *dateFormat = FwiAutoRelease([[NSDateFormatter alloc] init]);
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormat setDateStyle:NSDateFormatterNoStyle];
    [dateFormat setTimeStyle:NSDateFormatterNoStyle];
    [dateFormat setDateFormat:nil];
    
    __autoreleasing NSString *time = nil;
    if (_derValue == kFwiDerValue_GeneralizedTime) {
        [dateFormat setDateFormat:@"yyyyMMddHHmmss.SSS"];
        time = [dateFormat stringFromDate:date];
        
        if ([time hasSuffix:@"000"]) {
            time = [NSString stringWithFormat:@"%@Z", [time substringWithRange:NSMakeRange(0, 14)]];
        }
        else {
            time = [NSString stringWithFormat:@"%@Z", time];
        }
    }
    else {
        [dateFormat setDateFormat:@"yyMMddHHmmss"];
        time = [NSString stringWithFormat:@"%@Z", [dateFormat stringFromDate:date]];
    }
    [self setContent:[time toData]];
}

- (__autoreleasing NSString *)getObjectIdentifier {
    /* Condition validation */
    if (_derValue != kFwiDerValue_ObjectIdentifier || !_content || _content.length == 0) return nil;
    
    __autoreleasing NSMutableString *builder = [NSMutableString stringWithCapacity:20];
    const uint8_t *bytes = _content.bytes;
    
    // Process first byte
    if 		(bytes[0] < 40) {
        [builder appendFormat:@"0.%d", bytes[0]];
    }
    else if (bytes[0] < 80) {
        [builder appendFormat:@"1.%d", bytes[0] - 40];
    }
    else if (bytes[0] < 120) {
        [builder appendFormat:@"2.%d", bytes[0] - 80];
    }
    else {
        [builder appendFormat:@"3.%d", bytes[0] - 120];
    }
    
    // Process the rest
    size_t i = 1;
    while (i < _content.length) {
        size_t j = 0;
        while ((bytes[i + j] & 0x80) != 0) j++;
        
        NSInteger n = bytes[i + j];
        for (size_t k = 0; k < j; k++) {
            n += (bytes[(i + j) - k - 1]  & 0x0f) * pow(0x80, k + 1);
            n += ((bytes[(i + j) - k - 1] & 0x70) >> 4) * pow(0x80, k + 1) * 0x10;
        }
        
        [builder appendFormat:@".%li", (long)n];
        i += j + 1;
    }
    return builder;
}
- (void)setObjectIdentifier:(NSString *)oid {
    /* Condition validation */
    if (_derValue != kFwiDerValue_ObjectIdentifier || !oid || oid.length == 0) return;
    
    __autoreleasing NSMutableData *bytes = [NSMutableData dataWithCapacity:0];
    __autoreleasing NSArray *values = [oid componentsSeparatedByString:@"."];
    
    __autoreleasing NSNumberFormatter *numberFormat = FwiAutoRelease([[NSNumberFormatter alloc] init]);
    [numberFormat setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormat setNumberStyle:NSNumberFormatterNoStyle];
    
    NSUInteger a = 0;
    NSUInteger b = 0;
    for (size_t idx = 0; idx < [values count]; idx++) {
        if (idx == 0) {
            a = (uint8_t)[numberFormat numberFromString:values[idx]].unsignedIntegerValue;
        }
        else if (idx == 1) {
            a = ((a * 40) + (uint8_t)[numberFormat numberFromString:values[idx]].unsignedIntegerValue);
            [bytes appendBytes:&a length:1];
        }
        else {
            b = [numberFormat numberFromString:values[idx]].unsignedIntegerValue;
            if (b < 0x80) {
                [bytes appendBytes:&b length:1];
            }
            else if (b < 0x4000) {
                uint8_t c[] = { (uint8_t)(((b & 0x3f80) >> 7) | 0x80), (uint8_t)(b & 0x7f) };
                [bytes appendBytes:c length:2];
            }
            else if (b < 0x200000) {
                uint8_t c[] = { (uint8_t)(((b & 0x1fc000) >> 14) | 0x80), (uint8_t)(((b & 0x3f80) >> 7) | 0x80), (uint8_t)(b & 0x7f) };
                [bytes appendBytes:c length:3];
            }
            else {
                uint8_t c[] = { (uint8_t)(((b & 0xfe00000) >> 21) | 0x80), (uint8_t)(((b & 0x1fc000) >> 14) | 0x80), (uint8_t)(((b & 0x3f80) >> 7) | 0x80), (uint8_t)(b & 0x7f) };
                [bytes appendBytes:c length:4];
            }
        }
    }
    [self setContent:bytes];
}

- (__autoreleasing NSString *)getString {
    /* Condition validation */
    if (!_content || [_content length] == 0) return nil;
    
    if (_derClass == kFwiDerClass_Universal) {
        switch (_derValue) {
            case kFwiDerValue_Boolean: {
                return [self getBoolean] ? @"True" : @"False";
            }
            case kFwiDerValue_Integer:
            case kFwiDerValue_Enumerated: {
                return [[self getBigInt] description];
            }
            case kFwiDerValue_BitString:
            case kFwiDerValue_OctetString: {
                // FIX FIX FIX: Switch to hex function
                __autoreleasing NSMutableString *builder = [NSMutableString stringWithCapacity:((_content.length - (_derValue == kFwiDerValue_BitString ? 1 : 0)) << 1)];
                const uint8_t *bytes = [_content bytes];
                
                for (NSUInteger i = (_derValue == kFwiDerValue_BitString ? 1 : 0); i < [_content length]; i++) {
                    NSString *text = [[NSString alloc] initWithFormat:@"%X", bytes[i]];
                    
                    [builder appendFormat:@"%@%@", ([text length] == 1 ? @"0" : @""), text];
                    FwiRelease(text);
                }
                return builder;
            }
            case kFwiDerValue_Null: {
                return @"";
            }
            case kFwiDerValue_ObjectIdentifier: {
                return [self getObjectIdentifier];
            }
            case kFwiDerValue_Utf8String:
            case kFwiDerValue_NumericString:
            case kFwiDerValue_PrintableString:
            case kFwiDerValue_T61String:
            case kFwiDerValue_Ia5String:
            case kFwiDerValue_GraphicString:
            case kFwiDerValue_VisibleString:
            case kFwiDerValue_GeneralString:
            case kFwiDerValue_UtcTime:
            case kFwiDerValue_GeneralizedTime: {
                return [_content toString];
            }
            case kFwiDerValue_UniversalString: {
                // FIX FIX FIX: Switch to hex function
                uint8_t table[] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };
                
                __autoreleasing NSMutableString *builder = [NSMutableString stringWithFormat:@"%@", @"#"];
                const uint8_t *bytes = [_content bytes];
                
                for (NSUInteger i = 0; i < [_content length]; i++) {
                    [builder appendFormat:@"%c", table[(bytes[i] >> 4) & 0xf]];
                    [builder appendFormat:@"%c", table[bytes[i] & 0xf]];
                }
                return builder;
            }
            case kFwiDerValue_BmpString: {
                const uint8_t *bytes = [_content bytes];
                unichar *cs = malloc(sizeof(unichar) * (_content.length >> 1));
                
                for (size_t i = 0; i < [_content length]; i += 2) {
                    size_t index = (i >> 1);
                    cs[index] = (unichar)((bytes[i] << 8) | bytes[i + 1]);
                }
                
                __autoreleasing NSString *string = [NSString stringWithCharacters:cs length:(_content.length >> 1)];
                free(cs);
                return string;
            }
            default: return nil;
        }
    }
    else {
        // FIX FIX FIX: Switch to hex function
        __autoreleasing NSMutableString *builder = [NSMutableString stringWithCapacity:(_content.length << 1)];
        const uint8_t *bytes = [_content bytes];
        
        for (NSUInteger i = 0; i < [_content length]; i++) {
            NSString *text = [[NSString alloc] initWithFormat:@"%X", bytes[i]];
            
            [builder appendFormat:@"%@%@", ([text length] == 1 ? @"0" : @""), text];
            FwiRelease(text);
        }
        return builder;
    }
}
- (void)setStringWithData:(NSData *)input {
    /* Condition validation */
    if (!(_derValue == kFwiDerValue_Utf8String       || _derValue == kFwiDerValue_NumericString ||
          _derValue == kFwiDerValue_PrintableString  || _derValue == kFwiDerValue_T61String     ||
          _derValue == kFwiDerValue_Ia5String        || _derValue == kFwiDerValue_GraphicString ||
          _derValue == kFwiDerValue_VisibleString    || _derValue == kFwiDerValue_GeneralString ||
          _derValue == kFwiDerValue_UniversalString  || _derValue == kFwiDerValue_BmpString)) return;
    
    /* Condition validation: Validate content */
    if (!input || input.length == 0) return;
    
    const uint8_t *bytes = input.bytes;
    switch (_derValue) {
        case kFwiDerValue_NumericString: {
            BOOL isValid = YES;
            for (NSUInteger i = 0; i < input.length; i++) {
                if (('0' <= bytes[i] && bytes[i] <= '9') || bytes[i] == ' ') continue;
                
                isValid = NO;
                break;
            }
            if (isValid) [self setContent:input];
            break;
        }
        case kFwiDerValue_PrintableString: {
            BOOL isValid = YES;
            for (NSUInteger i = 0; i < input.length; i++) {
                if (('a' <= bytes[i] && bytes[i] <= 'z') ||
                    ('A' <= bytes[i] && bytes[i] <= 'Z') ||
                    ('0' <= bytes[i] && bytes[i] <= '9') ||
                    bytes[i] == ' ' || bytes[i] == '(' || bytes[i] == ')' || bytes[i] == '+' ||
                    bytes[i] == '-' || bytes[i] == '.' || bytes[i] == ':' || bytes[i] == '=' ||
                    bytes[i] == '?' || bytes[i] == '/' || bytes[i] == ',' || bytes[i] == '\'') continue;
                
                isValid = NO;
                break;
            }
            if (isValid) [self setContent:input];
            break;
        }
        case kFwiDerValue_Ia5String: {
            BOOL isValid = YES;
            for (NSUInteger i = 0; i < input.length; i++) {
                if (bytes[i] <= 0x007f) continue;
                
                isValid = NO;
                break;
            }
            if (isValid) [self setContent:input];
            break;
        }
        case kFwiDerValue_Utf8String:
        case kFwiDerValue_T61String:
        case kFwiDerValue_GraphicString:
        case kFwiDerValue_VisibleString:
        case kFwiDerValue_GeneralString:
        case kFwiDerValue_UniversalString:
        case kFwiDerValue_BmpString: {
            [self setContent:input];
            break;
        }
        default:
            // Do nothing
            break;
    }
}
- (void)setStringWithString:(NSString *)input {
    /* Condition validation */
    if (!(_derValue == kFwiDerValue_Utf8String       || _derValue == kFwiDerValue_NumericString ||
          _derValue == kFwiDerValue_PrintableString  || _derValue == kFwiDerValue_T61String     ||
          _derValue == kFwiDerValue_Ia5String        || _derValue == kFwiDerValue_GraphicString ||
          _derValue == kFwiDerValue_VisibleString    || _derValue == kFwiDerValue_GeneralString ||
          _derValue == kFwiDerValue_UniversalString  || _derValue == kFwiDerValue_BmpString)) return;
    
    /* Condition validation: Validate content */
    if (!input || input.length == 0) return;
    
    switch (_derValue) {
        case kFwiDerValue_Utf8String:
        case kFwiDerValue_NumericString:
        case kFwiDerValue_PrintableString:
        case kFwiDerValue_T61String:
        case kFwiDerValue_Ia5String:
        case kFwiDerValue_GraphicString:
        case kFwiDerValue_VisibleString:
        case kFwiDerValue_GeneralString:
        case kFwiDerValue_UniversalString: {
            [self setStringWithData:[input toData]];
            break;
        }
        case kFwiDerValue_BmpString: {
            uint8_t *bytes = malloc(input.length << 1);
            
            for (NSUInteger i = 0; i < input.length; i++) {
                unichar c = [input characterAtIndex:i];
                NSUInteger index = (i << 1);
                
                bytes[index] = (uint8_t)((c & 0xff00) >> 8);
                bytes[index + 1] = (uint8_t)(c & 0x00ff);
            }
            [self setStringWithData:[NSData dataWithBytesNoCopy:bytes length:(input.length << 1)]];
            break;
        }
        default:
            // Do nothing
            break;
    }
}

- (void)setBitStringWithData:(NSData *)input {
    /* Condition validation */
    if (_derValue != kFwiDerValue_BitString || !input || [input length] == 0) return;
    [self setBitStringWithData:input padding:0];
}
- (void)setBitStringWithData:(NSData *)input padding:(NSInteger)padding {
    /* Condition validation */
    if (_derValue != kFwiDerValue_BitString || !input || [input length] == 0) return;
    uint8_t *bytes = malloc(input.length + 1);
    
    bytes[0] = (uint8_t)padding;
    memcpy(&bytes[1], input.bytes, input.length);
    [self setContent:[NSData dataWithBytesNoCopy:bytes length:(input.length + 1)]];
}
- (void)setBitStringWithDer:(FwiDer *)der {
    /* Condition validation */
    if (_derValue != kFwiDerValue_BitString || !der) return;
    [self setBitStringWithData:[der encode] padding:0];
}
- (void)setBitStringWithDer:(FwiDer *)der padding:(NSInteger)padding {
    /* Condition validation */
    if (_derValue != kFwiDerValue_BitString || !der) return;
    [self setBitStringWithData:[der encode] padding:padding];
}

- (void)setOctetStringWithData:(NSData *)input {
    /* Condition validation */
    if (_derValue != kFwiDerValue_OctetString || !input || [input length] == 0) return;
    [self setContent:input];
}
- (void)setOctetStringWithDer:(FwiDer *)der {
    /* Condition validation */
    if (_derValue != kFwiDerValue_OctetString || !der) return;
    [self setContent:[der encode]];
}


@end


@implementation FwiDer (FwiDerEncode)


- (__autoreleasing NSData *)encode {
    __autoreleasing NSData *content = ([self isStructure] ? [self getContent] : _content);
    __autoreleasing NSMutableData *data = nil;
    
    if (content && content.length > 0) {
        NSUInteger length = content.length;
        
        if (length > 0x7f) {
            if (length < 0x100) {
                uint8_t b[] = { _identifier, (uint8_t)0x81, (uint8_t)length };
                
                data = [NSMutableData dataWithCapacity:(length + 3)];
                [data appendBytes:b length:3];
            }
            else if (length < 0x10000) {
                uint8_t b[] = { _identifier, (uint8_t)0x82, (uint8_t)((length & 0xff00) >> 8), (uint8_t)(length & 0x00ff) };
                
                data = [NSMutableData dataWithCapacity:(length + 4)];
                [data appendBytes:b length:4];
            }
            else if (length < 0x1000000) {
                uint8_t b[] = { _identifier, (uint8_t)0x83, (uint8_t)((length & 0xff0000) >> 16), (uint8_t)((length & 0x00ff00) >> 8), (uint8_t)(length & 0x0000ff) };
                
                data = [NSMutableData dataWithCapacity:(length + 5)];
                [data appendBytes:b length:5];
            }
            else {
                uint8_t b[] = { _identifier, (uint8_t)0x84, (uint8_t)((length & 0xff000000) >> 24), (uint8_t)((length & 0x00ff0000) >> 16), (uint8_t)((length & 0x0000ff00) >> 8), (uint8_t)(length & 0x000000ff) };
                
                data = [NSMutableData dataWithCapacity:(length + 6)];
                [data appendBytes:b length:6];
            }
        }
        else {
            uint8_t b[] = { _identifier, (uint8_t)length };
            
            data = [NSMutableData dataWithCapacity:(length + 2)];
            [data appendBytes:b length:2];
        }
        [data appendData:content];
    }
    else {
        uint8_t b[] = { _identifier, (uint8_t)0x00 };
        
        data = [NSMutableData dataWithCapacity:2];
        [data appendBytes:b length:2];
    }
    return data;
}

- (__autoreleasing NSData *)encodeBase64Data {
    return [[self encode] encodeBase64Data];
}

- (__autoreleasing NSString *)encodeBase64String {
    return [[self encodeBase64Data] toString];
}


@end