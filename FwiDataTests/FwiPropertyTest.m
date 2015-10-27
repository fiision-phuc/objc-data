//  Project name: FwiData
//  File name   : FwiPropertyTest.m
//
//  Author      : Phuc Tran
//  Created date: 2/17/15
//  Version     : 1.00
//  --------------------------------------------------------------
//  Copyright (c) 2015 FWI Group. All rights reserved.
//  --------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>


@interface ParentModel: NSObject {
}

@property (nonatomic, assign) NSInteger assignProperty;
@property (nonatomic, assign) BOOL boolProperty;

@property (nonatomic, assign, getter=isAvailable, setter=updateAvailable:) BOOL available;

@property (nonatomic, copy) NSString *cpyProperty;
@property (nonatomic, retain) NSString *retainProperty;
@property (nonatomic, retain, readonly) NSString *readonlyProperty;

@property (nonatomic, retain) NSSet *nssetProperty;
@property (nonatomic, retain) NSArray *nsarrayProperty;

@property (nonatomic, retain) NSDictionary *dictionaryProperty;

@property (nonatomic, retain) NSDate *dateProperty;
@property (nonatomic, assign) CLLocationCoordinate2D locationProperty;
@property (nonatomic, retain) NSURL *urlProperty;

@property (nonatomic, retain) ParentModel *modelProperty;
@property (nonatomic, assign) ParentModel *weakModelProperty;

@property (nonatomic, retain) id idProperty;

@end


@interface ChildModel: ParentModel {
}

@property (nonatomic, retain) NSString *stringProperty;
@property (nonatomic, retain) NSNumber *numberProperty;

@end


@implementation ParentModel
@end


@implementation ChildModel
@end


@interface FwiPropertyTest : XCTestCase {

@private
    FwiProperty *_assignProperty;
    FwiProperty *_boolProperty;

    FwiProperty *_availableProperty;

    FwiProperty *_copyProperty;
    FwiProperty *_retainProperty;
    FwiProperty *_readonlyProperty;

    FwiProperty *_nssetProperty;
    FwiProperty *_nsarrayProperty;

    FwiProperty *_nsdictionaryProperty;

    FwiProperty *_dateProperty;
    FwiProperty *_locationProperty;
    FwiProperty *_urlProperty;

    FwiProperty *_modelProperty;
    FwiProperty *_weakModelProperty;

    FwiProperty *_idProperty;
}

@end


@implementation FwiPropertyTest


#pragma mark - Setup
- (void)setUp {
    [super setUp];

    __autoreleasing NSArray *properties = [FwiProperty propertiesWithClass:[ParentModel class]];
    for (__weak FwiProperty *property in properties) {
        if ([property.name isEqualToString:@"assignProperty"]) {
            _assignProperty = property;
        }
        else if ([property.name isEqualToString:@"boolProperty"]) {
            _boolProperty = property;
        }
        else if ([property.name isEqualToString:@"available"]) {
            _availableProperty = property;
        }
        else if ([property.name isEqualToString:@"cpyProperty"]) {
            _copyProperty = property;
        }
        else if ([property.name isEqualToString:@"retainProperty"]) {
            _retainProperty = property;
        }
        else if ([property.name isEqualToString:@"readonlyProperty"]) {
            _readonlyProperty = property;
        }
        else if ([property.name isEqualToString:@"nssetProperty"]) {
            _nssetProperty = property;
        }
        else if ([property.name isEqualToString:@"nsarrayProperty"]) {
            _nsarrayProperty = property;
        }
        else if ([property.name isEqualToString:@"dictionaryProperty"]) {
            _nsdictionaryProperty = property;
        }
        else if ([property.name isEqualToString:@"dateProperty"]) {
            _dateProperty = property;
        }
        else if ([property.name isEqualToString:@"locationProperty"]) {
            _locationProperty = property;
        }
        else if ([property.name isEqualToString:@"urlProperty"]) {
            _urlProperty = property;
        }
        else if ([property.name isEqualToString:@"modelProperty"]) {
            _modelProperty = property;
        }
        else if ([property.name isEqualToString:@"weakModelProperty"]) {
            _weakModelProperty = property;
        }
        else if ([property.name isEqualToString:@"idProperty"]) {
            _idProperty = property;
        }
    }
}


