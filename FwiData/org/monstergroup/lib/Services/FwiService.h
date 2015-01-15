//  Project name: FwiData
//  File name   : FwiService.h
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


@protocol FwiServiceDelegate;


@interface FwiService : FwiOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate> {

@private
    NSURLConnection   *_con;
    NSURLRequest      *_req;
    NSHTTPURLResponse *_res;
}

@property (nonatomic, assign) id<FwiOperationDelegate, FwiServiceDelegate> delegate;

@end


@interface FwiService (FwiServiceCreation)

// Class's static constructors
+ (__autoreleasing FwiService *)serviceWithRequest:(FwiRequest *)request;

+ (__autoreleasing FwiService *)serviceWithURL:(NSURL *)url;
+ (__autoreleasing FwiService *)serviceWithURL:(NSURL *)url method:(FwiMethodType)method;
+ (__autoreleasing FwiService *)serviceWithURL:(NSURL *)url method:(FwiMethodType)method requestMessage:(FwiJson *)requestMessage;
+ (__autoreleasing FwiService *)serviceWithURL:(NSURL *)url method:(FwiMethodType)method requestDictionary:(NSDictionary *)requestDictionary;

// Class's constructors
- (id)initWithRequest:(FwiRequest *)request;

@end


@interface FwiService (FwiExtension)

/** Execute with completion/failure blocks. */
- (void)executeWithCompletion:(void(^)(NSURL *locationPath, NSError *error, NSInteger statusCode))completion;

@end


@protocol FwiServiceDelegate <FwiOperationDelegate>

@optional
/** Request authentication permission from delegate. */
- (BOOL)service:(FwiService *)service authenticationChallenge:(SecCertificateRef)certificateRef;

/** Notify receive data process. */
- (void)service:(FwiService *)service totalBytesWillReceive:(NSUInteger)totalBytes;
//- (void)service:(FwiService *)service totalBytesDidReceive:(NSUInteger)totalBytes;
- (void)service:(FwiService *)service bytesReceived:(NSUInteger)bytes;

@end