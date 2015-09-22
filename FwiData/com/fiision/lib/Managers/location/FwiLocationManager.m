#import "FwiLocationManager.h"


NSString * const kNotification_AddressUpdated  = @"kNotification_AddressUpdated";
NSString * const kNotification_GMTUpdated      = @"kNotification_GMTUpdated";
NSString * const kNotification_LocationUpdated = @"kNotification_LocationUpdated";


CLLocationCoordinate2D (^FwiCalculateCoordinateWithDistance)(double bearing, CLLocationCoordinate2D location, double distance) = ^(double bearing, CLLocationCoordinate2D location, double distance) {
    distance = (distance / 1000) / 6371;
    bearing  = FwiConvertToRadian(bearing);
    
    CLLocationDegrees lat1 = FwiConvertToRadian(location.latitude);
    CLLocationDegrees lng1 = FwiConvertToRadian(location.longitude);
    CLLocationDegrees lat2 = asin(sin(lat1) * cos(distance) + cos(lat1) * sin(distance) * cos(bearing));
    CLLocationDegrees lng2 = lng1 + atan2(sin(bearing) * sin(distance) * cos(lat1), cos(distance) - sin(lat1) * sin(lat2));
    
    // Finalize result
    CLLocationCoordinate2D l;
    l.latitude  = FwiConvertToDegree(lat2);
    l.longitude = FwiConvertToDegree(lng2);
    
    return l;
};


@interface FwiLocationManager () <FwiServiceDelegate> {
}

@property (atomic, assign) BOOL isLookup;
@property (atomic, assign) BOOL isStarted;


///** Look up the Google Map for specific input address. */
//- (void)lookupAddress:(NSString *)address;
///** Manual lookup address. */
//- (void)_parseResults:(FwiJson *)results;
///** Lookup address base on location. */
//- (void)_revertLocation:(CLLocation *)location;

@end


@implementation FwiLocationManager


