#import <math.h>
#import "FwiQRCode.h"
#import "FwiRS_Private.h"


@interface FwiQRCode () {
    
    FwiBitMatrix       *_bufferMatrix;      // For available bit validation
    FwiBitMatrix       *_matrix;
    FwiMutableBitArray *_data;
    
    NSInteger _totalDC;						// Total data codewords
	NSInteger _totalDB;						// Total data input count in bytes
	NSInteger _totalECC;					// Total error correction codewords
	NSInteger _RSBlocks;					// Number of Reed Solomon blocks
}


/**
 * Convert input text into binary data
 */
- (void)_generateData:(NSString *)text;

/**
 * Convert character into value for alphanumeric mode
 */
- (uint8_t)_alphanumeric:(unichar)character;

/**
 * Return the number of bits that will be used to hold the length of input data.
 */
- (NSUInteger)_calculateBitCountForLengthInfo;

/**
 * Return the length of the content in byte(s).
 */
- (NSUInteger)_calculateByteCountForText:(NSString *)text mode:(FwiQRMode)mode;

/**
 * Build 2D matrix of QR Code from "dataBits" with "version", and "ecLevel".
 */
- (void)_buildMatrixWithData:(NSData *)data;

/**
 * Embed basic patterns:
 *	- Position detection patterns
 *  - Position adjustment patterns
 *	- Timing patterns
 *	- Dark dot at the left bottom corner
 */
- (void)_embedBasicPatterns;
- (void)_embedPositionAdjustmentPattern;
- (void)_embedPositionDetectionPatternFromCoordX:(NSUInteger)coordX coordY:(NSUInteger)coordY;

/**
 * Embed type information. On success, modify the matrix.
 */
- (void)_embedTypeInfoWithMaskPattern:(NSUInteger)maskPattern;

/**
 * Embed version information if need be. See 8.10 of JISX0510:2004 (p.47) for how to embed version
 * information.
 */
- (void)_embedVersion:(FwiQRVersion)version;

/**
 * Embed "dataBits" using "getMaskPattern". On success, modify the matrix. See 8.7 of JISX0510:2004
 * (p.38) for how to embed data bits.
 */
- (void)_embedDataBits:(FwiBitArray *)dataBits maskPattern:(NSUInteger)maskPattern;

/**
 * Apply mask penalty rule 1 and return the penalty. Find repetitive cells with the same color and
 * give penalty to them. Example: 00000 or 11111.
 */
- (NSUInteger)_applyMaskPenaltyRule1;

/**
 * Apply mask penalty rule 2 and return the penalty. Find 2x2 blocks with the same color and give
 * penalty to them.
 */
- (NSUInteger)_applyMaskPenaltyRule2;

/**
 * Apply mask penalty rule 3 and return the penalty. Find consecutive cells of 00001011101 or
 * 10111010000, and give penalty to them. If we find patterns like 000010111010000, we give
 * penalties twice (i.e. 40 * 2).
 */
- (NSUInteger)_applyMaskPenaltyRule3;

/**
 * Apply mask penalty rule 4 and return the penalty. Calculate the ratio of dark cells and give
 * penalty if the ratio is far from 50%. It gives 10 penalty for 5% distance.
 */
- (NSUInteger)_applyMaskPenaltyRule4;

- (NSUInteger)_applyMaskPenaltyRule1Internal:(FwiBitMatrix *)matrix isHorizontal:(BOOL)isHorizontal;
- (NSUInteger)_calculateBCHCode:(NSUInteger)value typeInfoPoly:(uint16_t)infoPoly;
- (NSUInteger)_findMSBSet:(NSUInteger)value;

@end


