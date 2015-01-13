#import "FwiBigInt.h"


typedef NS_ENUM(NSInteger, Bitwise) {
    kBitwise_AND = 0,
    kBitwise_OR  = 1,
    kBitwise_XOR = 2,
    kBitwise_NOT = 3
};


@interface FwiBigInt () {
    
    BOOL _isNegative;
}

@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, assign) BOOL isNegative;


/** Handle single and multiple bytes division operation. */
+ (void)_multiBytesDivideWithNominator:(FwiBigInt *)nominator dominator:(FwiBigInt *)dominator quotient:(FwiBigInt *)quotient;
+ (void)_singleByteDivideWithNominator:(FwiBigInt *)nominator dominator:(FwiBigInt *)dominator quotient:(FwiBigInt *)quotient;


/** Return the position of the most significant bit. */
- (NSUInteger)_bitCount;

/** Remove all trailing bytes(0x00 | 0xFF). */
- (void)_fixData;
/** Centralize bitwise operations. */
- (void)_performBitwise:(Bitwise)bitwise source:(NSMutableData *)source isSourceNegative:(BOOL)isSourceNegative value:(NSMutableData *)value isValueNegative:(BOOL)isValueNegative;

@end


@implementation FwiBigInt


@synthesize data=_data, isNegative=_isNegative;


#pragma mark - Class's private static methods
+ (void)_multiBytesDivideWithNominator:(FwiBigInt *)nominator dominator:(FwiBigInt *)dominator quotient:(FwiBigInt *)quotient {
    @autoreleasepool {
        // Get values
        uint8_t *nominatorBytes = (void *)[nominator.data bytes];
        uint8_t *dominatorBytes = (void *)[dominator.data bytes];
        uint8_t *quotientBytes  = (void *)[quotient.data  bytes];
        size_t  retPos          = 0;
        
        // Perform multi bytes division
        while ([nominator isGreaterThan:dominator]) {
            uint16_t nominatorByte1 = nominatorBytes[[nominator.data length] - 1];
            uint16_t nominatorByte2 = nominatorBytes[[nominator.data length] - 2];
            uint16_t dominatorByte1 = dominatorBytes[[dominator.data length] - 1];
            uint16_t dominatorByte2 = dominatorBytes[[dominator.data length] - 2];
            
            // Calculate dividePart length
            size_t length = nominatorByte1 > dominatorByte1 ? dominator.data.length : dominator.data.length + 1;
            
            // Prepare dividePart
            __autoreleasing NSMutableData *copyData = [NSMutableData dataWithBytes:&nominatorBytes[nominator.data.length - length] length:length];
            __autoreleasing FwiBigInt *dividePart = [FwiBigInt bigIntWithData:copyData shouldReverse:NO];
            
            uint16_t dividend  = (nominatorByte1 <= dominatorByte2) ? ((nominatorByte1 << 8) | nominatorByte2) : nominatorByte1;
            uint16_t threshold = (nominatorByte1 <= dominatorByte2) ? 0x1000 : 0x10;
            uint16_t shift     = (nominatorByte1 <= dominatorByte2) ? 8 : 0;
            uint16_t q = dividend / dominatorByte1;
            uint16_t r = dividend % dominatorByte1;
            
            // Guess the quotient
            BOOL isFinished = NO;
            while (!isFinished) {
                isFinished = YES;
                uint16_t a = q * dominatorByte2;
                uint16_t b = (nominatorByte1 <= dominatorByte2) ? (r << shift) | nominatorByte2 : r;
                
                if (q == threshold || a > b) {
                    r += dominatorByte1;
                    q--;
                    
                    if (r < threshold) isFinished = NO;
                }
            }
            
            // Verify quotient
            __autoreleasing FwiBigInt *result = [dominator bigIntByMultiplying:[FwiBigInt bigIntWithUnsignedValue:q]];
            while ([result isGreaterThan:dividePart]) {
                q--;
                result = [dominator bigIntByMultiplying:[FwiBigInt bigIntWithUnsignedValue:q]];
            }
            
            // Calculate remainder
            [dividePart subtract:result];
            [dividePart.data setLength:length];
            memcpy(&nominatorBytes[nominator.data.length - length], dividePart.data.bytes, dividePart.data.length);
            
            // Stored result
            uint8_t byte1 = (uint8_t)((q & 0xff00) >> 8);
            uint8_t byte2 = (uint8_t)(q & 0x00ff);
            if (byte1 > 0) {
                retPos < [quotient.data length] ? quotientBytes[retPos] = byte1 : [quotient.data appendBytes:&byte1 length:1];
                retPos++;
            }
            if (byte2 > 0) {
                retPos < [quotient.data length] ? quotientBytes[retPos] = byte2 : [quotient.data appendBytes:&byte2 length:1];
                retPos++;
            };
            
            // Prepare for next divide part
            [nominator _fixData];
        }
    }
    
    // Finalize result
    [nominator _fixData];
    [quotient.data reverseBytes];
}
+ (void)_singleByteDivideWithNominator:(FwiBigInt *)nominator dominator:(FwiBigInt *)dominator quotient:(FwiBigInt *)quotient {
    @autoreleasepool {
        // Get values
        uint8_t *nominatorBytes = (void *)[nominator.data bytes];
        uint8_t *dominatorBytes = (void *)[dominator.data bytes];
        uint8_t *quotientBytes  = (void *)[quotient.data  bytes];

        // Initialize position
        NSInteger qPos = 0;
        NSInteger pos  = [nominator.data length] - 1;

        // Initialize value
        uint16_t dividend = (uint16_t)nominatorBytes[pos];
        uint16_t divisor  = dominatorBytes[0];

        if (dividend >= divisor) {
            uint8_t q = dividend / divisor;
            if (qPos < quotient.data.length) quotientBytes[qPos] = q;
            else [quotient.data appendBytes:&q length:1];
            qPos++;

            nominatorBytes[pos] = (uint8_t)(dividend % divisor);
        }
        pos--;
        
        // Perform single byte division
        while (pos >= 0) {
            dividend = ((uint16_t)nominatorBytes[pos + 1] << 8) | (uint16_t)nominatorBytes[pos];
            uint8_t q = dividend / divisor;
            
            if (qPos < quotient.data.length) quotientBytes[qPos] = q;
            else [quotient.data appendBytes:&q length:1];
            qPos++;
            
            nominatorBytes[pos + 1] = 0x00;
            nominatorBytes[pos--] = (uint8_t)(dividend % divisor);
        }
    }

    // Finalize result
    [nominator _fixData];
    [quotient.data reverseBytes];
}


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _data = [[NSMutableData alloc] initWithCapacity:1];
        _isNegative = NO;
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
	FwiRelease(_data);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's override methods
