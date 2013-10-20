//
//  ClientsWindowController.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/13/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "ClientsWindowController.h"
#import "AppDelegate.h"
#import "Client.h"
#import "CheckBoxCellView.h"
#import "NSString+RandomString.h"

@interface ClientsWindowController ()

@end

@implementation ClientsWindowController

-(id)init
{
    self = [self initWithWindowNibName:NSStringFromClass(self.class)
                                 owner:self];
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.dateStyle = NSDateFormatterShortStyle;
    
    NSError *populateError = [self populateClientsArrayWithSortDescriptor:@[@"isNotThirdParty"]];
    
    if (populateError) {
        
        [NSApp presentError:populateError
             modalForWindow:self.window
                   delegate:nil
         didPresentSelector:nil
                contextInfo:nil];
    }
    
    // KVC
    
}

-(void)dealloc
{
    
    
}

#pragma mark - KVC

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    
    
    
}

#pragma mark - Actions

-(void)newDocument:(id)sender
{
    // create new client...
    
    AppDelegate *appDelegate = [NSApp delegate];
    
    NSEntityDescription *clientEntity = [NSEntityDescription entityForName:@"Client"
                                                    inManagedObjectContext:appDelegate.store.context];
    
    Client *newClient = (Client *)[appDelegate.store newResourceWithEntityDescription:clientEntity];
    
    // set new values
    newClient.name = @"New Client";
    
    NSInteger tokenLength = [[NSUserDefaults standardUserDefaults] integerForKey:TokenLengthPreferenceKey];
    
    newClient.secret = [NSString randomStringWithLength:tokenLength];
    
    // TEMP
    NSLog(@"Created new client %@", newClient);
    
    [_clients addObject:newClient];
    
    [self.tableView reloadData];
}

-(void)delete:(id)sender
{
    // get model obeject
    
    Client *client = _clients[self.tableView.selectedRow];
    
    AppDelegate *appDelegate = [NSApp delegate];
    
    [appDelegate.store deleteResource:(NSManagedObject<NOResourceProtocol > *)client];
    
    [_clients removeObject:client];
    
    [self.tableView reloadData];
}

#pragma mark

-(NSError *)populateClientsArrayWithSortDescriptor:(NSArray *)sortDescriptors
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Client"];
    fetchRequest.sortDescriptors = sortDescriptors;
    
    AppDelegate *appDelegate = [NSApp delegate];
    
    NSManagedObjectContext *context = appDelegate.store.context;
    
    __block NSError *fetchError;
    
    [context performBlockAndWait:^{
        
        NSArray *result = [context executeFetchRequest:fetchRequest
                                                 error:&fetchError];
        
        if (result) {
            
            _clients = [NSMutableArray arrayWithArray:result];
        }
        
    }];
    
    return fetchError;
}

#pragma mark - NSTableView DataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _clients.count;
}

-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSError *error = [self populateClientsArrayWithSortDescriptor:self.tableView.sortDescriptors];
    
    if (error) {
        
        [NSApp presentError:error
             modalForWindow:self.window
                   delegate:nil
         didPresentSelector:nil
                contextInfo:nil];
    }
}

#pragma mark - NSTableView Delegate

-(NSView *)tableView:(NSTableView *)tableView
  viewForTableColumn:(NSTableColumn *)tableColumn
                 row:(NSInteger)row
{
    Client *client = _clients[row];
    
    // column identifier determines the model property to use and
    NSString *identifier = tableColumn.identifier;
    
    NSTableCellView *cellView = [self.tableView makeViewWithIdentifier:identifier
                                                                 owner:self];
    
    if ([identifier isEqualToString:@"isNotThirdParty"]) {
        
        CheckBoxCellView *checkBoxCellView = (CheckBoxCellView *)cellView;
        
        checkBoxCellView.checkBox.integerValue = client.isNotThirdParty.boolValue;
        
        return checkBoxCellView;
    }
    
    if ([identifier isEqualToString:@"created"]) {
        
        NSDate *date = client.created;
        
        cellView.textField.stringValue = [_dateFormatter stringFromDate:date];
        
        return cellView;
    }
    
    // for all other use KVC to get property value
    
    cellView.textField.stringValue = [client valueForKey:identifier];
    
    return cellView;
}


@end
