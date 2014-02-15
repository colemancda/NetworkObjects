//
//  SNSServer.m
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNSServer.h"

@interface SNSServer ()
{
    NOServer *_server;
}

@end

@interface SNSServer (URL)

@property (readonly) NSURL *sqlURL;

@end

@implementation SNSServer

#pragma mark - Singleton

+ (instancetype)sharedServer
{
    static SNSServer *sharedServer = nil;
    if (!sharedServer) {
        sharedServer  = [[super allocWithZone:nil] init];
    }
    return sharedServer;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedServer];
}

- (id)init
{
    self = [super init];
    if (self) {
        
        
        
    }
    return self;
}




@end

#pragma mark - Category Implementation

@implementation SNSServer (URL)

-(NSURL *)sqlURL
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