- (NSString *)description {
    return [self descriptionWithRadix:10];
}


#pragma mark - Class's properties
- (BOOL)isNegative {
    uint8_t *bytes = (void *)[_data bytes];
    uint8_t sign   = bytes[([_data length] - 1)];
    
    return (sign == 0xff && _isNegative);
}

- (void)setData:(NSMutableData *)data {
    if (!data) return;
    FwiRelease(_data);

    _isNegative = NO;
    _data = FwiRetain(data);

    if ([_data length] > 1) {
        const uint8_t *bytes = [_data bytes];
        _isNegative = (bytes[_data.length - 1] == 0xff);
    }
}


#pragma mark - Class's public methods
- (__autoreleasing NSString *)descriptionWithRadix:(NSUInteger)radix {
	if (radix < 2 || radix > 36) radix = 10;

	NSMutableString *builder = [[NSMutableString alloc] initWithCapacity:0];
    __autoreleasing NSString *charSet = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    @autoreleasepool {
        if ([self isEqualTo:[FwiBigInt zero]]) {
            [builder appendString:@"0"];
        }
        else if ([self isEqualTo:[FwiBigInt one]]) {
            [builder appendString:@"1"];
        }
        else {
            __autoreleasing FwiBigInt *integer  = [FwiBigInt bigIntWithBigInt:self];
            __autoreleasing FwiBigInt *biRadix  = [FwiBigInt bigIntWithValue:radix];
            __autoreleasing FwiBigInt *quotient = [FwiBigInt zero];

            // Validate negative sign
            if ([self isNegative]) [integer negate];

            uint8_t *bytes = (void *)[integer.data bytes];
            while (integer.data.length > 1 || (integer.data.length == 1 && bytes[0] != 0)) {
                [FwiBigInt _singleByteDivideWithNominator:integer dominator:biRadix quotient:quotient];

                if (bytes[0] < 10) {
                    [builder insertString:[NSString stringWithFormat:@"%d", bytes[0]]
                                  atIndex:0];
                }
                else {
                    [builder insertString:[NSString stringWithFormat:@"%c", [charSet characterAtIndex:(bytes[0] - 10)]]
                                  atIndex:0];
                }

                // Prepare for next loop
                [integer.data setLength:quotient.data.length];
                bytes = (void *)[integer.data bytes];

                memcpy(bytes, quotient.data.bytes, quotient.data.length);
                [quotient.data clearBytes];
                [quotient _fixData];
            }

            // Apply negative sign
            if ([self isNegative]) [builder insertString:@"-" atIndex:0];
        }
	}

    __autoreleasing NSString *description = [NSString stringWithFormat:@"%@", [builder description]];
    FwiRelease(builder);
	return description;
}