@implementation FwiQRCode


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        // Initial global public variables
        _mode    = kMode_Bytes;
        _level   = kECLevel_L;
        _version = kVersion_1;
        
        // Initial global private variables
        _totalDB  = 0;
        _totalDC  = 0;
        _totalECC = 0;
        _RSBlocks = 0;
        
        _matrix   = nil;
        _data     = nil;
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    FwiRelease(_bufferMatrix);
    FwiRelease(_matrix);
    FwiRelease(_data);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (void)encode {
    @autoreleasepool {
        /**
         * Step 5: Terminate the bits properly. Not appended if max data length is reached for the given
         * version and level.
         */
        if (([_data bitCount] + 4) < (_totalDB << 3)) {
            uint8_t t = 0x00;
            [_data appendBytes:&t bitCount:4 byteCount:1];
        }
        
        // Round up to the next byte
        [_data finalizeArray];
        
        // Pattern fill: alternately 11101100 and 00010001
        const uint8_t f[2] = {0xec, 0x11};
        NSUInteger n = 0;

        for (NSUInteger i = [_data byteCount]; i < _totalDB; i++) {
            [_data appendBytes:&f[n] bitCount:8 byteCount:1];
            n = (n + 1) % 2;
        }
        
        
        /**
         * Step 6: Interleave data bits with error correction code.
         */
        // Group1 calculation
        NSUInteger g1_RSBlocks	 = _RSBlocks - (_totalDC % _RSBlocks);
        NSUInteger g1_dataBytes	 = _totalDB / _RSBlocks;
        NSUInteger g1_totalBytes = _totalDC / _RSBlocks;
        NSUInteger g1_ECBytes	 = g1_totalBytes - g1_dataBytes;
        
        // Group2 calculation
        NSUInteger g2_dataBytes	 = g1_dataBytes  + 1;
        NSUInteger g2_totalBytes = g1_totalBytes + 1;
        NSUInteger g2_ECBytes	 = g2_totalBytes - g2_dataBytes;
        
        // Data & ec codewords place holders
        NSMutableArray *data = [NSMutableArray arrayWithCapacity:_RSBlocks];
        NSMutableArray *ec = [NSMutableArray arrayWithCapacity:_RSBlocks];
        FwiRS_Private *codec = [[FwiRS_Private alloc] init];

        for (NSUInteger i = 0; i < _RSBlocks; i++) {
            NSData *d = nil;
            NSData *e = nil;
            
            if (i < g1_RSBlocks) {
                uint8_t *bytes = malloc(g1_dataBytes);
                bzero(bytes, g1_dataBytes);
                
                memcpy(bytes, &[_data bytes][i * g1_dataBytes], g1_dataBytes);
                d = [NSData dataWithBytesNoCopy:bytes length:g1_dataBytes freeWhenDone:YES];
                e = [codec encode:bytes length:g1_dataBytes ECByteCount:g1_ECBytes];
            }
            else {
                NSUInteger index = g1_RSBlocks * g1_dataBytes;
                uint8_t	*bytes = malloc(g2_dataBytes);
                bzero(bytes, g2_dataBytes);
                
                memcpy(bytes, &[_data bytes][index + (i - g1_RSBlocks) * g2_dataBytes], g2_dataBytes);
                d = [NSData dataWithBytesNoCopy:bytes length:g2_dataBytes freeWhenDone:YES];
                e = [codec encode:bytes length:g2_dataBytes ECByteCount:g2_ECBytes];
            }
            [data addObject:d];
            [ec addObject:e];
        }

        // First: Place data codewords
        NSMutableData *final = [NSMutableData dataWithCapacity:0];
        NSUInteger maxDC = (g1_dataBytes >= g2_dataBytes) ? g1_dataBytes : g2_dataBytes;
        for (NSUInteger i = 0; i < maxDC; i++) {
            for (NSUInteger index = 0; index < [data count]; index++) {
                NSData *d = data[index];
                const uint8_t *bytes = [d bytes];
                
                if (i < [d length]) [final appendBytes:&bytes[i] length:1];
            }
        }
        
        // second: Place error correction codewords
        NSUInteger maxEC = (g1_ECBytes >= g2_ECBytes) ? g1_ECBytes : g2_ECBytes;
        for (NSUInteger i = 0; i < maxEC; i++) {
            for (NSUInteger index = 0; index < [ec count]; index++) {
                NSData *ecc = ec[index];
                const uint8_t *bytes = [ecc bytes];
                
                if (i < [ecc length]) [final appendBytes:&bytes[i] length:1];
            }
        }
        FwiRelease(codec);

        
        /**
         * Step 7 + 8: Build QR matrix & Choose the mask pattern
         */
        _matrix	= FwiRetain([FwiBitMatrix bitMatrixWithSize:(17 + (4 * _version))]);
        _bufferMatrix = FwiRetain([FwiBitMatrix bitMatrixWithSize:(17 + (4 * _version))]);
        [self _buildMatrixWithData:final];
    }
}
- (__autoreleasing UIImage *)generateImage:(NSUInteger)preferSize transparentBackground:(BOOL)transparent {
	/* Condition validation */
	if (!_matrix) return nil;
	
	// Calculate scale factor
	NSUInteger size	= [_matrix size];
    __autoreleasing NSDecimalNumber *a = FwiAutoRelease([[NSDecimalNumber alloc] initWithUnsignedInteger:preferSize]);
    NSDecimalNumberHandler *handler = [[NSDecimalNumberHandler alloc] initWithRoundingMode:NSRoundDown
                                                                                     scale:0
                                                                          raiseOnExactness:NO
                                                                           raiseOnOverflow:NO
                                                                          raiseOnUnderflow:NO
                                                                       raiseOnDivideByZero:NO];
    
	a = [a decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithMantissa:size exponent:0 isNegative:NO]
                        withBehavior:handler];
    FwiRelease(handler);
    
	NSUInteger scale = [a unsignedIntegerValue];
	
	// Generate image data
//	NSUInteger imageHeight = ((size + 8) * scale);				// 4 pixels for each top and bottom quietzone
//	NSUInteger imageWidth  = ((size + 8) * scale) * 4;			// 4 pixels for each left and right quietzone
    NSUInteger imageHeight = (size * scale);
    NSUInteger imageWidth  = (size * scale) * 4;
	NSUInteger imageLength = imageWidth * imageHeight;
	uint8_t	*buffer = malloc(imageLength);
	
	// White background
	for (NSUInteger i = 0; i < imageLength; i += 4) {
		buffer[i] = 0xff;
        buffer[i + 1] = 0xff;
        buffer[i + 2] = 0xff;
        buffer[i + 3] = 0x00;
	}
	
	
	/**
	 * Generate QRCode image data
	 */
	NSUInteger step  = 4 * scale;								// 1 pixel = 4 bytes
    NSUInteger index = -1;
