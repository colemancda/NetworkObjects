//
//  AppDelegate.h
//  NOClientExample
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ClientStore;

#define AppErrorDomain @"com.ColemanCDA.NetworkObjectsClient.ErrorDomain"

#define SessionPreferenceKey @"session"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
