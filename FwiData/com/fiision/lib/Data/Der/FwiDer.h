//  Project name: FwiData
//  File name   : FwiDer.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 12/18/12
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


@interface FwiDer : NSObject <NSCoding> {

@private
    NSData *_content;
    NSMutableArray *_children;
}

@property (nonatomic, readonly) BOOL isStructure;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) NSUInteger length;


/** Validate DER structure. */
- (BOOL)isLike:(FwiDer *)der;

/** Get/Set Content. */
- (__autoreleasing NSData *)getContent;
- (void)setContent:(NSData *)content;


@end


@interface FwiDer (FwiDerCreation)

// Class's static constructors
+ (__autoreleasing FwiDer *)null;

+ (__autoreleasing FwiDer *)boolean;
+ (__autoreleasing FwiDer *)booleanWithValue:(BOOL)value;

+ (__autoreleasing FwiDer *)integer;
+ (__autoreleasing FwiDer *)integerWithInt:(NSInteger)value;
+ (__autoreleasing FwiDer *)integerWithData:(NSData *)value;
+ (__autoreleasing FwiDer *)integerWithBigInt:(FwiBigInt *)value;

+ (__autoreleasing FwiDer *)bitString;
+ (__autoreleasing FwiDer *)bitStringWithData:(NSData *)input;
+ (__autoreleasing FwiDer *)bitStringWithData:(NSData *)input padding:(NSUInteger)padding;

+ (__autoreleasing FwiDer *)octetString;
+ (__autoreleasing FwiDer *)octetStringWithData:(NSData *)input;

+ (__autoreleasing FwiDer *)enumerated;
+ (__autoreleasing FwiDer *)enumeratedWithInt:(NSInteger)value;
+ (__autoreleasing FwiDer *)enumeratedWithData:(NSData *)value;
+ (__autoreleasing FwiDer *)enumeratedWithBigInt:(FwiBigInt *)value;

+ (__autoreleasing FwiDer *)utf8String;
+ (__autoreleasing FwiDer *)utf8StringWithData:(NSData *)input;
+ (__autoreleasing FwiDer *)utf8StringWithString:(NSString *)input;

+ (__autoreleasing FwiDer *)numericString;
+ (__autoreleasing FwiDer *)numericStringWithData:(NSData *)input;
+ (__autoreleasing FwiDer *)numericStringWithString:(NSString *)input;

+ (__autoreleasing FwiDer *)printableString;
+ (__autoreleasing FwiDer *)printableStringWithData:(NSData *)input;
+ (__autoreleasing FwiDer *)printableStringWithString:(NSString *)input;

+ (__autoreleasing FwiDer *)t61String;
+ (__autoreleasing FwiDer *)t61StringWithData:(NSData *)input;
+ (__autoreleasing FwiDer *)t61StringWithString:(NSString *)input;

+ (__autoreleasing FwiDer *)ia5String;
+ (__autoreleasing FwiDer *)ia5StringWithData:(NSData *)input;
+ (__autoreleasing FwiDer *)ia5StringWithString:(NSString *)input;

+ (__autoreleasing FwiDer *)graphicString;
+ (__autoreleasing FwiDer *)graphicStringWithData:(NSData *)input;
+ (__autoreleasing FwiDer *)graphicStringWithString:(NSString *)input;

+ (__autoreleasing FwiDer *)visibleString;
+ (__autoreleasing FwiDer *)visibleStringWithData:(NSData *)input;
+ (__autoreleasing FwiDer *)visibleStringWithString:(NSString *)input;

+ (__autoreleasing FwiDer *)generalString;
+ (__autoreleasing FwiDer *)generalStringWithData:(NSData *)input;
+ (__autoreleasing FwiDer *)generalStringWithString:(NSString *)input;

+ (__autoreleasing FwiDer *)universalString;
+ (__autoreleasing FwiDer *)universalStringWithData:(NSData *)input;
+ (__autoreleasing FwiDer *)universalStringWithString:(NSString *)input;

+ (__autoreleasing FwiDer *)bmpString;
+ (__autoreleasing FwiDer *)bmpStringWithData:(NSData *)input;
+ (__autoreleasing FwiDer *)bmpStringWithString:(NSString *)input;

+ (__autoreleasing FwiDer *)objectIdentifier;
+ (__autoreleasing FwiDer *)objectIdentifierWithOIDString:(NSString *)oidString;

