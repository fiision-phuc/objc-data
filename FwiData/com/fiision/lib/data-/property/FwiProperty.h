//  Project name: FwiData
//  File name   : FwiProperty.h
//
//  Author      : Phuc Tran
//  Created date: 2/18/15
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

#import <objc/runtime.h>


@interface FwiProperty : NSObject {
    
@private
    objc_property_t _property;
}

@property (nonatomic, readonly) BOOL isAssign;
@property (nonatomic, readonly) BOOL isCopy;
@property (nonatomic, readonly) BOOL isDynamic;
@property (nonatomic, readonly) BOOL isNonatomic;
@property (nonatomic, readonly) BOOL isReadonly;
@property (nonatomic, readonly) BOOL isRetain;

@property (nonatomic, readonly) BOOL isWeak;
@property (nonatomic, readonly) BOOL isWeakReference;

@property (nonatomic, readonly) BOOL isBlock;
@property (nonatomic, readonly) BOOL isCollection;
@property (nonatomic, readonly) BOOL isId;
@property (nonatomic, readonly) BOOL isObject;
@property (nonatomic, readonly) BOOL isPrimitive;

@property (nonatomic, readonly) SEL  getter;
@property (nonatomic, readonly) SEL  customGetter;
@property (nonatomic, readonly) SEL  setter;
@property (nonatomic, readonly) SEL  customSetter;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *ivarName;
@property (nonatomic, readonly) Class propertyClass;

/**
 * https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
 *
 * - `R`                    The property is read-only (`readonly`)
 * - `C`                    The property is a copy of the value last assigned (`copy`)
 * - `&`                    The property is a reference to the value last assigned (`retain`)
 * - `N`                    The property is non-atomic (`nonatomic`)
 * - `G<myGetter>`          The property defines a custom getter selector myGetter. The name follows the `G` (for example, `GmyGetter`)
 * - `S<mySetter:>`         The property defines a custom setter selector mySetter. The name follows the `S` (for example, `SmySetter:`)
 * - `D`                    The property is dynamic (`@dynamic`)
 * - `W`                    The property is a weak reference (`__weak`)
 * - `P`                    The property is eligible for garbage collection
 * - `t<encoding>`          Specifies the type using old-style encoding
 */
@property (nonatomic, readonly) NSString *propertyType;

/**
 * https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 *
 * - `c`                    A char (including `BOOL`)
 * - `i`                    An int
 * - `s`                    A short
 * - `l`                    A long (l is treated as a 32-bit quantity on 64-bit programs)
 * - `q`                    A long long
 * - `C`                    An unsigned char
 * - `I`                    An unsigned int
 * - `S`                    An unsigned short
 * - `L`                    An unsigned long
 * - `Q`                    An unsigned long long
 * - `f`                    A float
 * - `d`                    A double
 * - `B`                    A C++ bool or a C99 _Bool
 * - `v`                    A void
 * - `*`                    A character string (`char *`)
 * - `@`                    An object (whether statically typed or typed id)
 * - `#`                    A class object (`Class`)
 * - `:`                    A method selector (`SEL`)
 * - `[array type]`         An array
 * - `{name=type...}`       A structure
 * - `(name=type...)`       A union
 * - `bNUM`                 A bit field of num bits
 * - `^type`                A pointer to type
 * - `?`                    An unknown type (among other things, this code is used for function pointers)
 */
@property (nonatomic, readonly) NSString *typeEncoding;
@property (nonatomic, readonly) NSString *typeOldEncoding;


/** Test whether you can assign value to property. */
- (BOOL)canAssignValue:(id)value;

@end


@interface FwiProperty (FwiPropertyCreation)

// Class's static constructors
+ (__autoreleasing NSArray *)propertiesWithClass:(Class)aClass;
+ (__autoreleasing FwiProperty *)propertyWithObjCProperty:(objc_property_t)property;

// Class's constructors
- (id)initWithObjCProperty:(objc_property_t)property;

@end
