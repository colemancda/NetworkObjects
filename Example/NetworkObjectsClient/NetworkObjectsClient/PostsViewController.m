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
    
    [self.refreshControl addTarget:self.tableView
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

#pragma mark

-(void)downloadData
{
    // download all the posts specified
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSMutableArray *posts = [[NSMutableArray alloc] init];
    
    // download User again
    
    NSLog(@"Downloading User...");
    
    [[ClientStore sharedStore].store getResource:@"User" resourceID:[ClientStore sharedStore].user.resourceID.integerValue completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
       
        if (error) {
            
            [error presentError];
            
            return;
        }
        
        // download each post
        
        User *user = (User *)resource;
        
        NSMutableArray *dataTasks = [[NSMutableArray alloc] init];
        
        __block BOOL errorOcurred;
        
        __block BOOL finished;
        
        NSLog(@"Downloading posts...");
        
        for (Post *post in user.posts) {
            
            if (errorOcurred) {
                
                return;
            }
            
            NSURLSessionDataTask *task = [[ClientStore sharedStore].store getResource:@"Post" resourceID:post.resourceID.integerValue completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource)
            {
                if (error) {
                    
                    errorOcurred = YES;
                    
                    for (NSURLSessionDataTask *dataTask in dataTasks) {
                        
                        [dataTask cancel];
                    }
                    
                    return;
                }
                
                [posts addObject:resource];
                
                if (finished) {
                    
                    return;
                }
                
                if (user.posts.count == dataTasks.count) {
                    
                    for (NSURLSessionDataTask *dataTask in dataTasks) {
                        
                        if (dataTask.state != NSURLSessionTaskStateCompleted) {
                            
                            return;
                        }
                        
                        // all posts finished downloading
                        
                        _posts = posts;
                        
                        finished = YES;
                        
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                            
                            [self.tableView reloadData];
                            
                            [self.refreshControl endRefreshing];
                            
                            NSLog(@"Finished downloading Posts");
                            
                        }];
                    }
                }
            }];
            
            [dataTasks addObject:task];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
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
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