+ (__autoreleasing FwiDer *)utcTime;
+ (__autoreleasing FwiDer *)utcTimeWithDate:(NSDate *)time;

+ (__autoreleasing FwiDer *)generalizedTime;
+ (__autoreleasing FwiDer *)generalizedTimeWithDate:(NSDate *)time;

+ (__autoreleasing FwiDer *)bitStringWithDer:(FwiDer *)der;
+ (__autoreleasing FwiDer *)bitStringWithDers:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION;
+ (__autoreleasing FwiDer *)bitStringWithArray:(NSArray *)array;

+ (__autoreleasing FwiDer *)octetStringWithDer:(FwiDer *)der;
+ (__autoreleasing FwiDer *)octetStringWithDers:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION;
+ (__autoreleasing FwiDer *)octetStringWithArray:(NSArray *)array;

+ (__autoreleasing FwiDer *)sequence;
+ (__autoreleasing FwiDer *)sequence:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION;
+ (__autoreleasing FwiDer *)sequenceWithArray:(NSArray *)array;

+ (__autoreleasing FwiDer *)set;
+ (__autoreleasing FwiDer *)set:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION;
+ (__autoreleasing FwiDer *)setWithArray:(NSArray *)array;

+ (__autoreleasing FwiDer *)derWithIdentifier:(uint8_t)identifier;
+ (__autoreleasing FwiDer *)derWithIdentifier:(uint8_t)identifier content:(NSData *)content;

+ (__autoreleasing FwiDer *)derWithIdentifier:(uint8_t)identifier Ders:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION;
+ (__autoreleasing FwiDer *)derWithIdentifier:(uint8_t)identifier array:(NSArray *)array;

@end


@interface FwiDer (FwiDerCollection)

/** Get DER at index, return null if this DER is not structured. */
- (__autoreleasing FwiDer *)derAtIndex:(NSUInteger)index;
/** Get DER for DER path, return null if this DER is not structured. */
- (__autoreleasing FwiDer *)derWithPath:(NSString *)path;

/** Set new DER collection. The collection will be reset. */
- (void)setDers:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION;
- (void)setDersWithArray:(NSArray *)array;
/** Add new DER to current collection. */
- (void)addDers:(FwiDer *)der, ... NS_REQUIRES_NIL_TERMINATION;
- (void)addDersWithArray:(NSArray *)array;

/** Insert new DER. */
- (void)insertDer:(FwiDer *)der atIndex:(NSUInteger)index;
/** Replace old DER with new DER at index. */
- (void)replaceDer:(FwiDer *)der atIndex:(NSUInteger)index;

/** Remove last DER. */
- (void)removeLastDer;
/** Remove DER at index. */
- (void)removeDerAtIndex:(NSUInteger)index;

@end


@interface FwiDer (FwiDerPrimitive)

/** Get/Set Boolean. */
- (BOOL)getBoolean;
- (void)setBoolean:(BOOL)value;

/** Get/Set Integer. */
- (NSInteger)getInt;
- (void)setInt:(NSInteger)value;

/** Get/Set BigInt. */
- (__autoreleasing FwiBigInt *)getBigInt;
- (void)setBigInt:(FwiBigInt *)value;

/** Get/Set time. */
- (__autoreleasing NSDate *)getTime;
- (void)setTime:(NSDate *)date;

/** Get/Set Object Identifier. */
- (__autoreleasing NSString *)getObjectIdentifier;
- (void)setObjectIdentifier:(NSString *)oid;

/** Get/Set String. */
- (__autoreleasing NSString *)getString;
- (void)setStringWithData:(NSData *)input;
- (void)setStringWithString:(NSString *)input;

/** Set Bit String. */
- (void)setBitStringWithData:(NSData *)input;
- (void)setBitStringWithData:(NSData *)input padding:(NSInteger)padding;
- (void)setBitStringWithDer:(FwiDer *)der;
- (void)setBitStringWithDer:(FwiDer *)der padding:(NSInteger)padding;

/** Set Octet String. */
- (void)setOctetStringWithData:(NSData *)input;
- (void)setOctetStringWithDer:(FwiDer *)der;

@end


@interface FwiDer (FwiDerEncode)

/** Encode DER to data. */
- (__autoreleasing NSData *)encode;
/** Encode DER to base64 data. */
- (__autoreleasing NSData *)encodeBase64Data;
/** Encode DER to base64 string. */
- (__autoreleasing NSString *)encodeBase64String;

@end
