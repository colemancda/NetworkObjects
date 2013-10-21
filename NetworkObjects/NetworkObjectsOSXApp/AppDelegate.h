//
//  AppDelegate.h
//  NetworkObjectsOSXApp
//
//  Created by Alsey Coleman Miller on 10/5/13.
//
//

#import <Cocoa/Cocoa.h>
#import "NetworkObjects.h"

@class ClientsWindowController;

extern NSString *const ServerOnOffStatePreferenceKey;

extern NSString *const TokenLengthPreferenceKey;

extern NSString *const PrettyPrintJSONPreferenceKey;

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

- (IBAction)viewClients:(NSMenuItem *)sender;

#pragma mark - Window Controllers

-(void)initializeWindowControllers;

@property (readonly) ClientsWindowController *clientsWC;


@end
