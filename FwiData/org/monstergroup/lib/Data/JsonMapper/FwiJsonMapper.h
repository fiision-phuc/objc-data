//  Project name: FwiData
//  File name   : FwiJsonMapper.h
//
//  Author      : Phuc Tran
//  Created date: 2/18/15
//  Version     : 1.00
//  --------------------------------------------------------------
//  Copyright (c) 2015 FWI Group. All rights reserved.
//  --------------------------------------------------------------

#import <Foundation/Foundation.h>


@interface FwiJsonMapper : NSObject {
}


/** Convert json to object. */
- (id)decodeJsonData:(NSData *)jsonData model:(Class)model;
- (id)decodeJsonString:(NSString *)jsonString model:(Class)model;

/** Convert object to json. */
- (__autoreleasing NSData *)encodeJsonDataWithModel:(id)model;
- (__autoreleasing NSString *)encodeJsonStringWithModel:(id)model;

@end