//	NSUInteger yTop  = (imageWidth * 4) * scale;
//	NSUInteger xTop  = (step * 4) + yTop;
//	NSUInteger index = xTop - 1;
	for (NSUInteger y = 0; y < [_matrix size]; y++) {
		for (NSUInteger i = 0; i < scale; i++) {				// Scale vertical
			
			for (NSUInteger x = 0; x < [_matrix size]; x++) {
				BOOL value = [_matrix bitAtRow:y andCol:x];
				
				if (value) {
					for (NSUInteger j = 0; j < scale; j++) {            // Scale horizontal
						buffer[++index] = 0x00;     // Red
						buffer[++index] = 0x00;     // Green
						buffer[++index] = 0x00;     // Blue
						buffer[++index] = 0xff;     // Alpha
					}
				}
				else {
					index += step;
				}
			}
//			index += (8 * step);
		}
	}
	
	
	/**
	 * Generate QRCode image
	 */
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo alpha = transparent ? (kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast) : (kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast);
	CGContextRef bitmapContext = CGBitmapContextCreate(buffer, imageHeight, imageHeight,
													   8,											// bits  per component
													   imageWidth,									// bytes per row
													   colorSpace,
													   alpha);
	CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
	FwiReleaseCF(colorSpace);
	free(buffer);
	
	// Create image
    UIImage *image = [UIImage imageWithCGImage:cgImage];
	FwiReleaseCF(bitmapContext);
	FwiReleaseCF(cgImage);
	
	return image;
}