#pragma mark - Class's constructors
- (id)init {
	self = [super init];
	if (self) {
        _isStarted       = NO;
        _gmt			 = nil;
		_address		 = nil;
		_countryISO2	 = nil;
		_currentLocation = nil;
		_locationStatus	 = kCLAuthorizationStatusNotDetermined;
		
		// Initialize location manager
		_locationManager = [[CLLocationManager alloc] init];
        
        [_locationManager setDelegate:self];
		[_locationManager setDistanceFilter:kCLLocationAccuracyBest];
		[_locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];

//        [_locationManager setDistanceFilter:kCLLocationAccuracyHundredMeters];
//        [_locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
	}
	return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    FwiRelease(_gmt);
    FwiRelease(_address)
    FwiRelease(_countryISO2);
    FwiRelease(_currentLocation);
    FwiRelease(_locationManager);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's public methods
- (void)stopLocation {
    if (!_isStarted) return;

    self.isStarted = NO;
    [_locationManager stopUpdatingLocation];
}
- (void)startLocation {
    NSInteger osVersion = [[[UIDevice currentDevice] systemVersion] integerValue];
    
    if (osVersion >= 8 && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [_locationManager requestAlwaysAuthorization];
        return;
    }
    
    /* Condition validation */
    if (_isStarted) return;

    self.isStarted = YES;
    [_locationManager startUpdatingLocation];
}

//- (void)lookupAddress:(NSString *)address {
//    __autoreleasing NSString *encodedAddress = [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    __autoreleasing NSString *urlString = @"http://maps.googleapis.com/maps/api/geocode/json";
//
//    __autoreleasing FwiService *netRequest = [FwiService serviceWithURL:[NSURL URLWithString:urlString]
//                                                                 method:kHTTPRequest_MethodGET
//                                                      requestDictionary:@{@"address":encodedAddress, @"sensor":@"true"}];
//    [netRequest setDelegate:self];
//    
////    [netRequest executeWithCompletion:^(NSData *responseData, FwiJson *responseMessage) {
////        /* Condition validation */
////        if (!responseMessage) return;
////        [self _parseResults:responseMessage];
////    }];
//}


#pragma mark - Class's private methods
//- (void)_parseResults:(FwiJson *)results {
//	if ([results isLike:[FwiJson object:@"results", [FwiJson array], @"status", [FwiJson string], nil]] && [[[results objForPath:@"status"] stringValue] isEqualToStringIgnoreCase:@"ok"]) {
//        __block FwiJson *result = nil;
//
//        // Extract result
//        __autoreleasing results = [results objForPath:@"results"];
//        [results enumerateObjectsUsingBlock:^(FwiJson *json, NSUInteger idx, BOOL *stop) {
//            __autoreleasing NSString *type = [[json objForPath:@"types/0"] stringValue];
//
//            if ([type isEqualToStringIgnoreCase:@"street_address"] || [type isEqualToStringIgnoreCase:@"route"]) {
//                *stop = YES;
//                result = json;
//            }
//        }];
//        if (!result) result = [results objAtIdx:0];
//
//        // Get current location
//        CLLocationCoordinate2D coord;
//        FwiRelease(_currentLocation);
//
//        FwiJson *l = [result objForPath:@"geometry/location"];
//        coord.latitude   = [[[l objForPath:@"lat"] numberValue] doubleValue];
//        coord.longitude  = [[[l objForPath:@"lng"] numberValue] doubleValue];
//        _currentLocation = [[CLLocation alloc] initWithCoordinate:coord
//                                                         altitude:0.1
//                                               horizontalAccuracy:0
//                                                 verticalAccuracy:0
//                                                        timestamp:[NSDate date]];
//        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_LocationUpdated object:self];
//
//        
//        // Get Address
//        FwiRelease(_address);
//        _address = FwiRetain([[result objForPath:@"formatted_address"] stringValue]);
//
//        // Get CountryISO2
//        FwiJson *addressComponents = [result objForPath:@"address_components"];
//        [addressComponents enumerateObjectsUsingBlock:^(FwiJson *json, NSUInteger idx, BOOL *stop) {
//            if ([[[json objForPath:@"types/0"] stringValue] isEqualToStringIgnoreCase:@"country"]) {
//                FwiRelease(_countryISO2);
//
//                *stop = YES;
//                _countryISO2 = FwiRetain([[json objForPath:@"short_name"] stringValue]);
//            }
//        }];
//        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_AddressUpdated object:self];
//
//        
//        // Lookup GMT value for current location
//        NSString *urlTimezone = @"http://api.geonames.org/timezoneJSON";
//        FwiService   *gmtRequest  = [FwiService serviceWithURL:[NSURL URLWithString:urlTimezone]
//                                            method:kHTTPRequest_MethodGET
//                                 requestDictionary:@{@"lat" : [NSString stringWithFormat:@"%f", [[[l objForPath:@"lat"] numberValue] doubleValue]],
//                                                     @"lng" : [NSString stringWithFormat:@"%f", [[[l objForPath:@"lng"] numberValue] doubleValue]],
//                                                     @"username" : @"ipayment"}];
//        [gmtRequest setDelegate:self];
//        [gmtRequest execute];
//    }
//}
//
//- (void)_revertLocation:(CLLocation *)location {
//    CLLocationCoordinate2D coord = location.coordinate;
//    NSString *urlLocation = @"http://maps.googleapis.com/maps/api/geocode/json";
//
//    // Lookup address for current location
//    FwiService *locationRequest = [FwiService serviceWithURL:[NSURL URLWithString:urlLocation]
//                                          method:kHTTPRequest_MethodGET
//                               requestDictionary:@{@"latlng" : [NSString stringWithFormat:@"%f,%f", coord.latitude, coord.longitude],
//                                                   @"sensor" : @"true"}];
//    [locationRequest setDelegate:self];
//    [locationRequest execute];
//
//    // Lookup GMT value for current location
//    NSString *urlTimezone = @"http://api.geonames.org/timezoneJSON";
//    FwiService *gmtRequest = [FwiService serviceWithURL:[NSURL URLWithString:urlTimezone]
//                                     method:kHTTPRequest_MethodGET
//                          requestDictionary:@{@"lat" : [NSString stringWithFormat:@"%f", coord.latitude],
//                                              @"lng" : [NSString stringWithFormat:@"%f", coord.longitude],
//                                              @"username" : @"ipayment"}];
//    [gmtRequest setDelegate:self];
//    [gmtRequest execute];
//}


#pragma mark - CLLocationManagerDelegate's members
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    _locationStatus = status;

    if (_locationStatus != kCLAuthorizationStatusAuthorized) {
        FwiRelease(_gmt);
        FwiRelease(_address);
        FwiRelease(_countryISO2);
        FwiRelease(_currentLocation);
    }
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *newLocation = [locations lastObject];
    
	/* Condition validation */
	if (_currentLocation) {
		CLLocationDistance distance = [newLocation distanceFromLocation:_currentLocation];
		if (distance < 10) return;
	}

    // Save the newest result
    FwiRelease(_currentLocation);
	_currentLocation = FwiRetain(newLocation);
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_LocationUpdated object:nil];

    // Parse current location
