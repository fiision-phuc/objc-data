#import "NSArray+FwiExtension_Private.h"
#import "FwiJson.h"
#import "FwiDer.h"


@implementation NSArray (FwiExtension_Private)


- (__autoreleasing id)_objectWithPath:(NSString *)path {
    /* Condition validation: If the collection is empty, return nil right away */
    if ([self count] == 0) return nil;

    __autoreleasing NSArray *tokens = [path componentsSeparatedByString:@"/"];
    _weak id o = self;
    
    for (NSUInteger i = 0; i < [tokens count]; i++) {
        _weak NSString *pth = tokens[i];
        
        if ([o isKindOfClass:[NSArray class]]) {
			NSInteger index = [pth integerValue];
            if (index < 0 || index >= [(NSArray *)o count]) {
                o = nil;
            }
            else {
                o = ((NSArray *)o)[index];
            }
        }
        else if ([o isKindOfClass:[NSDictionary class]]) {
			o = ((NSDictionary *)o)[pth];
        }
        else if ([o isKindOfClass:[FwiDer class]]) {
            o = [o derAtIndex:[pth integerValue]];
        }
		else if ([o isKindOfClass:[FwiJson class]]) {
			o = [(FwiJson *)o jsonWithPath:pth];
        }
		else {
            o = nil;
			break;
		}
    }
	return o;
}


@end
