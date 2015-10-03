//  Project name: FwiData
//  File name   : FwiNetworkManagerTest.m
//
//  Author      : Phuc Tran
//  Created date: 10/1/15
//  Version     : 1.00
//  --------------------------------------------------------------
//  Copyright (c) Fiision Studio. All rights reserved.
//  --------------------------------------------------------------

#import <XCTest/XCTest.h>
#import "FwiNetworkManager.h"


@interface FwiNetworkManagerTest : XCTestCase {

@private
    NSURL *_baseHTTP;
    NSURL *_baseHTTPS;
    FwiNetworkManager *_instance;
}

@end


@implementation FwiNetworkManagerTest


#pragma mark - Setup
- (void)setUp {
    [super setUp];
    _baseHTTP  = [NSURL URLWithString:@"http://httpbin.org"];
    _baseHTTPS = [NSURL URLWithString:@"https://httpbin.org"];

    _instance = [FwiNetworkManager sharedInstance];
    XCTAssertNotNil(_instance, @"Network manager is singleton and should not be nil.");
}


#pragma mark - Tear Down
- (void)tearDown {
    _instance = nil;
    [super tearDown];
}


#pragma mark - Test Cases
//func testFwiServiceDelegate() {
//    var completedExpectation = self.expectationWithDescription("Operation completed.")
//
//    // Generate request
//    var request = NSURLRequest(URL: NSURL(string: "/", relativeToURL: baseHTTPS)!)
//    var service = FwiService(request: request)
//
//    service.delegate = self
//    service.sendRequestWithCompletion { (locationPath, error, statusCode) -> Void in
//        completedExpectation.fulfill()
//    }
//
//    // Wait for timeout handler
//    self.waitForExpectationsWithTimeout(60.0, handler: { (error: NSError!) -> Void in
//        XCTAssertTrue(self.authenticationCalled, "Authentication should be called.")
//        XCTAssertTrue(self.bytesReceivedCalled, "Bytes received should be called.")
//        XCTAssertTrue(self.totalBytesWillReceiveCalled, "Total bytes will receive should be called.")
//
//        if error == nil {
//            XCTAssertTrue(service.finished, "Operation finished.")
//        } else {
//            XCTAssertFalse(service.finished, "Operation could not finish.")
//        }
//    })
//}

- (void)testHTTP {
    XCTestExpectation *completedExpectation = [self expectationWithDescription:@"Operation completed."];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:_baseHTTP]];
    [_instance sendRequest:request completion:^(NSData *data, NSError *error, NSInteger statusCode) {

        XCTAssertTrue(FwiNetworkStatusIsSuccces(statusCode), @"Success connection should return status code range 200 - 299. But found %i", statusCode);
        XCTAssertNil(error, @"Success connection should not return error. But found %@", error);
        XCTAssertNotNil(data, @"Success connection should return data. But found nil");

        if (data) [completedExpectation fulfill];
    }];

    // Wait for timeout handler
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError * _Nullable error) {
        if (error) {
            XCTAssertThrows(@"Operation could not finish.");
        }
    }];
}

- (void)testHTTPS {
    XCTestExpectation *completedExpectation = [self expectationWithDescription:@"Operation completed."];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:_baseHTTPS]];
    [_instance sendRequest:request completion:^(NSData *data, NSError *error, NSInteger statusCode) {

        XCTAssertTrue(FwiNetworkStatusIsSuccces(statusCode), @"Success connection should return status code range 200 - 299. But found %i", statusCode);
        XCTAssertNil(error, @"Success connection should not return error. But found %@", error);
        XCTAssertNotNil(data, @"Success connection should return data. But found nil");

        if (data) [completedExpectation fulfill];
    }];

    // Wait for timeout handler
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError * _Nullable error) {
        if (error) {
            XCTAssertThrows(@"Operation could not finish.");
        }
    }];
}

