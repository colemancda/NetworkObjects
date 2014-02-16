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
    
    NSMutableArray *_arrangedfetchedObjects;
}

@property NSEntityDescription *selectedEntity;

@end

@implementation SNSBrowserViewController (Load)

-(void)fetchAll:(NSEntityDescription *)entity
{
    assert(entity);
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entity.name];
    
    Class entityClass = NSClassFromString(entity.managedObjectClassName);
    
    NSString *resourceIDKey = [entityClass resourceIDKey];
    
    NSSortDescriptor *sortByID = [NSSortDescriptor sortDescriptorWithKey:resourceIDKey
                                                               ascending:NO];
    
    fetchRequest.sortDescriptors = @[sortByID];
    
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    NSManagedObjectContext *context = appDelegate.store.context;
    
    [context performBlockAndWait:^{
       
        NSArray *results = [context executeFetchRequest:fetchRequest
                                                  error:nil];
        
        assert(results);
        
        _arrangedfetchedObjects = [[NSMutableArray alloc] initWithArray:results];
        
    }];
}

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
    
    // register for core data context notifications
    
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextDidChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:nil];
    
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
            
            return YES;
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
}

-(void)delete:(id)sender
{
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    // get selected resource
    
    id selectedItem = _arrangedfetchedObjects[self.tableView.clickedRow];
    
    [appDelegate.store deleteResource:selectedItem];
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
    
    // fetch
    
    [self fetchAll:self.selectedEntity];
    
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
    // get selected item
    
    id selectedItem = _arrangedfetchedObjects[self.tableView.clickedRow];
    
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
        
        // set represented object
        
        wc.representedObject = selectedItem;
        
        [_loadedWC setValue:wc
                     forKey:wcKey];
    }
    
    // show window
    [wc.window makeKeyAndOrderFront:nil];
    
}

#pragma mark - Notifications

-(void)contextDidChange:(NSNotification *)notification
{
    
    
    if (!self.selectedEntity) {
        
        return;
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        // check for insertions
        
        NSArray *insertedObjects = notification.userInfo[NSInsertedObjectsKey];
        
        if (insertedObjects.count) {
            
            // check for objects that are the same of the selected entity
            
            for (NSManagedObject *object in insertedObjects) {
                
                // update tableView if selected entity
                if (object.entity == self.selectedEntity) {
                    
                    [self fetchAll:self.selectedEntity];
                    
                    [self.tableView reloadData];
                    
                    break;
                }
            }
        }
        
        // check for deletions
        
        NSArray *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
        
        if (deletedObjects.count) {
            
            id selectedItem = _arrangedfetchedObjects[self.tableView.clickedRow];
            
            NSNumber *selectedItemResourceID = [selectedItem valueForKey:[[selectedItem class] resourceIDKey]];
            
            for (NSManagedObject *object in deletedObjects) {
                
                // try to get WC...
                
                NSString *wcKey = [NSString stringWithFormat:@"%@.%@", selectedItem, selectedItemResourceID];
                
                SNSRepresentedObjectWindowController *wc = _loadedWC[wcKey];
                
                if (wc) {
                    
                    // remove from dictonary
                    
                    [_loadedWC removeObjectForKey:wcKey];
                    
                }
                
            }
        }
        
    }];
}

#pragma mark - Table View Data Source

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _arrangedfetchedObjects.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn
           row:(NSInteger)row
{
    // get object for row
    
    NSManagedObject<NOResourceProtocol> *resource = _arrangedfetchedObjects[row];
    
    NSNumber *resourceID = [resource valueForKey:[[resource class] resourceIDKey]];
    
    return resourceID;
}

#pragma mark



@end
