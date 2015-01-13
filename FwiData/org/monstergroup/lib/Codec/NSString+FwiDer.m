#import "NSString+FwiDer.h"


@implementation NSString (FwiDer)


- (__autoreleasing FwiDer *)decodeBase64Der {
    /* Condition validation */
    if (!self || ![self isBase64]) return nil;
    return [[[self trim] toData] decodeBase64Der];
}


@end