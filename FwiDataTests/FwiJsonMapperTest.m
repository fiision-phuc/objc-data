//  Project name: FwiData
//  File name   : FwiJsonMapperTest.m
//
//  Author      : Phuc Tran
//  Created date: 2/19/15
//  Version     : 1.00
//  --------------------------------------------------------------
//  Copyright (c) 2015 FWI Group. All rights reserved.
//  --------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>


@interface SimpleModel : NSObject {
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger idNo;
@property (nonatomic, assign) double_t price;

@end

@implementation SimpleModel
@end


@interface FwiJsonMapperTest : XCTestCase {

@private
    NSString *_json1;
    NSString *_json2;
    NSString *_json3;
    NSString *_json4;

    FwiJsonMapper *_jsonMapper;
}

@end


@implementation FwiJsonMapperTest


#pragma mark - Setup
- (void)setUp {
    [super setUp];
    _json1 = @"{\"idNo\":1,\"name\":\"A green door\",\"price\":12.50}";
    _json2 = @"[{\"idNo\":0,\"name\":\"A green door\",\"price\":12.50},{\"idNo\":1,\"name\":\"A green door\",\"price\":12.50},{\"idNo\":2,\"name\":\"A green door\",\"price\":12.50}]";
    _json3 = @"[\"Some text here\",{\"idNo\":1,\"name\":\"A green door\",\"price\":12.50},{\"idNo\":1,\"name\":\"A green door\",\"price\":12.50},{\"idNo\":1,\"name\":\"A green door\",\"price\":12.50}]";
    _json4 = @"{\"1\":{\"idNo\":1,\"name\":\"A green door\",\"price\":12.50},\"2\":{\"idNo\":1,\"name\":\"A green door\",\"price\":12.50},\"3\":{\"idNo\":1,\"name\":\"A green door\",\"price\":12.50}}";

    _jsonMapper = [[FwiJsonMapper alloc] init];
}


#pragma mark - Tear Down
- (void)tearDown {
    _jsonMapper = nil;
    [super tearDown];
}


#pragma mark - Test Cases
- (void)testDecodeJsonWithModel {
    XCTAssertNil([_jsonMapper decodeJsonString:nil model:nil], "Mapper should return nil if jsonString is not defined.");
    XCTAssertNil([_jsonMapper decodeJsonString:_json1 model:nil], "Mapper should return nil if Model class is not defined.");
    XCTAssertNil([_jsonMapper decodeJsonString:@"FwiData" model:[SimpleModel class]], "Mapper should return nil if jsonString is invalid.");
    XCTAssertNotNil([_jsonMapper decodeJsonString:_json1 model:[SimpleModel class]], "Mapper should return a defined model.");
}

- (void)testCorrectnessOfDecodeJsonWithModelFunction {
    __autoreleasing SimpleModel *model1 = [_jsonMapper decodeJsonString:_json1 model:[SimpleModel class]];
    XCTAssertNotNil(model1, @"Model should not be nil.");
    XCTAssertNotNil(model1.name, @"Model's name should not be nil.");
    XCTAssertEqualObjects(model1.name, @"A green door", "Model's name should be A green door, but found %@.", model1.name);
    XCTAssertEqual(model1.idNo, 1, @"Model's id should be 1, but found \(model1?.id)");
    XCTAssertEqual(model1.price, 12.50f, "Model's id should be 12.50, but found \(model1?.price)");

    __autoreleasing NSArray *modelList = (NSArray *)[_jsonMapper decodeJsonString:_json2 model:[SimpleModel class]];
    XCTAssertNotNil(modelList, @"Mapper should return a list of defined model.");
    XCTAssertEqual(modelList.count, 3, @"List should have 3 items.");
    XCTAssertEqualObjects([modelList[0] name], @"A green door", @"Model's name should be A green door, but found %@.", [modelList[0] name]);
    XCTAssertEqual([modelList[0] idNo], 0, @"Model's id should be 1, but found %li.", (unsigned long)[modelList[0] idNo]);
    XCTAssertEqual([modelList[0] price], 12.50f, @"Model's id should be 12.50, but found %f.", [modelList[0] price]);

    modelList = (NSArray *)[_jsonMapper decodeJsonString:_json3 model:[SimpleModel class]];
    XCTAssertNotNil(modelList, @"Mapper should return a list of defined model.");
    XCTAssertEqual(modelList.count, 4, @"List should have 3 items.");
    XCTAssertEqualObjects(modelList[0], @"Some text here", @"Model's name should be A green door, but found %@.", modelList[0]);
    XCTAssertEqualObjects([modelList[1] name], @"A green door", @"Model's name should be A green door, but found %@.", [modelList[1] name]);
    XCTAssertEqual([modelList[1] idNo], 1, @"Model's id should be 1, but found %li.", (unsigned long)[modelList[1] idNo]);
    XCTAssertEqual([modelList[1] price], 12.50f, @"Model's id should be 12.50, but found %f.", [modelList[1] price]);
}

- (void)testCorrectnessOfEncodeJsonWithModelFunction {
    __autoreleasing SimpleModel *model1 = nil;
    __autoreleasing NSString *encodedJson = [_jsonMapper encodeJsonStringWithModel:model1];
    XCTAssertNil(encodedJson, @"Nil model should return nil.");

    model1 = [[SimpleModel alloc] init];
    encodedJson = [_jsonMapper encodeJsonStringWithModel:model1];
    XCTAssertNotNil(encodedJson, @"Encoded Json should not be nil.");

    model1 = [_jsonMapper decodeJsonString:_json1 model:[SimpleModel class]];
    encodedJson = [_jsonMapper encodeJsonStringWithModel:model1];
    XCTAssertNotNil(encodedJson, @"Encoded Json should not be nil.");

    __autoreleasing NSArray *modelList = (NSArray *)[_jsonMapper decodeJsonString:_json2 model:[SimpleModel class]];
    encodedJson = [_jsonMapper encodeJsonStringWithModel:modelList];
    XCTAssertNotNil(encodedJson, @"Encoded Json should not be nil.");
}


@end
