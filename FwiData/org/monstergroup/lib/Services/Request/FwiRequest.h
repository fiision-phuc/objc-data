//  Project name: FwiData
//  File name   : FwiRequest.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 8/4/13
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


@interface FwiRequest : NSMutableURLRequest {
}

@property (nonatomic, assign) BOOL enableGZip;


/** Build the request. */
- (size_t)prepare;

@end


@interface FwiRequest (FwiRequestCreation)

// Class's static constructors
+ (__autoreleasing FwiRequest *)requestWithURL:(NSURL *)url methodType:(FwiMethodType)type;

// Class's constructors
- (id)initWithURL:(NSURL *)url methodType:(FwiMethodType)type;

@end


@interface FwiRequest (FwiForm)

/** Add key-value. */
- (void)addFormParameter:(id)parameter;
- (void)addFormParameters:(id)parameter, ... NS_REQUIRES_NIL_TERMINATION;
/** Like add parameters but will reset the collection. */
- (void)setFormParameter:(id)parameter;
- (void)setFormParameters:(id)parameter, ... NS_REQUIRES_NIL_TERMINATION;

/** Add multipart data. */
- (void)addMultipartParameter:(id)parameter;
- (void)addMultipartParameters:(id)parameter, ... NS_REQUIRES_NIL_TERMINATION;
/** Like add multipart data but will reset the collection. */
- (void)setMultipartParameter:(id)parameter;
- (void)setMultipartParameters:(id)parameter, ... NS_REQUIRES_NIL_TERMINATION;

@end


@interface FwiRequest (FwiRaw)

/** Inject raw data to request. Previous raw data will be replaced. */
- (void)setDataParameter:(id)parameter;

@end