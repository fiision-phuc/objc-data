//  Project name: FwiData
//  File name   : FwiPersistent.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 2/17/12
//  Version     : 1.20
//  --------------------------------------------------------------
//  Copyright (C) 2012, 2014 Monster Group.
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


@protocol FwiPersistentDelegate;


@interface FwiPersistent : NSObject {

@private
    NSManagedObjectModel *_managedModel;
    NSManagedObjectContext *_managedContext;
    NSPersistentStoreCoordinator *_persistentCoordinator;
}

@property (nonatomic, readonly) NSManagedObjectModel *managedModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentCoordinator;


/** Return a sub managed object context that had been optimized to serve the update data process. */
- (__autoreleasing NSManagedObjectContext *)importContext;

/** Save current working context. */
- (__autoreleasing NSError *)saveContext;

@end


@interface FwiPersistent (FwiPersistentCreation)

/** Create persistent manager for specific data model. */
+ (__autoreleasing FwiPersistent *)persistentWithDataModel:(NSString *)dataModel;

/** Init with data model. */
- (id)initWithDataModel:(NSString *)dataModel;

@end


@protocol FwiPersistentDelegate <NSObject>

@optional
/** Allow delegate control the reset database process. */
- (BOOL)shouldResetPersistent:(FwiPersistent *)persistent;
/** Notify delegate that database will be reset due to error. */
- (void)persistent:(FwiPersistent *)persistent willResetDatabaseWithError:(NSError *)error;
/** Notify delegate that database had been reset due to error. */
- (void)persistent:(FwiPersistent *)persistent didResetDatabaseWithError:(NSError *)error;

@end