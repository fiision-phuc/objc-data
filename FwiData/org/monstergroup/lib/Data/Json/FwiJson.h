//  Project name: FwiData
//  File name   : FwiJson.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 9/23/12
//  Version     : 1.20
//  --------------------------------------------------------------
//  Copyright (C) 2012, 2015 Monster Group.
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
//  testing. Monster Group  disclaim  all  liability  and  responsibility  to  any
//  person or entity with respect to any loss or damage caused, or alleged  to  be
//  caused, directly or indirectly, by the use of this software.

#import <Foundation/Foundation.h>


@interface FwiJson : NSObject <NSCoding> {

@private
    NSNumber *_number;
    NSString *_string;
    NSMutableArray *_array;
    NSMutableDictionary *_objects;
}

@property (nonatomic, readonly) NSUInteger count;


/** Validate Json structure. */
- (BOOL)isLike:(FwiJson *)json;

@end


@interface FwiJson (FwiJsonCreation)

+ (__autoreleasing FwiJson *)null;

+ (__autoreleasing FwiJson *)boolean;
+ (__autoreleasing FwiJson *)booleanWithBool:(BOOL)value;

+ (__autoreleasing FwiJson *)number;
+ (__autoreleasing FwiJson *)numberWithInteger:(NSInteger)value;
+ (__autoreleasing FwiJson *)numberWithUnsignedInteger:(NSUInteger)value;
+ (__autoreleasing FwiJson *)numberWithLongLong:(long long)value;
+ (__autoreleasing FwiJson *)numberWithUnsignedLongLong:(unsigned long long)value;
+ (__autoreleasing FwiJson *)numberWithDouble:(double)value;
+ (__autoreleasing FwiJson *)numberWithDecimal:(NSDecimal)value;
+ (__autoreleasing FwiJson *)numberWithNumber:(NSNumber *)value;
+ (__autoreleasing FwiJson *)numberWithDecimalNumber:(NSDecimalNumber *)value;

+ (__autoreleasing FwiJson *)string;
+ (__autoreleasing FwiJson *)stringWithData:(NSData *)data;
+ (__autoreleasing FwiJson *)stringWithString:(NSString *)string;

+ (__autoreleasing FwiJson *)array;
+ (__autoreleasing FwiJson *)array:(id)json, ... NS_REQUIRES_NIL_TERMINATION;
+ (__autoreleasing FwiJson *)arrayWithArray:(NSArray *)objects;

+ (__autoreleasing FwiJson *)object;
+ (__autoreleasing FwiJson *)object:(id)key, ... NS_REQUIRES_NIL_TERMINATION;
+ (__autoreleasing FwiJson *)objectWithDictionary:(NSDictionary *)dictionary;

@end


@interface FwiJson (FwiJsonCollection)

/** Get Json at index, return nil if this Json is not structured. */
- (__autoreleasing FwiJson *)jsonAtIndex:(NSUInteger)index;
/** Get Json for path, return nil if this Json is not structured. */
- (__autoreleasing FwiJson *)jsonWithPath:(NSString *)path;

/** Add/Set new Json array. */
- (void)setJson:(id)json;
- (void)addJson:(id)json;
- (void)setJsons:(id)json, ... NS_REQUIRES_NIL_TERMINATION;
- (void)addJsons:(id)json, ... NS_REQUIRES_NIL_TERMINATION;
- (void)replaceJson:(FwiJson *)json atIndex:(NSUInteger)index;
- (void)removeJsons:(id)json, ... NS_REQUIRES_NIL_TERMINATION;
- (void)jsonWithPath:(NSString *)path setJsons:(id)json, ... NS_REQUIRES_NIL_TERMINATION;
- (void)jsonWithPath:(NSString *)path addJsons:(id)json, ... NS_REQUIRES_NIL_TERMINATION;
- (void)jsonWithPath:(NSString *)path removeJsons:(id)json, ... NS_REQUIRES_NIL_TERMINATION;

/** Add/Set new Json collection. */
- (void)setKey:(id)key andJson:(id)json;
- (void)addKey:(id)key andJson:(id)json;
- (void)setKeysAndJsons:(id)key, ... NS_REQUIRES_NIL_TERMINATION;
- (void)addKeysAndJsons:(id)key, ... NS_REQUIRES_NIL_TERMINATION;
- (void)removeJsonsForKeys:(id)key, ... NS_REQUIRES_NIL_TERMINATION;
- (void)jsonWithPath:(NSString *)path setKeysAndJsons:(id)key, ... NS_REQUIRES_NIL_TERMINATION;
- (void)jsonWithPath:(NSString *)path addKeysAndJsons:(id)key, ... NS_REQUIRES_NIL_TERMINATION;
- (void)jsonWithPath:(NSString *)path removeJsonsForKeys:(id)key, ... NS_REQUIRES_NIL_TERMINATION;

@end


@interface FwiJson (FwiJsonPrimitive)

/** Get/Set Boolean. */
- (BOOL)getBoolean;
- (void)setBoolean:(BOOL)value;

/** Get/Set Number. */
- (__autoreleasing NSNumber *)getNumber;
- (void)setNumber:(NSNumber *)value;

/** Get/Set String. */
- (__autoreleasing NSString *)getString;
- (void)setString:(NSString *)value;

@end


@interface FwiJson (FwiJsonEncode)

/** Encode Json to data. */
- (__autoreleasing NSData *)encode;
/** Encode Json to string. */
- (__autoreleasing NSString *)encodeJson;

/** Encode Json to base64 data. */
- (__autoreleasing NSData *)encodeBase64Data;
/** Encode Json to base64 string. */
- (__autoreleasing NSString *)encodeBase64String;

@end


@interface FwiJson (FwiJsonEnumeration)

/** Enumerate array. */
- (void)enumerateObjectsUsingBlock:(void(^)(FwiJson *json, NSUInteger idx, BOOL *stop))block;

/** Enumerate dictionaray. */
- (void)enumerateKeysAndObjectsUsingBlock:(void(^)(NSString *key, FwiJson *json, BOOL *stop))block;

@end
