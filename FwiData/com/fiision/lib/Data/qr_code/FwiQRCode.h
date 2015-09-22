//  Project name: FwiData
//  File name   : FwiQRCode.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 9/23/12
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


@interface FwiQRCode : NSObject {

@private
	FwiQRMode _mode;
	FwiECLevel _level;
	FwiQRVersion _version;
}

@property (nonatomic, readonly) FwiQRMode mode;
@property (nonatomic, readonly) FwiECLevel level;
@property (nonatomic, readonly) FwiQRVersion version;


/** Generate QRCode. */
- (void)encode;

/**
 * Generate QRCode image with prefer image's size. However, the function will check  if  the  prefer
 * size is less than the minimun size of QRCode image (1 pixel * 4), the minimum size will be  used.
 */
- (__autoreleasing UIImage *)generateImage:(NSUInteger)preferSize transparentBackground:(BOOL)transparent;

@end


@interface FwiQRCode (FwiQRCodeCreation)

/**
 * If the text length is greater than 4296, QREncode will not be generated.
 */
+ (__autoreleasing FwiQRCode *)alphanumeric:(NSString *)text ECLevel:(FwiECLevel)level;
/**
 * If the text length is greater than 7089, QREncode will not be generated.
 */
+ (__autoreleasing FwiQRCode *)numeric:(NSString *)text ECLevel:(FwiECLevel)level;
/**
 * If the text length is greater than 2953, QREncode will not be generated.
 */
+ (__autoreleasing FwiQRCode *)bytes:(NSString *)text ECLevel:(FwiECLevel)level;
/**
 * If the text length is greater than 1817, QREncode will not be generated.
 */
+ (__autoreleasing FwiQRCode *)kanji:(NSString *)text ECLevel:(FwiECLevel)level;


// Class's constructors
- (id)initWithString:(NSString *)text Mode:(FwiQRMode)mode ECLevel:(FwiECLevel)level;

@end