- (__autoreleasing NSData *)encode {
    __autoreleasing NSData *data = [NSData dataWithData:_data];
    [data reverseBytes];
    return data;
}
- (__autoreleasing NSData *)encodeBase64Data {
    return [[self encode] encodeBase64Data];
}
- (__autoreleasing NSString *)encodeBase64String {
    return [[self encodeBase64Data] toString];
}


#pragma mark - Class's public methods: Comparator
- (BOOL)isEqualTo:(FwiBigInt *)bigInt {
    return [_data isEqualToData:[bigInt data]];
}

- (BOOL)isGreaterThan:(FwiBigInt *)bigInt {
	if ([self isNegative] && ![bigInt isNegative]) return NO;       // self is negative, bigInt is positive
	else if (![self isNegative] && [bigInt isNegative]) return YES; // self is positive, bigInt is negative
	
	// Same sign
    uint8_t *bytes = (void *)[_data bytes];
    uint8_t *otherBytes = (void *)[bigInt.data bytes];

    NSInteger pos = 0;
    NSInteger length = MAX([_data length], [bigInt.data length]);
	for (pos = length - 1; pos >= 0; pos--) {
        uint8_t a = (pos < [_data length] ? bytes[pos] : ([self isNegative] ? 0xff : 0x00));
        uint8_t b = (pos < [bigInt.data length] ? otherBytes[pos] : ([bigInt isNegative] ? 0xff : 0x00));

        if (a < b) return NO;
        else if (a > b) return YES;
    }
	return NO;
}
- (BOOL)isGreaterThanOrEqualTo:(FwiBigInt *)bigInt {
	return ([self isGreaterThan:bigInt] || [self isEqualTo:bigInt]);
}

- (BOOL)isLessThan:(FwiBigInt *)bigInt {
    if ([self isNegative] && ![bigInt isNegative]) return YES;      // self is negative, bigInt is positive
	else if (![self isNegative] && [bigInt isNegative]) return NO;  // self is positive, bigInt is negative
	
	// Same sign
    uint8_t *bytes = (void *)[_data bytes];
    uint8_t *otherBytes = (void *)[bigInt.data bytes];
    
	NSInteger pos = 0;
    NSInteger length = MAX([_data length], [bigInt.data length]);
    for (pos = length - 1; pos >= 0; pos--) {
        uint8_t a = (pos < [_data length] ? bytes[pos] : ([self isNegative] ? 0xff : 0x00));
        uint8_t b = (pos < [bigInt.data length] ? otherBytes[pos] : ([bigInt isNegative] ? 0xff : 0x00));

        if (a < b)      return YES;
        else if (a > b) return NO;
    }
    return NO;
}
- (BOOL)isLessThanOrEqualTo:(FwiBigInt *)bigInt {
	return ([self isLessThan:bigInt] || [self isEqualTo:bigInt]);
}


