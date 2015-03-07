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
