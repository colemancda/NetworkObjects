//
//  AppDelegate.m
//  NetworkObjectsOSXApp
//
//  Created by Alsey Coleman Miller on 10/5/13.
//
//

#import "AppDelegate.h"
#import "NOServer.h"
#import "NOHTTPServer.h"
#import "ClientsWindowController.h"

NSString *const ServerOnOffStatePreferenceKey = @"ServerOnOffState";

NSString *const TokenLengthPreferenceKey = @"tokenLength";

@implementation AppDelegate

+(void)initialize
{
    // register defaults
    
    NSDictionary *defaults = @{ServerOnOffStatePreferenceKey: @NO,
                               TokenLengthPreferenceKey : @10};
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    // setup store (just a memory store for now)
    _store = [[NOStore alloc] init];
    
    _server = [[NOServer alloc] initWithStore:_store
                               userEntityName:@"User"
                            sessionEntityName:@"Session"
                             clientEntityName:@"Client"
                                    loginPath:@"login"];
    
    // Set a default Server header in the form of YourApp/1.0
	NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
	NSString *appVersion = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
	if (!appVersion) {
		appVersion = [bundleInfo objectForKey:@"CFBundleVersion"];
	}
	NSString *serverHeader = [NSString stringWithFormat:@"%@/%@",
							  [bundleInfo objectForKey:@"CFBundleName"],
							  appVersion];
	[_server.httpServer setDefaultHeader:@"Server" value:serverHeader];
    
    // start server if it was running last time
    BOOL start = [[NSUserDefaults standardUserDefaults] boolForKey:ServerOnOffStatePreferenceKey];
    
    if (start) {
        [self startStopServer:YES];
    }
    
    // GUI
    [self initializeWindowControllers];
}

-(BOOL)applicationShouldHandleReopen:(NSApplication *)sender
                   hasVisibleWindows:(BOOL)flag
{
    if (flag) {
        [self.window orderFront:self];
    }
    else {
        [self.window makeKeyAndOrderFront:self];
    }
    
    return YES;
}

-(void)initializeWindowControllers
{
    _clientsWC = [[ClientsWindowController alloc] init];
}

#pragma mark - Actions

- (IBAction)startStop:(id)sender {
    
    NSInteger state = [sender state];
    
    if (state == NSOffState) {
        
        [self startStopServer:NO];
    }
    else {
        [self startStopServer:YES];
    }
    
}

-(void)startStopServer:(BOOL)start
{
    
    // determine button state
    NSInteger state;
    if (start) {
        state = NSOnState;
    }
    else {
        state = NSOffState;
    }
    
    // stop server
    if (!start) {
        
        NSLog(@"Stopped Server");
        
        [self.server stop];
        
        [self.portTextField setEnabled:YES];
    }
    
    // start server
    else {
        
        NSUInteger port = self.portTextField.integerValue;
        
        NSLog(@"Starting Server on port %lu...", (unsigned long)port);
        
        NSError *startError = [self.server startOnPort:port];
        
        if (startError) {
            
            state = NSOffState;
            
            [NSApp presentError:startError];
            
        }
        else {
            
            [self.portTextField setEnabled:NO];
            
        }
    }
    
    // set the state of the GUI
    self.startServerMenuItem.state = state;
    self.startStopButton.state = state;
    
    // store in preferences
    [[NSUserDefaults standardUserDefaults] setBool:start
                                            forKey:ServerOnOffStatePreferenceKey];
    
}


- (IBAction)viewClients:(NSMenuItem *)sender {
    
    [_clientsWC.window makeKeyAndOrderFront:sender];
    
}


@end
