//  Project name: FwiData
//  File name   : FwiData.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 3/8/13
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

#ifndef __FWI_DATA__
#define __FWI_DATA__


typedef NS_ENUM(NSInteger, FwiECLevel) {
    kECLevel_L = 0,     //  ~7% correction
    kECLevel_M = 1,     // ~15% correction
    kECLevel_Q = 2,     // ~25% correction
    kECLevel_H = 3      // ~30% correction
};

typedef NS_ENUM(NSInteger, FwiQRMode) {
    kNumeric      = 0x1,
    kAlphanumeric = 0x2,
    kBytes        = 0x4,
    kKanji        = 0x8
};

typedef NS_ENUM(NSInteger, FwiQRVersion) {
    kVersion_1	= 1,
    kVersion_2	= 2,
    kVersion_3	= 3,
    kVersion_4  = 4,
    kVersion_5	= 5,
    kVersion_6	= 6,
    kVersion_7	= 7,
    kVersion_8	= 8,
    kVersion_9	= 9,
    kVersion_10 = 10,
    kVersion_11 = 11,
    kVersion_12 = 12,
    kVersion_13 = 13,
    kVersion_14 = 14,
    kVersion_15 = 15,
    kVersion_16 = 16,
    kVersion_17 = 17,
    kVersion_18 = 18,
    kVersion_19 = 19,
    kVersion_20 = 20,
    kVersion_21 = 21,
    kVersion_22 = 22,
    kVersion_23 = 23,
    kVersion_24 = 24,
    kVersion_25 = 25,
    kVersion_26 = 26,
    kVersion_27 = 27,
    kVersion_28 = 28,
    kVersion_29 = 29,
    kVersion_30 = 30,
    kVersion_31 = 31,
    kVersion_32 = 32,
    kVersion_33 = 33,
    kVersion_34 = 34,
    kVersion_35 = 35,
    kVersion_36 = 36,
    kVersion_37 = 37,
    kVersion_38 = 38,
    kVersion_39 = 39,
    kVersion_40 = 40
};

typedef NS_ENUM(NSInteger, FwiHttpMethod) {
    kCopy    = 0x00,
    kDelete  = 0x01,
    kGet     = 0x02,
    kHead    = 0x03,
    kLink    = 0x04,
    kOptions = 0x05,
    kPatch   = 0x06,
    kPost    = 0x07,
    kPurge   = 0x08,
    kPut     = 0x09,
    kUnlink  = 0x0a
};

typedef NS_ENUM(NSInteger, FwiNetworkStatus) {
    kNone                              = -1,
    kUnknown                           = NSURLErrorUnknown,
    kCancelled                         = NSURLErrorCancelled,
    kBadURL                            = NSURLErrorBadURL,
    kTimedOut                          = NSURLErrorTimedOut,
    kUnsupportedURL                    = NSURLErrorUnsupportedURL,
    kCannotFindHost                    = NSURLErrorCannotFindHost,
    kCannotConnectToHost               = NSURLErrorCannotConnectToHost,
    kNetworkConnectionLost             = NSURLErrorNetworkConnectionLost,
    kDNSLookupFailed                   = NSURLErrorDNSLookupFailed,
    kHTTPTooManyRedirects              = NSURLErrorHTTPTooManyRedirects,
    kResourceUnavailable               = NSURLErrorResourceUnavailable,
    kNotConnectedToInternet            = NSURLErrorNotConnectedToInternet,
    kRedirectToNonExistentLocation     = NSURLErrorRedirectToNonExistentLocation,
    kBadServerResponse                 = NSURLErrorBadServerResponse,
    kUserCancelledAuthentication       = NSURLErrorUserCancelledAuthentication,
    kUserAuthenticationRequired        = NSURLErrorUserAuthenticationRequired,
    kZeroByteResource                  = NSURLErrorZeroByteResource,
    kCannotDecodeRawData               = NSURLErrorCannotDecodeRawData,
    kCannotDecodeContentData           = NSURLErrorCannotDecodeContentData,
    kCannotParseResponse               = NSURLErrorCannotParseResponse,
    kFileDoesNotExist                  = NSURLErrorFileDoesNotExist,
    kFileIsDirectory                   = NSURLErrorFileIsDirectory,
    kNoPermissionsToReadFile           = NSURLErrorNoPermissionsToReadFile,
    kDataLengthExceedsMaximum          = NSURLErrorDataLengthExceedsMaximum,
    // SSL errors
    kSecureConnectionFailed            = NSURLErrorSecureConnectionFailed,
    kServerCertificateHasBadDate       = NSURLErrorServerCertificateHasBadDate,
    kServerCertificateUntrusted        = NSURLErrorServerCertificateUntrusted,
    kServerCertificateHasUnknownRoot   = NSURLErrorServerCertificateHasUnknownRoot,
    kServerCertificateNotYetValid      = NSURLErrorServerCertificateNotYetValid,
    kClientCertificateRejected         = NSURLErrorClientCertificateRejected,
    kClientCertificateRequired         = NSURLErrorClientCertificateRequired,
    kCannotLoadFromNetwork             = NSURLErrorCannotLoadFromNetwork,
    // Download and file I/O errors
    kCannotCreateFile                  = NSURLErrorCannotCreateFile,
    kCannotOpenFile                    = NSURLErrorCannotOpenFile,
    kCannotCloseFile                   = NSURLErrorCannotCloseFile,
    kCannotWriteToFile                 = NSURLErrorCannotWriteToFile,
    kCannotRemoveFile                  = NSURLErrorCannotRemoveFile,
    kCannotMoveFile                    = NSURLErrorCannotMoveFile,
    kDownloadDecodingFailedMidStream   = NSURLErrorDownloadDecodingFailedMidStream,
    kDownloadDecodingFailedToComplete  = NSURLErrorDownloadDecodingFailedToComplete,

    kInternationalRoamingOff           = NSURLErrorInternationalRoamingOff,
    kCallIsActive                      = NSURLErrorCallIsActive,
    kDataNotAllowed                    = NSURLErrorDataNotAllowed,
    kRequestBodyStreamExhausted        = NSURLErrorRequestBodyStreamExhausted,
};


// Validate network status
static inline BOOL FwiNetworkStatusIsSuccces(FwiNetworkStatus statusCode) {
    return (200 <= statusCode && statusCode <= 299);
}


// Data structures
#import "FwiBigInt.h"
#import "FwiBitArray.h"
#import "FwiMutableBitArray.h"
#import "FwiBitMatrix.h"
#import "FwiDer.h"
#import "FwiJsonMapper.h"
#import "FwiProperty.h"
#import "FwiQRCode.h"
// Codec
#import "NSData+FwiDer.h"
#import "NSString+FwiDer.h"
// Network
#import "FwiRequest.h"
#import "FwiDataParam.h"
#import "FwiFormParam.h"
#import "FwiMultipartParam.h"
#import "FwiService.h"
// Parser
#import "FwiCsvParser.h"


#endif