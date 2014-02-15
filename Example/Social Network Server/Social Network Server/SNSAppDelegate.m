//
//  SNSAppDelegate.m
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNSAppDelegate.h"
#import "SNSConstants.h"
#import "SNSServer.h"

@interface SNSAppDelegate (URL)

@property (readonly) NSURL *SQLURL;

@end

@interface SNSAppDelegate (Initialization)

-(void)setupServer;

-(void)setupUI;

@end

#pragma mark - Main Implementation

@implementation SNSAppDelegate

+(void)initialize
{
    // register defaults
    
    NSDictionary *defaults = @{kSNSPrettyPrintJSONPreferenceKey: @NO,
                               kSNSTokenLengthPreferenceKey : @10,
                               kSNSPrettyPrintJSONPreferenceKey : @YES};
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    [self setupServer];
    
    [self setupUI];
    
    // start server if it was running last time
    BOOL resume = [[NSUserDefaults standardUserDefaults] boolForKey:kSNSServerOnOffStatePreferenceKey];
    
    if (resume) {
        [self startServer];
    }
}

#pragma mark Actions

- (IBAction)startServer; {
    
    BOOL isServerRunning = self.server.httpServer.isRunning;
    
    // start server
    
    switch (isServerRunning) {
        case NO:
            
            
            
            break;
            
        default:
            
            
            
            break;
    }
    
}


@end

#pragma mark - Category Implementation

@implementation SNSAppDelegate (URL)

-(NSURL *)SQLURL
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
    
    NSString *sqliteFilePath = [appSupportFolder stringByAppendingPathComponent:@"NOExample.sqlite"];
    
    NSURL *sqlURL = [NSURL fileURLWithPath:sqliteFilePath];
    
    return sqlURL;
}

@end

@implementation SNSAppDelegate (Initialization)

-(void)setupServer
{
    // setup store
    _store = [[NOStore alloc] init];
    
    // get URL for store persistance...
    
    NSURL *sqlURL = self.SQLURL;
    
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
    
    
    
}

-(void)setupUI
{
    
    
}

@end