#pragma mark - Tear Down
- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


#pragma mark - Test Cases
- (void)testCreation {
    __autoreleasing FwiProperty *defaultProperty = [FwiProperty propertyWithObjCProperty:nil];
    XCTAssertFalse(defaultProperty.isAssign, @"Default property should return false.");
    XCTAssertFalse(defaultProperty.isCopy, @"Default property should return false.");
    XCTAssertFalse(defaultProperty.isDynamic, @"Default property should return false.");
    XCTAssertFalse(defaultProperty.isNonatomic, @"Default property should return false.");
    XCTAssertFalse(defaultProperty.isReadonly, @"Default property should return false.");
    XCTAssertFalse(defaultProperty.isRetain, @"Default property should return false.");
    XCTAssertFalse(defaultProperty.isWeak, @"Default property should return false.");
    XCTAssertFalse(defaultProperty.isWeakReference, @"Default property should return false.");
    XCTAssertFalse(defaultProperty.isBlock, @"Default property should return false.");
    XCTAssertFalse(defaultProperty.isCollection, @"Default property should return false.");
    XCTAssertFalse(defaultProperty.isId, @"Default property should return false.");
    XCTAssertFalse(defaultProperty.isObject, @"Default property should return false.");
    XCTAssertFalse(defaultProperty.isPrimitive, @"Default property should return false.");
    XCTAssertNil(defaultProperty.name, @"Default property's name should be empty, but found %@", defaultProperty.name);
    XCTAssertNil(defaultProperty.ivarName, @"Default property's ivarName should be empty, but found %@", defaultProperty.ivarName);
    XCTAssertNil(defaultProperty.propertyClass, @"Default property should not have a propertyClass.");
    XCTAssertNil(defaultProperty.propertyType, @"Default property should not have a propertyType.");
    XCTAssertNil(defaultProperty.typeEncoding, @"Default property's Type Encoding should be nil, but found \(defaultProperty.typeEncoding)");
    XCTAssertNil(defaultProperty.typeOldEncoding, @"Default property's Type Old Encoding should be nil, but found \(defaultProperty.typeEncoding)");


    XCTAssertNil([FwiProperty propertiesWithClass:nil], @"List should be nil.");

    __autoreleasing NSArray *properties = [FwiProperty propertiesWithClass:[ParentModel class]];
    XCTAssertNotNil(properties, @"List must not be nil.");
    XCTAssertEqual(properties.count, 15, @"List must have 15, but found %li", (unsigned long)properties.count);

    properties = [FwiProperty propertiesWithClass:[ChildModel class]];
    XCTAssertNotNil(properties, @"List must not be nil.");
    XCTAssertEqual(properties.count, 17, @"List must have 17, but found %li", (unsigned long)properties.count);
}

