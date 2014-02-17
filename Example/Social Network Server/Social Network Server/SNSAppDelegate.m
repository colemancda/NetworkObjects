//
//  SNSAppDelegate.m
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNSAppDelegate.h"
#import "SNSConstants.h"
#import "SNSBrowserViewController.h"
#import "SNSLogViewController.h"

@interface SNSAppDelegate ()

@property SNSBrowserViewController *browserVC;

@property SNSLogViewController *logVC;

@end

@interface SNSAppDelegate (Paths)

@property (readonly) NSString *appSupportFolderPath;

@end

@interface SNSAppDelegate (Initialization)

-(void)setupServer;

-(void)setupVCs;

@end

#pragma mark - Main Implementation

@implementation SNSAppDelegate

+(void)initialize
{
    // register defaults
    
    NSDictionary *defaults = @{kSNSPrettyPrintJSONPreferenceKey: @NO,
                               kSNSTokenLengthPreferenceKey : @10,
                               kSNSServerPort : @8080,
                               kSNSServerOnOffStatePreferenceKey : @NO};
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    [self setupServer];
    
    [self setupVCs];
    
    // start server if it was running last time
    BOOL resume = [[NSUserDefaults standardUserDefaults] boolForKey:kSNSServerOnOffStatePreferenceKey];
    
    if (resume) {
        
        NSLog(@"Server will be resumed...");
        
        [self startServer:nil];
    }
    
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
    NSLog(@"Terminating...");
    
    BOOL saved = [self.store save];
    
    if (saved) {
        
        NSLog(@"Saved data successfully");
    }
    else {
        
        NSLog(@"Could not save data");
    }
    
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    // intelligently terminate if the server is not running
    return !self.server.httpServer.isRunning;
}

-(BOOL)applicationShouldHandleReopen:(NSApplication *)sender
                   hasVisibleWindows:(BOOL)flag
{
    [self.window makeKeyAndOrderFront:nil];
    
    return YES;
}

#pragma mark Actions

- (IBAction)showServerControl:(NSToolbarItem *)sender {
    
    if (self.box.contentView != self.serverControlView) {
        
        self.box.contentView = self.serverControlView;
    }
}

- (IBAction)showLog:(NSToolbarItem *)sender {
    
    if (self.box.contentView != self.logVC.view) {
        
        self.box.contentView = self.logVC.view;
    }
}

- (IBAction)showBrowser:(NSToolbarItem *)sender {
    
    if (self.box.contentView != self.browserVC.view) {
        
        [self.box.contentView resignFirstResponder];
        
        self.box.contentView = self.browserVC.view;
        
        [self.window makeFirstResponder:self.browserVC];
        
    }
}

-(void)startServer:(id)sender
{
    BOOL isServerRunning = self.server.httpServer.isRunning;
    
    // start server
    
    if (!isServerRunning) {
        
        NSLog(@"Starting Server");
        
        NSInteger port = self.portTextField.integerValue;
        
        NSError *startServerError = [self.server startOnPort:port];
        
        if (startServerError) {
            
            [NSApp presentError:startServerError];
            
            return;
        }
        
        // if port was 0 then the HTTP server will give it a random value, we need to assign that to the UI
        
        if (!port) {
            
            NSLog(@"A random port was assigned to the server");
            
            self.portTextField.integerValue = (NSInteger)self.server.httpServer.port;
            
        }
        
        // update UI
        
        [self.portTextField setEnabled:NO];
        
        self.startButton.state = NSOnState;
        
        // set preferences
        
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:kSNSServerOnOffStatePreferenceKey];
        
    }
    
    // stop the server
    else {
        
        NSLog(@"Stopping Server");
        
        // update UI
        
        [self.server stop];
        
        [self.portTextField setEnabled:YES];
        
        self.startButton.state = NSOffState;
        
        // set preferences
        
        [[NSUserDefaults standardUserDefaults] setBool:NO
                                                forKey:kSNSServerOnOffStatePreferenceKey];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}



@end

#pragma mark - Category Implementation

@implementation SNSAppDelegate (Paths)

-(NSString *)appSupportFolderPath
{
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
    
    return appSupportFolder;
}

@end

@implementation SNSAppDelegate (Initialization)

-(void)setupServer
{
    // get paths
    
    NSString *sqliteFilePath = [self.appSupportFolderPath stringByAppendingPathComponent:@"NOExample.sqlite"];
    
    NSURL *sqlURL = [NSURL fileURLWithPath:sqliteFilePath];
    
    NSString *lastIDsPath = [self.appSupportFolderPath stringByAppendingPathComponent:@"lastIDs.plist"];
    
    NSURL *lastIDsURL = [NSURL fileURLWithPath:lastIDsPath];
    
    // setup store
    
    _store = [[NOStore alloc] initWithManagedObjectModel:nil
                                              lastIDsURL:lastIDsURL];
    
    
    // get URL for store persistance...
    
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
}

-(void)setupVCs
{
    // logVC
    
    self.logVC = [[SNSLogViewController alloc] init];
    
    // browser VC
    
    self.browserVC = [[SNSBrowserViewController alloc] init];
    
    // server control
    
    [self showServerControl:nil];
}

@end

