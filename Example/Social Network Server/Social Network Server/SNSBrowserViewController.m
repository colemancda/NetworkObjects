//
//  SNSBrowserViewController.m
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNSBrowserViewController.h"
#import "SNSAppDelegate.h"

@interface SNSBrowserViewController ()

{
    NSArray *_sortedComboBox;
}

@property NSEntityDescription *selectedEntity;

@end

@implementation SNSBrowserViewController

- (id)init
{
    self = [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        
    }
    return self;
}

#pragma mark - First Responder

-(void)newDocument:(id)sender
{
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    [appDelegate.store newResourceWithEntityDescription:self.selectedEntity];
    
    [self.tableView reloadData];
}

#pragma mark - ComboBox Data Source

-(NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    _sortedComboBox = [appDelegate.store.context.persistentStoreCoordinator.managedObjectModel.entitiesByName.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    return _sortedComboBox.count;
}

-(id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return _sortedComboBox[index];
}

#pragma mark - ComboBox Delegate

-(void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    NSString *selectedEntityName = _sortedComboBox[self.comboBox.indexOfSelectedItem];
    
    // set array controller entity
    self.arrayController.entityName = selectedEntityName;
    
    [self.arrayController fetch:self];
    
    // set selected entity
    
    SNSAppDelegate *appDelegate = [NSApp delegate];

    self.selectedEntity = appDelegate.store.context.persistentStoreCoordinator.managedObjectModel.entitiesByName[selectedEntityName];
    
    // update UI
    self.tableViewScrollView.hidden = NO;
    
    self.noSelectionLabel.hidden = YES;
    
    [self.tableView reloadData];
}

@end