#pragma mark - Class's private methods
- (void)_generateData:(NSString *)text {
    // Calculate version
	NSUInteger bodyLength = [self _calculateByteCountForText:text mode:_mode];
	for (NSInteger i = 0; i < 40; i++) {
		_totalDC  = TABLE_9[i][table_9_index_codewords];
		_totalECC = TABLE_9[i][table_9_index_ec_codewords + _level];
		_totalDB  = _totalDC - _totalECC;
		
		if (_totalDB >= (bodyLength + 3)) {
			_version  = TABLE_9[i][table_9_index_version];
			_RSBlocks = TABLE_9[i][table_9_index_ec_blocks + _level];
			break;
		}
	}
	
	// Append header
	uint8_t header = (uint8_t)(_mode & 0xff);
	[_data appendBytes:&header bitCount:4 byteCount:1];
	
	// Append input length
	uint16_t l = (uint16_t)([text length] & 0xffff);
	[_data appendWord:l bitCount:[self _calculateBitCountForLengthInfo]];
	
	// Encode input text (Default mode encoding is: kMode_Bytes)
	switch (_mode) {
		case kMode_Numeric: {
			NSUInteger r = [text length] % 3;
			NSUInteger counter = [text length] - r;
			
			// Encode three numeric chars in ten bits.
			for (NSUInteger i = 0; i < counter; i++) {
				uint8_t n1 = [text characterAtIndex:i] - '0';
				uint8_t n2 = [text characterAtIndex:++i] - '0';
				uint8_t n3 = [text characterAtIndex:++i] - '0';
				
				uint16_t nT = n1 * 100 + n2 * 10 + n3;
				[_data appendWord:nT bitCount:10];
			}
			
			if (r) {
				// Encode two numeric chars in seven bits.
				if (r == 2) {
					uint8_t n1 = [text characterAtIndex:([text length] - 2)] - '0';
					uint8_t n2 = [text characterAtIndex:([text length] - 1)] - '0';
					
					n1 = (n1 * 10) + n2;
					[_data appendBytes:&n1 bitCount:7 byteCount:1];
				}
				
				// Encode one numeric char in four bits.
				else {
					uint8_t n1 = [text characterAtIndex:([text length] - 1)] - '0';
					[_data appendBytes:&n1 bitCount:4 byteCount:1];
				}
			}
			break;
		}
		case kMode_Alphanumeric: {
			NSUInteger r = [text length] % 2;
			
			// Handle 2 chars at a time
			for (NSUInteger i = 0; i < ([text length] - r); i += 2) {
				const uint8_t  k1 = [self _alphanumeric:[text characterAtIndex:i]];
				const uint8_t  k2 = [self _alphanumeric:[text characterAtIndex:i + 1]];
				const uint16_t kT = (k1 * 45) + k2;
				[_data appendWord:kT bitCount:11];
			}
			
			// Handle single char if there is any left
			if (r == 1) {
				const uint8_t c	 = [self _alphanumeric:[text characterAtIndex:[text length]-1]];
				[_data appendBytes:&c bitCount:6 byteCount:1];
			}
			break;
		}
		case kMode_Kanji: {
            NSData *d = [text dataUsingEncoding:Kanji_DefaultEncoding];
			// Validate 2 bytes length
			if (([d length] % 2) != 0) return;
			
			// Validate input data
			const uint8_t *b = [d bytes];
			for (NSUInteger i = 0; i < [d length]; i += 2)
				if ((b[i] < 0x81 || b[i] > 0x9f) && (b[i] < 0xe0 || b[i] > 0xeb)) return;
			
			// Append data process
			for (NSUInteger i = 0; i < [d length]; i += 2) {
				uint8_t b1 = b[i];
				uint8_t b2 = b[i + 1];
				uint16_t code = (b1 << 8) | b2;
				if (code >= 0x8140 && code <= 0x9ffc) {
					code -= 0x8140;
				}
				else if (code >= 0xe040 && code <= 0xebbf) {
					code -= 0xc140;
				}
				if (code == 0) return;
				uint16_t encoded = ((code >> 8) * 0xc0) + (code & 0xff);
				[_data appendWord:encoded bitCount:13];
			}
			break;
		}
		default: {
            NSData *d = [text dataUsingEncoding:Bytes_DefaultEncoding];
			[_data appendBytes:[d bytes] bitCount:([d length] << 3) byteCount:[d length]];
			break;
		}
	}
}
- (uint8_t)_alphanumeric:(unichar)character {
	switch (character) {
		case '0': return 0;		case '1': return 1;		case '2': return 2;		case '3': return 3;
		case '4': return 4;		case '5': return 5;		case '6': return 6;		case '7': return 7;
		case '8': return 8;		case '9': return 9;		case 'A': return 10;	case 'B': return 11;
		case 'C': return 12;	case 'D': return 13;	case 'E': return 14;	case 'F': return 15;
		case 'G': return 16;	case 'H': return 17;	case 'I': return 18;	case 'J': return 19;
		case 'K': return 20;	case 'L': return 21;	case 'M': return 22;	case 'N': return 23;
		case 'O': return 24;	case 'P': return 25;	case 'Q': return 26;	case 'R': return 27;
		case 'S': return 28;	case 'T': return 29;	case 'U': return 30;	case 'V': return 31;
		case 'W': return 32;	case 'X': return 33;	case 'Y': return 34;	case 'Z': return 35;
		case ' ': return 36;	case '$': return 37;	case '%': return 38;	case '*': return 39;
		case '+': return 40;	case '-': return 41;	case '.': return 42;	case '/': return 43;
		case ':': return 44;	default : return 36;
	}
}
- (NSUInteger)_calculateBitCountForLengthInfo {
	switch (_mode) {
		case kMode_Numeric: {
			if (_version >= kVersion_1 && _version <= kVersion_9) return 10;
			else if (_version >= kVersion_10 && _version <= kVersion_26) return 12;
			else return 14;
			break;
		}
		case kMode_Alphanumeric: {
			if (_version >= kVersion_1 && _version <= kVersion_9) return 9;
			else if (_version >= kVersion_10 && _version <= kVersion_26) return 11;
			else return 13;
			break;
		}
		case kMode_Kanji: {
			if (_version >= kVersion_1 && _version <= kVersion_9) return 8;
			else if (_version >= kVersion_10 && _version <= kVersion_26) return 10;
			else return 12;
			break;
		}
		default: {
			if (_version >= kVersion_1 && _version <= kVersion_9) return 8;
			else if (_version >= kVersion_10 && _version <= kVersion_26) return 16;
			else return 16;
			break;
		}
	}
}
- (NSUInteger)_calculateByteCountForText:(NSString *)text mode:(FwiQRMode)mode {
	NSUInteger length = 0;
	
	switch (_mode) {
		case kMode_Numeric: {
			NSUInteger r = [text length] % 3;
			NSUInteger counter = [text length] - r;
			
			length = ((counter / 3) * 10) + ((r == 2) ? 7 : 4);
			break;
		}
		case kMode_Alphanumeric: {
			NSUInteger r = [text length] % 2;
			NSUInteger counter = [text length] - r;
			
			length = ((counter / 2) * 11) + ((r == 1) ? 6 : 0);
			break;
		}
		case kMode_Kanji: {
			length = [text length] * 13;
			break;
		}
		default: {
            NSData *d = [text dataUsingEncoding:Bytes_DefaultEncoding];
			length = [d length] << 3;
			break;
		}
	}
	
	length = ((length % 8) == 0) ? (length >> 3) : ((length >> 3) + 1);
	return length;
}


