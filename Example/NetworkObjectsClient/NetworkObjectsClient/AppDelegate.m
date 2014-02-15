//
//  AppDelegate.m
//  NOClientExample
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "AppDelegate.h"
#import "ClientStore.h"

@implementation AppDelegate

-(BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // initialize store
    [ClientStore sharedStore];
    
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - State Restoration and Preservation

-(BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

-(BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return YES;
}

-(UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    // decode storyboard
    UIStoryboard *storyBoard = [coder decodeObjectForKey:UIStateRestorationViewControllerStoryboardKey];
    
    if (!storyBoard) {
        
        return nil;
    }
    
    NSString *identifier;
    
    // if there is no session than just restore the authentication VC
    
    NSString *sessionToken = [[NSUserDefaults standardUserDefaults] stringForKey:SessionPreferenceKey];
    
    if (!sessionToken) {
        
        identifier = identifierComponents.firstObject;
    }
    
    // restore last VC
    else {
        
        identifierComponents = identifierComponents.lastObject;
    }
    
    UIViewController *restorableVC = [storyBoard instantiateViewControllerWithIdentifier:identifier];
    
    restorableVC.restorationIdentifier = identifier;
    
    restorableVC.restorationClass = [restorableVC class];
    
    return restorableVC;
}

-(void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder
{
    
    
    
}

@end
