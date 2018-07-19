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
#import "../Jetfire_websocket/JFRWebSocket.h"

@interface ViewController ()
<CLLocationManagerDelegate>

@end

@interface ViewController ()<JFRWebSocketDelegate>

@property(nonatomic, strong)JFRWebSocket *socket;

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
    
    // websocket connection initialization.
    self.socket = [[JFRWebSocket alloc] initWithURL:[NSURL URLWithString:@"ws://localhost:9002"] protocols:@[@"chat",@"superchat"]];
    self.socket.delegate = self;
    [self.socket connect];
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

- (IBAction)ReverseGroButtonTouched:(id)sender{
    CLLocation *newlocation = [[CLLocation alloc]
                               initWithLatitude:self.labelLatitude.text.doubleValue longitude:self.labelLongitude.text.doubleValue];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:newlocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Geocode failed with error: %@", error);
            return;
        }
        if (placemarks && placemarks.count > 0) {
            CLPlacemark *placemark = placemarks[0];
            CLLocation *location = placemark.location;
            
            // For ios 9 and later, use CNPostalAddress instead.
            // Extract address information
            NSLog(@"Found %@", placemark.name);
            NSString *placeName = placemark.name;
            NSString *city = placemark.locality;
            NSString *AdminArea = placemark.administrativeArea;
            NSString *postalCode = placemark.postalCode;
            NSString *country = placemark.country;
//            NSDictionary *addressDict = @{
//                                          CNPostalAddressStreetKey : location.street,
//                                          CNPostalAddressCityKey : location.city,
//                                          CNPostalAddressStateKey : location.state,
//                                          CNPostalAddressPostalCodeKey : location.zip,
//                                          CNPostalAddressCountryKey : location.country,
//                                          CNPostalAddressISOCountryCodeKey : location.countryCode
//                                          };
            
            // Before ios 9.
            //NSDictionary *addressDictionary = placemark.addressDictionary;
            //NSString *address = [addressDictionary objectForKey:(NSString *) kABPersonAddressStreetKey];
            //NSString *city = [addressDictionary objectForKey:(NSString *) kABPersonAddressCityKey];
            //NSString *state = [addressDictionary objectForKey:(NSString *) kABPersonAddressStateKey];
            
            // Show result on the label.
//            self.ReverseResult.text = [NSString localizedStringWithFormat:placeName];
            self.ReverseResult.text = [NSString stringWithFormat:@"%@ %@ %@ %@ %@",placeName, city, AdminArea, postalCode, country];
        }
    }];
}


// Touch other place in the screen to dismiss the input keyboard.
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.customTextField resignFirstResponder];
}

- (IBAction)UploadButtonClicked:(id)sender {
    NSString *strFName = @"nathan";
    NSString *strLName = @"Yosemite_GlacierPoint";
    NSString *SHA256 = @"3a6de1888650ee3a614d91017b30ca6976af13ec8adeebaf63e286fdf09178dd";
    
    NSString *strKeyFN = @"unique_image_name";
    NSString *strKeyLN = @"user_name";
    NSString *numValue = @"SHA256";
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    
    [dic setObject:strFName forKey:strKeyFN];
    [dic setObject:strLName forKey:strKeyLN];
    [dic setObject:[NSNumber numberWithInt:SHA256] forKey:numValue];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[NSArray arrayWithObject:dic] options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"JSON  %@",jsonString);
    
    //[self.socket writeString:@""];
    [self.socket writeString:jsonString];
}

- (IBAction)disconnect:(UIBarButtonItem *)sender {
    if(self.socket.isConnected) {
        sender.title = @"Connect";
        [self.socket disconnect];
    } else {
        sender.title = @"Disconnect";
        [self.socket connect];
    }
}

// pragma mark: WebSocket Delegate methods.

-(void)websocketDidConnect:(JFRWebSocket*)socket {
    NSLog(@"websocket is connected");
}

-(void)websocketDidDisconnect:(JFRWebSocket*)socket error:(NSError*)error {
    NSLog(@"websocket is disconnected: %@", [error localizedDescription]);
    [self.socket connect];
}

-(void)websocket:(JFRWebSocket*)socket didReceiveMessage:(NSString*)string {
    NSLog(@"Received text: %@", string);
}

-(void)websocket:(JFRWebSocket*)socket didReceiveData:(NSData*)data {
    NSLog(@"Received data: %@", data);
}

// pragma mark: target actions.

@end