- (void)testAssignProperty {
    XCTAssertTrue(_assignProperty.isAssign, @"Setter semantics should be assign.");
    XCTAssertFalse(_assignProperty.isCopy, @"Setter semantics should not be copied.");
    XCTAssertFalse(_assignProperty.isDynamic, @"Setter semantics should not be dynamic.");
    XCTAssertTrue(_assignProperty.isNonatomic, @"Setter semantics should be non-atomic.");
    XCTAssertFalse(_assignProperty.isReadonly, @"Property should not be read-only.");
    XCTAssertFalse(_assignProperty.isRetain, @"Property should not be retain.");
    XCTAssertFalse(_assignProperty.isWeak, @"Property should not be weak.");
    XCTAssertFalse(_assignProperty.isBlock, @"Property should not be block.");
    XCTAssertFalse(_assignProperty.isCollection, @"Property should not be collection.");
    XCTAssertFalse(_assignProperty.isId, @"Property should not be id.");
    XCTAssertFalse(_assignProperty.isObject, @"Property should not be object.");
    XCTAssertTrue(_assignProperty.isPrimitive, @"Property should be primitive.");
    XCTAssertEqualObjects(_assignProperty.name, @"assignProperty", @"Name should be assignProperty, but found %@.", _assignProperty.name);
    XCTAssertEqualObjects(_assignProperty.ivarName, @"_assignProperty", @"ivarName should be assignProperty, but found %@.", _assignProperty.ivarName);
    XCTAssertNil(_assignProperty.propertyClass, @"Property should not have a propertyClass.");
    XCTAssertEqualObjects(_assignProperty.typeEncoding, @"i", @"Type encoding should be i, but found %@.", _assignProperty.typeEncoding);

    XCTAssertTrue(_boolProperty.isAssign, @"Setter semantics should be assign.");
    XCTAssertFalse(_boolProperty.isCopy, @"Setter semantics should not be copied.");
    XCTAssertFalse(_boolProperty.isDynamic, @"Setter semantics should not be dynamic.");
    XCTAssertTrue(_boolProperty.isNonatomic, @"Setter semantics should be non-atomic.");
    XCTAssertFalse(_boolProperty.isReadonly, @"Property should not be read-only.");
    XCTAssertFalse(_boolProperty.isRetain, @"Property should not be retain.");
    XCTAssertFalse(_boolProperty.isWeak, @"Property should not be weak.");
    XCTAssertFalse(_boolProperty.isBlock, @"Property should not be block.");
    XCTAssertFalse(_boolProperty.isCollection, @"Property should not be collection.");
    XCTAssertFalse(_boolProperty.isId, @"Property should not be id.");
    XCTAssertFalse(_boolProperty.isObject, @"Property should not be object.");
    XCTAssertTrue(_boolProperty.isPrimitive, @"Property should be primitive.");
    XCTAssertEqualObjects(_boolProperty.name, @"boolProperty", @"Name should be boolProperty, but found %@.", _boolProperty.name);
    XCTAssertEqualObjects(_boolProperty.ivarName, @"_boolProperty", @"ivarName should be boolProperty, but found %@.", _boolProperty.ivarName);
    XCTAssertNil(_boolProperty.propertyClass, @"Property should not have a propertyClass.");
    XCTAssertEqualObjects(_boolProperty.typeEncoding, @"c", @"Type encoding should be c, but found %@.", _boolProperty.typeEncoding);
}

- (void)testRetainProperty {
    XCTAssertFalse(_retainProperty.isAssign, @"Setter semantics should not be assign.");
    XCTAssertFalse(_retainProperty.isCopy, @"Setter semantics should not be copied.");
    XCTAssertFalse(_retainProperty.isDynamic, @"Setter semantics should not be dynamic.");
    XCTAssertTrue(_retainProperty.isNonatomic, @"Setter semantics should be non-atomic.");
    XCTAssertFalse(_retainProperty.isReadonly, @"Retain property should not be read-only.");
    XCTAssertTrue(_retainProperty.isRetain, @"Retain property should be retain.");
    XCTAssertFalse(_retainProperty.isWeak, @"Retain property should not be weak.");
    XCTAssertFalse(_retainProperty.isBlock, @"Retain property should not be block.");
    XCTAssertFalse(_retainProperty.isCollection, @"Retain property should not be collection.");
    XCTAssertFalse(_retainProperty.isId, @"Retain property should not be id.");
    XCTAssertTrue(_retainProperty.isObject, @"Retain property should be object.");
    XCTAssertFalse(_retainProperty.isPrimitive, @"Retain property should not be primitive.");
    XCTAssertEqualObjects(_retainProperty.name, @"retainProperty", @"Name should be retainProperty, but found %@.", _retainProperty.name);
    XCTAssertEqualObjects(_retainProperty.ivarName, @"_retainProperty", @"ivarName should be retainProperty, but found %@.", _retainProperty.ivarName);
    XCTAssertNotNil(_retainProperty.propertyClass, @"Retain property should have a propertyClass.");
    XCTAssertEqualObjects(NSStringFromClass([_retainProperty.propertyClass class]), @"NSString", @"Class should be NSString, but found %@.", NSStringFromClass([_retainProperty.propertyClass class]));
    XCTAssertEqualObjects(_retainProperty.typeEncoding, @"@\"NSString\"", @"Type encoding should be @\"NSString\", but found %@.", _retainProperty.typeEncoding);
}

