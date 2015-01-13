#import "FwiCsvParser.h"


@interface FwiCsvParser () {
    
    NSMutableData *_buffer;
    
    BOOL   _isIgnored;
    size_t _trunkSize;
}

@property (nonatomic, assign) unichar quote;
@property (nonatomic, assign) unichar separator;
@property (nonatomic, assign) NSStringEncoding encoding;

@property (nonatomic, assign) NSUInteger lineIndex;
@property (nonatomic, assign) NSUInteger fieldIndex;


/** Read data from source. */
- (void)_read;

@end


@implementation FwiCsvParser


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _input     = nil;
        _encoding  = NSUTF8StringEncoding;
        
        _isIgnored = NO;
        _trunkSize = 1024;
        _buffer    = [[NSMutableData alloc] initWithCapacity:_trunkSize];
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    self.delegate = nil;
    FwiRelease(_buffer);
    FwiRelease(_input);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (void)parse {
    [self parseWithSeparator:',' quote:'"' encoding:NSUTF8StringEncoding];
}
- (void)parseWithSeparator:(unichar)separator {
    [self parseWithSeparator:separator quote:'"' encoding:NSUTF8StringEncoding];
}
- (void)parseWithSeparator:(unichar)separator quote:(unichar)quote {
    [self parseWithSeparator:separator quote:quote encoding:NSUTF8StringEncoding];
}
- (void)parseWithSeparator:(unichar)separator quote:(unichar)quote encoding:(NSStringEncoding)encoding {
    /* Condition validation */
    if (!_input) return;
    self.quote     = quote;
    self.encoding  = encoding;
    self.separator = separator;
    
    // Open stream
    [_input open];
    [_buffer setLength:0];
    
    // Notify delegate
    if (_delegate && [_delegate respondsToSelector:@selector(parserDidBegin:)])
        [_delegate parserDidBegin:self];
    
    // Parse process
    self.lineIndex  = 0;
    self.fieldIndex = 0;
    if (_delegate && [_delegate respondsToSelector:@selector(parser:didBeginLine:)]) {
        [_delegate parser:self didBeginLine:_lineIndex];
    }
    while ([_input hasBytesAvailable]) [self _read];
    
    // Close stream
    [_input close];
    
    // Notify delegate
    if (_delegate && [_delegate respondsToSelector:@selector(parserDidFinish:)])
        [_delegate parserDidFinish:self];
}


#pragma mark - Class's private methods
- (void)_read {
    size_t strData = 0;
    size_t endData = 0;
    uint8_t buffer[_trunkSize];
    NSInteger bytesReaded = [_input read:buffer maxLength:_trunkSize];
    
    // Parse buffer
    for (size_t i = 0; i < bytesReaded; i++) {
        if ((buffer[i] == _separator || buffer[i] == '\n') && !_isIgnored) {
            [_buffer appendBytes:&buffer[strData] length:endData];
            if (((uint8_t *) _buffer.bytes)[_buffer.length - 1] == _quote) [_buffer setLength:(_buffer.length - 1)];
            
            __autoreleasing NSString *data = FwiAutoRelease([[NSString alloc] initWithBytes:_buffer.bytes length:_buffer.length encoding:_encoding]);
            if (_delegate && [_delegate respondsToSelector:@selector(parser:didReadField:index:)]) {
                [_delegate parser:self didReadField:[data trim] index:_fieldIndex++];
            }
            
            endData = 0;
            strData = i + 1;
            [_buffer setLength:0];
            if (buffer[i] == '\n') {
                if (_delegate && [_delegate respondsToSelector:@selector(parser:didFinishLine:)]) {
                    [_delegate parser:self didFinishLine:_lineIndex];
                }
                
                _lineIndex++;
                _fieldIndex = 0;
                
                if (_delegate && [_delegate respondsToSelector:@selector(parser:didBeginLine:)]) {
                    [_delegate parser:self didBeginLine:_lineIndex];
                }
            }
        }
        else {
            if (buffer[i] != '\r') endData++;
            
            // Control the index
            if (buffer[i] == _quote) {
                _isIgnored = !_isIgnored;
                _isIgnored ? strData++ : endData--;
            }
        }
    }
    
    // Process remain buffer
    if (endData != 0) {
        endData = (strData + endData) > _trunkSize ? (_trunkSize - strData) : endData;
        [_buffer appendBytes:&buffer[strData] length:endData];
    }
}


@end


@implementation FwiCsvParser (FwiCSVParserCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiCsvParser *)parserWithData:(NSData *)data {
    __autoreleasing FwiCsvParser *parser = FwiAutoRelease([[FwiCsvParser alloc] initWithData:data]);
    return parser;
}
+ (__autoreleasing FwiCsvParser *)parserWithFile:(NSString *)path {
    __autoreleasing FwiCsvParser *parser = FwiAutoRelease([[FwiCsvParser alloc] initWithFile:path]);
    return parser;
}


#pragma mark - Class's constructors
- (id)initWithData:(NSData *)data {
    self = [self init];
    if (self) {
        _input = [[NSInputStream alloc] initWithData:data];
    }
    return self;
}
- (id)initWithFile:(NSString *)path {
    self = [self init];
    if (self) {
        _input = [[NSInputStream alloc] initWithFileAtPath:path];
    }
    return self;
}


@end