#pragma mark - Generate QRMatrix
- (void)_buildMatrixWithData:(NSData *)data {
    FwiBitArray *databits    = [FwiBitArray bitArrayWithBytes:[data bytes] bitCount:([data length] << 3) byteCount:[data length]];
	NSInteger minPenalty  = INT_MAX;
    NSInteger bestPattern = -1;
	
	// Look for the best mask pattern number
	for (NSUInteger i = 0; i < number_of_mask_patterns; i++) {
		if (i != 0) {
			[_matrix clean];
			[_bufferMatrix clean];
		}
		
		// Build matrix
		[self _embedBasicPatterns];																	// Embed basic patterns
		[self _embedTypeInfoWithMaskPattern:i];														// Type information appear with any version.
		[self _embedVersion:_version];																// Version info appear if version >= 7.
		[self _embedDataBits:databits maskPattern:i];												// Data should be embedded at end.
        
		// Calculate penalty
		NSUInteger penalty = 0;
		penalty += [self _applyMaskPenaltyRule1];
		penalty	+= [self _applyMaskPenaltyRule2];
		penalty	+= [self _applyMaskPenaltyRule3];
		penalty	+= [self _applyMaskPenaltyRule4];
		if (penalty < minPenalty) {
			minPenalty = penalty;
			bestPattern = i;
		}
	}
	
	if (bestPattern == -1) return;
	else {
		[_matrix clean];
		[_bufferMatrix clean];
		
		[self _embedBasicPatterns];
		[self _embedTypeInfoWithMaskPattern:bestPattern];
		[self _embedVersion:_version];
		[self _embedDataBits:databits maskPattern:bestPattern];
	}
}
- (void)_embedBasicPatterns {
    NSInteger pdpWidth = sizeof_position_detection_pattern;
	
	// Embed position detection patterns
	[self _embedPositionDetectionPatternFromCoordX:0 coordY:0];										// Left top corner
	[self _embedPositionDetectionPatternFromCoordX:0 coordY:([_matrix size] - pdpWidth)];			// Left bottom corner
	[self _embedPositionDetectionPatternFromCoordX:([_matrix size] - pdpWidth) coordY:0];			// Right top corner
	
	// Embed horizontal separators
	for (NSUInteger i = 0; i < 8; i++) {
		[_matrix changeBit:NO atRow:7 andCol:i];													// Left top corner
		[_matrix changeBit:NO atRow:([_matrix size] - 8) andCol:i];                                 // Left bottom corner
		[_matrix changeBit:NO atRow:7 andCol:([_matrix size] - 8 + i)];                             // Right Top corner
		
		[_bufferMatrix changeBit:YES atRow:7 andCol:i];
		[_bufferMatrix changeBit:YES atRow:([_bufferMatrix size] - 8) andCol:i];
		[_bufferMatrix changeBit:YES atRow:7 andCol:([_bufferMatrix size] - 8 + i)];
	}
	
	// Embed vertical separators
	for (NSInteger i = 0; i < 7; i++) {
		[_matrix changeBit:NO atRow:i andCol:7];													// Top left corner
		[_matrix changeBit:NO atRow:([_matrix size] - 7 + i) andCol:7];                             // bottom left corner
		[_matrix changeBit:NO atRow:i andCol:([_matrix size] - 8)];                                 // Top right corner
		
		[_bufferMatrix changeBit:YES atRow:i andCol:7];
		[_bufferMatrix changeBit:YES atRow:([_bufferMatrix size] - 7 + i) andCol:7];
		[_bufferMatrix changeBit:YES atRow:i andCol:([_bufferMatrix size] - 8)];
	}
	
	// Embed the dark dot at left bottom corner. JISX0510:2004 (p.46)
	[_matrix changeBit:YES atRow:([_matrix size] - 8) andCol:8];
	[_bufferMatrix changeBit:YES atRow:([_bufferMatrix size] - 8) andCol:8];
	
	// Embed position adjustment patterns
	[self _embedPositionAdjustmentPattern];
	
	// Embed timing patterns.
	for (NSUInteger i = 8; i < [_matrix size] - 8; i++) {
		BOOL bit = ((i + 1) % 2 == 1) ? YES : NO;
		[_matrix changeBit:bit atRow:6 andCol:i];                                                   // Horizontal line.
		[_matrix changeBit:bit atRow:i andCol:6];                                                   // Vertical line.
		
		[_bufferMatrix changeBit:YES atRow:6 andCol:i];
		[_bufferMatrix changeBit:YES atRow:i andCol:6];
    }
}
- (void)_embedPositionAdjustmentPattern {
	/* Condition validation */
	if (_version < 2) return;
	
    NSUInteger index = _version - 1;
	for (NSUInteger y = 0; y < 7; y++) {
		for (NSUInteger x = 0; x < 7; x++) {
			NSInteger row = POSITION_ADJUSTMENT_PATTERN_COORDINATE_TABLE[index][y];
			NSInteger col = POSITION_ADJUSTMENT_PATTERN_COORDINATE_TABLE[index][x];
			
			/* Condition validation */
			if (row == -1 || col == -1) continue;
			if ([_bufferMatrix bitAtRow:row andCol:col]) continue;
			
			// Append adjustment pattern process
			NSUInteger xStart = col - 2;
			NSUInteger yStart = row - 2;
			
			for (NSUInteger i = 0; i < sizeof_position_adjustment_pattern; i++) {
				NSUInteger idx = i * sizeof_position_adjustment_pattern;
				
				for (NSUInteger j = 0; j < sizeof_position_adjustment_pattern; j++, idx++) {
					[_matrix changeBit:POSITION_ADJUSTMENT_PATTERN[idx] atRow:(yStart + i) andCol:(xStart + j)];
					[_bufferMatrix changeBit:YES atRow:(yStart + i) andCol:(xStart + j)];
				}
			}
		}
	}
}
- (void)_embedPositionDetectionPatternFromCoordX:(NSUInteger)coordX coordY:(NSUInteger)coordY {
	NSUInteger size = sizeof_position_detection_pattern;
	
    for (NSUInteger row = 0; row < size; row++) {
		NSUInteger index = row * size;
		
		for (NSUInteger col = 0; col < size; col++, index++) {
			[_matrix changeBit:POSITION_DETECTION_PATTERN[index] atRow:(row + coordY) andCol:(col + coordX)];
			[_bufferMatrix changeBit:YES atRow:(row + coordY) andCol:(col + coordX)];
		}
	}
}
- (void)_embedTypeInfoWithMaskPattern:(NSUInteger)maskPattern {
    uint8_t  typeInfo = ((_level - 1) << 3) | maskPattern;
	uint16_t bchCode  = [self _calculateBCHCode:typeInfo typeInfoPoly:TYPE_INFO_POLY];
	
    FwiMutableBitArray *typeInfoBits = [FwiMutableBitArray mutableBitArray];
	[typeInfoBits appendBytes:&typeInfo bitCount:5 byteCount:1];
	[typeInfoBits appendWord:bchCode bitCount:10];
    
    FwiMutableBitArray *maskBits = [FwiMutableBitArray mutableBitArray];
	[maskBits appendWord:TYPE_INFO_MASK_PATTERN bitCount:15];
	[typeInfoBits operatorXOR:maskBits];
	
    for (NSUInteger i = 0; i < [typeInfoBits bitCount]; ++i) {
		// Place bits in LSB to MSB order.  LSB (least significant bit) is the last value in
		// "typeInfoBits".
		BOOL bit = [typeInfoBits bitAt:([typeInfoBits bitCount] - 1 - i)];
		
		// Type info bits at the left top corner. See 8.9 of JISX0510:2004 (p.46).
		NSInteger x1 = TYPE_INFO_COORDINATES[i][0];
		NSInteger y1 = TYPE_INFO_COORDINATES[i][1];
		[_matrix changeBit:bit atRow:y1 andCol:x1];
		[_bufferMatrix changeBit:YES atRow:y1 andCol:x1];
		
		if (i < 8) {
			// Right top corner.
			NSInteger x2 = [_matrix size] - i - 1;
			NSInteger y2 = 8;
			[_matrix changeBit:bit atRow:y2 andCol:x2];
			[_bufferMatrix changeBit:YES atRow:y2 andCol:x2];
		}
		else {
			// Left bottom corner.
			NSInteger x2 = 8;
			NSInteger y2 = [_matrix size] - 7 + (i - 8);
			[_matrix changeBit:bit atRow:y2 andCol:x2];
			[_bufferMatrix changeBit:YES atRow:y2 andCol:x2];
		}
    }
}
- (void)_embedVersion:(FwiQRVersion)version {
	/* Condition validation */
	if (_version < 7) return;
    
	uint16_t bchCode = [self _calculateBCHCode:version typeInfoPoly:VERSION_INFO_POLY];
	uint8_t bytesVersion = version;
	
    FwiMutableBitArray *versionInfoBits = [FwiMutableBitArray mutableBitArray];
	[versionInfoBits appendBytes:&bytesVersion bitCount:6 byteCount:1];
	[versionInfoBits appendWord:bchCode bitCount:12];
	
    NSUInteger bitIndex = 6 * 3 - 1;  // It will decrease from 17 to 0.
	
	for (NSUInteger i = 0; i < 6; i++) {
		for (NSUInteger j = 0; j < 3; j++) {
			// Place bits in LSB (least significant bit) to MSB order.
			BOOL bit = [versionInfoBits bitAt:bitIndex];
			bitIndex--;
			
			[_matrix changeBit:bit atRow:i andCol:([_matrix size] - 11 + j)];					// Top right corner
			[_matrix changeBit:bit atRow:([_matrix size] - 11 + j) andCol:i];					// Bottom left corner
			
			[_bufferMatrix changeBit:YES atRow:i andCol:([_matrix size] - 11 + j)];
			[_bufferMatrix changeBit:YES atRow:([_matrix size] - 11 + j) andCol:i];
		}
    }
}
- (void)_embedDataBits:(FwiBitArray *)dataBits maskPattern:(NSUInteger)maskPattern {
	NSInteger bitIndex  = 0;
    NSInteger direction = -1;
    
	// Start from the right bottom cell.
    NSInteger x = [_matrix size] - 1;
    NSInteger y = [_matrix size] - 1;
    
	while (x > 0) {
		// Skip the vertical timing pattern.
		if (x == 6) x -= 1;
		
		while (y >= 0 && y < [_matrix size]) {
			for (NSInteger i = 0; i < 2; ++i) {
				NSInteger xx = x - i;
				// Skip the cell if it's not empty.
				if ([_bufferMatrix bitAtRow:y andCol:xx]) continue;
				
				BOOL bit;
				if (bitIndex < [dataBits bitCount]) {
					bit = [dataBits bitAt:bitIndex];
					++bitIndex;
				}
				else {
					// Padding bit. If there is no bit left, we'll fill the left cells with 0, as described
					// in 8.4.9 of JISX0510:2004 (p. 24).
					bit = NO;
				}
				
				// Skip masking if mask_pattern is -1.
				if (maskPattern < number_of_mask_patterns) {
					NSInteger intermediate, temp;
					
					switch (maskPattern) {
						case 0:
							intermediate = (y + xx) & 0x1;
							break;
							
						case 1:
							intermediate = y & 0x1;
							break;
							
						case 2:
							intermediate = xx % 3;
							break;
							
						case 3:
							intermediate = (y + xx) % 3;
							break;
							
						case 4:
							intermediate = ((y >> 1) + (xx / 3)) & 0x1;
							break;
							
						case 5:
							temp = y * xx;
							intermediate = (temp & 0x1) + (temp % 3);
							break;
							
						case 6:
							temp = y * xx;
							intermediate = (((temp & 0x1) + (temp % 3)) & 0x1);
							break;
							
						case 7:
							temp = y * xx;
							intermediate = (((temp % 3) + ((y + xx) & 0x1)) & 0x1);
							break;
					}
					
					BOOL bFlag = (intermediate == 0) ? YES : NO;
					if (bFlag) bit = !bit;
				}
				
				[_matrix changeBit:bit atRow:y andCol:xx];
				[_bufferMatrix changeBit:YES atRow:y andCol:xx];
			}
			y += direction;
		}
		direction = -direction;	// Reverse the direction.
		y += direction;
		x -= 2;					// Move to the left.
    }
}
- (NSUInteger)_applyMaskPenaltyRule1 {
	NSUInteger penalty1 = [self _applyMaskPenaltyRule1Internal:_matrix isHorizontal:YES];
	NSUInteger penalty2 = [self _applyMaskPenaltyRule1Internal:_matrix isHorizontal:NO];
	return (penalty1 + penalty2);
}
- (NSUInteger)_applyMaskPenaltyRule2 {
	NSUInteger penalty = 0;
	NSUInteger width   = [_matrix size];
	NSUInteger height  = [_matrix size];
	
	for (NSUInteger y = 0; y < (height - 1); y++) {
		for (NSUInteger x = 0; x < (width - 1); x++) {
			BOOL value = [_matrix bitAtRow:y andCol:x];
			
			if (
				(
				 (value && [_matrix bitAtRow:y andCol:(x + 1)]) &&
				 (value && [_matrix bitAtRow:(y + 1) andCol:x]) &&
				 (value && [_matrix bitAtRow:(y + 1) andCol:(x + 1)])
                 )
				||
				(
				 (!value && ![_matrix bitAtRow:y andCol:(x + 1)]) &&
				 (!value && ![_matrix bitAtRow:(y + 1) andCol:x]) &&
				 (!value && ![_matrix bitAtRow:(y + 1) andCol:(x + 1)])
                 )
                )
			{
				penalty += 3;
			}
		}
	}
	return penalty;
}
- (NSUInteger)_applyMaskPenaltyRule3 {
	NSUInteger penalty = 0;
	NSUInteger width   = [_matrix size];
	NSUInteger height  = [_matrix size];
	
	for (NSInteger y = 0; y < height; y++) {
		for (NSInteger x = 0; x < width; x++) {
			if (
				(x + 6) < width
				&&  [_matrix bitAtRow:y andCol:x]
				&& ![_matrix bitAtRow:y andCol:(x + 1)]
				&&  [_matrix bitAtRow:y andCol:(x + 2)]
				&&  [_matrix bitAtRow:y andCol:(x + 3)]
				&&  [_matrix bitAtRow:y andCol:(x + 4)]
				&& ![_matrix bitAtRow:y andCol:(x + 5)]
				&&  [_matrix bitAtRow:y andCol:(x + 6)]
				&& (
					(
					 (x + 10) < width
					 && ![_matrix bitAtRow:y andCol:(x +  7)]
					 && ![_matrix bitAtRow:y andCol:(x +  8)]
					 && ![_matrix bitAtRow:y andCol:(x +  9)]
					 && ![_matrix bitAtRow:y andCol:(x + 10)]
                     )
					||
					(
					 (x - 4) >= 0
					 && ![_matrix bitAtRow:y andCol:(x - 1)]
					 && ![_matrix bitAtRow:y andCol:(x - 2)]
					 && ![_matrix bitAtRow:y andCol:(x - 3)]
					 && ![_matrix bitAtRow:y andCol:(x - 4)]
                     )
                    )
                )
			{
				penalty += 40;
			}
			
			if (
				(y + 6) < height
				&&  [_matrix bitAtRow:y andCol:x]
				&& ![_matrix bitAtRow:(y + 1) andCol:x]
				&&  [_matrix bitAtRow:(y + 2) andCol:x]
				&&  [_matrix bitAtRow:(y + 3) andCol:x]
				&&  [_matrix bitAtRow:(y + 4) andCol:x]
				&& ![_matrix bitAtRow:(y + 5) andCol:x]
				&&  [_matrix bitAtRow:(y + 6) andCol:x]
				&& (
					(
					 (y + 10) < height
					 && ![_matrix bitAtRow:(y +  7) andCol:x]
					 && ![_matrix bitAtRow:(y +  8) andCol:x]
					 && ![_matrix bitAtRow:(y +  9) andCol:x]
					 && ![_matrix bitAtRow:(y + 10) andCol:x]
                     )
					||
					(
					 (y - 4) >= 0
					 && ![_matrix bitAtRow:(y - 1) andCol:x]
					 && ![_matrix bitAtRow:(y - 2) andCol:x]
					 && ![_matrix bitAtRow:(y - 3) andCol:x]
					 && ![_matrix bitAtRow:(y - 4) andCol:x]
                     )
                    )
                )
			{
				penalty += 40;
			}
		}
	}
	return penalty;
}
- (NSUInteger)_applyMaskPenaltyRule4 {
	NSUInteger numDarkCells = 0;
	NSUInteger width  = [_matrix size];
	NSUInteger height = [_matrix size];
	
	for (NSUInteger y = 0; y < height; y++) {
		for (NSUInteger x = 0; x < width; x++) {
			if ([_matrix bitAtRow:y andCol:x]) numDarkCells += 1;
		}
	}
	NSUInteger numTotalCells = [_matrix size] * [_matrix size];
	double_t   darkRatio	 = (double_t) numDarkCells / numTotalCells;
	return ABS(round((darkRatio * 100 - 50))) / 5 * 10;
}


