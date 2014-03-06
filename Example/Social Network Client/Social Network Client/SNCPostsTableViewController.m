//
//  SNCPostsTableViewController.m
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/25/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNCPostsTableViewController.h"
#import "SNCStore.h"
#import "Post.h"
#import <NetworkObjects/NetworkObjects.h>
#import "User.h"

@interface SNCPostsTableViewController ()

@property NSFetchedResultsController *fetchedResultsController;

@property NSURLSession *urlSession;

@end

@implementation SNCPostsTableViewController (FetchCompletion)

-(void)didFinishFetching
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        [self.refreshControl endRefreshing];
        
        [self.tableView reloadData];
        
    }];
}

@end

@implementation SNCPostsTableViewController

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
    
    // KVO
    
    [self addObserver:self forKeyPath:@"users" options:NSKeyValueObservingOptionNew context:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"users"];
    
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if ([keyPath isEqualToString:@"users"]) {
        
        NSPredicate *predicate;
        
        if (self.users.count) {
            
            // build predicate string
            NSString *predicateString = @"";
            
            for (User *user in self.users) {
                
                predicateString = [predicateString stringByAppendingFormat:@"creator == %@", user];
                
                // multiple user posts
                if (self.users.count > 1) {
                    
                    if (user != self.users.lastObject) {
                        
                        predicateString = [predicateString stringByAppendingString:@" OR "];
                    }
                }
            }
            
            predicate = [NSPredicate predicateWithFormat:predicateString
                                           argumentArray:self.users];
            
            NSAssert(predicate, @"Predicate must be created");
            
        }
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
        
        // may be nil if the self.users array is nil or empty
        fetchRequest.predicate = predicate;
        
        // make nsfetchedresultscontroller
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[SNCStore sharedStore].context sectionNameKeyPath:@"created" cacheName:nil];
        
        self.fetchedResultsController.delegate = self;
        
        NSError *fetchError;
        
        // fetch
        [self fetchData:nil];
        
        if (fetchError) {
            
            [NSException raise:NSInternalInconsistencyException
                        format:@"Error executing fetch request. %@", fetchError.localizedDescription];
        }
        
        
        
    }
    
    
}

#pragma mark - Fetch data

-(void)fetchData:(id)sender
{
    // fetch user
    
    __block NSUInteger remainingUsersToFetch = self.users.count;
    
    __block BOOL errorOccurred;
    
    // success block
    
    for (User *user in self.users) {
        
        if (errorOccurred) {
            
            return;
        }
        
        [[SNCStore sharedStore] getCachedResource:@"User" resourceID:user.resourceID.integerValue URLSession:nil completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (errorOccurred) {
                
                return;
            }
            
            if (error) {
                
                errorOccurred = YES;
                
                [self didFinishFetching];
                
                return;
            }
            
            remainingUsersToFetch--;
            
            // last user fetched
            if (!remainingUsersToFetch) {
                
                [self didFinishFetching];
            }
            
        }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return _fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _fetchedResultsController ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
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
