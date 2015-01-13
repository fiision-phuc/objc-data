#import "FwiMutableBitArray.h"


@interface FwiMutableBitArray () {
    
    NSMutableData *_mutableArray;
    
    uint8_t       _buffer;
	NSUInteger	  _bitsUsed;			// Number of bits used within buffer
	NSUInteger	  _bufferLength;		// Length of buffer
}


/**
 * Add single byte to array
 */
- (void)_addSingleByte:(const uint8_t *)byte bitCount:(NSUInteger)bitCount;
/**
 * Commit data from buffer to bitArray
 */
- (void)_flushBuffer;
/**
 * Reset buffer
 */
- (void)_resetBuffer;

@end


@implementation FwiMutableBitArray


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _buffer       = 0x00;
		_bitsUsed	  = 0;
		_bufferLength = sizeof(_buffer);
		_mutableArray = [[NSMutableData alloc] init];
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    FwiRelease(_mutableArray);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (NSString *)description {
    __autoreleasing NSString *bitArray = [super description];
    
    /* Descript the current process buffer if and only if the buffer value is greater than zero */
    if (_bitsUsed > 0) {
        NSMutableString *description = [[NSMutableString alloc] initWithString:bitArray];
        if ([bitArray length] > 0) [description appendString:@" "];
		
		uint8_t validate = 0x80;
		for (NSUInteger i = 0; i < _bitsUsed; i++) {
			(_buffer & validate) ? [description appendString:@"1"] : [description appendString:@"0"];
			validate >>= 1;
		}
        __autoreleasing NSString *final = [NSString stringWithFormat:@"%@", description];
        FwiRelease(description);
        return final;
    }
    else return bitArray;
}

- (void)appendBytes:(const uint8_t *)bytes bitCount:(NSUInteger)bitCount byteCount:(NSUInteger)byteCount {
	/* Condition validation */
	if (!bytes			||
		bitCount  == 0	||
		byteCount == 0	||
		bitCount > (byteCount << 3)) return;	// Invalid parameters
	
	// Append process
	if (byteCount == 1) {
		// Flip all the bit(s) on the left hand side to zero
		uint8_t temp = *bytes;
		temp <<= (8 - bitCount);
		[self _addSingleByte:&temp bitCount:bitCount];
	}
	else {
		NSUInteger counter   = bitCount >> 3;
		NSUInteger remainder = (bitCount % 8);
		
		for (NSUInteger i = 0; i < counter; i++) [self _addSingleByte:&bytes[i] bitCount:8];
		if (remainder != 0) [self _addSingleByte:&bytes[counter] bitCount:remainder];
	}
    _bits = (void *)[_mutableArray bytes];
}
- (void)appendBytesWithoutCopy:(uint8_t *)bytes bitCount:(NSUInteger)bitCount byteCount:(NSUInteger)byteCount {
	[self appendBytes:bytes bitCount:bitCount byteCount:byteCount];
	bzero(bytes, byteCount);
	free(bytes);
}

- (void)appendWord:(uint16_t)word bitCount:(NSUInteger)bitCount {
	/* Condition validation */
	if (bitCount > 16) return;	// Invalid parameters
	
	// Convert from word to bytes
	uint8_t b1 = (word & 0xff00) >> 8;
	uint8_t b2 = (word & 0x00ff);
	
	// Append process
	if (bitCount <= 8) {
		[self appendBytes:&b2 bitCount:bitCount byteCount:1];
	}
	else {
		NSUInteger r = bitCount - 8;
		[self appendBytes:&b1 bitCount:r byteCount:1];
		[self appendBytes:&b2 bitCount:8 byteCount:1];
	}
}

- (void)clean {
    bzero(_bits, _byteCount);
    _buffer &= 0x00;
}
- (void)finalizeArray {
    [self _flushBuffer];
    [self _resetBuffer];
}

/**
 * Bitwise operators
 */
- (void)operatorXOR:(FwiBitArray *)bitArray {
    /* Condition validation */
    if ([self bitCount] == 0 || [self bitCount] != [bitArray bitCount]) return;
    
    // Perform XOR operator
    if ([self bitCount] % 8 == 0) {
        for (NSUInteger i = 0; i < [bitArray byteCount]; i++) {
            _bits[i] ^= [bitArray byteAt:i];
        }
    }
    else {
        for (NSUInteger i = 0; i < ([bitArray byteCount] - 1); i++) {
            _bits[i] ^= [bitArray byteAt:i];
        }
        _buffer ^= [bitArray byteAt:([bitArray byteCount] - 1)];
    }
}

