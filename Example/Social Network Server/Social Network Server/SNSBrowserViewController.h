//
//  SNSBrowserViewController.h
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SNSBrowserViewController : NSViewController <NSComboBoxDelegate, NSComboBoxDataSource>

@property (weak) IBOutlet NSComboBox *comboBox;

@property (weak) IBOutlet NSTableView *tableView;

@property (readonly) NSEntityDescription *selectedEntity;

@end
