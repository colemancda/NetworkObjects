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

@implementation SNSBrowserViewController (Load)

-(void)fetchAll:(NSEntityDescription *)entity
{
    assert(entity);
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entity.name];
    
    Class entityClass = NSClassFromString(entity.managedObjectClassName);
    
    NSString *resourceIDKey = [entityClass resourceIDKey];
    
    NSSortDescriptor *sortByID = [NSSortDescriptor sortDescriptorWithKey:resourceIDKey
                                                               ascending:YES];
    
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
    
    [self fetchAll:self.selectedEntity];
    
    [self.tableView reloadData];
}

-(void)delete:(id)sender
{
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    // get selected resource
    
    NSManagedObject *selectedItem = _arrangedfetchedObjects[self.tableView.selectedRow];
    
    [appDelegate.store deleteResource:(id)selectedItem];
    
    [self fetchAll:self.selectedEntity];
    
    [self.tableView reloadData];
    
    // try to get WC...
    
    NSNumber *selectedItemResourceID = [selectedItem valueForKey:[[selectedItem class] resourceIDKey]];
    
    NSString *wcKey = [NSString stringWithFormat:@"%@.%@", selectedItem.entity.name, selectedItemResourceID];
    
    SNSRepresentedObjectWindowController *wc = _loadedWC[wcKey];
    
    if (wc) {
        
        // remove from dictonary
        
        [_loadedWC removeObjectForKey:wcKey];
        
        [wc close];
        
    }
    
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
    
    // set selected entity
    
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    self.selectedEntity = appDelegate.store.context.persistentStoreCoordinator.managedObjectModel.entitiesByName[selectedEntityName];
    
    // fetch
    
    [self fetchAll:self.selectedEntity];
    
    // update UI
    
    self.tableViewScrollView.hidden = NO;
    
    self.noSelectionLabel.hidden = YES;
    
    [self.tableView reloadData];
    
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
    if (self.tableView.clickedRow == -1 || !_arrangedfetchedObjects.count) {
        
        return;
    }
    
    // get selected item
    
    NSManagedObject *selectedItem = _arrangedfetchedObjects[self.tableView.clickedRow];
    
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
        
        // KVO
        [selectedItem addObserver:self
                       forKeyPath:@"isDeleted"
                          options:NSKeyValueObservingOptionNew
                          context:KVOContext];
        
    }
    
    // show window
    [wc.window makeKeyAndOrderFront:nil];
    
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == KVOContext) {
        
        if ([keyPath isEqualToString:@"isDeleted"]) {
            
            NSManagedObject *selectedItem = (NSManagedObject *)object;
            
            // try to get WC...
            
            NSNumber *selectedItemResourceID = [selectedItem valueForKey:[[selectedItem class] resourceIDKey]];
            
            NSString *wcKey = [NSString stringWithFormat:@"%@.%@", selectedItem.entity.name, selectedItemResourceID];
            
            SNSRepresentedObjectWindowController *wc = _loadedWC[wcKey];
            
            if (wc) {
                
                // remove from dictonary
                
                [_loadedWC removeObjectForKey:wcKey];
                
                [wc close];
                
            }
            
            // stop observing
            
            [selectedItem removeObserver:self forKeyPath:@"isDeleted"];
            
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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


@end
