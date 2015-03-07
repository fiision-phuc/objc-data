#import "FwiRS_Private.h"


#define RSPrimitive     0x011d
#define RSSize          0x100


@interface FwiRS_Private () {
    
    uint8_t *_expTable;
	uint8_t *_logTable;
	
    NSData  *_zero;
    NSData  *_one;
}

- (NSData *)_generatorCoefficients:(uint8_t)degree;

- (NSData *)_GF256_buildMonomial:(uint8_t)degree coefficient:(uint8_t)coefficient;
- (uint8_t )_GF256_inverse:(uint8_t)a;
- (uint8_t )_GF256_multiply:(uint8_t)a by:(uint8_t)b;

- (NSData  *)_GF256Poly:(const uint8_t *)coefficients length:(NSUInteger)length;
- (NSData  *)_GF256Poly_addOrSubtractCoefficients:(NSData *)a coefficients:(NSData *)b;
- (NSData  *)_GF256Poly_multiplyCoefficients:(NSData *)a byCoefficients:(NSData *)b;
- (NSData  *)_GF256Poly_multiplyCoefficients:(NSData *)a byMonomialDegree:(uint8_t)degree coefficient:(uint8_t)coefficient;
- (NSData  *)_GF256Poly_multiplyCoefficients:(NSData *)a byScalar:(uint8_t)scalar;
- (NSArray *)_GF256Poly_divideCoefficients:(NSData *)a byCoefficients:(NSData *)b;

@end


@implementation FwiRS_Private


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
	if (self) {
		_expTable = malloc(RSSize);
		_logTable = malloc(RSSize);
		bzero(_expTable, RSSize);
		bzero(_logTable, RSSize);
		
		// Generate exponents table
		NSUInteger x = 1;
		for (NSUInteger i = 0; i < RSSize; i++) {
			_expTable[i] = x;
			x <<= 1;
			if (x >= RSSize) x ^= RSPrimitive;
		}
		
		// Generate log table
		for (NSUInteger i = 0; i < (RSSize - 1); i++) {
			_logTable[_expTable[i]] = i;
		}
		
		// Generate GF zero and GF one
		uint8_t gf0 = 0;
		uint8_t gf1 = 1;
		_zero = [[NSData alloc] initWithBytes:&gf0 length:1];
		_one  = [[NSData alloc] initWithBytes:&gf1 length:1];
		
		// Initialize cache generators
		_cachedGenerators = [[NSMutableArray alloc] initWithCapacity:1];
		[_cachedGenerators addObject:_one];
	}
	return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    if (_expTable) free(_expTable);
	if (_logTable) free(_logTable);
    
    FwiRelease(_cachedGenerators);
    FwiRelease(_zero);
    FwiRelease(_one);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (NSData *)encode:(const uint8_t *)data length:(NSUInteger)length ECByteCount:(NSUInteger)ecByteCount {
    NSData *generatorCoefficients = [self _generatorCoefficients:ecByteCount];
	
	uint8_t *infoCoefficients = malloc(length);
	bzero(infoCoefficients, length);
	memcpy(infoCoefficients, data, length);
	
    NSData *info = [self _GF256Poly:infoCoefficients length:length];
	info = [self _GF256Poly_multiplyCoefficients:info byMonomialDegree:ecByteCount coefficient:1];
	bzero(infoCoefficients, length);
	free(infoCoefficients);
	
    NSData *remainder = (NSData *)[self _GF256Poly_divideCoefficients:info byCoefficients:generatorCoefficients][1];
	uint8_t *infoBytes = (void *)[info bytes];
	memcpy(&infoBytes[length], [remainder bytes], [remainder length]);
	
	uint8_t *finalBytes = malloc(ecByteCount);
	bzero(finalBytes, ecByteCount);
	memcpy(finalBytes, &infoBytes[length], ecByteCount);
    NSData *final = [NSData dataWithBytesNoCopy:finalBytes length:ecByteCount freeWhenDone:YES];
	
	return final;
}


