//  Project name: FwiData
//  File name   : FwiBitMatrix.h
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


@interface FwiBitMatrix : NSObject <NSCoding> {

@private
    NSMutableArray *_matrix;
}

@property (nonatomic, readonly) NSUInteger size;


/**
 * Change the value of a bit at specific coordinate. If coordinate is invalid, the function will do
 * nothing.
 *
 * Value:   YES = 1
 *          NO  = 0
 */
- (void)changeBit:(BOOL)bit atRow:(NSUInteger)row andCol:(NSUInteger)col;

/**
 * Zero out all bits within bitMatrix
 */
- (void)clean;

/**
 * Return bit value at specific coordinate
 */
- (BOOL)bitAtRow:(NSUInteger)row andCol:(NSUInteger)col;

@end


@interface FwiBitMatrix (FwiBitMatrixCreation)

// Class's static constructors
+ (__autoreleasing FwiBitMatrix *)bitMatrixWithSize:(NSUInteger)size;

// Class's constructors
- (id)initWithSize:(NSUInteger)size;

@end