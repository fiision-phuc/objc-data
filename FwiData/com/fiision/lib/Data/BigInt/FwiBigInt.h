//  Project name: FwiData
//  File name   : FwiBigInt.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 9/21/12
//  Version     : 1.20
//  --------------------------------------------------------------
//  Copyright (C) 2012, 2015 Fiision Studio.
//  All Rights Reserved.
//  --------------------------------------------------------------
//
//  Permission is hereby granted, free of charge, to any person obtaining  a  copy
//  of this software and associated documentation files (the "Software"), to  deal
//  in the Software without restriction, including without limitation  the  rights
//  to use, copy, modify, merge,  publish,  distribute,  sublicense,  and/or  sell
//  copies of the Software,  and  to  permit  persons  to  whom  the  Software  is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF  ANY  KIND,  EXPRESS  OR
//  IMPLIED, INCLUDING BUT NOT  LIMITED  TO  THE  WARRANTIES  OF  MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO  EVENT  SHALL  THE
//  AUTHORS OR COPYRIGHT HOLDERS  BE  LIABLE  FOR  ANY  CLAIM,  DAMAGES  OR  OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING  FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN  THE
//  SOFTWARE.
//
//
//  Disclaimer
//  __________
//  Although reasonable care has been taken to  ensure  the  correctness  of  this
//  software, this software should never be used in any application without proper
//  testing. Fiision Studio disclaim  all  liability  and  responsibility  to  any
//  person or entity with respect to any loss or damage caused, or alleged  to  be
//  caused, directly or indirectly, by the use of this software.

#import <Foundation/Foundation.h>


@interface FwiBigInt : NSObject <NSCoding> {

@private
    NSMutableData *_data;
}

@property (nonatomic, readonly) BOOL isNegative;


// Class's public methods
- (__autoreleasing NSString *)descriptionWithRadix:(NSUInteger)radix;

/** Encode this bigInt into data, compatible with Java BigInteger. */
- (__autoreleasing NSData *)encode;
/** Encode this bigInt into base64 data, compatible with Java BigInteger. */
- (__autoreleasing NSData *)encodeBase64Data;
/** Encode this bigInt into base64 string, compatible with Java BigInteger. */
- (__autoreleasing NSString *)encodeBase64String;

// Class's public methods: Comparator
- (BOOL)isEqualTo:(FwiBigInt *)bigInt;

- (BOOL)isGreaterThan:(FwiBigInt *)bigInt;
- (BOOL)isGreaterThanOrEqualTo:(FwiBigInt *)bigInt;

- (BOOL)isLessThan:(FwiBigInt *)bigInt;
- (BOOL)isLessThanOrEqualTo:(FwiBigInt *)bigInt;

// Class's public methods: Basic operations
- (void)add:(FwiBigInt *)bigInt;
- (void)subtract:(FwiBigInt *)bigInt;
- (void)divide:(FwiBigInt *)bigInt;
- (void)multiply:(FwiBigInt *)bigInt;

// Class's public methods: Bitwise operations
- (void)negate;
- (void)shiftLeft:(NSUInteger)shiftValue;
- (void)shiftRight:(NSUInteger)shiftValue;

- (void)and:(FwiBigInt *)bigInt;
- (void) or:(FwiBigInt *)bigInt;
- (void)xor:(FwiBigInt *)bigInt;
- (void)not;

// Class's public methods: Other operations
- (void)mod:(FwiBigInt *)bigInt;
- (void)abs;
- (void)sqrt;

@end


@interface FwiBigInt (FwiBigIntCreation)

// Class's static constructors
+ (__autoreleasing FwiBigInt *)bigIntWithValue:(long long)value;
+ (__autoreleasing FwiBigInt *)bigIntWithUnsignedValue:(unsigned long long)value;

+ (__autoreleasing FwiBigInt *)bigIntWithInteger:(NSInteger)value;
+ (__autoreleasing FwiBigInt *)bigIntWithUnsignedInteger:(NSUInteger)value;

+ (__autoreleasing FwiBigInt *)one;
+ (__autoreleasing FwiBigInt *)zero;

+ (__autoreleasing FwiBigInt *)bigIntWithBigInt:(FwiBigInt *)bigInt;
+ (__autoreleasing FwiBigInt *)bigIntWithString:(NSString *)value radix:(NSUInteger)radix;
+ (__autoreleasing FwiBigInt *)bigIntWithData:(NSData *)data shouldReverse:(BOOL)shouldReverse;

// Class's constructors
- (id)initWithBigInt:(FwiBigInt *)bigInt;
- (id)initWithString:(NSString *)string radix:(NSUInteger)radix;

- (id)initWithValue:(long long)value;
- (id)initWithUnsignedValue:(unsigned long long)value;

@end


@interface FwiBigInt (FwiExtension)

- (__autoreleasing FwiBigInt *)bigIntByAdding:(FwiBigInt *)bigInt;
- (__autoreleasing FwiBigInt *)bigIntBySubtracting:(FwiBigInt *)bigInt;
- (__autoreleasing FwiBigInt *)bigIntByDividing:(FwiBigInt *)bigInt;
- (__autoreleasing FwiBigInt *)bigIntByMultiplying:(FwiBigInt *)bigInt;

- (__autoreleasing FwiBigInt *)bigIntByNegate;
- (__autoreleasing FwiBigInt *)bigIntByShiftLeft:(NSUInteger)shiftValue;
- (__autoreleasing FwiBigInt *)bigIntByShiftRight:(NSUInteger)shiftValue;

- (__autoreleasing FwiBigInt *)bigIntByBitwiseAND:(FwiBigInt *)bigInt;
- (__autoreleasing FwiBigInt *)bigIntByBitwiseOR :(FwiBigInt *)bigInt;
- (__autoreleasing FwiBigInt *)bigIntByBitwiseXOR:(FwiBigInt *)bigInt;
- (__autoreleasing FwiBigInt *)bigIntByBitwiseNOT;

- (__autoreleasing FwiBigInt *)bigIntByModulus:(FwiBigInt *)bigInt;
- (__autoreleasing FwiBigInt *)bigIntByAbsolute;
- (__autoreleasing FwiBigInt *)bigIntBySquareRoot;

@end