#pragma mark - Generate QRMatrix > Supported methods
- (NSUInteger)_applyMaskPenaltyRule1Internal:(FwiBitMatrix *)matrix isHorizontal:(BOOL)isHorizontal {
	BOOL prevBit = NO;
	NSUInteger penalty = 0;
	NSUInteger numSameBitCells = 0;
	NSUInteger iLimit = [_matrix size];
	NSUInteger jLimit = [_matrix size];
	
	for (NSUInteger i = 0; i < iLimit; i++) {
		for (NSUInteger j = 0; j < jLimit; j++) {
			BOOL bit = isHorizontal ? [_matrix bitAtRow:i andCol:j] : [_matrix bitAtRow:j andCol:i];
			
			if ((bit && prevBit) || (!bit && !prevBit)) {
				numSameBitCells += 1;
				if (numSameBitCells == 5) penalty += 3;
				else if (numSameBitCells > 5) penalty += 1;
			}
			else {
				numSameBitCells = 1;
				prevBit = bit;
			}
		}
		numSameBitCells = 0;
	}
	return penalty;
}
- (NSUInteger)_calculateBCHCode:(NSUInteger)value typeInfoPoly:(uint16_t)infoPoly {
    NSUInteger msbSetInPoly = [self _findMSBSet:infoPoly];
	
    value <<= (msbSetInPoly - 1);
    while ([self _findMSBSet:value] >= msbSetInPoly) {
		value ^= infoPoly << ([self _findMSBSet:value] - msbSetInPoly);
    }
    return value;
}
- (NSUInteger)_findMSBSet:(NSUInteger)value {
    NSUInteger numDigits = 0;
	
    while (value != 0) {
		value >>= 1;
		++numDigits;
    }
    return numDigits;
}


