#import "FwiBitMatrix.h"


@interface FwiBitMatrix () {
}

/**
 * Return internal BitArray collection
 */
- (__autoreleasing NSArray *)_matrix;

@end


@implementation FwiBitMatrix


@synthesize size=_size;


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _matrix = nil;
        _size   = 0;
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    FwiRelease(_matrix);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithCapacity:(_size * _size)];
    
    for (NSUInteger i = 0; i < _size; i++) {
        FwiBitArray *bitArray = _matrix[i];
		
		for (NSUInteger j = 0; j < [bitArray bitCount]; j++) {
			if ([bitArray bitAt:j]) [description appendString:@" 1"];
			else [description appendString:@" 0"];
		}
		[description appendString:@"\n"];
    }
    
    __autoreleasing NSString *final = [NSString stringWithFormat:@"%@", description];
    FwiRelease(description);
    return final;
}

- (void)clean {
    for (NSUInteger i = 0; i < _size; i++) {
        FwiBitArray *bitArray = _matrix[i];
        [bitArray clean];
    }
}
- (void)copy:(id)bitMatrix {
	/* Condition validation */
	if (!bitMatrix || _size != [(FwiBitMatrix *)bitMatrix size]) return;
	
    __autoreleasing NSArray *_otherMatrix = [bitMatrix _matrix];
	for (NSUInteger i = 0; i < [_otherMatrix count]; i++) {
        FwiBitArray *otherRecord = _otherMatrix[i];
        FwiBitArray *record = _matrix[i];
        
		const uint8_t *otherBytes = [otherRecord bytes];
		uint8_t *bytes = (void *)[record bytes];
        
		memcpy(bytes, otherBytes, [otherRecord byteCount]);
	}
}

- (void)changeBit:(BOOL)bit atRow:(NSUInteger)row andCol:(NSUInteger)col {
    /* Condition validation */
    if (row >= _size || col >= _size) return;
    
    FwiBitArray *bitArray = _matrix[row];
    [bitArray changeBit:bit atIndex:col];
}
- (BOOL)bitAtRow:(NSUInteger)row andCol:(NSUInteger)col {
    /* Condition validation */
    if (row >= _size || col >= _size) return NO;
    
    FwiBitArray *bitArray = _matrix[row];
    return [bitArray bitAt:col];
}
- (__autoreleasing NSArray *)_matrix {
	return _matrix;
}


#pragma mark - Class's private methods


#pragma mark - Class's notification handlers


#pragma mark - NSCoding's members
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self && aDecoder) {
        FwiRelease(_matrix);
        _size = [[aDecoder decodeObjectForKey:@"_size"] unsignedIntegerValue];
        
        __autoreleasing NSArray *matrixObj = [aDecoder decodeObjectForKey:@"_matrix"];
        if (matrixObj) _matrix = FwiRetain([matrixObj toMutableArray]);
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (!aCoder) return;
    
    [aCoder encodeObject:_matrix forKey:@"_matrix"];
    [aCoder encodeObject:@(_size) forKey:@"_size"];
}


@end


@implementation FwiBitMatrix (FwiBitMatrixCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiBitMatrix *)bitMatrixWithSize:(NSUInteger)size {
    __autoreleasing FwiBitMatrix *matrix = [[FwiBitMatrix alloc] initWithSize:size];
    return FwiAutoRelease(matrix);
}


#pragma mark - Class's constructors
- (id)initWithSize:(NSUInteger)size {
    self = [self init];
    if (self) {
        _size = size;
        if (_size > 0) {
            _matrix = [[NSMutableArray alloc] initWithCapacity:_size];

            // Create BitArray data
            NSUInteger length = ((_size % 8) == 0) ? (_size >> 3) : ((_size >> 3) + 1);
            uint8_t *bytes = malloc(_size);
            bzero(bytes, length);

            // Create BitMatrix
            for (NSUInteger i = 0; i < _size; i++) {
                __autoreleasing FwiBitArray *array = [FwiBitArray bitArrayWithBytes:bytes bitCount:_size byteCount:length];
                [_matrix addObject:array];
            }
            free(bytes);
        }
    }
    return self;
}


@end