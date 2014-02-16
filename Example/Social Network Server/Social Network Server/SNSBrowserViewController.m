//
//  SNSBrowserViewController.m
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNSBrowserViewController.h"
#import "SNSAppDelegate.h"
#import "SNSClientWindowController.h"
#import "SNSRepresentedObjectWindowController.h"

@interface SNSBrowserViewController ()

{
    NSArray *_sortedComboBox;
    
    NSMutableDictionary *_loadedWC;
}

@property NSEntityDescription *selectedEntity;

@end

@implementation SNSBrowserViewController

- (id)init
{
    self = [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        
        _loadedWC = [[NSMutableDictionary alloc] init];
        
    }
    return self;
}

-(void)loadView
{
    [super loadView];
    
    // table view double click selector
    [self.tableView setDoubleAction:@selector(doubleClickedTableViewRow:)];
    
    [self.tableView setTarget:self];
    
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

#pragma mark - Actions

-(void)doubleClickedTableViewRow:(id)sender
{
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    // get selected item
    
    id selectedItem = self.arrayController.arrangedObjects[self.tableView.clickedRow];
    
    // attempt to get already open WC for the selected object
    
    NSNumber *selectedItemResourceID = [selectedItem valueForKey:[[selectedItem class] resourceIDKey]];
    
    NSString *wcKey = [NSString stringWithFormat:@"%@.%@", selectedItem, selectedItemResourceID];
    
    SNSRepresentedObjectWindowController *wc = _loadedWC[wcKey];
    
    // lazily initialize and add to loadedWC
    
    if (!wc) {
        
        // determine WC to load based on entity...
        
        NSString *wcClassName = [NSString stringWithFormat:@"SNS%@WindowController", self.selectedEntity.name];
        
        Class wcClass = NSClassFromString(wcClassName);
        
        wc = [[wcClass alloc] init];
        
        [_loadedWC setValue:wc
                     forKey:wcKey];
    }
    
    // set represented object
    
    wc.representedObject = selectedItem;
    
    // show window
    [wc.window makeKeyAndOrderFront:nil];
    
}

@end
