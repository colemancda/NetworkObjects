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
    self = [super init];
    if (self) {
        
        
        
    }
    return self;
}

#pragma mark - First Responder

-(void)newDocument:(id)sender
{
    
    
}

#pragma mark - ComboBox Data Source

-(NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    NSArray *namesOfEntities = appDelegate.store.context.persistentStoreCoordinator.managedObjectModel.entitiesByName.allKeys;
    
    return namesOfEntities.count;
}

-(id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    
    
    return nil;
}

#pragma mark - ComboBox Delegate

-(void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    
    
}



@end