- (void)testNetworkIndicator {
    XCTestExpectation *completedExpectation = [self expectationWithDescription:@"Operation completed."];

    NSURLRequest *req1 = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:_baseHTTP]];
    NSURLRequest *req2 = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/" relativeToURL:nil]];
    __block BOOL request1 = NO;
    __block BOOL request2 = NO;
    __block BOOL request3 = NO;
    __block BOOL request4 = NO;
    __block BOOL request5 = NO;

    [_instance sendRequest:req1 completion:^(NSData *data, NSError *error, NSInteger statusCode) {
        request1 = YES;
        if (request1 && request2 && request3 && request4 && request5) {
            [completedExpectation fulfill];
        }
    }];
    [_instance sendRequest:req1 completion:^(NSData *data, NSError *error, NSInteger statusCode) {
        request2 = YES;
        if (request1 && request2 && request3 && request4 && request5) {
            [completedExpectation fulfill];
        }
    }];
    [_instance sendRequest:req1 completion:^(NSData *data, NSError *error, NSInteger statusCode) {
        request3 = YES;
        if (request1 && request2 && request3 && request4 && request5) {
            [completedExpectation fulfill];
        }
    }];
    [_instance sendRequest:req1 completion:^(NSData *data, NSError *error, NSInteger statusCode) {
        request4 = YES;
        if (request1 && request2 && request3 && request4 && request5) {
            [completedExpectation fulfill];
        }
    }];
    [_instance sendRequest:req2 completion:^(NSData *data, NSError *error, NSInteger statusCode) {
        request1 = YES;
        if (request1 && request2 && request3 && request4 && request5) {
            [completedExpectation fulfill];
        }
    }];
    [completedExpectation fulfill];

    // Wait for timeout handler
    [self waitForExpectationsWithTimeout:10.0f handler:^(NSError * _Nullable error) {
        if ([[UIApplication sharedApplication] isNetworkActivityIndicatorVisible]) {
            XCTAssertThrows(@"Operation could not finish.");
        }
    }];
}

- (void)testUnsupportedURL {
    XCTestExpectation *completedExpectation = [self expectationWithDescription:@"Operation completed."];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/" relativeToURL:nil]];
    [_instance sendRequest:request completion:^(NSData *data, NSError *error, NSInteger statusCode) {

        XCTAssertTrue(statusCode == kUnsupportedURL, @"Fail connection status should be %i. But found %i", kUnsupportedURL, statusCode);
        XCTAssertNotNil(error, @"Fail connection should not return error. But found %@", error);
        XCTAssertNil(data, @"Fail connection should return nil data. But found %@", data);

        if (error && !data) [completedExpectation fulfill];
    }];

    // Wait for timeout handler
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError * _Nullable error) {
        if (error) {
            XCTAssertThrows(@"Operation could not finish.");
        }
    }];
}

- (void)testCannotConnectToHost {
    XCTestExpectation *completedExpectation = [self expectationWithDescription:@"Operation completed."];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8080"]];
    [_instance sendRequest:request completion:^(NSData *data, NSError *error, NSInteger statusCode) {
        
        XCTAssertTrue(statusCode == kCannotConnectToHost, @"Cancelled connection status should be %i. But found %i", kCannotConnectToHost, statusCode);
        XCTAssertNotNil(error, @"Cancelled connection should return error. But found nil");
        XCTAssertNil(data, @"Cancelled connection should return nil data. But found %@", data);

        if (error && !data) [completedExpectation fulfill];
    }];

    // Wait for timeout handler
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError * _Nullable error) {
        if (error) {
            XCTAssertThrows(@"Operation could not finish.");
        }
    }];
}

- (void)testStatus3xx {
    XCTestExpectation *completedExpectation = [self expectationWithDescription:@"Operation completed."];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/redirect/5" relativeToURL:_baseHTTP]];
    [_instance sendRequest:request completion:^(NSData *data, NSError *error, NSInteger statusCode) {

        XCTAssertNil(error, @"Redirect connection should return nil error. But found %@", error);
        if (!error) [completedExpectation fulfill];
    }];

    // Wait for timeout handler
    [self waitForExpectationsWithTimeout:30.0f handler:^(NSError * _Nullable error) {
        if (error) {
            XCTAssertThrows(@"Operation could not finish.");
        }
    }];
}

- (void)testStatus4xx {
    XCTestExpectation *completedExpectation = [self expectationWithDescription:@"Operation completed."];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/404" relativeToURL:_baseHTTP]];
    [_instance sendRequest:request completion:^(NSData *data, NSError *error, NSInteger statusCode) {
        XCTAssertTrue(statusCode == 404, @"Status should be %i. But found %i", 404, statusCode);
        XCTAssertNotNil(error, @"Connection should return error. But found nil");

        if (error) [completedExpectation fulfill];
    }];

    // Wait for timeout handler
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError * _Nullable error) {
        if (error) {
            XCTAssertThrows(@"Operation could not finish.");
        }
    }];
}

- (void)testStatus5xx {
    XCTestExpectation *completedExpectation = [self expectationWithDescription:@"Operation completed."];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/500" relativeToURL:_baseHTTP]];
    [_instance sendRequest:request completion:^(NSData *data, NSError *error, NSInteger statusCode) {
        XCTAssertTrue(statusCode == 500, @"Status should be %i. But found %i", 500, statusCode);
        XCTAssertNotNil(error, @"Connection should return error. But found nil");

        if (error) [completedExpectation fulfill];
    }];

    // Wait for timeout handler
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError * _Nullable error) {
        if (error) {
            XCTAssertThrows(@"Operation could not finish.");
        }
    }];
}


@end
