//
//  PostsViewController.m
//  NetworkObjectsClient
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "PostsViewController.h"
#import "ClientStore.h"
#import "Post.h"
#import "AppDelegate.h"
#import "NSError+presentError.h"
#import "User.h"
#import "Post.h"
#import "PostComposerViewController.h"
#import "PostCell.h"

static NSString *CellIdentifier = @"PostCell";

@interface PostsViewController ()

@end

@implementation PostsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _posts = [[NSMutableArray alloc] init];
    
    [self.refreshControl addTarget:self
                            action:@selector(downloadData)
                  forControlEvents:UIControlEventValueChanged];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self downloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refreshFromCache];
}

#pragma mark

-(void)refreshFromCache
{
    NSLog(@"Loading posts from cache");
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"resourceID"
                                                           ascending:YES];
    
    _posts = [NSMutableArray arrayWithArray:[[ClientStore sharedStore].user.posts.allObjects sortedArrayUsingDescriptors:@[sort]]];
    
    [self.tableView reloadData];
}

-(void)downloadData
{
    // download all the posts specified
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // download User again
    
    NSLog(@"Downloading User...");
    
    [[ClientStore sharedStore].store getResource:@"User" resourceID:[ClientStore sharedStore].user.resourceID.integerValue completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
       
        if (error) {
            
            [error presentError];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                [self.refreshControl endRefreshing];
                
            }];
            
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            [self refreshFromCache];
            
            [self.refreshControl endRefreshing];
            
            NSLog(@"Finished downloading user");
            
        }];
        
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PostCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    // get the model object
    Post *post = _posts[indexPath.row];
    
    if (!post.created ||
        !post.creator ||
        !post.text) {
        
        cell.textLabel.text = @"Loading...";
        
        cell.dateLabel.text = @"";
        
        cell.userLabel.text = @"";
        
        // download post
        [[ClientStore sharedStore].store getResource:post.entity.name resourceID:post.resourceID.integerValue completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
           
            if (error) {
                
                [error presentError];
                
                return;
            }
            
            Post *post = (Post *)resource;
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
               
                cell.textLabel.text = post.text;
                
                cell.dateLabel.text = post.created.description;
                
                cell.userLabel.text = post.creator.username;
                
                NSLog(@"downloaded post %@", post.resourceID);
                
            }];
        }];
        
        return cell;
    }
    
    cell.textLabel.text = post.text;
    
    cell.dateLabel.text = post.created.description;
    
    cell.userLabel.text = post.creator.username;
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Delete the row from the data source...
        
        Post *post = _posts[indexPath.row];
        
        [[ClientStore sharedStore].store deleteResource:(NSManagedObject<NOResourceKeysProtocol> *)post completion:^(NSError *error) {
            
            if (error) {
                
                [error presentError];
                
                return;
            }
            
            [_posts removeObject:post];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                [tableView deleteRowsAtIndexPaths:@[indexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
            }];
            
        }];
        
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
 -(void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
 {
     if ([segue.identifier isEqualToString:@"editPostComposer"]) {
         
         PostComposerViewController *composerVC = segue.destinationViewController;
         
         // get model object
         
         composerVC.post = _posts[self.tableView.indexPathForSelectedRow.row];
         
         composerVC.textView.text = composerVC.post.text;
     }
 }

#pragma mark - Unwinding

-(void)unwindToPostsVC:(UIStoryboardSegue *)segue
{
    
    
}


@end
