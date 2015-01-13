#import "FwiBitArray.h"


@interface FwiBitArray () {
    
    NSData *_data;
}

@end


@implementation FwiBitArray


@synthesize bytes=_bits;


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _data      = nil;
        _bits      = nil;
        _bitCount  = 0;
        _byteCount = 0;
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    _bits = nil;
    FwiRelease(_data);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithCapacity:_bitCount];
	
	/* Descript the array if and only if the length of the bytes is greater than zero */
	if (_byteCount > 0) {
        NSUInteger bitCounter = 0;
        
		for (NSUInteger i = 0; i < _byteCount; i++) {
			NSUInteger counter  = 8;
			uint8_t	   validate = 0x80;
			
			for (NSUInteger j = 0; j < counter; j++) {
				(_bits[i] & validate) ? [description appendString:@"1"] : [description appendString:@"0"];
				validate >>= 1;
                
                // Terminate condition
                bitCounter++;
                if (bitCounter >= _bitCount) break;
			}
			if (i < (_byteCount - 1)) [description appendString:@" "];
		}
	}
    
    __autoreleasing NSString *final = [NSString stringWithFormat:@"%@", description];
    FwiRelease(description);
	return final;
}

- (void)clean {
    if (!_bits) return;
    bzero(_bits, _byteCount);
}

- (void)operatorXOR:(FwiBitArray *)bitArray {
    /* Condition validation */
    if (_bitCount != [bitArray bitCount]) return;
    
    // Perform XOR operator
    NSUInteger counter = ((_bitCount % 8) == 0) ? (_bitCount >> 3) : ((_bitCount >> 3) + 1);
    for (NSUInteger i = 0; i < counter; i++) {
        _bits[i] ^= [bitArray byteAt:i];
    }
}

- (void)changeBit:(BOOL)bit atIndex:(NSUInteger)index {
    /* Condition validation */
	if (index >= _bitCount) return;
	
    // Flip bit at index
    if (bit) {
		if (![self bitAt:index]) _bits[index >> 3] |= (0x80 >> (index & 0x07));
		else /* Keep current value */;
	}
    else {
		if ([self bitAt:index]) _bits[index >> 3] ^= (0x80 >> (index & 0x07));
		else /* Keep current value */;
	}
}
- (BOOL)bitAt:(NSUInteger)index {
    /* Condition validation */
    if (index >= _bitCount) return NO;
    
    // Get bit at index
    return (_bits[index >> 3] & (0x80 >> (index & 0x07)));
}
- (uint8_t)byteAt:(NSUInteger)index {
    /* Condition validation */
    if (index >= _byteCount) return 0x00;
    return _bits[index];
}


#pragma mark - Class's private methods


#pragma mark - Class's notification handlers


#pragma mark - NSCoding's members
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self && aDecoder) {
        _data = FwiRetain([aDecoder decodeObjectForKey:@"_data"]);
        _bitCount = [aDecoder decodeIntForKey:@"_bitCount"];
        
        _bits = (void *)[_data bytes];
        _byteCount = [_data length];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (!aCoder) return;
    
    [aCoder encodeObject:_data forKey:@"_data"];
    [aCoder encodeInteger:_bitCount forKey:@"_bitCount"];
}


@end


@implementation FwiBitArray (FwiBitArrayCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiBitArray *)bitArrayWithBytes:(const uint8_t *)bytes bitCount:(NSUInteger)bitCount byteCount:(NSUInteger)byteCount {
    /* Condition validation */
    if (bitCount > (byteCount << 3)) return nil;

    __autoreleasing FwiBitArray *bitArray = FwiAutoRelease([[FwiBitArray alloc] initWithBytes:bytes bitCount:bitCount]);
    return bitArray;
}
+ (__autoreleasing FwiBitArray *)bitArrayWithBytesWithoutCopy:(uint8_t *)bytes bitCount:(NSUInteger)bitCount byteCount:(NSUInteger)byteCount {
    /* Condition validation */
    if (bitCount > (byteCount << 3)) return nil;
    __autoreleasing FwiBitArray *bitArray = [FwiBitArray bitArrayWithBytes:bytes bitCount:bitCount byteCount:byteCount];
    
    // Free memory after used
    bzero(bytes, byteCount);
    free(bytes);

    return bitArray;
}


#pragma mark - Class's constructors
- (id)initWithBytes:(const uint8_t *)bytes bitCount:(NSUInteger)bitCount {
    self = [self init];
    if (self) {
        _bitCount = bitCount;

        // Calculate number of byte(s) will be used
        NSUInteger remainder = _bitCount % 8;
        _byteCount = (remainder == 0) ? (_bitCount >> 3) : ((_bitCount >> 3) + 1);

        // Copy data from source
		_data = [[NSData alloc] initWithBytes:bytes length:_byteCount];
        _bits = (void *)[_data bytes];

        if (remainder != 0) {
            remainder = 8 - remainder;

            // Zero out all unused bit(s)
            _bits[(_byteCount - 1)] >>= remainder;
            _bits[(_byteCount - 1)] <<= remainder;
        }
    }
    return self;
}


@end