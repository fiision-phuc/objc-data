#import "NSData+FwiJson.h"
#import "FwiJson_Private.h"


@implementation NSData (FwiJson)


- (__autoreleasing FwiJson *)decodeBase64Json {
    /* Condition validation */
    if (!self || self.length == 0) return nil;
    else return [[self decodeBase64Data] decodeJson];
}
- (__autoreleasing FwiJson *)decodeJson {
    /* Condition validation */
    if (!self || self.length == 0) return nil;

    __autoreleasing NSError *error = nil;
    __autoreleasing id obj = [NSJSONSerialization JSONObjectWithData:self
                                                             options:NSJSONReadingAllowFragments
                                                               error:&error];
    if (error) {
        return nil;
    }
    else {
        if ([obj isKindOfClass:[NSArray class]]) {
            return [FwiJson arrayWithArray:(NSArray *)obj];
        }
        else if ([obj isKindOfClass:[NSDictionary class]]) {
            return [FwiJson objectWithDictionary:(NSDictionary *)obj];
        }
        else {
            return nil;
        }
    }
}


@end