- (void)testReadonlyProperty {
    XCTAssertFalse(_readonlyProperty.isAssign, @"Setter semantics should be assign.");
    XCTAssertFalse(_readonlyProperty.isCopy, @"Setter semantics should not be copied.");
    XCTAssertFalse(_readonlyProperty.isDynamic, @"Setter semantics should not be dynamic.");
    XCTAssertTrue(_readonlyProperty.isNonatomic, @"Setter semantics should be non-atomic.");
    XCTAssertTrue(_readonlyProperty.isReadonly, @"Readonly property should be read-only.");
    XCTAssertFalse(_readonlyProperty.isBlock, @"Readonly property should not be block.");
    XCTAssertFalse(_readonlyProperty.isCollection, @"Readonly property should not be collection.");
    XCTAssertTrue(_readonlyProperty.isObject, @"Readonly property should be object.");
    XCTAssertFalse(_readonlyProperty.isPrimitive, @"Readonly property should not be primitive.");
    XCTAssertEqualObjects(_readonlyProperty.name, @"readonlyProperty", @"Name should be readonlyProperty, but found %@.", _readonlyProperty.name);
    XCTAssertEqualObjects(_readonlyProperty.ivarName, @"_readonlyProperty", @"Name should be readonlyProperty, but found %@.", _readonlyProperty.ivarName);
    XCTAssertNotNil(_readonlyProperty.propertyClass, @"Readonly property should have a propertyClass.");
    XCTAssertEqualObjects(NSStringFromClass([_readonlyProperty.propertyClass class]), @"NSString", @"Class should be NSString, but found %@.", NSStringFromClass([_readonlyProperty.propertyClass class]));
    XCTAssertEqualObjects(_readonlyProperty.typeEncoding, @"@\"NSString\"", @"Type encoding should be @, but found %@.", _readonlyProperty.typeEncoding);
}

- (void)testNSSetProperty {
    XCTAssertFalse(_nssetProperty.isAssign, @"Setter semantics should not be assign.");
    XCTAssertFalse(_nssetProperty.isCopy, @"Setter semantics should not be copied.");
    XCTAssertFalse(_nssetProperty.isDynamic, @"Setter semantics should not be dynamic.");
    XCTAssertTrue(_nssetProperty.isNonatomic, @"Setter semantics should be non-atomic.");
    XCTAssertFalse(_nssetProperty.isReadonly, @"NSSet property should not be read-only.");
    XCTAssertTrue(_nssetProperty.isRetain, @"NSSet property should be retain.");
    XCTAssertFalse(_nssetProperty.isWeak, @"NSSet property should not be weak.");
    XCTAssertFalse(_nssetProperty.isBlock, @"NSSet property should not be block.");
    XCTAssertTrue(_nssetProperty.isCollection, @"NSSet property should be collection.");
    XCTAssertFalse(_nssetProperty.isId, @"NSSet property should not be id.");
    XCTAssertTrue(_nssetProperty.isObject, @"NSSet property should be object.");
    XCTAssertFalse(_nssetProperty.isPrimitive, @"NSSet property should not be primitive.");
    XCTAssertEqualObjects(_nssetProperty.name, @"nssetProperty", @"Name should be nssetProperty, but found %@.", _nssetProperty.name);
    XCTAssertEqualObjects(_nssetProperty.ivarName, @"_nssetProperty", @"ivarName should be nssetProperty, but found %@.", _nssetProperty.ivarName);
    XCTAssertNotNil(_nssetProperty.propertyClass, @"NSSet property should have a propertyClass.");
    XCTAssertEqualObjects(NSStringFromClass([_nssetProperty.propertyClass class]), @"NSSet", @"Class should be NSSet, but found %@.", NSStringFromClass([_nssetProperty.propertyClass class]));
    XCTAssertEqualObjects(_nssetProperty.typeEncoding, @"@\"NSSet\"", @"Type encoding should be @\"NSSet\", but found %@.", _nssetProperty.typeEncoding);
}

