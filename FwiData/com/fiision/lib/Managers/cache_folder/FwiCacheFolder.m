#import "FwiCacheFolder.h"


#define kSeconds_Per1day                    86400   // 1 day  = 24 * 60 * 60
#define kSeconds_Per7days                   604800  // 7 days = 7 * 24 * 60 * 60


@interface FwiCacheFolder () {
    
    NSFileManager  *_manager;
    NSTimeInterval _ageLimit;
}


/** Validate filename. */
- (NSString *)_validateFilename:(NSString *)filename;

/** Delete all expired files. */
- (void)_clearFolder;
/** Delete all files at specific path. */
- (void)_clearAllFilesAtPath:(NSString *)path;

@end


@implementation FwiCacheFolder


#pragma mark - Class's constructors
- (id)init {
    self = [super init];
    if (self) {
        _pathReady   = nil;
        _pathLoading = nil;
        _ageLimit    = kSeconds_Per7days;
        _manager     = [NSFileManager defaultManager];
    }
    return self;
}


#pragma mark - Cleanup memory
-(void)dealloc {
    FwiRelease(_pathReady);
    FwiRelease(_pathLoading);
	
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (__autoreleasing NSString *)readyPathForFilename:(NSString *)filename {
    /* Condition validation */
    if (!filename || filename.length == 0) return nil;
    
    filename = [self _validateFilename:filename];
	return [NSString stringWithFormat:@"%@%@", _pathReady, filename];
}
- (__autoreleasing NSString *)loadingPathForFilename:(NSString *)filename {
    /* Condition validation */
    if (!filename || filename.length == 0) return nil;
    
    filename = [self _validateFilename:filename];
	return [NSString stringWithFormat:@"%@%@", _pathLoading, filename];
}
- (__autoreleasing NSString *)loadingFinishedForFilename:(NSString *)filename {
    /* Condition validation */
    if (!filename || filename.length == 0) return nil;
	__autoreleasing NSString *loadingFile = [self loadingPathForFilename:filename];
	__autoreleasing NSString *readyFile = [self readyPathForFilename:filename];
    
    // Move file to ready folder
	__autoreleasing NSError  *error = nil;
	[_manager moveItemAtPath:loadingFile toPath:readyFile error:&error];
    
    // Apply exclude backup attribute
    NSURL *readyURL = [NSURL fileURLWithPath:readyFile];
    [readyURL setResourceValues:@{NSURLIsExcludedFromBackupKey:@YES} error:&error];
    
    // Destroy file if it could not exclude from backup
    if (error) [_manager removeItemAtPath:readyFile error:nil];
    return (!error ? readyFile : nil);
}

- (void)updateFile:(NSString *)filename {
    /* Condition validation */
	NSDictionary *attributes = [_manager attributesOfItemAtPath:filename error:nil];
    if (!attributes) return;
    
    /* Condition validation: */
    NSTimeInterval seconds = -1 * [[attributes objectForKey:NSFileModificationDate] timeIntervalSinceNow];
    if (seconds < (_ageLimit / 2)) return;
    
    NSMutableDictionary *newAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
    [newAttributes setObject:[NSDate date] forKey:NSFileModificationDate];
    [_manager setAttributes:newAttributes ofItemAtPath:filename error:nil];
}
- (void)clearCache {
	[self _clearAllFilesAtPath:_pathReady];
	[self _clearAllFilesAtPath:_pathLoading];
}


#pragma mark - Class's private methods
- (NSString *)_validateFilename:(NSString *)filename {
    __autoreleasing NSData *data = [filename toData];
    uint8_t *chars = (void *)[data bytes];
    
    // Replace all invalid characters
    for (NSUInteger i = 0; i < data.length; i++) {
        if (chars[i] == ':' || chars[i] == '/') chars[i] = '_';
    }
    filename = [data toString];
	return filename;
}

- (void)_clearFolder {
    NSDirectoryEnumerator *enumerator = [_manager enumeratorAtPath:_pathReady];
    NSString *filename = [enumerator nextObject];
    
    while (filename) {
        filename = [NSString stringWithFormat:@"%@%@", _pathReady, filename];
        
        // Load file's attributes
        NSDictionary *attributes = [_manager attributesOfItemAtPath:filename error:nil];
        NSTimeInterval seconds = -1 * [[attributes fileModificationDate] timeIntervalSinceNow];
        
        if (seconds > _ageLimit) {
            [_manager removeItemAtPath:filename error:nil];
        }
        filename = [enumerator nextObject];
    }
}
- (void)_clearAllFilesAtPath:(NSString *)path {
	NSError *error = nil;
    
    /* Condition validation: Validate path */
	NSArray *files = [_manager contentsOfDirectoryAtPath:path error:&error];
	if (error != nil) return;
    
    // Delete files
	for (NSString *file in files) {
		NSString *filepath = [NSString stringWithFormat:@"%@%@", path, file];
		[_manager removeItemAtPath:filepath error:&error];
	}
}


@end


@implementation FwiCacheFolder (FwiCacheCreation)


#pragma mark - Class's static constructors
+ (FwiCacheFolder *)cacheFolderWithPath:(NSString *)path {
    return FwiAutoRelease([[FwiCacheFolder alloc] initWithPath:path]);
}


#pragma mark - Class's constructors
- (id)initWithPath:(NSString *)path {
	self = [self init];
    if (self) {
        _pathReady   = [[NSString alloc] initWithFormat:@"%@/%@/", [[NSURL documentDirectory] path], path];
        _pathLoading = FwiRetain(NSTemporaryDirectory());
        
        /* Condition validation: Validate paths */
        if (![_manager fileExistsAtPath:_pathReady]) {
            // Create folder
            __autoreleasing NSError *error = nil;
            [_manager createDirectoryAtPath:_pathReady withIntermediateDirectories:YES attributes:nil error:&error];
            
            // Apply exclude backup attribute
            NSURL *readyURL = [NSURL fileURLWithPath:_pathReady];
            [readyURL setResourceValues:@{NSURLIsExcludedFromBackupKey:@YES} error:&error];
            
            // If error, delete folder
            if (error) [_manager removeItemAtPath:_pathReady error:nil];
        }
        
        //delete any half loaded files
        [self _clearFolder];
        [self _clearAllFilesAtPath:_pathLoading];
	}
	return self;
}


@end