#pragma mark - Class's public methods: Basic operations
- (void)add:(FwiBigInt *)bigInt {
    /* Condition validation: add to zero result self */
    if ([bigInt isEqualTo:[FwiBigInt zero]]) return;

    @autoreleasepool {
        // Validate negative sign
        BOOL flag1 = [self isNegative];
        BOOL flag2 = [bigInt isNegative];

        //   a  + (-b) =   a - b
        if (!flag1 && flag2) {
            __autoreleasing FwiBigInt *bigIntCopy = [FwiBigInt bigIntWithBigInt:bigInt];
            [bigIntCopy negate];

            [self subtract:bigIntCopy];
        }

        // (-a) +   b  =   b - a
        else if (flag1 && !flag2) {
            __autoreleasing FwiBigInt *bigIntCopy = [FwiBigInt bigIntWithBigInt:bigInt];
            [self negate];
            
            [bigIntCopy subtract:self];
            FwiRelease(_data);
            
            _data = FwiRetain(bigIntCopy.data);
            _isNegative = [bigIntCopy isNegative];
        }

        // (-a) + (-b) = -(a + b)
        else if (flag1 && flag2) {
            __autoreleasing FwiBigInt *bigIntCopy = [FwiBigInt bigIntWithBigInt:bigInt];
            [bigIntCopy negate];
            [self negate];

            [self add:bigIntCopy];
            [self negate];
        }

        //   a  +   b  =   a + b
        else {
            // Get data
            uint8_t *bytes = (void *)[_data bytes];
            uint8_t *otherBytes = (void *)[bigInt.data bytes];

            uint8_t c = 0;
            size_t  length = MAX([_data length], [bigInt.data length]);

            for (int i = 0; i < length; i++) {
                // Get byte value at index
                uint8_t a = (i < [_data length] ? bytes[i] : ([self isNegative] ? 0xff : 0x00));
                uint8_t b = (i < [bigInt.data length] ? otherBytes[i] : ([bigInt isNegative] ? 0xff : 0x00));

                // Perform sum at index
                uint16_t sum = a + b + c;
                c = (sum & 0xff00) >> 8;

                // Update value at index
                if (i < [_data length]) bytes[i] = (uint8_t)(sum & 0x00ff);
                else [_data appendBytes:&sum length:1];
            }

            // Append carry number if there is any left
            if (c != 0x00) [_data appendBytes:&c length:1];
            [self _fixData];
        }
    }
}
- (void)subtract:(FwiBigInt *)bigInt {
    /* Condition validation: subtract to zero result self */
    if ([bigInt isEqualTo:[FwiBigInt zero]]) return;

    @autoreleasepool {
        // Validate negative sign
        BOOL flag1 = [self isNegative];
        BOOL flag2 = [bigInt isNegative];

        //  a - (-b) =   a + b
        if (!flag1 && flag2) {
            __autoreleasing FwiBigInt *bigIntCopy = [FwiBigInt bigIntWithBigInt:bigInt];
            [bigIntCopy negate];

            [self add:bigIntCopy];
        }

        // -a -   b  = -(a + b)
        else if (flag1 && !flag2) {
            __autoreleasing FwiBigInt *bigIntCopy = [FwiBigInt bigIntWithBigInt:bigInt];
            [bigIntCopy negate];
            [self negate];

            [self add:bigIntCopy];
            [self negate];
        }

        // -a - (-b) =   b - a
        else if (flag1 && flag2) {
            __autoreleasing FwiBigInt *bigIntCopy = [FwiBigInt bigIntWithBigInt:bigInt];
            [bigIntCopy negate];
            [self negate];
            
            [bigIntCopy subtract:self];
            FwiRelease(_data);
            
            _data = FwiRetain(bigIntCopy.data);
            _isNegative = bigIntCopy.isNegative;
        }

        //  a -   b  =   a - b
        else {
            // Get data
            uint8_t *bytes = (void *)[_data bytes];
            uint8_t *otherBytes = (void *)[bigInt.data bytes];

            uint8_t c = 0;
            int16_t diff = 0;
            size_t  length = MAX([_data length], [bigInt.data length]);

            for (int i = 0; i < length; i++) {
                // Get byte value at index
                uint16_t a = (i < [_data length] ? bytes[i] : ([self isNegative] ? 0xff : 0x00));
                uint16_t b = (i < [bigInt.data length] ? otherBytes[i] : ([bigInt isNegative] ? 0xff : 0x00));

                // Perform subtract at index
                diff = a - b - c;
                c = diff < 0 ? 1 : 0;

                // Update value at index
                if (i < [_data length]) bytes[i] = (uint8_t)(diff & 0x00ff);
                else [_data appendBytes:&diff length:1];
            }

            // Append carry number if there is any left
            if (c != 0) {
                c = 0xff;
                _isNegative = YES;
                [_data appendBytes:&c length:1];
            }
            [self _fixData];
        }
    }
}
- (void)divide:(FwiBigInt *)bigInt {
    @autoreleasepool {
        /* Condition validation: divide by zero result nan */
        if ([bigInt isEqualTo:[FwiBigInt zero]]) return;
        
        /* Condition validation: divide by one result self */
        if ([bigInt isEqualTo:[FwiBigInt one]]) return;

        // Check negative sign
        BOOL selfNegative = [self isNegative];
        BOOL othrNegative = [bigInt isNegative];
        BOOL isNegative   = (selfNegative | othrNegative);

        if (selfNegative && othrNegative) isNegative = NO;
        if (selfNegative) [self negate];
        if (othrNegative) [bigInt negate];

        // Perform divide operation
        __autoreleasing FwiBigInt *quotient = [FwiBigInt zero];
        
        if ([self isLessThan:bigInt]) {
            [_data clearBytes];
            [self _fixData];
        }
        else {
            if ([bigInt.data length] == 1) [FwiBigInt _singleByteDivideWithNominator:self dominator:bigInt quotient:quotient];
            else [FwiBigInt _multiBytesDivideWithNominator:self dominator:bigInt quotient:quotient];
        }

        // Finalize result
        FwiRelease(_data);
        _data = FwiRetain(quotient.data);

        // Apply negative sign if neccessary
        if (isNegative) [self negate];
    }
}
- (void)multiply:(FwiBigInt *)bigInt {
    @autoreleasepool {
        /* Condition validation: zero multiply to any number is zero */
        if ([self isEqualTo:[FwiBigInt zero]]) return;

        /* Condition validation: multiply with one result self */
        if ([bigInt isEqualTo:[FwiBigInt one]]) return;

        /* Condition validation: multiply with zero, result is zero */
        if ([bigInt isEqualTo:[FwiBigInt zero]]) {
            [_data clearBytes];
            [self _fixData];
            return;
        }

        /* Condition validation: one multiply with other number */
        if ([self isEqualTo:[FwiBigInt one]]) {
            [_data setLength:bigInt.data.length];
            memcpy((void *)_data.bytes, bigInt.data.bytes, bigInt.data.length);
            return;
        }

        // Check negative sign
        BOOL selfNegative  = [self isNegative];
        BOOL otherNegative = [bigInt isNegative];
        BOOL isNegative    = (selfNegative | otherNegative);

        if (selfNegative && otherNegative) isNegative = NO;
        if (selfNegative)  [self negate];
        if (otherNegative) [bigInt negate];


        // Create container
        NSMutableData *container = [[NSMutableData alloc] initWithCapacity:_data.length];
        [container setLength:_data.length];

        // Get values
        uint8_t *result     = (void *)[container bytes];
        uint8_t *bytes      = (void *)[_data bytes];
        uint8_t *otherBytes = (void *)[bigInt.data bytes];

        for (size_t i = 0; i < [bigInt.data length]; i++) {
            for (size_t j = 0; j < [_data length]; j++) {
                // Get byte value at index
                uint8_t a = (j < [_data length] ? bytes[j] : ([self isNegative] ? 0xff : 0x00));
                uint8_t b = (i < [bigInt.data length] ? otherBytes[i] : ([bigInt isNegative] ? 0xff : 0x00));

                // Perform multiply at index
                uint16_t product = a * b;

                // Perform add from index
                // i[0][1][2][3][4][5]
                // j[0][1][2][3][4][5]
                uint16_t   carry = 0;
                NSUInteger index = i + j;
                while (product > 0 || carry > 0) {
                    uint16_t sum = (index < [container length] ? result[index] : 0) + (uint8_t)(product & 0x00ff) + carry;
                    carry = sum >> 8;

                    if (index < [container length]) result[index] = (uint8_t)(sum & 0x00ff);
                    else [container appendBytes:&sum length:1];
                    product >>= 8;
                    index++;
                }
                // Advance to next step
                if (carry) [container appendBytes:&carry length:1];
            }
        }

        // Finalize result
        FwiRelease(_data);
        _data = container;

        // Apply negative sign if neccessary
        if (isNegative) [self negate];
    }
}


