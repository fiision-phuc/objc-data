#import "NSString+FwiJson.h"


@implementation NSString (FwiJson)


- (__autoreleasing FwiJson *)decodeBase64Json {
    return [[[self trim] toData] decodeBase64Json];
}
- (__autoreleasing FwiJson *)decodeJson {
    return [[[self trim] toData] decodeJson];
}


@end