//
//  ClientsWindowController.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/13/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ClientsWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
    NSMutableArray *_clients;
    
    NSDateFormatter *_dateFormatter;
}

@property (weak) IBOutlet NSTableView *tableView;

#pragma mark - Actions

-(IBAction)newDocument:(id)sender;

-(IBAction)delete:(id)sender;

-(void)populateClientsArrayWithSortDescriptor:(NSArray *)sortDescriptors;

-(IBAction)checkBoxSelected:(NSButton *)sender;



@end
