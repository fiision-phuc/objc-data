//  Project name: FwiData
//  File name   : FwiMutableBitArray.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 9/21/12
//  Version     : 1.20
//  --------------------------------------------------------------
//  Copyright (C) 2012, 2014 Monster Group.
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


@interface FwiMutableBitArray : FwiBitArray <NSCoding> {
}


/**
 * The function will append one or more than one byte(s) to the array. The function will do nothing
 * if the bitCount is greater than byteCount (byteCount * 8).
 *
 * Processing algorithm:
 *		- Case byteCount = 1:	The function will flip all the bit(s) on the left hand side to zero
 *								and keep all the bit(s) on the right hand side untouch. The counter
 *								will start from right to left and stop when the number of bit(s) is
 *								equal to bitCount, then add all the bit(s) to array.
 *
 *		- Case byteCount > 2:	The function will add all the bit(s) to array from left to right
 *								without any zero bit(s) trimming process.
 *
 *		-> Special Case(s):
 *			bytes is nil		: Do nothing.
 *			bitCount > byteCount: Do nothing.
 *			bitCount  = 0		: Do nothing.
 *			byteCount = 0		: Do nothing.
 */
- (void)appendBytes:(const uint8_t *)bytes bitCount:(NSUInteger)bitCount byteCount:(NSUInteger)byteCount;

/**
 * The same as the above method except that it will free all the bytes after used.
 */
- (void)appendBytesWithoutCopy:(uint8_t *)bytes bitCount:(NSUInteger)bitCount byteCount:(NSUInteger)byteCount;

/**
 * Append single word to array. The function will behave like appendBytes function, case add 1 byte.
 * If number of bits is larger than 16, the function will do nothing.
 */
- (void)appendWord:(uint16_t)word bitCount:(NSUInteger)bitCount;

/**
 * Add zero as missing bit(s) to the last byte
 */
- (void)finalizeArray;

@end


@interface FwiMutableBitArray (FwiMutableBitArrayCreation)

// Class's static constructors
+ (__autoreleasing FwiMutableBitArray *)mutableBitArray;

@end