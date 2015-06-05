//  Project name: FwiData
//  File name   : FwiLocation.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 4/13/12
//  Version     : 1.20
//  --------------------------------------------------------------
//  Copyright (C) 2012, 2015 Fiision Studio.
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
//  testing. Fiision Studio disclaim  all  liability  and  responsibility  to  any
//  person or entity with respect to any loss or damage caused, or alleged  to  be
//  caused, directly or indirectly, by the use of this software.

#import <Foundation/Foundation.h>


FOUNDATION_EXPORT NSString *const kNotification_AddressUpdated;
FOUNDATION_EXPORT NSString *const kNotification_GMTUpdated;
FOUNDATION_EXPORT NSString *const kNotification_LocationUpdated;


/**
 * Calculate new location base on input location and distance
 * @Input: location (Input location)
 * @Input: bearing  (Clockwise, in degree)
 * @Input: distance (How far from location, in meter)
 */
FOUNDATION_EXPORT CLLocationCoordinate2D (^FwiCalculateCoordinateWithDistance)(double bearing, CLLocationCoordinate2D location, double distance);


@interface FwiLocation : NSObject <CLLocationManagerDelegate> {

@private
    CLLocationManager *_locationManager;
}

@property (nonatomic, readonly) CLLocation *currentLocation;
@property (nonatomic, readonly) CLAuthorizationStatus locationStatus;

@property (nonatomic, readonly) NSNumber *gmt;
@property (nonatomic, readonly) NSString *address;
@property (nonatomic, readonly) NSString *countryISO2;


/** Stop location service. */
- (void)stopLocation;
/** Start location service. */
- (void)startLocation;

@end


@interface FwiLocation (FwiLocationSingleton)

/** Get singleton location manager. */
+ (__autoreleasing FwiLocation *)sharedInstance;

@end