#pragma mark - Class's public methods: Bitwise operations
- (void)negate {
    /* Condition validation: If this is positive number, we have to add 0xff at the end */
    BOOL isPositive = ![self isNegative];

    uint8_t *bytes = (void *)[_data bytes];
	for (size_t i = 0; i < [_data length]; i++) {
		bytes[i] = ~bytes[i];
	}

	// Add 1 unit lost during the flipping process
	uint8_t carry = 0;
	for (size_t i = 0; i < [_data length]; i++) {
		uint16_t sum = bytes[i] + 1 + carry;
		carry = sum >> 8;

		bytes[i] = (uint8_t)(sum & 0x00ff);
		if (carry == 0) break;
	}
    [self _fixData];

    if (isPositive) {
        _isNegative = YES;
        uint8_t negativeSign = 0xff;
        [_data appendBytes:&negativeSign length:1];
    }
    else {
        _isNegative = NO;
    }
}
- (void)shiftLeft:(NSUInteger)shiftValue {
    /* Condition validation */
    if (shiftValue == 0) return;

    // Get values
    uint8_t *bytes = (void *)[_data bytes];

    // Perform shift operation
    for (NSUInteger counter = 0; counter < shiftValue; counter++) {
        uint8_t carry = 0;

        for (NSInteger idx = 0; idx < [_data length]; idx++) {
            uint8_t a = bytes[idx];
            uint16_t value = a << 1 | carry;
            carry = (value & 0xff00) >> 8;

            if (idx < [_data length]) bytes[idx] = (uint8_t)(value & 0x00ff);
            else [_data appendBytes:&value length:1];
        }

        // Append carry value if it is not zero
        if (carry != 0) [_data appendBytes:&carry length:1];
    }
}
- (void)shiftRight:(NSUInteger)shiftValue {
    /* Condition validation */
    if (shiftValue == 0) return;

    // Get values
    uint8_t *bytes = (void *)[_data bytes];

    // Perform shift operation
    for (NSUInteger counter = 0; counter < shiftValue; counter++) {
        uint16_t carry = 0;

        for (NSInteger idx = ([_data length] - 1); idx >= 0; idx--) {
            uint8_t a = bytes[idx];
            uint16_t value = a << 7 | (carry << 8);
            carry = (uint8_t)(value & 0x00ff);

            bytes[idx] = (uint8_t)((value & 0xff00) >> 8);
        }
        [self _fixData];
        if ([self isEqualTo:[FwiBigInt zero]]) break;
    }
}

