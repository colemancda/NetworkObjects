//
//  SNSBrowserViewController.h
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SNSBrowserViewController : NSViewController <NSComboBoxDelegate, NSComboBoxDataSource>

@property (strong) IBOutlet NSArrayController *arrayController;

#pragma mark - IB UI

@property (weak) IBOutlet NSComboBox *comboBox;

@property (weak) IBOutlet NSTableView *tableView;

@property (weak) IBOutlet NSTextField *noSelectionLabel;

@property (weak) IBOutlet NSScrollView *tableViewScrollView;

#pragma mark - KVO Properties

@property (readonly) NSEntityDescription *selectedEntity;

@end
