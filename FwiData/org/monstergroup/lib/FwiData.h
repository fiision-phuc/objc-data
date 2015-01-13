//  Project name: FwiData
//  File name   : FwiData.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 3/8/13
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

#ifndef __FWI_DATA__
#define __FWI_DATA__


typedef NS_ENUM(NSInteger, FwiNetworkStatus) {
    kNetworkStatus_None                              = -1,
    kNetworkStatus_Unknown                           = NSURLErrorUnknown,
    kNetworkStatus_Cancelled                         = NSURLErrorCancelled,
    kNetworkStatus_BadURL                            = NSURLErrorBadURL,
    kNetworkStatus_TimedOut                          = NSURLErrorTimedOut,
    kNetworkStatus_UnsupportedURL                    = NSURLErrorUnsupportedURL,
    kNetworkStatus_CannotFindHost                    = NSURLErrorCannotFindHost,
    kNetworkStatus_CannotConnectToHost               = NSURLErrorCannotConnectToHost,
    kNetworkStatus_NetworkConnectionLost             = NSURLErrorNetworkConnectionLost,
    kNetworkStatus_DNSLookupFailed                   = NSURLErrorDNSLookupFailed,
    kNetworkStatus_HTTPTooManyRedirects              = NSURLErrorHTTPTooManyRedirects,
    kNetworkStatus_ResourceUnavailable               = NSURLErrorResourceUnavailable,
    kNetworkStatus_NotConnectedToInternet            = NSURLErrorNotConnectedToInternet,
    kNetworkStatus_RedirectToNonExistentLocation     = NSURLErrorRedirectToNonExistentLocation,
    kNetworkStatus_BadServerResponse                 = NSURLErrorBadServerResponse,
    kNetworkStatus_UserCancelledAuthentication       = NSURLErrorUserCancelledAuthentication,
    kNetworkStatus_UserAuthenticationRequired        = NSURLErrorUserAuthenticationRequired,
    kNetworkStatus_ZeroByteResource                  = NSURLErrorZeroByteResource,
    kNetworkStatus_CannotDecodeRawData               = NSURLErrorCannotDecodeRawData,
    kNetworkStatus_CannotDecodeContentData           = NSURLErrorCannotDecodeContentData,
    kNetworkStatus_CannotParseResponse               = NSURLErrorCannotParseResponse,
    kNetworkStatus_FileDoesNotExist                  = NSURLErrorFileDoesNotExist,
    kNetworkStatus_FileIsDirectory                   = NSURLErrorFileIsDirectory,
    kNetworkStatus_NoPermissionsToReadFile           = NSURLErrorNoPermissionsToReadFile,
    kNetworkStatus_DataLengthExceedsMaximum          = NSURLErrorDataLengthExceedsMaximum,
    // SSL errors
    kNetworkStatus_SecureConnectionFailed            = NSURLErrorSecureConnectionFailed,
    kNetworkStatus_ServerCertificateHasBadDate       = NSURLErrorServerCertificateHasBadDate,
    kNetworkStatus_ServerCertificateUntrusted        = NSURLErrorServerCertificateUntrusted,
    kNetworkStatus_ServerCertificateHasUnknownRoot   = NSURLErrorServerCertificateHasUnknownRoot,
    kNetworkStatus_ServerCertificateNotYetValid      = NSURLErrorServerCertificateNotYetValid,
    kNetworkStatus_ClientCertificateRejected         = NSURLErrorClientCertificateRejected,
    kNetworkStatus_ClientCertificateRequired         = NSURLErrorClientCertificateRequired,
    kNetworkStatus_CannotLoadFromNetwork             = NSURLErrorCannotLoadFromNetwork,
    // Download and file I/O errors
    kNetworkStatus_CannotCreateFile                  = NSURLErrorCannotCreateFile,
    kNetworkStatus_CannotOpenFile                    = NSURLErrorCannotOpenFile,
    kNetworkStatus_CannotCloseFile                   = NSURLErrorCannotCloseFile,
    kNetworkStatus_CannotWriteToFile                 = NSURLErrorCannotWriteToFile,
    kNetworkStatus_CannotRemoveFile                  = NSURLErrorCannotRemoveFile,
    kNetworkStatus_CannotMoveFile                    = NSURLErrorCannotMoveFile,
    kNetworkStatus_DownloadDecodingFailedMidStream   = NSURLErrorDownloadDecodingFailedMidStream,
    kNetworkStatus_DownloadDecodingFailedToComplete  = NSURLErrorDownloadDecodingFailedToComplete,

    kNetworkStatus_InternationalRoamingOff           = NSURLErrorInternationalRoamingOff,
    kNetworkStatus_CallIsActive                      = NSURLErrorCallIsActive,
    kNetworkStatus_DataNotAllowed                    = NSURLErrorDataNotAllowed,
    kNetworkStatus_RequestBodyStreamExhausted        = NSURLErrorRequestBodyStreamExhausted,
};

typedef NS_ENUM(NSInteger, FwiMethodType) {
	kMethodType_Copy    = 0x00,
	kMethodType_Delete  = 0x01,
    kMethodType_Get     = 0x02,
    kMethodType_Head    = 0x03,
    kMethodType_Link    = 0x04,
    kMethodType_Options = 0x05,
    kMethodType_Patch   = 0x06,
    kMethodType_Post    = 0x07,
    kMethodType_Purge   = 0x08,
    kMethodType_Put     = 0x09,
    kMethodType_Unlink  = 0x0a
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
#import "FwiJson.h"
// Codec
#import "FwiQRCode.h"
#import "NSData+FwiDer.h"
#import "NSString+FwiDer.h"
#import "NSData+FwiJson.h"
#import "NSString+FwiJson.h"
// Network
#import "FwiRequest.h"
#import "FwiDataParameter.h"
#import "FwiFormParameter.h"
#import "FwiMultipartParameter.h"
#import "FwiService.h"
#import "FwiRESTService.h"
#import "FwiSOAPService.h"
// Parser
#import "FwiCsvParser.h"


#endif