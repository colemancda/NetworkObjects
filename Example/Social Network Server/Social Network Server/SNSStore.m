//
//  SNSStore.m
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNSStore.h"

@interface SNSStore ()

@end

@interface SNSStore (URLs)

@property (readonly) NSString *appSupportPath;

@property (readonly) NSURL *sqlURL;

@property (readonly) NSURL *lastIDsURL;

@end

@implementation SNSStore

+ (instancetype)sharedStore
{
    static SNSStore *sharedStore = nil;
    if (!sharedStore) {
        sharedStore = [[super allocWithZone:nil] init];
    }
    return sharedStore;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedStore];
}

-(id)initWithManagedObjectModel:(NSManagedObjectModel *)model lastIDsURL:(NSURL *)lastIDsURL
{
    return [[self class] sharedStore];
}

- (id)init
{
    self = [super initWithManagedObjectModel:nil
                                  lastIDsURL:self.lastIDsURL];
    if (self) {
        
        
        
    }
    return self;
}


#pragma mark

@end

#pragma mark - Category Implementation

@implementation SNSStore (URLs)

-(NSString *)appSupportPath
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
    
    // sub directory inside Application Support
    return appSupportFolder;
}

-(NSURL *)sqlURL
{
    
    NSString *sqliteFilePath = [self.appSupportPath stringByAppendingPathComponent:@"SNSDataBase.sqlite"];
    
    NSURL *sqlURL = [NSURL fileURLWithPath:sqliteFilePath];
    
    return sqlURL;
}

-(NSURL *)lastIDsURL
{
    NSString *lastIDsPath = [self.appSupportPath stringByAppendingPathComponent:@"SNSLastIDs.plist"];
    
    NSURL *url = [NSURL fileURLWithPath:lastIDsPath];
    
    return url;
}

@end
