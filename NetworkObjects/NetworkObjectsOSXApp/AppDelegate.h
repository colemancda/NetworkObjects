//
//  AppDelegate.h
//  NetworkObjectsOSXApp
//
//  Created by Alsey Coleman Miller on 10/5/13.
//
//

#import <Cocoa/Cocoa.h>
#import "NetworkObjects.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly) NOServer *server;

@property (readonly) NOStore *store;

#pragma mark - UI

- (IBAction)startStop:(id)sender;

@property (weak) IBOutlet NSTextField *portTextField;

@end
