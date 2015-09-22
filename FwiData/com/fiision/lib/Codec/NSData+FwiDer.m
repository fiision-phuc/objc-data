#import "NSData+FwiDer.h"
#import "FwiDer_Private.h"


@implementation NSData (FwiDer)


- (__autoreleasing FwiDer *)decodeBase64Der {
    /* Condition validation */
    if (!self || ![self isBase64]) return nil;
    return [[self decodeBase64Data] decodeDer];
}
- (__autoreleasing FwiDer *)decodeDer {
    /* Condition validation */
    if (!self || self.length == 0) return nil;
    
    // Create root object
    __autoreleasing NSMutableArray *oStack = [NSMutableArray arrayWithCapacity:10];
    __autoreleasing NSMutableArray *iStack = [NSMutableArray arrayWithCapacity:10];
    const uint8_t *bytes = self.bytes;
    
    NSInteger index  = 0;
    NSInteger length = 0;
    __autoreleasing FwiDer *root = nil;
    
    while (index < self.length) {
        /* Condition validation: Validate DER class & value */
        FwiDerClass derClass = FwiGetDerClass(bytes[index]);
        FwiDerValue derValue = FwiGetDerValue(bytes[index]);
        if (!FwiValidateDerClass(derClass) || (derClass == kFwiDerClass_Universal && !FwiValidateDerValue(derValue))) return nil;
        
        // Continue the process
        __autoreleasing FwiDer *object = [FwiDer derWithIdentifier:bytes[index++]];
        uint8_t lengthLevel = bytes[index++];
        NSInteger l = 0;
        
        switch (lengthLevel) {
            case kFwiDerLengthLevel_1: {
                l = bytes[index++];
                break;
            }
            case kFwiDerLengthLevel_2: {
                uint8_t b1 = bytes[index++];
                uint8_t b2 = bytes[index++];
                l = (b1 << 8) | b2;
                break;
            }
            case kFwiDerLengthLevel_3: {
                uint8_t b1 = bytes[index++];
                uint8_t b2 = bytes[index++];
                uint8_t b3 = bytes[index++];
                l = (b1 << 16) | (b2 << 8) | b3;
                break;
            }
            case kFwiDerLengthLevel_4: {
                uint8_t b1 = bytes[index++];
                uint8_t b2 = bytes[index++];
                uint8_t b3 = bytes[index++];
                uint8_t b4 = bytes[index++];
                l = (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
                break;
            }
            default:
                l = lengthLevel;
                break;
        }
        
        /* Condition validation: Validate length */
        if (l < 0) return nil;
        
        // Construct DER
        if ([object isStructure]) {
            if (root) {
                [oStack addObject:root];
                [iStack addObject:@(length)];
            }
            root = object;
            length = l;
        }
        else {
            [object setContent:[NSData dataWithBytes:&bytes[index] length:l]];
            index += l;
            
            // Add object to root
            if (root) {
                [root addDer:object];
            }
            else {
                root = object;
            }
        }
        
        // Pop all completed DERs
        while (root.length == length && oStack.count > 0) {
            __autoreleasing FwiDer *previousRoot = oStack[oStack.count - 1];
            length = [(NSNumber *)iStack[iStack.count - 1] integerValue];
            
            [previousRoot addDer:root];
            root = FwiAutoRelease(FwiRetain(previousRoot));
            [oStack removeObjectAtIndex:(oStack.count - 1)];
            [iStack removeObjectAtIndex:(iStack.count - 1)];
        }
    }
    return root;
}


@end