- (void)and:(FwiBigInt *)bigInt {
    /* Condition validation */
    if (!bigInt) return;

    [self _performBitwise:kBitwise_AND
                   source:_data
         isSourceNegative:[self isNegative]
                    value:[bigInt data]
          isValueNegative:[bigInt isNegative]];
}
- (void) or:(FwiBigInt *)bigInt {
    /* Condition validation */
    if (!bigInt) return;

    [self _performBitwise:kBitwise_OR
                   source:_data
         isSourceNegative:[self isNegative]
                    value:[bigInt data]
          isValueNegative:[bigInt isNegative]];
}
- (void)xor:(FwiBigInt *)bigInt {
    /* Condition validation */
    if (!bigInt) return;

    [self _performBitwise:kBitwise_XOR
                   source:_data
         isSourceNegative:[self isNegative]
                    value:[bigInt data]
          isValueNegative:[bigInt isNegative]];
}
- (void)not {
	[self _performBitwise:kBitwise_NOT
                   source:_data
         isSourceNegative:[self isNegative]
                    value:_data
          isValueNegative:[self isNegative]];
}


#pragma mark - Class's public methods: Other operations
- (void)mod:(FwiBigInt *)bigInt {
    @autoreleasepool {
        /* Condition validation: divide by zero result nan */
        if ([bigInt isEqualTo:[FwiBigInt zero]]) return;

        /* Condition validation: divide by one result self */
        if ([bigInt isEqualTo:[FwiBigInt one]]) return;

        if ([self isNegative]  ) [self negate];
        if ([bigInt isNegative]) [bigInt negate];

        // Perform divide operation
        __autoreleasing FwiBigInt *quotient = [FwiBigInt zero];

        if ([self isLessThan:bigInt]) {
            // Do nothing
        }
        else {
            if ([bigInt.data length] == 1) [FwiBigInt _singleByteDivideWithNominator:self dominator:bigInt quotient:quotient];
            else [FwiBigInt _multiBytesDivideWithNominator:self dominator:bigInt quotient:quotient];
        }
    }
}
- (void)abs {
    if ([self isNegative]) [self negate];
}
- (void)sqrt {
    @autoreleasepool {
        /* Condition validation: Square root of zero is zero */
        if ([self isEqualTo:[FwiBigInt zero]]) return;

        /* Condition validation: Square root of one is one */
        if ([self isEqualTo:[FwiBigInt zero]]) return;

        /* Condition validation: Square root of negative number is error */
        if ([self isNegative]) {
            [_data setLength:1];
            [_data clearBytes];
            _isNegative = NO;
            return;
        }

        NSUInteger numBits = [self _bitCount];

        // Odd number of bits
        if ((numBits & 0x1) != 0) numBits = (numBits >> 1) + 1;
        else numBits = (numBits >> 1);

        NSUInteger bytePos = numBits / 8;
        NSUInteger bitPos  = numBits % 8;

        // Prepare to guess
        uint8_t mask = 0x80;
        if (bitPos == 0) {
            mask = 0x80;
        }
        else {
            mask = (1 << bitPos);
            bytePos++;
        }

        // Perform guess
        __autoreleasing FwiBigInt *result = [FwiBigInt zero];
        [result.data setLength:bytePos];

        uint8_t *data = (void *)result.data.bytes;
        for (NSInteger i = (bytePos - 1); i >= 0; i--) {
            while (mask != 0) {
                data[i] = data[i] ^ mask;

                FwiBigInt *other = [FwiBigInt bigIntWithBigInt:result];
                [other multiply:result];

                // undo the guess if its square is larger than this
                if ([other isGreaterThan:self]) data[i] = data[i] ^ mask;
                mask >>= 1;
            }
            mask = 0x80;
        }

        // Finalize result
        FwiRelease(_data);
        _data = FwiRetain(result.data);
    }
}


