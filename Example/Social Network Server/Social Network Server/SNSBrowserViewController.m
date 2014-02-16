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

@end

@implementation SNSBrowserViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        //
        
    }
    return self;
}

-(void)loadView
{
    [super loadView];
    
    // load comboBox...
    
    // get NSArray of strings from the names of the entities
    
    SNSAppDelegate *appDelegate = [NSApp delegate];
    
    NSArray *namesOfEntities = appDelegate.store.context.persistentStoreCoordinator.managedObjectModel.entitiesByName.allKeys;
    
    [self.comboBox addItemsWithObjectValues:namesOfEntities];
    
    
    
}

#pragma mark - First Responder

-(void)newDocument:(id)sender
{
    
    
}

@end
