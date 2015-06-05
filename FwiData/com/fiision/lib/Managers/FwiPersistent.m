#import "FwiPersistent.h"


@interface FwiPersistent () {
    
    NSString *_dataModel;
}


/** Handle did save event from other context beside main context. */
- (void)_handleContextDidSaveNotification:(NSNotification *)notification;

@end


@implementation FwiPersistent


#pragma mark - Class's constructors
- (id)init {
	self = [super init];
	if (self) {
        _dataModel             = nil;
        _managedModel          = nil;
        _managedContext        = nil;
        _persistentCoordinator = nil;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
	}
	return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    FwiRelease(_dataModel);
    FwiRelease(_managedModel);
    FwiRelease(_managedContext);
    FwiRelease(_persistentCoordinator);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties
- (NSManagedObjectModel *)managedModel {
	if (_managedModel) return _managedModel;

	// Create managed object model if it is not available
	@synchronized (self) {
        __autoreleasing NSURL *modelURL = [[NSBundle mainBundle] URLForResource:_dataModel withExtension:@"momd"];
        _managedModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	}
	return _managedModel;
}
- (NSPersistentStoreCoordinator *)persistentCoordinator {
	if (_persistentCoordinator) return _persistentCoordinator;
	
	// Create persistent store coordinator if not
    @synchronized(self) {
//        @"journal_mode":@"WAL"
//        @"journal_mode":@"DELETE"
        
        // Prepare store option
        __autoreleasing NSDictionary *options = @{NSSQLitePragmasOption:@{@"journal_mode":@"WAL"},
                                                  NSMigratePersistentStoresAutomaticallyOption:@YES,
                                                  NSInferMappingModelAutomaticallyOption:@YES};
        
        // Setup persistent store coordinator
        __autoreleasing NSError  *error     = nil;
        __autoreleasing NSString *storeDB1  = [NSString stringWithFormat:@"%@.sqlite", _dataModel];
        __autoreleasing NSString *storeDB2  = [NSString stringWithFormat:@"%@.sqlite-shm", _dataModel];
        __autoreleasing NSString *storeDB3  = [NSString stringWithFormat:@"%@.sqlite-wal", _dataModel];
        __autoreleasing NSURL    *storeURL1 = [[NSURL documentDirectory] URLByAppendingPathComponent:storeDB1];
        
        _persistentCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedModel]];
        __autoreleasing NSPersistentStore *persistentStore = [_persistentCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                                                  configuration:nil
                                                                                                            URL:storeURL1
                                                                                                        options:options
                                                                                                          error:&error];
        
        // Lightweight migrate data / Reset if neccessary
        if (!persistentStore) {
            __autoreleasing NSFileManager *manager = [NSFileManager defaultManager];
            __autoreleasing NSString *path1 = [storeURL1 path];
            __autoreleasing NSString *path2 = [NSString stringWithFormat:@"%@/%@", [[NSURL documentDirectory] path], storeDB2];
            __autoreleasing NSString *path3 = [NSString stringWithFormat:@"%@/%@", [[NSURL documentDirectory] path], storeDB3];
            
            if ([manager fileExistsAtPath:path1]) [manager removeItemAtPath:path1 error:nil];
            if ([manager fileExistsAtPath:path2]) [manager removeItemAtPath:path2 error:nil];
            if ([manager fileExistsAtPath:path3]) [manager removeItemAtPath:path3 error:nil];
            
            error = nil;
            _persistentCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedModel]];
            persistentStore = [_persistentCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                   configuration:nil
                                                                             URL:storeURL1
                                                                         options:options
                                                                           error:&error];
            if (persistentStore) {
                DLog(@"[INFO] Data model has been reset...");
            }
            else {
                DLog(@"[ERROR] Unresolved error %@, %@!", error, [error userInfo]);
            }
        }
        
        // Exclude from backup
        __autoreleasing NSURL *storeURL2 = [[NSURL documentDirectory] URLByAppendingPathComponent:storeDB2];
        __autoreleasing NSURL *storeURL3 = [[NSURL documentDirectory] URLByAppendingPathComponent:storeDB3];
        [storeURL1 setResourceValues:@{NSURLIsExcludedFromBackupKey:@YES} error:&error];
        [storeURL2 setResourceValues:@{NSURLIsExcludedFromBackupKey:@YES} error:&error];
        [storeURL3 setResourceValues:@{NSURLIsExcludedFromBackupKey:@YES} error:&error];

        return _persistentCoordinator;
    }
}


#pragma mark - Class's public methods
- (__autoreleasing NSManagedObjectContext *)importContext {
    __autoreleasing NSManagedObjectContext *saveContext = FwiAutoRelease([[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType]);
    
    [saveContext setPersistentStoreCoordinator:[self persistentCoordinator]];
    [saveContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [saveContext setUndoManager:nil];
    
    return saveContext;
}
- (__autoreleasing NSError *)saveContext {
    __block NSError *temp = nil;
    __unsafe_unretained __block NSManagedObjectContext *context = _managedContext;
    
    [_managedContext performBlockAndWait:^{
        [context save:&temp];
    }];
    
    __autoreleasing NSError *error = temp;
    context = nil;
    temp = nil;
    
    return error;
}


#pragma mark - Class's private methods


#pragma mark - Class's notification handlers
- (void)_handleContextDidSaveNotification:(NSNotification *)notification {
    NSManagedObjectContext *otherContext = (NSManagedObjectContext *) notification.object;
    
    /* Condition validation: Ignore main context event */
    if (_managedContext == otherContext) return;
    [_managedContext mergeChangesFromContextDidSaveNotification:notification];
}


@end


@implementation FwiPersistent (FwiPersistentCreation)


#pragma mark - Class's static constructors
+ (__autoreleasing FwiPersistent *)persistentWithDataModel:(NSString *)dataModel {
    /* Condition validation */
	if (!dataModel || [dataModel length] == 0) return nil;

    __autoreleasing FwiPersistent *persistentManager = FwiAutoRelease([[FwiPersistent alloc] initWithDataModel:dataModel]);
	return persistentManager;
}


#pragma mark - Class's constructors
- (id)initWithDataModel:(NSString *)dataModel {
	self = [self init];
	if (self) {
		_dataModel = FwiRetain(dataModel);

		// Create managed object context
		_managedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[_managedContext setPersistentStoreCoordinator:[self persistentCoordinator]];
        [_managedContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
	}
	return self;
}


@end