/**
 * Class's accessor methods
 */
- (void)changeBit:(BOOL)bit atIndex:(NSUInteger)index {
	/* Condition validation */
    if (index >= (_bitCount + _bitsUsed)) return;
    
    // Flip bit process
    if (index < _bitCount) return [super changeBit:bit atIndex:index];
    else {
		// Flip bit at index
		NSUInteger temp = (index % 8);
		if (bit) {
			if (![self bitAt:index]) _buffer |= (0x80 >> (temp & 0x07));
			else /* Keep current value */;
		}
		else {
			if ([self bitAt:index]) _buffer ^= (0x80 >> (temp & 0x07));
			else /* Keep current value */;
		}
    }
}
- (const uint8_t *)getBytes {
	return nil;
}
- (NSUInteger)bitCount {
    return (_bitCount + _bitsUsed);
}
- (NSUInteger)byteCount {
    return (_byteCount + (_bitsUsed ? _bufferLength : 0));
}
- (BOOL)bitAt:(NSUInteger)index {
    /* Condition validation */
    if (index >= (_bitCount + _bitsUsed)) return NO;
    
    // Get bit process
    if (index < _bitCount) return [super bitAt:index];
    else {
        // Calculate check bit
        index = (index % 8);
        return (_buffer & (0x80 >> (index & 0x07)));
    }
}
- (uint8_t)byteAt:(NSUInteger)index {
    /* Condition validation */
    if (index >= (_byteCount + _bufferLength)) return 0x00;
    
    if (index < _byteCount) return [super byteAt:index];
    else return _buffer;
}


#pragma mark - Class's private methods
- (void)_addSingleByte:(const uint8_t *)byte bitCount:(NSUInteger)bitCount {
	uint8_t	temp = *byte;
	
	// Append to array
	NSUInteger unusedBits = ((_bufferLength << 3) - _bitsUsed);
	if (unusedBits >= bitCount) {
		_buffer = (_buffer | (temp >> _bitsUsed));
		_bitsUsed += bitCount;
	}
	else {
		uint8_t split = temp >> (8 - unusedBits);
		bitCount -= unusedBits;
		temp <<= unusedBits;
		
		// Add first part
		_buffer	|= split;
		_bitsUsed += unusedBits;
		[self _flushBuffer];
		[self _resetBuffer];
		
		// Add second part
		_buffer = (_buffer | (temp >> _bitsUsed));
		_bitsUsed += bitCount;
	}
	
	// Zero out all un-used bit(s)
	NSUInteger shift = (8 - _bitsUsed);
	_buffer >>= shift;
	_buffer <<= shift;
	
	// Commit buffer to array if necessary
	if (_bitsUsed & 8) {
		[self _flushBuffer];
		[self _resetBuffer];
	}
}
- (void)_flushBuffer {
	[_mutableArray appendBytes:&_buffer length:_bufferLength];
    
    // Update BitArray components
	_bits = (void *)[_mutableArray bytes];
    _byteCount = [_mutableArray length];
    _bitCount  = _byteCount << 3;
}
- (void)_resetBuffer {
	bzero(&_buffer, _bufferLength);
	_bitsUsed &= 0x00;
}


#pragma mark - Class's notification handlers


#pragma mark - NSCoding's members
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self && aDecoder) {
        FwiRelease(_mutableArray);
        
        __autoreleasing NSData *data = [aDecoder decodeObjectForKey:@"_mutableArray"];
        if (data) _mutableArray = [[NSMutableData alloc] initWithData:data];
        
        _buffer = [aDecoder decodeIntForKey:@"_buffer"];
        _bitsUsed = [aDecoder decodeIntForKey:@"_bitsUsed"];
        _bufferLength = [aDecoder decodeIntForKey:@"_bufferLength"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (!aCoder) return;
    
    [aCoder encodeObject:_mutableArray forKey:@"_mutableArray"];
    
    [aCoder encodeInteger:_buffer forKey:@"_buffer"];
    [aCoder encodeInteger:_bitsUsed forKey:@"_bitsUsed"];
    [aCoder encodeInteger:_bufferLength forKey:@"_bufferLength"];
}


@end


@implementation FwiMutableBitArray (FwiMutableBitArrayCreation)


#pragma mark - Class's static constructors
+ (FwiMutableBitArray *)mutableBitArray {
    __autoreleasing FwiMutableBitArray *array = FwiAutoRelease([[FwiMutableBitArray alloc] init]);
	return array;
}


@end