#pragma mark - Class's private methods
- (NSUInteger)_bitCount {
    /* Condition validation: If self is zero, return 0 */
    if ([self isEqualTo:[FwiBigInt zero]]) return 0;

    /* Condition validation: If self is one, return 1 */
    if ([self isEqualTo:[FwiBigInt one]]) return 1;

    // Get the most left byte on the right
    const uint8_t *data = _data.bytes;
    uint8_t lastByte = [self isNegative] ? data[_data.length - 2] : data[_data.length - 1];

    // Find the most significant bit
    size_t pos = 8;
	uint8_t mask = 0x80;
	while (pos > 0 && (lastByte & mask) == 0) {
        mask >>= 1;
        pos--;
	}

	pos += (([self isNegative] ? (_data.length - 2) : (_data.length - 1)) * 8);
	return pos;
}

- (void)_fixData {
    const uint8_t *bytes = [_data bytes];

    // Fix data length
    size_t reduce = 0;
	for (NSUInteger i = ([_data length] - 1); i >= 1; i--) {
        if (bytes[i] == 0x00) reduce++;
        else break;
    }
    [_data setLength:([_data length] - reduce)];
}
- (void)_performBitwise:(Bitwise)bitwise source:(NSMutableData *)source isSourceNegative:(BOOL)isSourceNegative value:(NSMutableData *)value isValueNegative:(BOOL)isValueNegative {
    // Get values
    uint8_t *bytes      = (void *)[source bytes];
    uint8_t *otherBytes = (void *)[value bytes];

	size_t length = MAX(source.length, value.length);
	for (size_t i = 0; i < length; i++) {
        // Get byte value at index
        uint8_t a = (i < [source length] ? bytes[i] : (isSourceNegative ? 0xff : 0x00));
        uint8_t b = (i < [value length] ? otherBytes[i] : (isValueNegative ? 0xff : 0x00));

        uint8_t c = 0;
        switch (bitwise) {
            case kBitwise_AND: c = a & b; break;
            case kBitwise_NOT: c = ~a   ; break;
            case kBitwise_OR : c = a | b; break;
            case kBitwise_XOR: c = a ^ b; break;
            default:
                break;
        }
        if (i < [source length]) bytes[i] = c;
        else [source appendBytes:&c length:1];
	}
    [self _fixData];
}


