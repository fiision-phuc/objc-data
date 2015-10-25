#import "FwiProperty.h"


@interface FwiProperty () {

    NSArray *_attributes;
}


/** Check if it is has specific type of attribute. */
- (BOOL)_hasAttribute:(NSString *)attribute;

/** Return content of specific attribute. */
- (NSString *)_contentOfAttribute:(NSString *)attribute;

@end


@implementation FwiProperty


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's override methods
- (NSUInteger)hash {
    return [self.name hash] ^ [[self typeEncoding] hash];
}
- (BOOL)isEqual:(id)other {
    return [other isKindOfClass:[FwiProperty class]] &&
    [[self name] isEqual:[other name]] &&
    ([self propertyType] ? [[self propertyType] isEqual: [other propertyType]] : ![other propertyType]) &&
    [[self typeEncoding] isEqual: [other typeEncoding]] &&
    ([self ivarName] ? [[self ivarName] isEqual: [other ivarName]] : ![other ivarName]);
}

- (NSString *)description {
    __autoreleasing NSString *propertyType = self.propertyType;
    __autoreleasing NSString *typeEncoding = self.typeEncoding;
    return [NSString stringWithFormat: @"<Property:%@ (ivar:%@) %@ %@>", self.name, self.ivarName, (propertyType && propertyType.length > 0 ? propertyType : @"-"), (typeEncoding && typeEncoding.length > 0 ? typeEncoding : @"-")];
}


#pragma mark - Class's properties
- (BOOL)isAssign {
    if (_property) {
        return !(self.isCopy | self.isRetain);
    }
    else {
        return NO;
    }
}
- (BOOL)isCopy {
    return [self _hasAttribute:@"C"];
}
- (BOOL)isDynamic {
    return [self _hasAttribute:@"D"];
}
- (BOOL)isNonatomic {
    return [self _hasAttribute:@"N"];
}
- (BOOL)isReadonly {
    return [self _hasAttribute:@"R"];
}
- (BOOL)isRetain {
    return [self _hasAttribute:@"&"];
}

- (BOOL)isWeak {
    return self.isWeakReference || (self.isObject && !self.isCopy && !self.isRetain);
}
- (BOOL)isWeakReference {
    return [self _hasAttribute:@"W"];
}

- (BOOL)isBlock {
    return [[self typeEncoding] isEqualToString:@"@?"];
}
- (BOOL)isCollection {
    Class propClass = [self propertyClass];
    return (propClass && ([propClass isKindOfClass:[NSArray class]] || [propClass isKindOfClass:[NSSet class]] || [propClass isKindOfClass:[NSDictionary class]]));
}
- (BOOL)isId {
    return [[self typeEncoding] isEqualToString:@"@"];
}
- (BOOL)isObject {
    return [[self typeEncoding] hasPrefix: @"@"] && ![self isBlock];
}
- (BOOL)isPrimitive {
    __autoreleasing NSString *typeEncoding = [self typeEncoding];
    return ([typeEncoding isEqualToString: @"i"] || [typeEncoding isEqualToString: @"I"] ||
            [typeEncoding isEqualToString: @"s"] || [typeEncoding isEqualToString: @"S"] ||
            [typeEncoding isEqualToString: @"l"] || [typeEncoding isEqualToString: @"L"] ||
            [typeEncoding isEqualToString: @"q"] || [typeEncoding isEqualToString: @"Q"] ||
            [typeEncoding isEqualToString: @"f"] ||
            [typeEncoding isEqualToString: @"d"] ||
            [typeEncoding isEqualToString: @"B"] ||
            [typeEncoding isEqualToString: @"c"] || [typeEncoding isEqualToString: @"C"]);
}

- (SEL)getter {
    SEL getter = [self customGetter];
    
    if (!getter) getter = NSSelectorFromString([self name]);
    return getter;
}
- (SEL)customGetter {
    return NSSelectorFromString([self _contentOfAttribute:@"G"]);
}

