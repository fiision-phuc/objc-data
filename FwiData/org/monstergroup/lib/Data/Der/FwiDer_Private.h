//  Project name: FwiData
//  File name   : FwiDer_Private.h
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


#define kFwiDerLengthLevel_1        0x81
#define kFwiDerLengthLevel_2        0x82
#define kFwiDerLengthLevel_3        0x83
#define kFwiDerLengthLevel_4        0x84


typedef NS_ENUM(NSInteger, FwiDerClass) {
    kFwiDerClass_Universal          = 0x00,
	kFwiDerClass_Application        = 0x40,
	kFwiDerClass_ContextSpecific    = 0x80
};

typedef NS_ENUM(NSInteger, FwiDerValue) {
	kFwiDerValue_Boolean            = 0x01, // Primitive
	kFwiDerValue_Integer            = 0x02, // Primitive
	kFwiDerValue_BitString          = 0x03, // Primitive
	kFwiDerValue_OctetString        = 0x04, // Primitive
	kFwiDerValue_Null               = 0x05, // Primitive
	kFwiDerValue_ObjectIdentifier   = 0x06, // Primitive
	kFwiDerValue_Enumerated         = 0x0a, // Primitive
	kFwiDerValue_Utf8String         = 0x0c, // Primitive
	kFwiDerValue_NumericString      = 0x12, // Primitive
	kFwiDerValue_PrintableString    = 0x13, // Primitive
	kFwiDerValue_T61String          = 0x14, // Primitive
//	kFwiDerValue_VideotexString     = 0x15, // Primitive    // Not supported
	kFwiDerValue_Ia5String          = 0x16, // Primitive
	kFwiDerValue_UtcTime            = 0x17, // Primitive
	kFwiDerValue_GeneralizedTime    = 0x18, // Primitive
	kFwiDerValue_GraphicString      = 0x19, // Primitive
	kFwiDerValue_VisibleString      = 0x1a, // Primitive
	kFwiDerValue_GeneralString      = 0x1b, // Primitive
	kFwiDerValue_UniversalString    = 0x1c, // Primitive
	kFwiDerValue_BmpString          = 0x1e, // Primitive
    
    kFwiDerValue_Sequence           = 0x10, // Constructed
	kFwiDerValue_Set                = 0x11  // Constructed
};


// Define private macro functions
static inline BOOL FwiValidateDerClass(FwiDerClass value) {
    switch (value) {
        case kFwiDerClass_Universal:
        case kFwiDerClass_Application:
        case kFwiDerClass_ContextSpecific: {
            return YES;
        }
        default: {
            return NO;
        }
    }
}
static inline BOOL FwiValidateDerValue(FwiDerValue value) {
    switch (value) {
        case kFwiDerValue_Boolean:
        case kFwiDerValue_Integer:
        case kFwiDerValue_BitString:
        case kFwiDerValue_OctetString:
        case kFwiDerValue_Null:
        case kFwiDerValue_ObjectIdentifier:
        case kFwiDerValue_Enumerated:
        case kFwiDerValue_Utf8String:
        case kFwiDerValue_NumericString:
        case kFwiDerValue_PrintableString:
        case kFwiDerValue_T61String:
        case kFwiDerValue_Ia5String:
        case kFwiDerValue_UtcTime:
        case kFwiDerValue_GeneralizedTime:
        case kFwiDerValue_GraphicString:
        case kFwiDerValue_VisibleString:
        case kFwiDerValue_GeneralString:
        case kFwiDerValue_UniversalString:
        case kFwiDerValue_BmpString:
        case kFwiDerValue_Sequence:
        case kFwiDerValue_Set: {
            return YES;
        }
        default: {
            return NO;
        }
    }
}

static inline FwiDerClass FwiGetDerClass(uint8_t identifier) {
    return (FwiDerClass)(identifier & 0xc0);
}
static inline FwiDerValue FwiGetDerValue(uint8_t identifier) {
    return (FwiDerValue)(identifier & 0x1f);
}

static inline NSString* FwiGetDerClassDescription(FwiDerClass identifier) {
    switch (identifier) {
        case kFwiDerClass_Universal      : return @"U";
        case kFwiDerClass_Application    : return @"A";
        case kFwiDerClass_ContextSpecific: return @"C";
        default                          : return nil;
    }
}
static inline NSString* FwiGetDerValueDescription(FwiDerValue identifier) {
    switch (identifier) {
        case kFwiDerValue_Boolean         : return @"Boolean";
        case kFwiDerValue_Integer         : return @"Integer";
        case kFwiDerValue_BitString       : return @"Bit-String";
        case kFwiDerValue_OctetString     : return @"Octet-String";
        case kFwiDerValue_Null            : return @"Null";
        case kFwiDerValue_ObjectIdentifier: return @"Object-Identifier";
        case kFwiDerValue_Enumerated      : return @"Enumerated";
        case kFwiDerValue_Utf8String      : return @"UTF8-String";
        case kFwiDerValue_NumericString   : return @"Numeric-String";
        case kFwiDerValue_PrintableString : return @"Printable-String";
        case kFwiDerValue_T61String       : return @"T61-String";
//        case kFwiDerValue_VideotexString  : return @"Videotex-String";
        case kFwiDerValue_Ia5String       : return @"IA5-String";
        case kFwiDerValue_UtcTime         : return @"UTC-Time";
        case kFwiDerValue_GeneralizedTime : return @"GMT-Time";
        case kFwiDerValue_GraphicString   : return @"Graphic-String";
        case kFwiDerValue_VisibleString   : return @"Visible-String";
        case kFwiDerValue_GeneralString   : return @"General-String";
        case kFwiDerValue_UniversalString : return @"Universal-String";
        case kFwiDerValue_BmpString       : return @"BMP-String";
            
        case kFwiDerValue_Sequence        : return @"Sequence";
        case kFwiDerValue_Set             : return @"Set";
            
        default                           : return nil;
    }
}


@interface FwiDer () {
    
    uint8_t _identifier;
    FwiDerClass _derClass;
    FwiDerValue _derValue;
}

@property (nonatomic, readonly) uint8_t identifier;
@property (nonatomic, readonly) FwiDerClass derClass;
@property (nonatomic, readonly) FwiDerValue derValue;

@property (nonatomic, readonly) NSData *internalContent;


/** Return DER's description. */
- (__autoreleasing NSString *)_objectDescription:(FwiDer *)der spaceIndent:(NSString *)spaceIndent;

@end


@interface FwiDer (FwiDerCreation_Private)

// Class's constructors
- (id)initWithIdentifier:(uint8_t)identifier;

@end