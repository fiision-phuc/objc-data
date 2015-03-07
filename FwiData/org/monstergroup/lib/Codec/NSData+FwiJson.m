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
    return (error ? nil : [FwiJson _JsonFromObject:obj]);
}


@end