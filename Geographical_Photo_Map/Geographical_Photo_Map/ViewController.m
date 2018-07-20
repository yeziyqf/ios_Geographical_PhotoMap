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
    
    // Firebase initialization.
    self.ref = [[FIRDatabase database] reference];
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

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //You can retrieve the actual UIImage
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    //Or you can get the image url from AssetsLibrary
    NSURL *path = [info valueForKey:UIImagePickerControllerReferenceURL];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"finish choosing image.");
    
    // Upload to firebase
    // Local file you want to upload
    //NSURL *localFile = [NSURL URLWithString: path];
    NSURL *localFile = path;
    
    // Create the file metadata
    FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc] init];
    metadata.contentType = @"image/jpeg";
    
    // Get a reference to the storage service using the default Firebase App
    FIRStorage *storage = [FIRStorage storage];
    
    // Create a storage reference from our storage service
    FIRStorageReference *storageRef = [storage reference];
    
    // Upload file and metadata to the object 'images/mountains.jpg'
    FIRStorageUploadTask *uploadTask = [storageRef putFile:localFile metadata:metadata];
    
    // Listen for state changes, errors, and completion of the upload.
    [uploadTask observeStatus:FIRStorageTaskStatusResume handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload resumed, also fires when the upload starts
    }];
    
    [uploadTask observeStatus:FIRStorageTaskStatusPause handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload paused
    }];
    
    [uploadTask observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload reported progress
        double percentComplete = 100.0 * (snapshot.progress.completedUnitCount) / (snapshot.progress.totalUnitCount);
    }];
    
    [uploadTask observeStatus:FIRStorageTaskStatusSuccess handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload completed successfully
    }];

    // Errors only occur in the "Failure" case
    [uploadTask observeStatus:FIRStorageTaskStatusFailure handler:^(FIRStorageTaskSnapshot *snapshot) {
        if (snapshot.error != nil) {
            switch (snapshot.error.code) {
                case FIRStorageErrorCodeObjectNotFound:
                    // File doesn't exist
                    break;
                    
                case FIRStorageErrorCodeUnauthorized:
                    // User doesn't have permission to access file
                    break;
                    
                case FIRStorageErrorCodeCancelled:
                    // User canceled the upload
                    break;
                    
                    /* ... */
                    
                case FIRStorageErrorCodeUnknown:
                    // Unknown error occurred, inspect the server response
                    break;
            }
        }
    }];
}

- (IBAction)UploadButtonClicked:(id)sender {
    // Choose from photo library.
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
    

    
    // Construct the json vector to be sent to server.
    NSString *strFName = @"nathan";
    NSString *strLName = @"YOSEMITE";
    NSString *SHA256 = @"3a6de1888650ee3a614d91017b30ca6976af13ec8adeebaf63e286fdf09178dd";
    
    NSString *strKeyFN = @"unique_image_name";
    NSString *strKeyLN = @"user_name";
    NSString *imgVector = @"SHA256";
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    
    [dic setObject:strLName forKey:strKeyFN];
    [dic setObject:strFName forKey:strKeyLN];
    [dic setObject:SHA256 forKey:imgVector];
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