#pragma mark - Class's private methods
- (NSData *)_generatorCoefficients:(uint8_t)degree {
	if (degree >= [_cachedGenerators count]) {
        NSData *lastGenerator = _cachedGenerators[[_cachedGenerators count] - 1];
		
		for (NSUInteger d = [_cachedGenerators count]; d <= degree; d++) {
			const uint8_t a[2] = { 1, _expTable[d - 1]};
			
            NSData *nextGenerator = [self _GF256Poly_multiplyCoefficients:lastGenerator byCoefficients:[NSData dataWithBytes:a length:2]];
			[_cachedGenerators addObject:nextGenerator];
			lastGenerator = nextGenerator;
		}
	}
	return (NSData *)_cachedGenerators[degree];
}

- (NSData *)_GF256_buildMonomial:(uint8_t)degree coefficient:(uint8_t)coefficient {
	if (coefficient == 0) return _zero;
    
	uint8_t *coefficients = malloc(degree + 1);
	bzero(coefficients, degree + 1);
	coefficients[0] = coefficient;
	
    NSData *d = [self _GF256Poly:(const uint8_t *)coefficients length:degree + 1];
	free(coefficients);
	return d;
}
- (uint8_t)_GF256_inverse:(uint8_t)a {
    uint8_t m = 0;
	
	if (a != 0) m = _expTable[255-_logTable[a]];
	return m;
}
- (uint8_t)_GF256_multiply:(uint8_t)a by:(uint8_t)b {
	uint8_t m = 0;
	
	if (a != 0 && b != 0) {
		uint16_t logSum = _logTable[a] + _logTable[b];
		m = _expTable[(logSum & 0xff) + (logSum >> 8)];
	}
	return m;
}

