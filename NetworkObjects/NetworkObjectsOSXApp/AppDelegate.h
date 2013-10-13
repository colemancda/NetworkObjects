//
//  AppDelegate.h
//  NetworkObjectsOSXApp
//
//  Created by Alsey Coleman Miller on 10/5/13.
//
//

#import <Cocoa/Cocoa.h>
#import "NetworkObjects.h"

extern NSString *const ServerOnOffStatePreferenceKey;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly) NOServer *server;

@property (readonly) NOStore *store;

#pragma mark - UI

-(IBAction)startStop:(id)sender;

-(void)startStopServer:(BOOL)start;

@property (weak) IBOutlet NSTextField *portTextField;

@property (weak) IBOutlet NSMenuItem *startServerMenuItem;

@property (weak) IBOutlet NSButton *startStopButton;


@end