//	[self _revertLocation:_currentLocation];
}


//#pragma mark - FwiNetDelegate's members
//- (void)network:(FwiService *)network didFinishWithResponseMessage:(FwiJson *)responseMessage {
//    /* Condition validation */
//    if (!responseMessage) return;
//
//    if ([responseMessage isLike:[FwiJson object:@"results", [FwiJson array], @"status", [FwiJson string], nil]] &&
//        [[[responseMessage objForPath:@"status"] stringValue] isEqualToStringIgnoreCase:@"ok"])
//    {
//        __block FwiJson *result = nil;
//
//        // Extract result
//        FwiJson *results = [responseMessage objForPath:@"results"];
//        [results enumerateObjectsUsingBlock:^(FwiJson *json, NSUInteger idx, BOOL *stop) {
//            NSString *type = [[json objForPath:@"types/0"] stringValue];
//
//            if ([type isEqualToStringIgnoreCase:@"street_address"] || [type isEqualToStringIgnoreCase:@"route"]) {
//                *stop = YES;
//                result = json;
//            }
//        }];
//        if (!result) result = [results objAtIdx:0];
//
//        // Get Address
//        FwiRelease(_address);
//        _address = FwiRetain([[result objForPath:@"formatted_address"] stringValue]);
//
//        // Get CountryISO2
//        FwiJson *addressComponents = [result objForPath:@"address_components"];
//        [addressComponents enumerateObjectsUsingBlock:^(FwiJson *json, NSUInteger idx, BOOL *stop) {
//            if ([[[json objForPath:@"types/0"] stringValue] isEqualToStringIgnoreCase:@"country"]) {
//                FwiRelease(_countryISO2);
//
//                *stop = YES;
//                _countryISO2 = FwiRetain([[json objForPath:@"short_name"] stringValue]);
//            }
//        }];
//        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_AddressUpdated object:self];
//    }
//    else if ([responseMessage isLike:[FwiJson object:
//                                      @"timezoneId" , [FwiJson string],
//                                      @"rawOffset"  , [FwiJson number],
//                                      @"sunrise"    , [FwiJson string],
//                                      @"dstOffset"  , [FwiJson number],
//                                      @"countryCode", [FwiJson string],
//                                      @"countryName", [FwiJson string],
//                                      @"gmtOffset"  , [FwiJson number],
//                                      @"time"       , [FwiJson string],
//                                      @"lng"        , [FwiJson number],
//                                      @"lat"        , [FwiJson number],
//                                      @"sunset"     , [FwiJson string],
//                                      nil]])
//    {
//        FwiRelease(_gmt);
//
//        _gmt = [[responseMessage objForPath:@"gmtOffset"] numberValue];
//        if (!_gmt) _gmt = FwiRetain([NSNumber numberWithInteger:0]);
//
//        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_GMTUpdated object:self];
//    }
//}


@end


@implementation FwiLocationManager (FwiLocationManagerSingleton)


static FwiLocationManager *_LocationManager;


#pragma mark - Environment initialize
+ (void)initialize {
	_LocationManager = nil;
}


#pragma mark - Class's static constructors
+ (_weak FwiLocationManager *)sharedInstance {
    if (_LocationManager) return _LocationManager;

    @synchronized (self) {
        if (!_LocationManager) _LocationManager = [[FwiLocationManager alloc] init];
    }
    return _LocationManager;
}


@end