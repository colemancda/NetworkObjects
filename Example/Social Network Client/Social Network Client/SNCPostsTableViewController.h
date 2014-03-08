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
    
    NSDateFormatter *_dateFormatter;
    
    NSError *_errorDownloadingPost;
}

@property User *user;

@property (readonly) NSDate *dateLastFetched;

@property (readonly) NSURLSession *urlSession;

-(IBAction)fetchData:(id)sender;

#pragma mark - Segue

-(IBAction)savedPost:(UIStoryboardSegue *)segue;


@end
