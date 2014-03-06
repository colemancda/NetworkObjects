//
//  SNCPostsTableViewController.h
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/25/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreData;
@class User;

@interface SNCPostsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *_fetchedResultsController;
}

@property NSArray *users;

@property (readonly) NSURLSession *urlSession;

-(IBAction)fetchData:(id)sender;

@end
