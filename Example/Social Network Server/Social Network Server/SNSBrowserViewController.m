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

static void *KVOContext;

@interface SNSBrowserViewController ()

@property NSEntityDescription *selectedEntity;

@property BOOL canCreateNew;

@property BOOL canDelete;

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
    
    // sorting
    self.arrayController.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"resourceID"
                                                                           ascending:YES]];
    
    // register for context changes
    
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextDidChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:appDelegate.store.context];
    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - First Responder

-(BOOL)acceptsFirstResponder
{
    return YES;
}

-(BOOL)becomeFirstResponder
{
    return YES;
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    // new
    if (menuItem.action == @selector(newDocument:)) {
        
        // an entity must be selected
        
        if (self.selectedEntity) {
            
            // dont create new sessions objects
            
            if ([self.selectedEntity.name isEqualToString:@"Client"]) {
                
                return YES;
            }
            
            return NO;
        }
        
        return NO;
    }
    
    // delete
    if (menuItem.action == @selector(delete:)) {
        
        // a tableview row must selected and an entity must be selected
        
        if (self.selectedEntity && self.tableView.selectedRow != -1) {
            
            return YES;
        }
        
        return NO;
    }
    
    return YES;
}

-(void)newDocument:(id)sender
{
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    [appDelegate.store newResourceWithEntityDescription:self.selectedEntity];
    
    [self.arrayController fetch:nil];
}

-(void)delete:(id)sender
{
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    // get selected resource
    
    NSManagedObject *selectedItem = self.arrayController.arrangedObjects[self.tableView.selectedRow];
    
    [appDelegate.store deleteResource:(id)selectedItem];
    
    [self.arrayController fetch:nil];
    
}

#pragma mark - ComboBox Data Source

-(NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    // populate with names of entities
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
    
    // set selected entity
    
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    self.selectedEntity = appDelegate.store.context.persistentStoreCoordinator.managedObjectModel.entitiesByName[selectedEntityName];
    
    self.arrayController.entityName = self.selectedEntity.name;
    
    [self.arrayController fetch:nil];
    
    // update UI
    
    self.tableViewScrollView.hidden = NO;
    
    self.noSelectionLabel.hidden = YES;
    
    // enable new button for client
    if ([self.selectedEntity.name isEqualToString:@"Client"]) {
        
        self.canCreateNew = YES;
    }
    else {
        
        self.canCreateNew = NO;
        
    }
    
}

#pragma mark - Actions

-(void)doubleClickedTableViewRow:(id)sender
{
    NSArray *arrangedObjects = self.arrayController.arrangedObjects;
    
    if (self.tableView.clickedRow == -1 || !arrangedObjects.count) {
        
        return;
    }
    
    // get selected item
    
    NSManagedObject *selectedItem = arrangedObjects[self.tableView.clickedRow];
    
    // attempt to get already open WC for the selected object
    
    NSNumber *selectedItemResourceID = [selectedItem valueForKey:[[selectedItem class] resourceIDKey]];
    
    NSString *wcKey = [NSString stringWithFormat:@"%@.%@", selectedItem.entity.name, selectedItemResourceID];
    
    SNSRepresentedObjectWindowController *wc = _loadedWC[wcKey];
    
    // lazily initialize and add to loadedWC
    
    if (!wc) {
        
        // determine WC to load based on entity...
        
        NSString *wcClassName = [NSString stringWithFormat:@"SNS%@WindowController", self.selectedEntity.name];
        
        Class wcClass = NSClassFromString(wcClassName);
        
        wc = [[wcClass alloc] init];
        
        // set represented object
        
        wc.representedObject = selectedItem;
        
        [_loadedWC setValue:wc
                     forKey:wcKey];
        
    }
    
    // show window
    [wc.window makeKeyAndOrderFront:nil];
    
}

#pragma mark - Table View Delegate

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (self.tableView.selectedRow == -1) {
        
        self.canDelete = NO;
        
    }
    
    else {
        
        self.canDelete = YES;
    }
    
}

#pragma mark - Notifications

-(void)contextDidChange:(NSNotification *)notification
{
    // deleted WC of deleted object
    NSSet *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
    
    for (NSManagedObject *managedObject in deletedObjects) {
        
        // try to get WC...
        
        NSNumber *selectedItemResourceID = [managedObject valueForKey:[[managedObject class] resourceIDKey]];
        
        NSString *wcKey = [NSString stringWithFormat:@"%@.%@", managedObject.entity.name, selectedItemResourceID];
        
        SNSRepresentedObjectWindowController *wc = _loadedWC[wcKey];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if (wc) {
                
                // remove from dictionary
                
                [_loadedWC removeObjectForKey:wcKey];
                
                [wc close];
                
            }
            
            // check if visible
            if (managedObject.entity == self.selectedEntity) {
                
                [self.arrayController fetch:nil];
            }
            
        }];
        
    }
}


@end