#pragma mark - Class's notification handlers


@end


@implementation FwiQRCode (FwiQRCodeCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiQRCode *)alphanumeric:(NSString *)text ECLevel:(FwiECLevel)level {
    /* Condition validation */
	if ([text length] > 4296) return nil;

    __autoreleasing FwiQRCode *encode = [[FwiQRCode alloc] initWithString:text Mode:kMode_Alphanumeric ECLevel:level];
    return FwiAutoRelease(encode);
}
+ (__autoreleasing FwiQRCode *)numeric:(NSString *)text ECLevel:(FwiECLevel)level {
    /* Condition validation */
	if ([text length] > 7089) return nil;

    __autoreleasing FwiQRCode *encode = [[FwiQRCode alloc] initWithString:text Mode:kMode_Numeric ECLevel:level];
    return FwiAutoRelease(encode);
}
+ (__autoreleasing FwiQRCode *)bytes:(NSString *)text ECLevel:(FwiECLevel)level {
    /* Condition validation */
	if ([text length] > 2953) return nil;

    __autoreleasing FwiQRCode *encode = [[FwiQRCode alloc] initWithString:text Mode:kMode_Bytes ECLevel:level];
    return FwiAutoRelease(encode);
}
+ (__autoreleasing FwiQRCode *)kanji:(NSString *)text ECLevel:(FwiECLevel)level {
    /* Condition validation */
	if ([text length] > 1817) return nil;

    __autoreleasing FwiQRCode *encode = [[FwiQRCode alloc] initWithString:text Mode:kMode_Kanji ECLevel:level];
    return FwiAutoRelease(encode);
}


#pragma mark - Class's constructors
- (id)initWithString:(NSString *)text Mode:(FwiQRMode)mode ECLevel:(FwiECLevel)level {
    self = [self init];
    if (self) {
        _data  = FwiRetain([FwiMutableBitArray mutableBitArray]);
		_mode  = mode;
        _level = level;

        [self _generateData:text];
    }
    return self;
}


@end