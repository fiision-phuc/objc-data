#import "FwiJsonMapper.h"


@interface FwiJsonMapper () {
}

/** Build array from a sequence of model. */
- (__autoreleasing NSArray *)_convertJsonArray:(NSArray *)array withModel:(Class)model;

/** Build Json from a model. */
- (__autoreleasing id)_convertModelToJson:(id)model;

/** Inject properties's values into model. */
- (__autoreleasing id)_injectValues:(NSDictionary *)properties intoModel:(Class)model;

@end


@implementation FwiJsonMapper


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


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (id)decodeJsonData:(NSData *)jsonData model:(Class)model {
    /* Condition validation */
    if (!jsonData || jsonData.length == 0 || !model) return nil;

    // Parse Json
    __autoreleasing NSError *error = nil;
    __autoreleasing id decodedJson = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];

    /* Condition validation: Validate json parse process */
    if (error || !decodedJson) return nil;

    // Map Json: Currently, only NSArray or NSDictionary is being supported from NSJSONSerialization
    if ([decodedJson isKindOfClass:[NSArray class]]) {
        _weak NSArray *array = (NSArray *)decodedJson;
        return [self _convertJsonArray:array withModel:model];
    }
    else if ([decodedJson isKindOfClass:[NSDictionary class]]) {
        _weak NSDictionary *properties = (NSDictionary *)decodedJson;
        return [self _injectValues:properties intoModel:model];
    }
    else {
        return decodedJson;
    }
}
- (id)decodeJsonString:(NSString *)jsonString model:(Class)model {
    /* Condition validation */
    if (!jsonString || jsonString.length == 0 || !model) return nil;
    else return [self decodeJsonData:[jsonString toData] model:model];
}

- (__autoreleasing NSData *)encodeJsonDataWithModel:(id)model {
    /* Condition validation */
    if (!model) return nil;
    __autoreleasing id data = nil;

    // Validate model
    if ([model isKindOfClass:[NSArray class]]) {
        __block NSMutableArray *list = [NSMutableArray arrayWithCapacity:[(NSArray *)model count]];
        [(NSArray *)model enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL *stop) {
            __autoreleasing NSDictionary *record = [self _convertModelToJson:item];
            [list addObject:record];
        }];

        data = list;
        list = nil;
    }
    else if ([model isKindOfClass:[NSSet class]]) {
        __block NSMutableArray *list = [NSMutableArray arrayWithCapacity:[(NSSet *)model count]];
        [(NSSet *)model enumerateObjectsUsingBlock:^(id item, BOOL *stop) {
            __autoreleasing NSDictionary *record = [self _convertModelToJson:item];
            [list addObject:record];
        }];

        data = list;
        list = nil;
    }
    else if ([model isKindOfClass:[NSDictionary class]]) {
    }
    else {
        data = [self _convertModelToJson:model];
    }

    // Convert data to json
    if (data) {
        __autoreleasing NSError *error = nil;
        __autoreleasing NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data
                                                                           options:kNilOptions
                                                                             error:&error];

        if (!error) {
            return jsonData;
        }
        else {
            return nil;
        }
    }
    else {
        return nil;
    }
}
- (__autoreleasing NSString *)encodeJsonStringWithModel:(id)model {
    __autoreleasing NSData *jsonData = [self encodeJsonDataWithModel:model];
    return [jsonData toString];
}

#pragma mark - Class's private methods
- (__autoreleasing NSArray *)_convertJsonArray:(NSArray *)array withModel:(Class)model {
    __block NSMutableArray *models = [NSMutableArray arrayWithCapacity:array.count];

    [array enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL *stop) {
        if ([item isKindOfClass:[NSDictionary class]]) {
            _weak NSDictionary *properties = (NSDictionary *)item;

            __autoreleasing id objectModel = [self _injectValues:properties intoModel:model];
            if (objectModel) [models addObject:objectModel];
        }
        else {
            [models addObject:item];
        }
    }];
    return models;
}

- (__autoreleasing id)_convertModelToJson:(id)model {
    __autoreleasing NSArray *properties = [FwiProperty propertiesWithClass:[model class]];
    __autoreleasing NSMutableDictionary *json = [NSMutableDictionary dictionaryWithCapacity:properties.count];

    for (_weak FwiProperty *property in properties) {
        __autoreleasing id value = [model valueForKey:property.name];
        if (!value) value = [NSNull null];

        [json setObject:value forKey:property.name];
    }
    return json;
}

- (__autoreleasing id)_injectValues:(NSDictionary *)properties intoModel:(Class)model {
    __autoreleasing id instance = FwiAutoRelease([[model alloc] init]);
    __autoreleasing NSArray *propertiesList = [FwiProperty propertiesWithClass:model];

    /* Condition validation */
    if (!instance) return nil;

    for (_weak FwiProperty *property in propertiesList) {
        _weak id value = properties[property.name];
        if ([property canAssignValue:value]) [instance setValue:value forKey:property.name];
    }
    return instance;
}


@end
