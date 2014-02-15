//
//  SNSAppDelegate.m
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNSAppDelegate.h"
#import "SNSConstants.h"

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
    
    
}

#pragma mark - Actions

- (IBAction)startServer:(NSButton *)sender {
    
    
    
}


@end
