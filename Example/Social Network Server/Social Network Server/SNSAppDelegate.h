//
//  SNSAppDelegate.h
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

@import Cocoa;
#import "SNSConstants.h"

@interface SNSAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

#pragma mark - IB Outlets

@property (weak) IBOutlet NSButton *startButton;

@property (weak) IBOutlet NSTextField *portTextField;

#pragma mark - Actions

- (IBAction)startServer:(NSButton *)sender;

@end