- (void)testNSArrayProperty {
    XCTAssertFalse(_nsarrayProperty.isAssign, @"Setter semantics should not be assign.");
    XCTAssertFalse(_nsarrayProperty.isCopy, @"Setter semantics should not be copied.");
    XCTAssertFalse(_nsarrayProperty.isDynamic, @"Setter semantics should not be dynamic.");
    XCTAssertTrue(_nsarrayProperty.isNonatomic, @"Setter semantics should be non-atomic.");
    XCTAssertFalse(_nsarrayProperty.isReadonly, @"NSArray property should not be read-only.");
    XCTAssertTrue(_nsarrayProperty.isRetain, @"NSArray property should be retain.");
    XCTAssertFalse(_nsarrayProperty.isWeak, @"NSArray property should not be weak.");
    XCTAssertFalse(_nsarrayProperty.isBlock, @"NSArray property should not be block.");
    XCTAssertTrue(_nsarrayProperty.isCollection, @"NSArray property should be collection.");
    XCTAssertFalse(_nsarrayProperty.isId, @"NSArray property should not be id.");
    XCTAssertTrue(_nsarrayProperty.isObject, @"NSArray property should be object.");
    XCTAssertFalse(_nsarrayProperty.isPrimitive, @"NSArray property should not be primitive.");
    XCTAssertEqualObjects(_nsarrayProperty.name, @"nsarrayProperty", @"Name should be nsarrayProperty, but found %@.", _nsarrayProperty.name);
    XCTAssertEqualObjects(_nsarrayProperty.ivarName, @"_nsarrayProperty", @"ivarName should be nsarrayProperty, but found %@.", _nsarrayProperty.ivarName);
    XCTAssertNotNil(_nsarrayProperty.propertyClass, @"NSArray property should have a propertyClass.");
    XCTAssertEqualObjects(NSStringFromClass([_nsarrayProperty.propertyClass class]), @"NSArray", @"Class should be NSArray, but found %@.", NSStringFromClass([_nsarrayProperty.propertyClass class]));
    XCTAssertEqualObjects(_nsarrayProperty.typeEncoding, @"@\"NSArray\"", @"Type encoding should be @\"NSArray\", but found %@.", _nsarrayProperty.typeEncoding);
}

- (void)testNSDictionaryProperty {
    XCTAssertFalse(_nsdictionaryProperty.isAssign, @"Setter semantics should not be assign.");
    XCTAssertFalse(_nsdictionaryProperty.isCopy, @"Setter semantics should not be copied.");
    XCTAssertFalse(_nsdictionaryProperty.isDynamic, @"Setter semantics should not be dynamic.");
    XCTAssertTrue(_nsdictionaryProperty.isNonatomic, @"Setter semantics should be non-atomic.");
    XCTAssertFalse(_nsdictionaryProperty.isReadonly, @"NSDictionary property should not be read-only.");
    XCTAssertTrue(_nsdictionaryProperty.isRetain, @"NSDictionary property should be retain.");
    XCTAssertFalse(_nsdictionaryProperty.isWeak, @"NSDictionary property should not be weak.");
    XCTAssertFalse(_nsdictionaryProperty.isBlock, @"NSDictionary property should not be block.");
    XCTAssertTrue(_nsdictionaryProperty.isCollection, @"NSDictionary property should be collection.");
    XCTAssertFalse(_nsdictionaryProperty.isId, @"NSDictionary property should not be id.");
    XCTAssertTrue(_nsdictionaryProperty.isObject, @"NSDictionary property should be object.");
    XCTAssertFalse(_nsdictionaryProperty.isPrimitive, @"NSDictionary property should not be primitive.");
    XCTAssertEqualObjects(_nsdictionaryProperty.name, @"dictionaryProperty", @"Name should be nsdictionaryProperty, but found %@.", _nsdictionaryProperty.name);
    XCTAssertEqualObjects(_nsdictionaryProperty.ivarName, @"_dictionaryProperty", @"ivarName should be nsdictionaryProperty, but found %@.", _nsdictionaryProperty.ivarName);
    XCTAssertNotNil(_nsdictionaryProperty.propertyClass, @"NSDictionary property should have a propertyClass.");
    XCTAssertEqualObjects(NSStringFromClass([_nsdictionaryProperty.propertyClass class]), @"NSDictionary", @"Class should be NSDictionary, but found %@.", NSStringFromClass([_nsdictionaryProperty.propertyClass class]));
    XCTAssertEqualObjects(_nsdictionaryProperty.typeEncoding, @"@\"NSDictionary\"", @"Type encoding should be @\"NSDictionary\", but found %@.", _nsdictionaryProperty.typeEncoding);
}

