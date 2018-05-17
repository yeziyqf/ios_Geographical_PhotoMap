//
//  AppDelegate.h
//  Geographical_Photo_Map
//
//  Created by qye on 5/17/18.
//  Copyright © 2018 qye. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

