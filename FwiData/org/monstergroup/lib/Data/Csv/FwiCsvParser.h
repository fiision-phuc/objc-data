//  Project name: FwiData
//  File name   : FwiCsvParser.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 1/6/14
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


@protocol FwiCsvParserDelegate;


@interface FwiCsvParser : NSObject {
    
@private
    NSInputStream *_input;
}

@property (nonatomic, assign) id<FwiCsvParserDelegate> delegate;


/** Parse csv file. */
- (void)parse;
- (void)parseWithSeparator:(unichar)separator;
- (void)parseWithSeparator:(unichar)separator quote:(unichar)quote;
- (void)parseWithSeparator:(unichar)separator quote:(unichar)quote encoding:(NSStringEncoding)encoding;

@end


@interface FwiCsvParser (FwiCSVParserCreation)

// Class's static constructors
+ (__autoreleasing FwiCsvParser *)parserWithData:(NSData *)data;
+ (__autoreleasing FwiCsvParser *)parserWithFile:(NSString *)path;

// Class's constructors
- (id)initWithData:(NSData *)data;
- (id)initWithFile:(NSString *)path;

@end


@protocol FwiCsvParserDelegate <NSObject>

@optional
/** Begin/Finish document. */
- (void)parserDidBegin:(FwiCsvParser *)parser;
- (void)parserDidFinish:(FwiCsvParser *)parser;

/** Begin/Finish line. */
- (void)parser:(FwiCsvParser *)parser didBeginLine:(NSUInteger)lineIndex;
- (void)parser:(FwiCsvParser *)parser didFinishLine:(NSUInteger)lineIndex;

/** Parse fields. */
- (void)parser:(FwiCsvParser *)parser didReadField:(NSString *)field index:(NSUInteger)index;

@end