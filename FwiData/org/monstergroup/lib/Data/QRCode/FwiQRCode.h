//  Project name: FwiData
//  File name   : FwiQRCode.h
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


typedef NS_ENUM(NSInteger, FwiECLevel) {
	kECLevel_L = 0,     //  ~7% correction
	kECLevel_M = 1,     // ~15% correction
	kECLevel_Q = 2,     // ~25% correction
	kECLevel_H = 3      // ~30% correction
};

typedef NS_ENUM(NSInteger, FwiQRMode) {
	kMode_Numeric      = 0x1,
	kMode_Alphanumeric = 0x2,
	kMode_Bytes        = 0x4,
	kMode_Kanji        = 0x8
};

typedef NS_ENUM(NSInteger, FwiQRVersion) {
	kVersion_1	= 1,	kVersion_2	= 2,	kVersion_3	= 3,    kVersion_4  = 4,
    kVersion_5	= 5,	kVersion_6	= 6,    kVersion_7	= 7,	kVersion_8	= 8,
    kVersion_9	= 9,    kVersion_10 = 10,	kVersion_11 = 11,	kVersion_12 = 12,
	kVersion_13 = 13,	kVersion_14 = 14,	kVersion_15 = 15,   kVersion_16 = 16,
    kVersion_17 = 17,	kVersion_18 = 18,   kVersion_19 = 19,	kVersion_20 = 20,
    kVersion_21 = 21,   kVersion_22 = 22,	kVersion_23 = 23,	kVersion_24 = 24,
    kVersion_25 = 25,	kVersion_26 = 26,	kVersion_27 = 27,   kVersion_28 = 28,
    kVersion_29 = 29,	kVersion_30 = 30,   kVersion_31 = 31,	kVersion_32 = 32,
    kVersion_33 = 33,   kVersion_34 = 34,	kVersion_35 = 35,	kVersion_36 = 36,
	kVersion_37 = 37,	kVersion_38 = 38,	kVersion_39 = 39,   kVersion_40 = 40
};


@interface FwiQRCode : NSObject {

@private
	FwiQRMode    _mode;
	FwiECLevel   _level;
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