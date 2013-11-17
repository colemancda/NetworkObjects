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
    
    _posts = [NSMutableArray arrayWithArray:[ClientStore sharedStore].user.posts.allObjects];
    
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
        
        // download each post
        
        User *user = (User *)resource;
        
        if (!user.posts.count) {
            
            _posts = [[NSMutableArray alloc] init];
            
            NSLog(@"User has 0 posts");
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                [self.tableView reloadData];
                
                [self.refreshControl endRefreshing];
                
                NSLog(@"Finished downloading Posts");
                
            }];
        }
        
        NSLog(@"Downloading posts...");
        
        __block NSError *previousError;
        
        __block NSInteger counter = user.posts.count;
        
        for (Post *post in user.posts) {
            
            [[ClientStore sharedStore].store getResource:@"Post" resourceID:post.resourceID.integerValue completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource)
            {
                if (error) {
                    
                    previousError = error;
                    
                    [error presentError];
                    
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        
                        [self.refreshControl endRefreshing];
                        
                    }];
                    
                    return;
                }
                
                if (previousError) {
                    
                    return;
                }
                
                counter--;
                
                if (counter == 0) {
                    
                    // all posts finished downloading
                    
                    _posts = [NSMutableArray arrayWithArray:user.posts.allObjects];
                    
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        
                        [self.tableView reloadData];
                        
                        [self.refreshControl endRefreshing];
                        
                        NSLog(@"Finished downloading Posts");
                        
                    }];
                }
            }];
        }
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
    
    cell.textLabel.text = post.text;
    
    cell.userLabel.text = post.creator.username;
    
    cell.dateLabel.text = post.created.description;
    
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
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
         
     }
 }

#pragma mark - Unwinding

-(void)unwindToPostsVC:(UIStoryboardSegue *)segue
{
    
    
}


@end