- (NSData *)_GF256Poly:(const uint8_t *)coefficients length:(NSUInteger)length {
    if (!coefficients || length == 0) return nil;
    
	if (length > 1 && coefficients[0] == 0) {
		NSUInteger firstNonZero = 1;
		while (firstNonZero < length && coefficients[firstNonZero] == 0) firstNonZero++;
		
		if (firstNonZero == length) return _zero;
		else {
			NSUInteger l = length - firstNonZero;
			uint8_t *c = malloc(l);
			bzero(c, l);
			
			memcpy(c, &coefficients[firstNonZero], l);
			return [NSData dataWithBytesNoCopy:c length:l freeWhenDone:YES];
		}
	}
	else return [NSData dataWithBytes:coefficients length:length];
}
- (NSData *)_GF256Poly_addOrSubtractCoefficients:(NSData *)a coefficients:(NSData *)b {
	const uint8_t *ab = [a bytes];
	const uint8_t *bb = [b bytes];
	
	if (ab[0] == 0) return b;
	else if (bb[0] == 0) return a;
	else {
        NSData *smallerCoefficients = a;
		NSData *largerCoefficients  = b;
		
		if ([smallerCoefficients length] > [largerCoefficients length]) {
            NSData *temp = smallerCoefficients;
			smallerCoefficients = largerCoefficients;
			largerCoefficients = temp;
		}
		
		uint8_t *sumDiff = malloc([largerCoefficients length]);
		bzero(sumDiff, [largerCoefficients length]);
		
		NSUInteger lengthDiff = [largerCoefficients length] - [smallerCoefficients length];
		const uint8_t *largerCoefficientsb  = [largerCoefficients bytes];
		const uint8_t *smallerCoefficientsb = [smallerCoefficients bytes];
		memcpy(sumDiff, largerCoefficientsb, lengthDiff);
		
		for (NSUInteger i = lengthDiff; i < [largerCoefficients length]; i++) {
			sumDiff[i] = smallerCoefficientsb[i - lengthDiff] ^ largerCoefficientsb[i];
		}
        NSData *d = [self _GF256Poly:(const uint8_t *)sumDiff length:[largerCoefficients length]];
		free(sumDiff);
		return d;
	}
}
- (NSData *)_GF256Poly_multiplyCoefficients:(NSData *)a byCoefficients:(NSData *)b {
	const uint8_t *ab = [a bytes];
	const uint8_t *bb = [b bytes];
	
    if (ab[0] == 0 || bb[0] == 0) return _zero;
    else {
		uint8_t *p = malloc([a length] + [b length] - 1);
		bzero(p, [a length] + [b length] - 1);
		
		for (NSUInteger i = 0; i < [a length]; i++) {
			for (NSUInteger j = 0; j < [b length]; j++) {
				p[i+j] ^= [self _GF256_multiply:ab[i] by:bb[j]];
			}
		}
		
        NSData *d = [self _GF256Poly:(const uint8_t *)p length:([a length] + [b length] - 1)];
		free(p);
		return d;
	}
}
- (NSData *)_GF256Poly_multiplyCoefficients:(NSData *)a byMonomialDegree:(uint8_t)degree coefficient:(uint8_t)coefficient {
    if (coefficient == 0) return _zero;
    else {
		NSUInteger	  size = [a length] + degree;
		const uint8_t *ab  = [a bytes];
		uint8_t		  *p   = malloc(size);
		bzero(p, size);
		
		for (NSUInteger i = 0; i < [a length]; i++) {
			uint8_t result = [self _GF256_multiply:ab[i] by:coefficient];
			p[i] = result;
		}
		
        NSData *d = [self _GF256Poly:(const uint8_t *)p length:([a length] + degree)];
		free(p);
		return d;
	}
}
- (NSData *)_GF256Poly_multiplyCoefficients:(NSData *)a byScalar:(uint8_t)scalar {
	if (scalar == 0) return _zero;
	else if (scalar == 1) return a;
	else {
		const uint8_t *ab = [a bytes];
		uint8_t *p = malloc([a length]);
		bzero(p, [a length]);
		
		for (NSUInteger i = 0; i < [a length]; i++) {
			p[i] = [self _GF256_multiply:ab[i] by:scalar];
		}
		
        NSData *d = [self _GF256Poly:(const uint8_t *)p length:[a length]];
		free(p);
		return d;
	}
}
- (NSArray *)_GF256Poly_divideCoefficients:(NSData *)a byCoefficients:(NSData *)b {
	const uint8_t *bb = [b bytes];
	if (bb[0] == 0) return nil;
    
    NSData *quotient  = _zero;
    NSData *remainder = a;
	
	uint8_t denominatorLeadingTerm = bb[[b length] - 1 - ([b length] - 1)];
	uint8_t inverseDenominatorLeadingTerm = [self _GF256_inverse:denominatorLeadingTerm];

    uint8_t *rb = malloc(1); bzero(rb, 1);
    [remainder getBytes:rb length:1];

	while ((([remainder length] - 1) >= ([b length] - 1)) && rb[0] != 0) {
		uint8_t degreeDifference = ([remainder length] - 1) - ([b length] - 1);
		uint8_t scale = [self _GF256_multiply:rb[[remainder length] - 1 - ([remainder length] - 1)] by:inverseDenominatorLeadingTerm];
		
        NSData *term  = [self _GF256Poly_multiplyCoefficients:b byMonomialDegree:degreeDifference coefficient:scale];
        NSData *iterationQuotient = [self _GF256_buildMonomial:degreeDifference coefficient:scale];
		
		quotient  = [self _GF256Poly_addOrSubtractCoefficients:quotient coefficients:iterationQuotient];
		remainder = [self _GF256Poly_addOrSubtractCoefficients:remainder coefficients:term];
        
        [remainder getBytes:rb length:1];
	}
	free(rb);
    
    NSArray *array = @[quotient, remainder];
	return array;
}


#pragma mark - Class's notification handlers


@end