- (void)testLocationProperty {
    XCTAssertTrue(_locationProperty.isAssign, @"Setter semantics should be assign.");
    XCTAssertFalse(_locationProperty.isCopy, @"Setter semantics should not be copied.");
    XCTAssertFalse(_locationProperty.isDynamic, @"Setter semantics should not be dynamic.");
    XCTAssertTrue(_locationProperty.isNonatomic, @"Setter semantics should be non-atomic.");
    XCTAssertFalse(_locationProperty.isReadonly, @"NSDictionary property should not be read-only.");
    XCTAssertFalse(_locationProperty.isRetain, @"Location property should not be retain.");
    XCTAssertFalse(_locationProperty.isWeak, @"Location property should not be weak.");
    XCTAssertFalse(_locationProperty.isBlock, @"Location property should not be block.");
    XCTAssertFalse(_locationProperty.isCollection, @"Location property should be collection.");
    XCTAssertFalse(_locationProperty.isId, @"Location property should not be id.");
    XCTAssertFalse(_locationProperty.isObject, @"Location property should be object.");
    XCTAssertFalse(_locationProperty.isPrimitive, @"Location property should not be primitive.");
    XCTAssertEqualObjects(_locationProperty.name, @"locationProperty", @"Name should be locationProperty, but found %@.", _locationProperty.name);
    XCTAssertEqualObjects(_locationProperty.ivarName, @"_locationProperty", @"ivarName should be locationProperty, but found %@.", _locationProperty.ivarName);
    XCTAssertNil(_locationProperty.propertyClass, @"Location property should not have a propertyClass.");
    XCTAssertEqualObjects(_locationProperty.typeEncoding, @"{?=dd}", @"Type encoding should be {?=dd}, but found %@.", _locationProperty.typeEncoding);
}

- (void)testIntCanAcceptNSNumber {
    __autoreleasing NSNumber *number = @(8);
    XCTAssertTrue([_assignProperty canAssignValue:number], @"Assign property should be able to accept NSNumber.");
}

- (void)testBoolCanAcceptNSNumber {
    __autoreleasing NSNumber *number = @(1);
    XCTAssertTrue([_boolProperty canAssignValue:number], @"Bool property should be able to accept NSNumber.");
}

- (void)testBoolCanAcceptNSNumberWithBool {
    __autoreleasing NSNumber *number = @YES;
    XCTAssertTrue([_boolProperty canAssignValue:number], @"Bool property should be able to accept NSNumber.");
}

- (void)testStringCanAcceptString {
    XCTAssertTrue([_copyProperty canAssignValue:@""], @"String property should be able to accept String.");
    XCTAssertTrue([_retainProperty canAssignValue:@""], @"NSString property should be able to accept String.");
}

- (void)testStringCannotAcceptNumber {
    XCTAssertFalse([_copyProperty canAssignValue:@(8)], @"String property should not be able to accept NSNumber.");
    XCTAssertFalse([_retainProperty canAssignValue:@(8)], @"NSString property should not be able to accept NSNumber.");
}

- (void)testIntCannotAcceptString {
    XCTAssertFalse([_assignProperty canAssignValue:@""], @"Assign property should not be able to accept String.");
}

- (void)testCustomGetterSetter {
    XCTAssertTrue(_availableProperty.getter != nil, @"Getter should not be nil.");
    XCTAssertTrue(_availableProperty.customGetter != nil, @"Custom getter should not be nil.");
    XCTAssertTrue(_availableProperty.setter != nil, @"Setter should not be nil.");
    XCTAssertTrue(_availableProperty.customSetter != nil, @"Custom setter should not be nil.");

    XCTAssertEqual(_availableProperty.getter, @selector(isAvailable), @"Getter should be isAvailable, but found %@.", NSStringFromSelector(_availableProperty.getter));
    XCTAssertEqual(_availableProperty.customGetter, @selector(isAvailable), @"Custom getter should be isAvailable, but found %@.", NSStringFromSelector(_availableProperty.customGetter));

    XCTAssertEqual(_availableProperty.setter, @selector(updateAvailable:), @"Getter should be updateAvailable:, but found %@.", NSStringFromSelector(_availableProperty.setter));
    XCTAssertEqual(_availableProperty.customSetter, @selector(updateAvailable:), @"Custom getter should be updateAvailable:, but found %@.", NSStringFromSelector(_availableProperty.customSetter));
}


@end