#pragma mark - NSCoding's members
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self && aDecoder) {
        _data = FwiRetain([aDecoder decodeObjectForKey:@"_data"]);
        _isNegative = [aDecoder decodeBoolForKey:@"_isNegative"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (!aCoder) return;
    [aCoder encodeObject:_data forKey:@"_data"];
    [aCoder encodeBool:_isNegative forKey:@"_isNegative"];
}


@end


@implementation FwiBigInt (FwiBigIntCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiBigInt *)bigIntWithValue:(long long)value {
	return FwiAutoRelease([[FwiBigInt alloc] initWithValue:value]);
}
+ (__autoreleasing FwiBigInt *)bigIntWithUnsignedValue:(unsigned long long)value {
	return FwiAutoRelease([[FwiBigInt alloc] initWithUnsignedValue:value]);
}

+ (__autoreleasing FwiBigInt *)bigIntWithInteger:(NSInteger)value {
    return FwiAutoRelease([[FwiBigInt alloc] initWithValue:value]);
}
+ (__autoreleasing FwiBigInt *)bigIntWithUnsignedInteger:(NSUInteger)value {
    return FwiAutoRelease([[FwiBigInt alloc] initWithUnsignedValue:value]);
}

+ (__autoreleasing FwiBigInt *)one {
    return FwiAutoRelease([[FwiBigInt alloc] initWithValue:1]);
}
+ (__autoreleasing FwiBigInt *)zero {
    return FwiAutoRelease([[FwiBigInt alloc] initWithValue:0]);
}

+ (__autoreleasing FwiBigInt *)bigIntWithBigInt:(FwiBigInt *)bigInt {
	return FwiAutoRelease([[FwiBigInt alloc] initWithBigInt:bigInt]);
}
+ (__autoreleasing FwiBigInt *)bigIntWithString:(NSString *)value radix:(NSUInteger)radix {
	return FwiAutoRelease([[FwiBigInt alloc] initWithString:value radix:radix]);
}
+ (__autoreleasing FwiBigInt *)bigIntWithData:(NSData *)data shouldReverse:(BOOL)shouldReverse {
    __autoreleasing NSMutableData *copyData = [NSMutableData dataWithData:data];
    if (shouldReverse) [copyData reverseBytes];

    __autoreleasing FwiBigInt *integer = [FwiBigInt zero];
    [integer setData:copyData];
    return integer;
}


#pragma mark - Class's constructors
- (id)initWithBigInt:(FwiBigInt *)bigInt {
    self = [super init];
	if(self) {
        if (bigInt) {
            _data = [[NSMutableData alloc] initWithBytes:bigInt.data.bytes length:bigInt.data.length];
            _isNegative = [bigInt isNegative];
        }
        else {
            _data = [[NSMutableData alloc] initWithCapacity:1];

            uint8_t value = 0x00;
            [_data appendBytes:&value length:1];
        }
	}
	return self;
}
- (id)initWithString:(NSString *)string radix:(NSUInteger)radix {
    self = [self init];
	if(self) {
        if (radix < 2 || radix > 36) radix = 10;
        [_data setLength:1];

		FwiBigInt *multiplier = [FwiBigInt bigIntWithValue:radix];
		string = [string uppercaseString];

		NSUInteger limit = 0;
		if ([string characterAtIndex:0] == '-') limit = 1;

		for (NSInteger i = limit; i < string.length; i++) {
			NSInteger posVal = (NSInteger)[string characterAtIndex:i];

			if (posVal >= '0' && posVal <= '9') posVal -= '0';
			else if (posVal >= 'A' && posVal <= 'Z') posVal = (posVal - 'A') + 10;
			else posVal = 9999999;

            __autoreleasing FwiBigInt *number = [FwiBigInt bigIntWithValue:posVal];
            [self multiply:multiplier];
            [self add:number];
		}

        // Validate negative sign
        if ([string characterAtIndex:0] == '-') [self negate];
	}
	return self;
}

- (id)initWithValue:(long long)value {
	self = [self init];
	if (self) {
		for (NSUInteger i = 0; i < sizeof(long long); i++) {
            [_data appendBytes:&value length:1];
            value >>= 8;

            // Break condition validation
            if (value == -1) {
                [_data appendBytes:&value length:1];
                _isNegative = YES;
                break;
            }
            else if (!value) break;
		}
	}
	return self;
}
- (id)initWithUnsignedValue:(unsigned long long)value {
	self = [self init];
	if (self) {
        for (NSUInteger i = 0; i < sizeof(unsigned long long); i++) {
            [_data appendBytes:&value length:1];
            value >>= 8;

            // Break condition validation
            if (!value) break;
        }
        [self _fixData];
	}
	return self;
}


@end


@implementation FwiBigInt (FwiExtension)

- (__autoreleasing FwiBigInt *)bigIntByAdding:(FwiBigInt *)bigInt {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer add:bigInt];
    return integer;
}
- (__autoreleasing FwiBigInt *)bigIntBySubtracting:(FwiBigInt *)bigInt {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer subtract:bigInt];
    return integer;
}
- (__autoreleasing FwiBigInt *)bigIntByDividing:(FwiBigInt *)bigInt {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer divide:bigInt];
    return integer;
}
- (__autoreleasing FwiBigInt *)bigIntByMultiplying:(FwiBigInt *)bigInt {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer multiply:bigInt];
    return integer;
}

- (__autoreleasing FwiBigInt *)bigIntByNegate {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer negate];
    return integer;
}
- (__autoreleasing FwiBigInt *)bigIntByShiftLeft:(NSUInteger)shiftValue {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer shiftLeft:shiftValue];
    return integer;
}
- (__autoreleasing FwiBigInt *)bigIntByShiftRight:(NSUInteger)shiftValue {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer shiftRight:shiftValue];
    return integer;
}

- (__autoreleasing FwiBigInt *)bigIntByBitwiseAND:(FwiBigInt *)bigInt {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer and:bigInt];
    return integer;
}
- (__autoreleasing FwiBigInt *)bigIntByBitwiseOR :(FwiBigInt *)bigInt {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer or:bigInt];
    return integer;
}
- (__autoreleasing FwiBigInt *)bigIntByBitwiseXOR:(FwiBigInt *)bigInt {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer xor:bigInt];
    return integer;
}
- (__autoreleasing FwiBigInt *)bigIntByBitwiseNOT {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer not];
    return integer;
}

- (__autoreleasing FwiBigInt *)bigIntByModulus:(FwiBigInt *)bigInt {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer mod:bigInt];
    return integer;
}
- (__autoreleasing FwiBigInt *)bigIntByAbsolute {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer abs];
    return integer;
}
- (__autoreleasing FwiBigInt *)bigIntBySquareRoot {
    /* Condition validation */
    if (!self) return nil;

    __autoreleasing FwiBigInt *integer = [FwiBigInt bigIntWithBigInt:self];
    [integer sqrt];
    return integer;
}


@end