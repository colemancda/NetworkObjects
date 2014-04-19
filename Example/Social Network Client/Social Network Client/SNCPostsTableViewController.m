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
#import "User.h"
#import "NSError+presentError.h"
#import "SNCPostViewController.h"
#import "SNCPostCell.h"

static void *KVOContext = &KVOContext;

@interface SNCPostsTableViewController ()

@property (nonatomic) NSURLSession *urlSession;

@property (nonatomic) NSDate *dateLastFetched;

@end

@interface SNCPostsTableViewController (ConfigureCell)

-(void)configureCell:(SNCPostCell *)cell
        forIndexPath:(NSIndexPath *)indexPath;

@end

@implementation SNCPostsTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        // KVO
        [self addObserver:self
               forKeyPath:NSStringFromSelector(@selector(predicate))
                  options:NSKeyValueObservingOptionNew
                  context:KVOContext];
        
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
    
    // default predicate
    
    self.predicate = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(predicate))];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == KVOContext) {
        
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(predicate))]) {
            
            // create fetch request
            
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
            
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"resourceID"
                                                                           ascending:NO]];
            fetchRequest.predicate = self.predicate;
            
            // make nsfetchedresultscontroller
            _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[SNCStore sharedStore].mainContext sectionNameKeyPath:nil cacheName:nil];
            
            _fetchedResultsController.delegate = self;
            
            NSError *fetchError;
            
            [_fetchedResultsController performFetch:&fetchError];
            
            if (fetchError) {
                
                [NSException raise:NSInternalInconsistencyException
                            format:@"Error executing fetch request. (%@)", fetchError.localizedDescription];
            }
            
            // fetch
            [self fetchData:nil];
            
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Fetch data

-(void)fetchData:(id)sender
{
    // refetch all of the fetch results
    
    self.dateLastFetched = [NSDate date];
    
    [[SNCStore sharedStore] searchForCachedResourceWithFetchRequest:_fetchedResultsController.fetchRequest URLSession:self.urlSession completion:^(NSError *error, NSArray *results) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [self.tableView reloadData];
            
            [self.refreshControl endRefreshing];
            
        }];
       
        if (error) {
            
            [error presentError];
            
            return;
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
    
    return _fetchedResultsController.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SNCPostCell";
    
    SNCPostCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                            forIndexPath:indexPath];
    
    [self configureCell:cell forIndexPath:indexPath];
    
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
    // get model object
    Post *post = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [[SNCStore sharedStore] deleteCachedResource:(id)post URLSession:self.urlSession completion:^(NSError *error) {
            
            if (error) {
                
                [error presentError];
                
                return;
            }
            
        }];
        
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


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

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"selectedPost"]) {
        
        // set post object
        SNCPostViewController *postVC = segue.destinationViewController;
        
        postVC.post = _fetchedResultsController.fetchedObjects[self.tableView.indexPathForSelectedRow.row];
        
    }
    
}

-(void)savedPost:(UIStoryboardSegue *)segue
{
    SNCPostViewController *postVC = segue.sourceViewController;
    
    // create new post
    if (!postVC.post) {
        
        [[SNCStore sharedStore] createCachedResource:@"Post" initialValues:@{@"text": postVC.textView.text} URLSession:postVC.urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (error) {
                
                [error presentError];
                
                return;
            }
            
            // configure new post
            
            Post *post = (Post *)resource;
            
            [post.managedObjectContext performBlock:^{
                
                post.creator = [SNCStore sharedStore].user;
                
                post.created = [NSDate date];
                
                // save
                
                NSError *saveError;
                
                if (![post.managedObjectContext save:&saveError]) {
                    
                    [NSException raise:NSInternalInconsistencyException
                                format:@"%@", saveError.localizedDescription];
                }
                
            }];
            
        }];
        
    }
    
    // edit existing post
    else {
        
        [[SNCStore sharedStore] editCachedResource:(id)postVC.post changes:@{@"text": postVC.textView.text} URLSession:postVC.urlSession completion:^(NSError *error) {
            
            if (error) {
                
                [error presentError];
                
                return;
            }
            
        }];
    }
     
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    
    [self.tableView beginUpdates];
    
}


- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            
            // setup cell without reloading it...
            
            [self configureCell:(SNCPostCell *)[self.tableView cellForRowAtIndexPath:indexPath]
                   forIndexPath:indexPath];
            
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
    
}


- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id )sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
    
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    
    [self.tableView endUpdates];
}


@end

@implementation SNCPostsTableViewController (ConfigureCell)

-(void)configureCell:(SNCPostCell *)cell
        forIndexPath:(NSIndexPath *)indexPath
{
    // blocks
    
    Post *post = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    // download if not in cache...
    
    NSDate *dateCached = [[SNCStore sharedStore] dateCachedForResource:@"Post"
                                                            resourceID:post.resourceID.integerValue];
    
    // never downloaded / not in cache
    if (!dateCached) {
        
        // Configure the cell...
        cell.textContentLabel.text = NSLocalizedString(@"Loading...",
                                                @"Loading...");
        
        cell.dateLabel.text = @"";
        
        // lazily download
        
        [[SNCStore sharedStore] getCachedResource:@"Post" resourceID:post.resourceID URLSession:self.urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (error) {
                
                [error presentError];
                
            }
            
        }];
        
        return;
    }
    
    // was downloaded before the table was reloaded
    
    if ([dateCached compare:self.dateLastFetched] == NSOrderedAscending) {
        
        [[SNCStore sharedStore] getCachedResource:@"Post" resourceID:post.resourceID URLSession:self.urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (error) {
                
                [error presentError];
                
            }
            
        }];
        
    }
    
    // Configure the cell...
    cell.textContentLabel.text = post.text;
    
    if (!_dateFormatter) {
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
    }
    
    cell.dateLabel.text = [_dateFormatter stringFromDate:post.created];
    
}

@end

