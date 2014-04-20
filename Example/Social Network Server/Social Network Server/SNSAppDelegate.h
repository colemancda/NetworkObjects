//
//  SNSAppDelegate.h
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

@import Cocoa;
#import <NetworkObjects/NetworkObjects.h>
#import "SNSConstants.h"
@class SNSBrowserViewController, SNSLogViewController;

@interface SNSAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

#pragma mark - Properties

@property (nonatomic, readonly) NOServer *server;

@property (nonatomic, readonly) NOStore *store;

@property (nonatomic, readonly) NSManagedObjectContext *context;

#pragma mark - View Controllers

@property (readonly) SNSBrowserViewController *browserVC;

@property (readonly) SNSLogViewController *logVC;

#pragma mark - IB Outlets

@property (weak) IBOutlet NSBox *box;

@property (weak) IBOutlet NSButton *startButton;

@property (weak) IBOutlet NSTextField *portTextField;

@property (weak) IBOutlet NSView *serverControlView;

#pragma mark - Actions

- (IBAction)showServerControl:(NSToolbarItem *)sender;

- (IBAction)showLog:(NSToolbarItem *)sender;

- (IBAction)showBrowser:(NSToolbarItem *)sender;

- (IBAction)startServer:(id)sender;


@end
