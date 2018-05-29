//
//  ViewController.m
//  Geographical_Photo_Map
//
//  Created by qye on 5/17/18.
//  Copyright © 2018 qye. All rights reserved.
//
#define METERS_MILE 1609.344
#define METERS_FEET 3.28084

#import "ViewController.h"

@interface ViewController ()
<CLLocationManagerDelegate>

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[self mapView] setShowsUserLocation:YES];
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    [[self locationManager] setDelegate:self];
    
    
    // Need to setup the location manager with permission in iOS versions later than ios8.
    if ([[self locationManager] respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [[self locationManager] requestWhenInUseAuthorization];
    }
    
    [[self locationManager] setDesiredAccuracy:kCLLocationAccuracyBest];
    [[self locationManager] startUpdatingLocation];
    
    // Geocoding
    self.searchResult.text = @"default text";
    [self.searchButton setTitle:@"Search Location Name" forState:(UIControlStateNormal)];
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = locations.lastObject;
    [[self labelLatitude] setText:[NSString stringWithFormat:@"%.6f",
                                   location.coordinate.latitude]];
    [[self labelLongitude] setText:[NSString stringWithFormat:@"%.6f",
                                    location.coordinate.longitude]];
    [[self labelAltitude] setText:[NSString stringWithFormat:@"%.2f feet",
                                   location.altitude*METERS_FEET]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)handleSearchButtonClick:(id)sender {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:(self.customTextField.text) completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Geocode failed with error: %@", error);
            return;
        }
        if (placemarks && placemarks.count > 0) {
            CLPlacemark *placemark = placemarks[0];
            CLLocation * location = placemark.location;
            _coords = location.coordinate;
            self.searchResult.text = [NSString localizedStringWithFormat:
                                      @"Latitude = %f, Longitude = %f",
                                      _coords.latitude, _coords.longitude];
            
        }
    }];
    
    // Create your coordinate
    CLLocationCoordinate2D myCoordinate;
    myCoordinate.latitude = _coords.latitude;
    myCoordinate.longitude = _coords.longitude;
    //Create your annotation
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    // Set your annotation to point at your coordinate
    point.coordinate = myCoordinate;
    //Clear other pins/annotations that already exist.
    for (id annotation in self.mapView.annotations) {
        [self.mapView removeAnnotation:annotation];
    }
    //Drop pin on map
    [self.mapView addAnnotation:point];

}

// Touch other place in the screen to dismiss the input keyboard.
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.customTextField resignFirstResponder];
}
@end
