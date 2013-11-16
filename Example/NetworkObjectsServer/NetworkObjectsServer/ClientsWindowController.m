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
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"resourceID"
                                                           ascending:YES];
    
    [self populateClientsArrayWithSortDescriptor:@[sort]];
    
    [self.tableView reloadData];
    
}

#pragma mark - First Responder

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(delete:)) {
        
        if (self.tableView.selectedRow == -1) {
            return NO;
        }
        
        return YES;
    }
    
    // return super implementation
    return YES;
}

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

-(void)checkBoxSelected:(NSButton *)sender
{
    // get model object
    
    Client *client = _clients[sender.tag];
    
    if (sender.state == NSOnState) {
        
        client.isNotThirdParty = @YES;
    }
    else {
        client.isNotThirdParty = @NO;
    }
    
    NSLog(@"Set Client %@ isNotThirdPary property to %@", client.resourceID, client.isNotThirdParty);
}

#pragma mark - Populate Array

-(void)populateClientsArrayWithSortDescriptor:(NSArray *)sortDescriptors
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Client"];
    
    fetchRequest.sortDescriptors = sortDescriptors;
    
    AppDelegate *appDelegate = [NSApp delegate];
    
    NSManagedObjectContext *context = appDelegate.store.context;
    
    [context performBlockAndWait:^{
        
        NSError *fetchError;
        NSArray *result = [context executeFetchRequest:fetchRequest
                                                 error:&fetchError];
        
        if (!result) {
            
            [NSException raise:@"Fetch Request Failed"
                        format:@"%@", fetchError.localizedDescription];
            return;
        }
        
        _clients = [NSMutableArray arrayWithArray:result];
        
    }];
}

#pragma mark - NSTableView DataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _clients.count;
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
        
        // set tag
        
        checkBoxCellView.checkBox.tag = row;
        
        return checkBoxCellView;
    }
    
    // set tags
    cellView.textField.tag = row;
    
    if ([identifier isEqualToString:@"created"]) {
        
        NSDate *date = client.created;
        
        if (!_dateFormatter) {
            _dateFormatter = [[NSDateFormatter alloc] init];
            _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        }
        
        cellView.textField.stringValue = [_dateFormatter stringFromDate:date];
        
        return cellView;
    }
    
    if ([identifier isEqualToString:@"id"]) {
        
        cellView.textField.integerValue = client.resourceID.integerValue;
        
        return cellView;
    }
    
    // for all other use KVC to get property value
    
    cellView.textField.stringValue = [client valueForKey:identifier];
    
    return cellView;
}

-(void)controlTextDidEndEditing:(NSNotification *)notification
{
    NSTextField *textField = notification.object;
    
    NSInteger row = textField.tag;
    
    // get model object
    
    Client *client = _clients[row];
    
    // use KVC to set value
    
    [client setValue:textField.stringValue
              forKey:textField.identifier];
    
    NSLog(@"Changed Client %@ attribute '%@' to '%@'", client.resourceID, textField.identifier, textField.stringValue);
}


@end
