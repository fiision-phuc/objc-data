#import "NSString+FwiJson.h"


@implementation NSString (FwiJson)


- (__autoreleasing FwiJson *)decodeBase64Json {
    if (!self || ![self isBase64]) return nil;
    return [[[self trim] toData] decodeBase64Json];
}
- (__autoreleasing FwiJson *)decodeJson {
    if (!self) return nil;
    return [[[self trim] toData] decodeJson];
}


@end