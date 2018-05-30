//
//  ViewController.h
//  Geographical_Photo_Map
//
//  Created by qye on 5/17/18.
//  Copyright © 2018 qye. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Contacts/Contacts.h>

@interface ViewController : UIViewController


@property (weak, nonatomic) IBOutlet UILabel *labelLongitude;
@property (weak, nonatomic) IBOutlet UILabel *labelLatitude;
@property (weak, nonatomic) IBOutlet UILabel *labelAltitude;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

// For geocoding
@property (weak, nonatomic) IBOutlet UITextField *customTextField;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UILabel *searchResult;
@property CLLocationCoordinate2D coords;
@property (weak, nonatomic) IBOutlet UIButton *ReverseGeoButton;
@property (weak, nonatomic) IBOutlet UILabel *ReverseResult;

@end


