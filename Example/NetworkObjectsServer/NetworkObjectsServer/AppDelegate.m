//
//  AppDelegate.m
//  NetworkObjectsOSXApp
//
//  Created by Alsey Coleman Miller on 10/5/13.
//
//

#import "AppDelegate.h"
#import "ClientsWindowController.h"
#import "DDKeychain.h"
#import <NetworkObjects/NetworkObjects.h>

NSString *const ServerOnOffStatePreferenceKey = @"serverOnOffState";

NSString *const TokenLengthPreferenceKey = @"tokenLength";

NSString *const PrettyPrintJSONPreferenceKey = @"prettyPrintJSON";

@implementation AppDelegate

+(void)initialize
{
    // register defaults
    
    NSDictionary *defaults = @{ServerOnOffStatePreferenceKey: @NO,
                               TokenLengthPreferenceKey : @10,
                               PrettyPrintJSONPreferenceKey : @YES};
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    // setup store
    _store = [[NOStore alloc] init];
    
    // get URL for store persistance...
    
    // App Support Directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    
    // Application Support directory
    NSString *appSupportPath = paths[0];
    
    // get the app bundle identifier
    NSString *folderName = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleIdentifier"];
    
    // use that as app support folder and create it if it doesnt exist
    NSString *appSupportFolder = [appSupportPath stringByAppendingPathComponent:folderName];
    
    BOOL isDirectory;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:appSupportFolder
                                                           isDirectory:&isDirectory];
    
    // create folder if it doesnt exist
    if (!isDirectory || !fileExists) {
        
        NSError *error;
        BOOL createdFolder = [[NSFileManager defaultManager] createDirectoryAtPath:appSupportFolder
                                                       withIntermediateDirectories:YES
                                                                        attributes:nil
                                                                             error:&error];
        if (!createdFolder) {
            
            [NSException raise:@"Could not create Application Support folder"
                        format:@"%@", error.localizedDescription];
        }
    }
    
    NSString *sqliteFilePath = [appSupportFolder stringByAppendingPathComponent:@"NOExample.sqlite"];
    
    NSURL *sqlURL = [NSURL fileURLWithPath:sqliteFilePath];
    
    // add persistance
    NSError *addPersistentStoreError;
    [_store.context.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                            configuration:nil
                                                                      URL:sqlURL
                                                                  options:nil
                                                                    error:&addPersistentStoreError];
    
    if (addPersistentStoreError) {
        
        [NSApp presentError:addPersistentStoreError];
        
        [NSApp terminate:nil];
    }
    
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
        
        // enable HTTPS
        
        // create a new certificate if non exists
        if (![DDKeychain SSLIdentityAndCertificates].count) {
            
            [DDKeychain createNewIdentity];
        }
        
        self.server.sslIdentityAndCertificates = [DDKeychain SSLIdentityAndCertificates];
        
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
