//
//  SNSBrowserViewController.h
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SNSClientWindowController;

@interface SNSBrowserViewController : NSViewController <NSComboBoxDelegate, NSComboBoxDataSource, NSTableViewDataSource, NSTableViewDelegate>

{
    NSArray *_sortedComboBox;
    
    NSMutableDictionary *_loadedWC;
}

@property IBOutlet NSArrayController *arrayController;

#pragma mark - IB UI

@property (weak) IBOutlet NSComboBox *comboBox;

@property (weak) IBOutlet NSTableView *tableView;

@property (weak) IBOutlet NSTextField *noSelectionLabel;

@property (weak) IBOutlet NSScrollView *tableViewScrollView;

#pragma mark - KVO Properties

@property (readonly) NSEntityDescription *selectedEntity;

@property (readonly) BOOL canCreateNew;

@property (readonly) BOOL canDelete;

#pragma mark - Actions

-(void)doubleClickedTableViewRow:(id)sender;

-(IBAction)newDocument:(id)sender;

-(IBAction)delete:(id)sender;

-(IBAction)fetch:(id)sender;

#pragma mark - Notifications

-(void)contextDidChange:(NSNotification *)notification;

@end