- (SEL)setter {
    SEL setter = [self customSetter];
    
    if (!setter) {
        NSString *propName   = [self name];
        NSString *setterName = [NSString stringWithFormat:@"set%@%@:", [[propName substringToIndex:1] uppercaseString], [propName substringFromIndex:1]];
        
        setter = NSSelectorFromString(setterName);
    }
    return setter;
}
- (SEL)customSetter {
    return NSSelectorFromString([self _contentOfAttribute:@"S"]);
}

- (NSString *)name {
    if (_property) {
        return [NSString stringWithUTF8String:property_getName(_property)];
    }
    else {
        return nil;
    }
}
- (NSString *)ivarName {
    return [self _contentOfAttribute: @"V"];
}
- (Class)propertyClass {
    /* Condition validation */
    if (!self.isObject) return nil;
    
    NSArray *encodingComponents = [[self typeEncoding] componentsSeparatedByString:@"\""];
    if ([encodingComponents count] < 2) {
        //id looks like '@', blocks like '@?'
        return nil;
    }
    
    //typeEncoding looks like '@"AModel"'.  This is with the @ and "s.
    NSString *className = [encodingComponents objectAtIndex:1];
    Class class = NSClassFromString(className);
    return class;
}

- (NSString *)propertyType {
    __autoreleasing NSPredicate *filter = [NSPredicate predicateWithFormat:@"NOT (self BEGINSWITH 'T') AND NOT (self BEGINSWITH 'V')"];
    return [[_attributes filteredArrayUsingPredicate:filter] componentsJoinedByString:@","];
}

- (NSString *)typeEncoding {
    return [self _contentOfAttribute: @"T"];
}
- (NSString *)typeOldEncoding {
    return [self _contentOfAttribute: @"t"];
}


#pragma mark - Class's public methods
- (BOOL)canAssignValue:(id)value {
    /* Condition validation */
    if (self.isReadonly || !value) return false;

    if (self.isId) {
        return YES;
    }
    else if (self.isObject && !self.isWeak) {
        return [value isKindOfClass:[self propertyClass]];
    }
    else if (self.isPrimitive) {
        return [value isKindOfClass:[NSNumber class]];
    }
    
    // We don't handle structs, char*, etc yet.  KVC does, tho.
    return YES;
}


#pragma mark - Class's private methods
- (BOOL)_hasAttribute:(NSString *)attribute {
    __block BOOL isHave = NO;
    
    [_attributes enumerateObjectsUsingBlock:^(NSString *encoded, NSUInteger idx, BOOL *stop) {
        if ([encoded hasPrefix:attribute]) {
            isHave = YES;
            *stop  = YES;
        }
    }];
    return isHave;
}

- (NSString *)_contentOfAttribute:(NSString *)attribute {
    for(NSString *encoded in _attributes) {
        if([encoded hasPrefix: attribute]) return [encoded substringFromIndex:1];
    }
    return nil;
}


@end


@implementation FwiProperty (FwiPropertyCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing NSArray *)propertiesWithClass:(Class)aClass {
    /* Condition validation */
    if (!aClass) return nil;
    
    // Get all properties
    __autoreleasing NSMutableArray *properties = [NSMutableArray array];
    while (aClass && (aClass != [NSObject class])) {
        uint32_t count = 0;
        objc_property_t *list = class_copyPropertyList(aClass, &count);
        
        for (NSUInteger i = 0; i < count; i++) {
            FwiProperty *property = [FwiProperty propertyWithObjCProperty:list[i]];
            [properties addObject:property];
        }
        
        free(list);
        aClass = [aClass superclass];
    }
    return properties;
}
+ (__autoreleasing FwiProperty *)propertyWithObjCProperty:(objc_property_t)property {
    return FwiAutoRelease([[FwiProperty alloc] initWithObjCProperty:property]);
}


#pragma mark - Class's constructors
- (id)initWithObjCProperty:(objc_property_t)property {
    self = [self init];
    if(self) {
        _property = property;
        if (_property) {
            _attributes = [[[NSString stringWithUTF8String:property_getAttributes(property)] componentsSeparatedByString: @","] copy];
        }
    }
    return self;
}


@end
